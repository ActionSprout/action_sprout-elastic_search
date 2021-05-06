# frozen_string_literal: true

require_relative "lib/action_sprout/elastic_search/version"

Gem::Specification.new do |spec|
  spec.name = "action_sprout-elastic_search"
  spec.version = ActionSprout::ElasticSearch::VERSION
  spec.authors = ["Amiel Martin"]
  spec.email = ["amiel.martin@gmail.com"]

  spec.summary = "Tools for indexing to ElasticSearch"
  spec.description = "ActionSprout::ElasticSearch includes tools for bulk indexing many documents to ElasticSearch"
  spec.homepage = "https://github.com/ActionSprout/action_sprout-elastic_search"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ActionSprout/action_sprout-elastic_search"
  spec.metadata["changelog_uri"] = "https://github.com/ActionSprout/action_sprout-elastic_search/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activesupport", "> 0"
  spec.add_dependency "action_sprout-method_object", "> 0"
  spec.add_dependency "elasticsearch", "~> 6"
  spec.add_dependency "addressable", "~> 2.6"
  spec.add_dependency "net-http-persistent", "~> 4.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
