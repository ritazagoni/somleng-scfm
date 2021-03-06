RSpec.shared_examples_for "has_metadata" do
  describe "#metadata" do
    def assert_metadata!
      expect(subject.metadata).to eq({})
    end

    it { assert_metadata! }
  end

  describe ".metadata_has_value(key, value)" do
    let(:metadata_key) { "foo" }
    let(:metadata_value) { "bar" }
    let(:metadata) { { metadata_key => metadata_value } }

    let(:key) { metadata_key }
    let(:value) { metadata_value }
    let(:results) { described_class.metadata_has_value(key, value) }

    let(:record_with_metadata) { create(factory, :metadata => metadata) }
    let(:record_without_metadata) { create(factory) }

    before do
      setup_scenario
    end

    def setup_scenario
      record_with_metadata
      record_without_metadata
    end

    def assert_scope!
      expect(results).to match_array(asserted_results)
    end

    context "passing a key and value matching existing metadata" do
      let(:asserted_results) { [record_with_metadata] }
      it { assert_scope! }
    end

    context "passing nil as the value" do
      let(:value) { nil }

      context "where the key exists (but it's value is nil)" do
        let(:metadata_value) { nil }
        let(:asserted_results) { [record_with_metadata, record_without_metadata] }

        it { assert_scope! }
      end

      context "where the key does not exist" do
        let(:asserted_results) { [record_without_metadata] }
        it { assert_scope! }
      end
    end
  end
end
