require 'rails_helper'

RSpec.describe CalloutsTask do
  describe CalloutsTask::Install do
    describe ".rake_tasks" do
      it { expect(described_class.rake_tasks).to eq([:run!, :create!, :populate!, :statistics]) }
    end
  end

  describe "#callout" do
    before do
      setup_scenario
    end

    let(:callout_task_callout_id) { nil }
    let(:callout) { create(:callout) }
    let(:result) { subject.callout }

    def setup_scenario
      stub_env(env)
    end

    def env
      {
        "CALLOUTS_TASK_CALLOUT_ID" => callout_task_callout_id
      }
    end

    def assert_result!
      expect(result).to eq(asserted_result)
    end

    def assert_result_not_found!
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "no callouts exist" do
      it { assert_result_not_found! }
    end

    context "callouts exist" do
      let(:asserted_result) { callout }

      def setup_scenario
        super
        callout
      end

      context "one callout exists" do
        context "by default" do
          it { assert_result! }
        end

        context "setting CALLOUT_TASK_CALLOUT_ID to an id that doesn't exist" do
          let(:callout_task_callout_id) { 0 }
          it { assert_result_not_found! }
        end

        context "setting CALLOUT_TASK_CALLOUT_ID to an id that exists" do
          let(:callout_task_callout_id) { callout.id }
          it { assert_result! }
        end
      end

      context "multiple callouts exist" do
        let(:asserted_result) { callout }

        def setup_scenario
          super
          create(:callout)
        end

        context "by default" do
          it { assert_result_not_found! }
        end

        context "setting CALLOUT_TASK_CALLOUT_ID to an id that doesn't exist" do
          let(:callout_task_callout_id) { 0 }
          it { assert_result_not_found! }
        end

        context "setting CALLOUT_TASK_CALLOUT_ID to an id that exists" do
          let(:callout_task_callout_id) { callout.id }
          it { assert_result! }
        end
      end
    end
  end

  describe "#run!" do
    let(:callout) { create(:callout, "can_#{callout_event}".gsub(/!$/, "").to_sym) }

    before do
      setup_scenario
    end

    def setup_scenario
      stub_env(env)
      callout
    end

    def env
      {
        "CALLOUTS_TASK_ACTION" => callouts_task_action.to_s
      }
    end

    def assert_event!
      expect(subject.run!).to eq(true)
    end

    [:start, :stop, :pause, :resume].each do |callout_event|
      context "CALLOUTS_TASK_ACTION='#{callout_event}'" do
        let(:callout_event) { callout_event }
        let(:callouts_task_action) { callout_event }
        it { assert_event! }
      end
    end

    context "CALLOUTS_TASK_ACTION=" do
      let(:callout_event) { :start }
      let(:callouts_task_action) { nil }
      it { expect { subject.run! }.to raise_error(ArgumentError) }
    end

    context "CALLOUTS_TASK_ACTION='delete'" do
      let(:callout_event) { :start }
      let(:callouts_task_action) { "delete" }
      it { expect { subject.run! }.to raise_error(ArgumentError) }
    end
  end

  describe "#create!" do
    let(:metadata) { nil }
    let(:asserted_metadata) { {} }
    let(:result) { subject.create! }

    before do
      setup_scenario
    end

    def setup_scenario
      allow(STDOUT).to receive(:puts)
      stub_env(env)
    end

    def env
      {
        "CALLOUTS_TASK_CREATE_METADATA" => metadata && metadata.to_json
      }
    end

    def assert_create!
      expect(STDOUT).to receive(:puts).with(Integer)
      expect(result).to eq(Callout.last!)
      expect(result.metadata).to eq(asserted_metadata)
    end

    it { assert_create! }

    context "specifying metadata" do
      let(:metadata) { { "foo" => "bar" } }
      let(:asserted_metadata) { metadata }

      it { assert_create! }
    end
  end

  describe "#populate!" do
    let(:metadata) { nil }
    let(:callout) { create(:callout) }
    let(:asserted_metadata) { {} }
    let(:contact) { create(:contact) }

    before do
      setup_scenario
    end

    def setup_scenario
      callout
      contact
      stub_env(env)
    end

    def env
      {
        "CALLOUTS_TASK_POPULATE_METADATA" => metadata && metadata.to_json
      }
    end

    def assert_populate!
      subject.populate!
      expect(callout.contacts).to match_array([contact])
      phone_number = callout.phone_numbers.last!
      expect(phone_number.metadata).to eq(asserted_metadata)
    end

    it { assert_populate! }

    context "specifying metadata" do
      let(:metadata) { { "foo" => "bar" } }
      let(:asserted_metadata) { metadata }

      it { assert_populate! }
    end
  end

  describe "#statistics" do
    let(:callout) { create(:callout) }
    let(:phone_number) { create(:phone_number, :callout => callout) }
    let(:callout_id) { callout.id }

    before do
      setup_scenario
    end

    def setup_scenario
      stub_env(env)
      phone_number
      create(:phone_number)
    end

    def env
      {
        "CALLOUTS_TASK_CALLOUT_ID" => callout_id
      }
    end

    def assert_statistics!
      expect(STDOUT).to receive(:puts) do |arg|
        expect(arg).to include("Callout Status")
        expect(arg).to match(/Total Phone Numbers:\s+1/)
      end
      subject.statistics
    end

    it { assert_statistics! }
  end
end
