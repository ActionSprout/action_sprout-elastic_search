require "spec_helper"

require "action_sprout/elastic_search/load_index_options"

RSpec.describe ActionSprout::ElasticSearch::LoadIndexOptions, ".call" do
  describe "#options_for_index" do
    let(:options) { subject.options_for_index "stories" }

    it "loads index settings" do
      expect(options[:settings]).to eq({
        "index" => {
          "number_of_shards" => "1",
          "number_of_replicas" => "1",
          "refresh_interval" => "30s"
        }
      })
    end

    it "loads index mappings" do
      expect(options.dig(:mappings, "story", "properties", "country")).to eq "type" => "keyword"
    end
  end

  describe "#call" do
    it "loads all indices and suffixes their names" do
      expect(subject.call.keys).to match_array [
        "affiliations_test",
        "inspiration_test",
        "recommended_stories_test",
        "stories_test",
        "timeline_posts_test",
        "tracked_ads_test"
      ]
    end

    it "loads settings for all of the indices" do
      number_of_shardses = subject.call.map do |_index_name, options|
        options.dig(:settings, "index", "number_of_shards")
      end

      expect(number_of_shardses).to eq(["1"] * number_of_shardses.size)
    end
  end
end
