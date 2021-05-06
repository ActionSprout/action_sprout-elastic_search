require "spec_helper"

require "action_sprout/elastic_search/get_document"

RSpec.describe ActionSprout::ElasticSearch::GetDocument do
  let(:client) { ActionSprout::ElasticSearch.client }

  let(:index) { double index_name: "example_test", index_type: "example" }

  let(:id) { "123" }

  let(:document) {
    {
      "name" => "I Am Rose"
    }
  }

  before do
    client.indices.create index: index.index_name, ignore: [400]
    client.index index: index.index_name, type: index.index_type, id: id, body: document
  end

  it "can load a document from elasticsearch" do
    source = described_class.call index: index, id: id

    expect(source["name"]).to eq "I Am Rose"
  end

  it "returns nil when the document does not exist" do
    source = described_class.call index: index, id: "1234"

    expect(source).to be_nil
  end
end
