require 'rails_helper'

RSpec.describe PhoneNumber do
  let(:factory) { :phone_number }
  include_examples "has_metadata"

  include SomlengScfm::SpecHelpers::MsisdnExamples

  def msisdn_uniqueness_matcher
    super.scoped_to(:callout_id)
  end

  it_behaves_like "has_msisdn"

  describe "associations" do
    def assert_associations!
      is_expected.to belong_to(:callout)
      is_expected.to belong_to(:contact)
      is_expected.to have_many(:phone_calls)
    end

    it { assert_associations! }
  end

  describe "validations" do
    context "persisted" do
      subject { create(factory) }

      def assert_validations!
        is_expected.to validate_uniqueness_of(:contact_id).scoped_to(:callout_id)
      end

      it { assert_validations! }
    end
  end

  describe "scopes" do
    before do
      setup_scenario
    end

    def setup_scenario
    end

    def assert_scope!
      expect(results).to match_array(asserted_results)
    end

    describe ".from_running_callout" do
      let(:running_callout) { create(:callout, :status => :running) }
      let(:phone_number) { create(factory, :callout => running_callout) }
      let(:results) { described_class.from_running_callout }
      let(:asserted_results) { [phone_number] }

      def setup_scenario
        create(factory)
        phone_number
      end

      it { assert_scope! }
    end

    context "relating to phone calls" do
      let(:callout) { create(:callout) }

      let(:phone_number_with_no_calls) {
        create(
          :phone_number, :callout => callout
        )
      }

      let(:phone_number_last_attempt_failed) {
        create_phone_number_last_attempt(
          :failed,
          :previous_attempt => :completed,
          :callout => callout
        )
      }

      let(:phone_number_last_attempt_completed) {
        create_phone_number_last_attempt(
          :completed,
          :previous_attempt => :failed,
          :callout => callout
        )
      }

      def setup_scenario
        super
        phone_number_with_no_calls
        phone_number_last_attempt_completed
        phone_number_last_attempt_failed
      end

      def create_phone_number_last_attempt(status, options = {})
        previous_attempt = options.delete(:previous_attempt)

        first_attempt = build(
          :phone_call,
          :status => previous_attempt,
          :phone_number => nil
        ) if previous_attempt

        last_attempt = build(
          :phone_call,
          :status => status,
          :phone_number => nil
        )

        create(
          :phone_number, {
            :phone_calls => [first_attempt, last_attempt].compact
          }.merge(options)
        )
      end

      describe ".remaining" do
        let(:results) { described_class.remaining }

        def setup_scenario
          stub_env(env)
          super
        end

        def env
          {
            "PHONE_NUMBER_RETRY_STATUSES" => retry_statuses
          }
        end

        context "by default" do
          let(:retry_statuses) { nil }
          let(:asserted_results) { [phone_number_with_no_calls, phone_number_last_attempt_failed] }
          it { assert_scope! }
        end

        context "PHONE_NUMBER_RETRY_STATUSES='failed,completed'" do
          let(:retry_statuses) { "failed,completed" }
          let(:asserted_results) { [phone_number_with_no_calls, phone_number_last_attempt_failed, phone_number_last_attempt_completed] }
          it { assert_scope! }
        end
      end

      describe ".last_phone_call_attempt(status)" do
        let(:results) { described_class.last_phone_call_attempt(status) }

        context "failed" do
          let(:status) { :failed }
          let(:asserted_results) { [phone_number_last_attempt_failed] }
          it { assert_scope! }
        end

        context "completed" do
          let(:status) { :completed }
          let(:asserted_results) { [phone_number_last_attempt_completed] }
          it { assert_scope! }
        end

        context "failed or completed" do
          let(:status) { [:failed, :completed] }
          let(:asserted_results) { [phone_number_last_attempt_failed, phone_number_last_attempt_completed] }
          it { assert_scope! }
        end
      end

      describe ".no_phone_calls_or_last_attempt(status)" do
        let(:status) { :failed }
        let(:results) { described_class.no_phone_calls_or_last_attempt(status) }
        let(:asserted_results) { [phone_number_with_no_calls, phone_number_last_attempt_failed] }
        it { assert_scope! }
      end

      describe ".no_phone_calls" do
        let(:results) { described_class.no_phone_calls }
        let(:asserted_results) { [phone_number_with_no_calls] }
        it { assert_scope! }
      end
    end
  end
end
