require "action_sprout/elastic_search/indexing_error"

# Given an array of `records`, create one bulk update in elasticsearch.
#
# Currently this only supports update (as upsert), but could easily support
# deletion when needed.
#
# Each record (of `records`) is expected to respond to:
#
# * `index_name`
# * `index_type`
# * `id`
# * `parent_id`
# * `source_data`
# * `action`
#
module ActionSprout
  module ElasticSearch
    class IndexRecords
      extend ActionSprout::MethodObject
      method_object :records, client: ElasticSearch.client

      def call
        return if records.empty?

        operations = records.map { |record| bulk_operation_for(record) }.compact

        client.bulk(body: operations).tap do |response|
          handle_response(response)
        end
      end

      private

      def bulk_operation_for(record)
        return if record.action == :noop

        metadata = metadata_for(record).merge(doc_for(record))

        {record.action => metadata}
      end

      def metadata_for(record)
        {
          _id: record.id,
          _index: record.index_name,
          _type: record.index_type,
          routing: record.parent_id || record.id
        }.compact
      end

      def doc_for(record)
        return {} if record.action == :delete
        return {data: source_data_for(record)} if record.action == :create

        {data: {doc: source_data_for(record), doc_as_upsert: true}}
      end

      def handle_response(response)
        if response["errors"]
          raise IndexingError.new(response)
        end
      end

      def source_data_for(record)
        record.source_data.merge(join_data_for(record))
      end

      def join_data_for(record)
        return {} unless record.join_field.present?

        {
          record.join_field => {
            name: record.join_type,
            parent: record.parent_id
          }
        }
      end
    end
  end
end
