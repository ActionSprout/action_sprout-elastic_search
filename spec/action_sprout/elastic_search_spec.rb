# frozen_string_literal: true

RSpec.describe ActionSprout::ElasticSearch do
  it "has a version number" do
    expect(ActionSprout::ElasticSearch::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(ActionSprout::ElasticSearch.client).to_not be_nil
  end
end
