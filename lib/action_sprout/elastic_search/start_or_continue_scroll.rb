module ActionSprout
  module ElasticSearch
    class StartOrContinueScroll
      SCROLL_TIMEOUT = "5m"

      def self.default_cache
        if defined?(Rails)
          Rails.cache
        else
          require "action_sprout/elastic_search/in_memory_cache"
          InMemoryCache.instance
        end
      end

      extend ActionSprout::MethodObject
      method_object :index, :query, :batch_size, :cache_key,
        scroll_timeout: SCROLL_TIMEOUT,
        cache_service: default_cache, # `read`, `write`, and `delete'
        elasticsearch: ElasticSearch.client

      def call
        handle_errors do
          results = scroll_id.present? ? continue_scroll(scroll_id) : start_scroll

          update_scroll_id results

          results.dig("hits", "hits")
        end
      end

      private

      def handle_errors
        yield
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        if cache_service.delete(cache_key) && !@_retried
          @_scroll_id = nil
          @_retried = true
          retry
        else
          raise
        end
      end

      def scroll_id
        @_scroll_id ||= cache_service.read cache_key
      end

      def continue_scroll(scroll_id)
        elasticsearch.scroll scroll_id: scroll_id, scroll: scroll_timeout
      end

      def start_scroll
        elasticsearch.search search_options
      end

      def update_scroll_id(results)
        if results.dig("hits", "hits").present?
          cache_service.write cache_key, results["_scroll_id"]
        else
          cache_service.delete cache_key
        end
      end

      def search_options
        {
          index: index.index_name,
          type: index.index_type,

          scroll: scroll_timeout,
          size: batch_size,
          **query
        }
      end
    end
  end
end
