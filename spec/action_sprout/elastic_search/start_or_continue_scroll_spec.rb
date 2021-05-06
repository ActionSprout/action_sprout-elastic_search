require "spec_helper"

require "action_sprout/elastic_search/start_or_continue_scroll"
require "action_sprout/elastic_search/index_records"

RSpec.describe ActionSprout::ElasticSearch::StartOrContinueScroll, ".call" do
  setup_index "examples"

  let(:index) { double index_name: "examples_test", index_type: "example" }
  let(:cache_key) { "example_scroll_test" }
  let(:cache_service) { ActiveSupport::Cache::MemoryStore.new }

  class Thing
    kwattr :id,
      index_name: "examples_test",
      index_type: "example",
      join_field: nil,
      parent_id: nil,
      action: :create

    def source_data
      {num: id}
    end
  end

  before(:all) do |test|
    # Make a bunch of records to search with
    records = 1.upto(10).map { |i| Thing.new id: i }
    ActionSprout::ElasticSearch::IndexRecords.call records: records

    refresh_index "examples"
  end

  before do
    cache_service.delete cache_key
  end

  after do
    scroll_id = cache_service.read cache_key
    cache_service.clear

    if scroll_id.present?
      ActionSprout::ElasticSearch.client.clear_scroll scroll_id: scroll_id
    end
  end

  let(:query) {
    {
      sort: ["num:asc"],
      body: {
        query: {
          range: {num: {lt: 6}}
        }
      }
    }
  }

  it "can start a search" do
    results = described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

    expect(results.map { |doc| doc["_source"]["num"] }).to eq [1, 2]
  end

  it "stores the scroll id" do
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

    expect(cache_service.read(cache_key)).to be
  end

  it "can continue a search" do
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    results = described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

    expect(results.map { |doc| doc["_source"]["num"] }).to eq [3, 4]
  end

  it "can continue a search again" do
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    results = described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

    expect(results.map { |doc| doc["_source"]["num"] }).to eq [5]
  end

  it "the last time it returns an empty array" do
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    results = described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

    expect(results).to be_empty
  end

  it "the last time clears the scroll id as well" do
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
    described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

    expect(cache_service.read(cache_key)).to be_nil
  end

  context "when the scroll has expired" do
    let(:original_scroll_id) { cache_service.read cache_key }

    before do
      described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service
      ActionSprout::ElasticSearch.client.clear_scroll scroll_id: original_scroll_id
    end

    it "starts a new scroll" do
      described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

      expect(cache_service.read(cache_key)).to_not eq(original_scroll_id)
    end

    it "returns the first result set again" do
      results = described_class.call index: index, query: query, batch_size: 2, cache_key: cache_key, cache_service: cache_service

      expect(results.map { |doc| doc["_source"]["num"] }).to eq [1, 2]
    end
  end
end
