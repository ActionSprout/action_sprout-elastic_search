require "spec_helper"
require_relative "../../support/elastic_search_support"

require "action_sprout/elastic_search/get_documents"
require "action_sprout/elastic_search/index_records"

RSpec.describe ActionSprout::ElasticSearch::GetDocuments do
  let(:client) { ElasticSearch.client }

  setup_index "example"

  let(:default_options) do
    {index_name: "example_test", index_type: "example", join_field: nil, parent_id: nil, action: :update}
  end

  let(:index) { double default_options }

  let(:records) {
    [
      double(default_options.merge(id: "1", source_data: {name: "Hi 1"})),
      double(default_options.merge(id: "2", source_data: {name: "Hi 2"})),
      double(default_options.merge(id: "3", source_data: {name: "Hi 3", extra: "Hi"}))
    ]
  }

  before do
    ActionSprout::ElasticSearch::IndexRecords.call records: records
  end

  it "can load multiple documents from elasticsearch" do
    documents = described_class.call index: index, ids: ["1", "2"]

    expect(documents).to eq "1" => {"name" => "Hi 1"}, "2" => {"name" => "Hi 2"}
  end

  it "results in nil for documents that do not exist" do
    documents = described_class.call index: index, ids: ["1", "9"]

    expect(documents).to eq "1" => {"name" => "Hi 1"}, "9" => nil
  end

  it "can request only certain fields from the source" do
    documents = described_class.call index: index, ids: ["1", "3"], source: ["extra"]

    expect(documents).to eq "1" => {}, "3" => {"extra" => "Hi"}
  end
end
