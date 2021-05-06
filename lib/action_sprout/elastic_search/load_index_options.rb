module ActionSprout
  module ElasticSearch
    class LoadIndexOptions

      def self.default_config_path
        if defined?(Rails)
          Rails.root.join("config/indices")
        else
          Pathname.new("indices")
        end
      end

      extend ActionSprout::MethodObject
      method_object index_suffix: ElasticSearch.index_suffix, config_path: default_config_path

      def call
        load_all_configuration.to_h
      end

      def options_for_index(index_name)
        YAML.safe_load(ERB.new(config_path.join("#{index_name}.yml").read).result(binding)) || {}
      end

      private

      def load_all_configuration
        index_names.map do |index_name|
          [
            ElasticSearch.index_name_for(index_name),
            options_for_index(index_name)
          ]
        end
      end

      def index_names
        config_path.each_child(false).map { |file| file.basename(".yml").to_s }
      end
    end
  end
end
