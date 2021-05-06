require "spec_helper"

require "action_sprout/elastic_search/reindex_status"

RSpec.describe ActionSprout::ElasticSearch::ReindexStatus do
  let(:json_response) {
    %q( {
    "nodes": {
      "x9zbuTSOR3u4PIhPTERVig": {
        "name": "x9zbuTS",
        "tasks": {
          "x9zbuTSOR3u4PIhPTERVig:22261": {
            "node": "x9zbuTSOR3u4PIhPTERVig",
            "id": 22261,
            "type": "transport",
            "action": "indices:data/write/reindex",
            "status":{"total":31007271,"updated":6747,"created":4754253,"deleted":0,"batches":4761,"version_conflicts":0,"noops":0,"retries":{"bulk":0,"search":0},"throttled_millis":0,"requests_per_second":-1,"throttled_until_millis":0},
            "description": "reindex from [scheme=https host=as-fern-production-x.us-east-1.bonsaisearch.net port=443 query={\n  \"match_all\" : {\n    \"boost\" : 1.0\n  }\n} username=ebponjvfum password=<<>>][stories_production] to [stories_production]",
            "start_time_in_millis": 1586200195137,
            "running_time_in_nanos": 1498123043303,
            "cancellable": true
          },
          "x9zbuTSOR3u4PIhPTERVig:15709": {
            "node": "x9zbuTSOR3u4PIhPTERVig",
            "id": 15709,
            "type": "transport",
            "action": "indices:data/write/reindex",
            "status":{"total":30319266,"updated":0,"created":6309461,"deleted":0,"batches":6310,"version_conflicts":0,"noops":0,"retries":{"bulk":0,"search":0},"throttled_millis":0,"requests_per_second":-1,"throttled_until_millis":0},
            "description": "reindex from [scheme=https host=as-fern-production-x.us-east-1.bonsaisearch.net port=443 query={\n  \"match_all\" : {\n    \"boost\" : 1.0\n  }\n} username=ebponjvfum password=<<>>][inspire_production] to [inspire_production]",
            "start_time_in_millis": 1586200127430,
            "running_time_in_nanos": 1565830561920,
            "cancellable": true
          }
        }
      }
    }
  } )
  }

  let(:client_stub) { double(tasks: double(list: JSON.parse(json_response))) }

  let(:now) { Time.zone.parse("2020-04-06T19:35:00Z") }

  let(:expected_output_lines) {
    [
      "to [stories_production]         4.76 Million of    31 Million (15.4%) -- 25 minutes and 4.0 seconds elapsed\n",
      "Estimated  2 hours, 18 minutes, and 15.0 seconds left of  2 hours, 43 minutes, and 20.0 seconds total\n\n",
      "to [inspire_production]         6.31 Million of  30.3 Million (20.8%) -- 26 minutes and 12.0 seconds elapsed\n",
      "Estimated   1 hour, 39 minutes, and 44.0 seconds left of   2 hours, 5 minutes, and 56.0 seconds total\n\n"
    ]
  }

  xit "prints the expected output" do
    expected_output = expected_output_lines.join

    expect { ActionSprout::ElasticSearch::ReindexStatus.call client: client_stub, now: now }.to output(expected_output).to_stdout
  end
end
