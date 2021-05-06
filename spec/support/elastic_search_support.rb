require "action_sprout/elastic_search"
require "action_sprout/elastic_search/load_index_options"
require "action_sprout/elastic_search/setup_indices"
require "action_sprout/elastic_search/delete_indices"

module ElasticSearchSupport
  extend ActiveSupport::Concern

  def refresh_index(index_name)
    ActionSprout::ElasticSearch.client.indices.refresh index: index_name_for(index_name)
  end

  def index_name_for(index_name)
    ActionSprout::ElasticSearch.index_name_for(index_name)
  end

  module ClassMethods
    def setup_index(index_name)
      before(:all) do
        index = index_name_for(index_name)
        config_path = Pathname.new("spec/indices")
        index_options = ActionSprout::ElasticSearch::LoadIndexOptions.call(config_path: config_path)[index] || {}
        ActionSprout::ElasticSearch::DeleteIndices.call indices: [index]
        ActionSprout::ElasticSearch::SetupIndices.call indices: {index => index_options}
      end

      after(:all) do
        index = index_name_for(index_name)
        ActionSprout::ElasticSearch::DeleteIndices.call indices: [index]
      end
    end
  end
end

RSpec.configure do |config|
  config.include ElasticSearchSupport
end
