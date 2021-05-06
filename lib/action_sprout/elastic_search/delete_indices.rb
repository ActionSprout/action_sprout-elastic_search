module ActionSprout
  module ElasticSearch
    class DeleteIndices
      extend ActionSprout::MethodObject
      method_object client: ElasticSearch.client, indices: []

      def call
        raise "Do not delete indices in production" if ElasticSearch.env == "production"

        indices.each { |index_name| delete_index index_name }
      end

      private

      def delete_index(index_name)
        ElasticSearch.logger.warn "Deleting index #{index_name}"
        client.indices.delete index: index_name, ignore: [404]
      end
    end
  end
end
