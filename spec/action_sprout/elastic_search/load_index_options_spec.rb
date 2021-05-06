require 'spec_helper'

require "yaml"
require "erb"
require 'action_sprout/elastic_search/load_index_options'

RSpec.describe ActionSprout::ElasticSearch::LoadIndexOptions, '.call' do
  subject { described_class.new(config_path: Pathname.new("spec/indices")) }

  describe '#options_for_index' do
    let(:options) { subject.options_for_index 'example' }

    it 'loads index settings' do
      expect(options[:settings]).to eq({
        'index' => {
          'number_of_shards' => "1",
          'number_of_replicas' => "2",
          'refresh_interval' => "1s",
        },
      })
    end

    it 'loads index mappings' do
      expect(options.dig(:mappings, 'example', 'properties', 'id')).to eq 'type' => 'long'
    end
  end

  describe '#call' do
    it 'loads all indices and suffixes their names' do
      expect(subject.call.keys).to match_array [
        'example_test',
      ]
    end

    it 'loads settings for all of the indices' do
      number_of_shardses = subject.call.map do |_index_name, options|
        options.dig(:settings, 'index', 'number_of_shards')
      end

      expect(number_of_shardses).to eq(['1'] * number_of_shardses.size)
    end
  end
end

