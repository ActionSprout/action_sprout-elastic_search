# frozen_string_literal: true

require "active_support/all"
require "elasticsearch"
require "action_sprout/method_object"

require_relative "elastic_search/version"

module ActionSprout
  module ElasticSearch
    mattr_accessor :client, :index_suffix, :migrate_to_client, :migrate_from_client

    def self.env
      if defined?(Rails)
        Rails.env
      else
        ENV['RACK_ENV']
      end
    end

    self.index_suffix = ENV.fetch("INDEX_SUFFIX", env)

    def self.initialize_clients
      self.client = build_client ENV.fetch("ELASTICSEARCH_URL")
      self.migrate_to_client = build_client ENV["ELASTICSEARCH_MIGRATE_TO_URL"]
      self.migrate_from_client = build_client ENV["ELASTICSEARCH_MIGRATE_FROM_URL"]
    end

    def self.index_name_for(index_name)
      [index_name, index_suffix].join "_"
    end

    def self.build_client(url)
      return unless url.present?

      Elasticsearch::Client.new({
        url: url,
        adapter: :net_http_persistent,
        log: (ENV["ELASTICSEARCH_VERBOSE"] == "true" || ENV["ELASTICSEARCH_VERBOSE"] == url),

        # These settings were lifted from the default searchkick settings
        transport_options: {
          request: {timeout: ENV.fetch("ELASTICSEARCH_TIMEOUT", "30").to_i},
          headers: {content_type: "application/json"}
        }
      })
    end

    def self.client_for_write
      if migrate_to_client && migrate_from_client
        yield migrate_to_client
        yield migrate_from_client
      else
        yield client
      end
    end

    def self.logger
      if defined?(Rails)
        Rails.logger
      else
        require 'logger'
        Logger.new(STDOUT)
      end
    end

    initialize_clients

  end

end
