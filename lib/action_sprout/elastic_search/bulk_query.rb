# ElasticSearch::BulkQuery is a way to query elasticsearch to stream a large
# result set.
#
# Arguments:
#
# - index - anything that responds to `index_name` and `index_type`
# - query - The elasticsearch query request. Scroll and index options will be
#   added.
# - batch_size - how many hits to load in each batch.
# - client - the elasticsearch client to query.
#
# Returns:
#
# The return value of `call` is an enumerator. The result of each iteration of
# this enumerator is a batch of elasticsearch "hits" (as configured by the
# batch_size argument).
#
module ActionSprout
  module ElasticSearch
    class BulkQuery
      DEFAULT_SCROLL_TIMEOUT = "5m" # This just needs to be long enough to process one batch, not all.

      extend ActionSprout::MethodObject
      method_object :index, :query,
        batch_size: 1000,
        client: ElasticSearch.client,
        scroll_timeout: DEFAULT_SCROLL_TIMEOUT

      def call
        to_enum :each_result
      end

      private

      def each_result
        results = start_search

        loop do
          hits = results["hits"]["hits"]

          break if hits.empty?
          yield hits

          results = client.scroll(scroll_id: results["_scroll_id"], scroll: scroll_timeout)
        end
      ensure
        client.clear_scroll scroll_id: results["_scroll_id"] if results
      end

      def start_search
        client.search(
          index: index.index_name,
          type: index.index_type,

          size: batch_size,
          scroll: scroll_timeout,
          **query
        )
      end
    end
  end
end
