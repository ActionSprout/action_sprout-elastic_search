require "spec_helper"
require_relative "../../support/elastic_search_support"

require "action_sprout/elastic_search/bulk_query"
require "action_sprout/elastic_search/index_records"

RSpec.describe ActionSprout::ElasticSearch::BulkQuery do
  setup_index "examples"
  let(:index) { double index_name: "examples_test", index_type: "example" }

  WORDS = %w[
    Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor
    incididunt ut labore et dolore magna aliqua
  ]

  class Word
    kwattr :id, :word,
      index_name: "examples_test",
      index_type: "example",
      join_field: nil,
      parent_id: nil,
      action: :create

    def source_data
      {word: word, is_even: id.even?}
    end
  end

  before(:all) do
    records = WORDS.map.with_index(1) do |word, id|
      Word.new id: id, word: word
    end

    ActionSprout::ElasticSearch::IndexRecords.call records: records
    refresh_index "examples"
  end

  it "can return all the words" do
    enumerator = ActionSprout::ElasticSearch::BulkQuery.call index: index, query: {
      body: {query: {match_all: {}}}
    }

    words_from_query = enumerator.flat_map do |result_set|
      result_set.map { |result| result["_source"]["word"] }
    end

    expect(words_from_query).to match_array WORDS
  end

  it "can return all the words when the batch size is less than the total" do
    enumerator = ActionSprout::ElasticSearch::BulkQuery.call index: index, batch_size: 3, query: {
      body: {query: {match_all: {}}}
    }

    words_from_query = enumerator.flat_map do |result_set|
      result_set.map { |result| result["_source"]["word"] }
    end

    expect(words_from_query).to match_array WORDS
  end

  it "can run the specified filters and return the correct words when the batch size is less than the total" do
    enumerator = ActionSprout::ElasticSearch::BulkQuery.call index: index, batch_size: 3, query: {
      body: {query: {constant_score: {filter: {term: {is_even: true}}}}}
    }

    words_from_query = enumerator.flat_map do |result_set|
      result_set.map { |result| result["_source"]["word"] }
    end

    expect(words_from_query).to match_array %w[
      ipsum sit consectetur elit do tempor ut et magna
    ]
  end

  it "can run the specified filters" do
    enumerator = ActionSprout::ElasticSearch::BulkQuery.call index: index, query: {
      body: {query: {constant_score: {filter: {term: {is_even: true}}}}}
    }

    words_from_query = enumerator.flat_map do |result_set|
      result_set.map { |result| result["_source"]["word"] }
    end

    expect(words_from_query).to match_array %w[
      ipsum sit consectetur elit do tempor ut et magna
    ]
  end

  it "can take other elasticsearch options" do
    enumerator = ActionSprout::ElasticSearch::BulkQuery.call index: index, query: {
      stored_fields: [],
      body: {query: {constant_score: {filter: {term: {word: "ipsum"}}}}}
    }

    first_result = enumerator.to_a.flatten.first

    expect(first_result.keys).to match_array %w[_id _type _index _score _routing]
  end
end
