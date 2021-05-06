module ActionSprout
  module ElasticSearch
    class SetupIndices
      # If there is a `migrate_to_client`, then we probably don't want to be
      # making changes to the migrate_from_client. Otherwise, just use the
      # default client.
      extend ActionSprout::MethodObject
      method_object client: (ElasticSearch.migrate_to_client || ElasticSearch.client), indices: {}

      CREATE_ONLY_SETTINGS = %w[number_of_shards mapping]

      def call
        indices.each do |index_name, index_options|
          if client.indices.exists index: index_name
            update_index index_name, index_options
          else
            create_index index_name, index_options
          end
        end
      end

      private

      def create_index(index_name, index_options)
        ElasticSearch.logger.warn "Creating index #{index_name} with #{index_options.inspect}"
        client.indices.create index: index_name, body: index_options
      end

      def update_index(index_name, index_options)
        settings = index_options[:settings]
        mappings = index_options.fetch(:mappings) { {} }

        if settings.present?
          settings = settings_for_update(settings) if settings["index"].present?

          ElasticSearch.logger.warn "Updating settings for index #{index_name}"
          client.indices.put_settings index: index_name, body: settings
        end

        mappings.each do |type, mapping|
          ElasticSearch.logger.warn "Updating mappings for index #{index_name} and type #{type}"
          client.indices.put_mapping index: index_name, type: type, body: mapping
        end
      end

      def settings_for_update(settings)
        index_settings = settings["index"].reject do |key, value|
          key.in? CREATE_ONLY_SETTINGS
        end

        # Update without mutating
        settings.merge("index" => index_settings)
      end
    end
  end
end
