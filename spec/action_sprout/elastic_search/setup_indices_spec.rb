require 'spec_helper'

require 'action_sprout/elastic_search/setup_indices'
require 'action_sprout/elastic_search/delete_indices'

RSpec.describe ActionSprout::ElasticSearch::SetupIndices, '.call' do
  let(:client) { ActionSprout::ElasticSearch.client }

  before do
    ActionSprout::ElasticSearch::DeleteIndices.call indices: ['examples_test']
  end

  it 'can set up an empty index' do
    ActionSprout::ElasticSearch::SetupIndices.call indices: { examples_test: {} }

    expect(client.indices.exists? index: 'examples_test').to eq true
  end

  it 'can set up a mapping' do
    ActionSprout::ElasticSearch::SetupIndices.call indices: {
      examples_test: {
        mappings: {
          example: {
            properties: {
              name: { type: 'keyword' },
            },
          },
        },
      },
    }

    result = client.indices.get index: 'examples_test'
    expect(result.dig('examples_test', 'mappings', 'example', 'properties', 'name', 'type')).to eq 'keyword'
  end

  it 'can set up settings' do
    ActionSprout::ElasticSearch::SetupIndices.call indices: {
      examples_test: {
        settings: {
          index: {
            number_of_shards: 2,
            number_of_replicas: 2,
            refresh_interval: '2s',
          },
        },
      },
    }

    result = client.indices.get index: 'examples_test'
    expect(result.dig('examples_test', 'settings', 'index', 'refresh_interval')).to eq '2s'
    expect(result.dig('examples_test', 'settings', 'index', 'number_of_shards')).to eq "2"
    expect(result.dig('examples_test', 'settings', 'index', 'number_of_replicas')).to eq "2"
  end

  it 'can update a mapping' do
    ActionSprout::ElasticSearch::SetupIndices.call indices: {
      examples_test: {
        mappings: {
          example: {
            properties: {
              name: { type: 'keyword' },
            },
          },
        },
      },
    }

    ActionSprout::ElasticSearch::SetupIndices.call indices: {
      examples_test: {
        mappings: {
          example: {
            properties: {
              description: { type: 'text' },
            },
          },
        },
      },
    }

    result = client.indices.get index: 'examples_test'
    expect(result.dig('examples_test', 'mappings', 'example', 'properties', 'description', 'type')).to eq 'text'
  end

  it 'can update settings' do
    ActionSprout::ElasticSearch::SetupIndices.call indices: { examples_test: {} }

    ActionSprout::ElasticSearch::SetupIndices.call indices: {
      examples_test: {
        settings: {
          index: {
            refresh_interval: '2s',
          },
        },
      },
    }

    result = client.indices.get index: 'examples_test'
    expect(result.dig('examples_test', 'settings', 'index', 'refresh_interval')).to eq '2s'
  end

end

