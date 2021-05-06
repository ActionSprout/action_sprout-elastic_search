module ActionSprout
  module ElasticSearch
    class GetDocuments
      extend ActionSprout::MethodObject
      method_object :index, :ids, source: nil, client: ElasticSearch.client

      # `index` is expected to respond to `index_name` and `index_type`
      def call
        response = client.mget options

        pairs = response["docs"].map { |doc| [doc["_id"], doc["_source"]] }

        pairs.to_h
      end

      private

      def options
        {
          index: index.index_name,
          type: index.index_type,
          body: {ids: ids},
          _source: source
        }
      end
    end
  end
end
