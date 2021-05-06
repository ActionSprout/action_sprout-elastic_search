module ActionSprout
  module ElasticSearch
    class InMemoryCache
      def self.instance
        @@_instance ||= new
      end

      def initialize
        clear
      end

      def read(key)
        @cache[key]
      end

      def write(key, value)
        @cache[key] = value
      end

      def delete(key)
        @cache.delete(key)
      end

      def clear
        @cache = Hash.new
      end
    end
  end
end
