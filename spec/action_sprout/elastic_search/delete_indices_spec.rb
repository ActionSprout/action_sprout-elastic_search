require "spec_helper"

require "action_sprout/elastic_search/delete_indices"

RSpec.describe ActionSprout::ElasticSearch::DeleteIndices, ".call" do
  let(:client) { ActionSprout::ElasticSearch.client }

  it "can delete an index that exists" do
    client.indices.create index: "examples_test", ignore: [400]
    described_class.call indices: ["examples_test"]

    expect(client.indices.exists?(index: "examples_test")).to eq false
  end

  it "does not fail if the index does not already exist" do
    described_class.call indices: ["examples_test"]
    described_class.call indices: ["examples_test"]

    expect(client.indices.exists?(index: "examples_test")).to eq false
  end
end
