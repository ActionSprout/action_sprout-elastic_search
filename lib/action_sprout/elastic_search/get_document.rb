module ActionSprout
  module ElasticSearch
    class GetDocument
      extend ActionSprout::MethodObject
      method_object :index, :id, parent_id: nil, client: ElasticSearch.client

      # `index` is expected to respond to `index_name` and `index_type`
      #
      # TODO: what should we do with non-happy cases?
      def call
        document = client.get options

        document["_source"]
      end

      private

      def options
        {
          index: index.index_name,
          type: index.index_type,
          id: id,
          ignore: [404],
          routing: parent_id
        }.compact
      end
    end
  end
end
