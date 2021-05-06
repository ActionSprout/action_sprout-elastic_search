module ActionSprout
  module ElasticSearch
    class IndexingError < RuntimeError
      attr_accessor :response
      def initialize(response)
        self.response = response
        super message_from_response(response)
      end

      private

      def message_from_response(response)
        reasons = response["items"].flat_map do |item|
          item.values.first.dig("error", "reason") || []
        end

        reasons.join "; "
      end
    end
  end
end
