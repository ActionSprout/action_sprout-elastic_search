module ActionSprout
  module ElasticSearch
    class Reindex
      method_object :source_index_name, :dest_index_name, wait_for_completion: false, client: ElasticSearch.client,
                                                          script: "", query: {}

      def self.inspire_pages_script
        <<-PAINLESS
      ctx._source.is_page = ctx._type == 'page';
      ctx._source.page_join = 'page';
      ctx._type = 'doc';
        PAINLESS
      end

      def self.inspire_pages_query
        {term: {_type: "page"}}
      end

      def call
        setup_index
        settings_for_reindex

        do_reindex
      end

      private

      def setup_index
        indices = LoadIndexOptions.call
        SetupIndices.call indices: indices.slice(dest_index_name), client: client
      end

      def settings_for_reindex
        client.indices.put_settings index: dest_index_name, body: {
          index: {
            refresh_interval: -1,
            number_of_replicas: 0
          }
        }
      end

      def do_reindex
        client.reindex({
          body: {
            source: {
              query: query,
              index: source_index_name
            },
            dest: {
              index: dest_index_name
            },
            script: {
              lang: "painless",
              source: script
            }
          },
          wait_for_completion: wait_for_completion
        })
      end
    end
  end
end
