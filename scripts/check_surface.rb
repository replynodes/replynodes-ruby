# frozen_string_literal: true

require "json"
require "set"

ROOT = File.expand_path("..", __dir__)
spec = JSON.parse(File.read(File.join(ROOT, "openapi/replynodes-fetcher.openapi.json")))
$LOAD_PATH.unshift(File.join(ROOT, "lib"))
require "replynodes"

def snake(value)
  value.gsub(/([a-z0-9])([A-Z])/, '\\1_\\2').tr("-", "_").downcase.to_sym
end

canonical = {}
spec.fetch("paths").each do |path, path_item|
  operation = path_item["get"]
  next unless operation

  key = snake(operation.fetch("operationId"))
  canonical[key] = {
    operation_id: operation.fetch("operationId"),
    path: path,
    parameters: operation.fetch("parameters", []).map do |parameter|
      {
        name: snake(parameter.fetch("name")),
        wire_name: parameter.fetch("name"),
        location: parameter.fetch("in").to_sym,
        required: parameter.fetch("required", false)
      }
    end
  }
end

registry = ReplyNodes::OPERATIONS
abort "registry operation coverage mismatch" unless registry.keys.to_set == canonical.keys.to_set
abort "public operation count mismatch" unless registry.size == canonical.size

registry.each do |name, entry|
  expected = canonical.fetch(name)
  %i[operation_id path].each do |field|
    abort "#{name}: #{field} mismatch" unless entry.fetch(field) == expected.fetch(field)
  end
  abort "#{name}: parameter contract mismatch" unless entry.fetch(:parameters) == expected.fetch(:parameters)

  api_class = ReplyNodesGenerated.const_get(entry.fetch(:api_class))
  generated_method = entry.fetch(:generated_method)
  abort "#{name}: generated method missing" unless api_class.public_instance_methods.include?(generated_method)
  abort "#{name}: public method missing" unless ReplyNodes::Client.public_instance_methods.include?(name)
end

ReplyNodes::ALIASES.each do |alias_name, target|
  abort "alias target missing: #{target}" unless registry.key?(target)
  abort "alias collides with operation: #{alias_name}" if registry.key?(alias_name)
  abort "alias method missing: #{alias_name}" unless ReplyNodes::Client.public_instance_methods.include?(alias_name)
end

abort "non-GET operation leaked into registry" unless registry.values.all? { |entry| entry[:parameters].all? { |parameter| %i[path query].include?(parameter[:location]) } }
puts "surface check passed: #{canonical.size} canonical GET operations, #{ReplyNodes::ALIASES.size} intentional aliases"
