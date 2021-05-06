module ActionSprout
  module ElasticSearch
    module BaseIndex
      extend ActiveSupport::Concern

      included do
        class_attribute :index_name, :index_type

        # For parent/child relationships, specify the field name as join_field, the
        # parent or child name as join_type, and child documents should also
        # implement parent_id.
        class_attribute :join_field, :join_type
      end

      def action
        :update
      end

      def id
        raise NotImplementedError
      end

      def parent_id
        nil
      end

      def source_data
        {}
      end
    end
  end
end
