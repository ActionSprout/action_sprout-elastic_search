module ActionSprout
  module ElasticSearch
    class ReindexFromRemote
      method_object :index_name, wait_for_completion: false

      def call
        setup_index
        settings_for_reindex

        do_reindex
      end

      private

      def setup_index
        indices = LoadIndexOptions.call
        SetupIndices.call indices: indices.slice(index_name), client: ElasticSearch.migrate_to_client
      end

      def settings_for_reindex
        ElasticSearch.migrate_to_client.indices.put_settings index: index_name, body: {
          index: {
            refresh_interval: -1,
            number_of_replicas: 0
          }
        }
      end

      def do_reindex
        ElasticSearch.migrate_to_client.reindex({
          body: {
            source: {
              remote: {
                host: elasticsearch_host,
                username: remote_uri.user,
                password: remote_uri.password
              },
              index: index_name
            },
            dest: {
              index: index_name
            }
          },
          wait_for_completion: wait_for_completion
        })
      end

      def remote_uri
        @_remote_uri ||= Addressable::URI.parse(ENV.fetch("ELASTICSEARCH_MIGRATE_FROM_URL"))
      end

      def elasticsearch_host
        remote_uri.omit(:user, :password).to_s
      end
    end
  end
end
