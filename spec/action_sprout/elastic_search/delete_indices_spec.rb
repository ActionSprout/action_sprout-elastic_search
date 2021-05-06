require "spec_helper"

require "action_sprout/elastic_search/delete_indices"

RSpec.describe ActionSprout::ElasticSearch::DeleteIndices, ".call" do
  let(:client) { ElasticSearch.client }

  it "can delete an index that exists" do
    client.indices.create index: "examples_test", ignore: [400]
    ActionSprout::ElasticSearch::DeleteIndices.call indices: ["examples_test"]

    expect(client.indices.exists?(index: "examples_test")).to eq false
  end

  it "does not fail if the index does not already exist" do
    ActionSprout::ElasticSearch::DeleteIndices.call indices: ["examples_test"]
    ActionSprout::ElasticSearch::DeleteIndices.call indices: ["examples_test"]

    expect(client.indices.exists?(index: "examples_test")).to eq false
  end
end
