require "spec_helper"

require "action_sprout/elastic_search"
require "action_sprout/elastic_search/index_records"
require "action_sprout/elastic_search/setup_indices"
require "action_sprout/elastic_search/delete_indices"
require "action_sprout/elastic_search/get_document"

RSpec.describe ActionSprout::ElasticSearch::IndexRecords, ".call" do
  let(:client) { ActionSprout::ElasticSearch.client }

  around(:all) do |test|
    ActionSprout::ElasticSearch::DeleteIndices.call indices: ["examples_test"]
    test.call
    ActionSprout::ElasticSearch::DeleteIndices.call indices: ["examples_test"]
  end

  it "can do nothing when indexing no records" do
    described_class.call records: []
  end

  context "with a simple index" do
    before(:all) do
      ActionSprout::ElasticSearch::SetupIndices.call indices: {examples_test: {}}
    end

    before { described_class.call records: records }

    context "with one record" do
      let(:records) { [double(index_name: "examples_test", index_type: "example", action: :update, id: "1", join_field: nil, parent_id: nil, source_data: {name: "OMG HAI"})] }

      it "indexes that record" do
        result = ActionSprout::ElasticSearch::GetDocument.call index: records.first, id: "1"
        expect(result["name"]).to eq "OMG HAI"
      end

      it "can then delete that record" do
        delete_operations = [double(index_name: "examples_test", index_type: "example", action: :delete, id: "1", join_field: nil, parent_id: nil, source_data: {})]
        described_class.call records: delete_operations

        expect(ActionSprout::ElasticSearch::GetDocument.call(index: records.first, id: "1")).to be_nil
      end
    end

    context "with more than one record" do
      let(:records) {
        [
          double(index_name: "examples_test", index_type: "example", action: :update, id: "1", join_field: nil, parent_id: nil, source_data: {name: "OMG HAI"}),
          double(index_name: "examples_test", index_type: "example", action: :update, id: "2", join_field: nil, parent_id: nil, source_data: {name: "YAAAAAY"})
        ]
      }

      it "indexes the first record" do
        result = ActionSprout::ElasticSearch::GetDocument.call index: records.first, id: "1"
        expect(result["name"]).to eq "OMG HAI"
      end

      it "indexes the second record" do
        result = ActionSprout::ElasticSearch::GetDocument.call index: records.first, id: "2"
        expect(result["name"]).to eq "YAAAAAY"
      end
    end

    context "when one record is a noop action" do
      let(:records) {
        [
          double(index_name: "examples_test", index_type: "example", action: :update, id: "1", join_field: nil, parent_id: nil, source_data: {name: "OMG HAI"}),
          double(index_name: "examples_test", index_type: "example", action: :noop, id: "1", join_field: nil, parent_id: nil, source_data: {name: "YAAAAAY"})
        ]
      }

      it "does not update that the data from the noop action" do
        result = ActionSprout::ElasticSearch::GetDocument.call index: records.first, id: "1"
        expect(result["name"]).to eq "OMG HAI"
      end
    end
  end

  it "can index a record with a parent/child relationship" do
    records = [
      double(index_name: "examples_test", index_type: "doc", action: :update, id: "2", parent_id: nil, join_type: "the_parent", join_field: "join_field", source_data: {}),
      double(index_name: "examples_test", index_type: "doc", action: :update, id: "1", parent_id: "2", join_type: "the_child", join_field: "join_field", source_data: {name: "OMG HAI"})
    ]

    ActionSprout::ElasticSearch::SetupIndices.call indices: {
      examples_test: {
        mappings: {
          doc: {
            properties: {
              join_field: {
                type: "join",
                relations: {the_parent: "the_child"}
              }
            }
          }
        }
      }
    }

    described_class.call records: records

    result = client.get index: "examples_test", type: "doc", parent: "2", id: "1"

    expect(result["_source"]["join_field"]).to eq "parent" => "2", "name" => "the_child"
    expect(result["_source"]["name"]).to eq "OMG HAI"
  end

  it "can report errors" do
    ActionSprout::ElasticSearch::SetupIndices.call indices: {
      examples_test: {
        mappings: {
          example_with_date: {
            properties: {
              date: {type: "date", format: "strict_date_time_no_millis||epoch_second"}
            }
          }
        }
      }
    }

    records = [
      double(index_name: "examples_test", index_type: "example_with_date", action: :update, id: "1", join_field: nil, parent_id: nil, source_data: {date: Time.current.to_i}),
      double(index_name: "examples_test", index_type: "example_with_date", action: :update, id: "2", join_field: nil, parent_id: nil, source_data: {date: "omg"}),
      double(index_name: "examples_test", index_type: "example_with_date", action: :update, id: "3", join_field: nil, parent_id: nil, source_data: {date: "omg2"}),
      double(index_name: "examples_test", index_type: "example_with_date", action: :update, id: "4", join_field: nil, parent_id: nil, source_data: {date: Time.current.to_i})
    ]

    expect {
      described_class.call records: records
    }.to raise_exception(ActionSprout::ElasticSearch::IndexingError, "failed to parse field [date] of type [date]; failed to parse field [date] of type [date]")
  end
end
