# frozen_string_literal: true

require "set"

generated_path = File.expand_path("replynodes/generated", __dir__)
$LOAD_PATH.unshift(generated_path) unless $LOAD_PATH.include?(generated_path)

# Bundler evaluates the gemspec before loading the library, which loads the
# public version file under the same require feature as the generated version.
# Load the generated namespace's version by path so ApiClient always sees it.
require_relative "replynodes/generated/replynodes/version"
require "replynodes/generated"
require_relative "replynodes/version"
require_relative "replynodes/operation_registry"
require_relative "replynodes/error"
require_relative "replynodes/response"
require_relative "replynodes/client"
