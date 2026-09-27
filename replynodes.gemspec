# frozen_string_literal: true

require_relative "lib/replynodes/version"

Gem::Specification.new do |spec|
  spec.name = "replynodes"
  spec.version = ReplyNodes::VERSION
  spec.authors = ["ReplyNodes"]
  spec.email = ["support@replynodes.com"]
  spec.summary = "ReplyNodes Ruby SDK"
  spec.description = "Ruby client for the authenticated, read-only ReplyNodes API."
  spec.homepage = "https://replynodes.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/replynodes/replynodes-ruby"
  spec.metadata["bug_tracker_uri"] = "https://github.com/replynodes/replynodes-ruby/issues"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"].sort
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "faraday", ">= 2.0", "< 3.0"
  spec.add_runtime_dependency "faraday-multipart", ">= 1.0"
  spec.add_runtime_dependency "marcel", ">= 1.0"
end
