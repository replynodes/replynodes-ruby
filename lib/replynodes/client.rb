# frozen_string_literal: true

require "uri"

module ReplyNodes
  class Client
    DEFAULT_BASE_URL = "https://api.replynodes.com"
    DEFAULT_TIMEOUT = 60

    attr_reader :base_url, :timeout

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, timeout: DEFAULT_TIMEOUT, user_agent: nil)
      raise ArgumentError, "api_key is required" if api_key.nil? || api_key.to_s.empty?

      @base_url = normalize_base_url(base_url)
      @timeout = Float(timeout)
      raise ArgumentError, "timeout must be greater than zero" unless @timeout.positive?

      configuration = ReplyNodesGenerated::Configuration.new
      configure_base_url(configuration, @base_url)
      configuration.access_token = api_key.to_s
      configuration.timeout = @timeout
      # The generated Faraday client has no retry middleware. Keep this
      # explicit: every SDK operation performs exactly one HTTP GET attempt.
      configuration.configure_faraday_connection { |_connection| }

      @api_client = ReplyNodesGenerated::ApiClient.new(configuration)
      @api_client.user_agent = user_agent if user_agent
      @apis = {}
    end

    def call(operation, *positional, **keyword)
      name = operation.to_sym
      specification = OPERATIONS.fetch(name) do
        raise ArgumentError, "unknown ReplyNodes operation: #{operation}"
      end
      params = normalize_params(positional, keyword)
      required_values, optional_values = split_params(specification, params, positional)
      api = api_for(specification[:api_class])
      method = "#{specification[:generated_method]}_with_http_info"
      generated, status, headers = api.public_send(method, *required_values, optional_values)
      Response.new(generated, status, headers)
    rescue ReplyNodesGenerated::ApiError => e
      raise Error.from_exception(e), cause: e
    end

    OPERATIONS.each_key do |operation|
      define_method(operation) do |*positional, **keyword|
        call(operation, *positional, **keyword)
      end
    end

    private

    def normalize_base_url(value)
      uri = URI.parse(value.to_s)
      unless %w[http https].include?(uri.scheme) && uri.host
        raise ArgumentError, "base_url must be an absolute HTTP(S) URL"
      end
      if uri.userinfo || uri.query || uri.fragment
        raise ArgumentError, "base_url must not contain credentials, query, or fragment"
      end

      uri.to_s.sub(%r{/\z}, "")
    rescue URI::InvalidURIError
      raise ArgumentError, "base_url must be an absolute HTTP(S) URL"
    end

    def configure_base_url(configuration, value)
      uri = URI.parse(value)
      configuration.ignore_operation_servers = true
      configuration.scheme = uri.scheme
      host = uri.host
      default_port = uri.scheme == "https" ? 443 : 80
      host = "#{host}:#{uri.port}" if uri.port && uri.port != default_port
      configuration.host = host
      configuration.base_path = uri.path
    end

    def normalize_params(positional, keyword)
      if positional.last.is_a?(Hash) && keyword.empty?
        positional.pop.merge
      else
        keyword
      end
    end

    def split_params(specification, params, positional)
      params = params.transform_keys(&:to_sym)
      required = specification[:parameters].select { |parameter| parameter[:required] }
      optional = specification[:parameters] - required
      if positional.length > required.length
        raise ArgumentError, "too many positional arguments for #{specification[:operation_id]}"
      end

      required_values = required.each_with_index.map do |parameter, index|
        if index < positional.length
          positional[index]
        else
          value, = take_param(params, parameter, required: true)
          value
        end
      end

      optional_values = {}
      optional.each do |parameter|
        value, present = take_param(params, parameter, required: false)
        optional_values[parameter[:name]] = value if present
      end

      unknown = params.keys - specification[:parameters].flat_map { |parameter| [parameter[:name], parameter[:wire_name].to_sym] }
      raise ArgumentError, "unknown parameter(s) for #{specification[:operation_id]}: #{unknown.join(", ")}" unless unknown.empty?

      [required_values, optional_values]
    end

    def take_param(params, parameter, required:)
      keys = [parameter[:name], parameter[:wire_name].to_sym]
      key = keys.find { |candidate| params.key?(candidate) }
      return [params.delete(key), true] if key
      return [nil, false] unless required

      raise ArgumentError, "missing required parameter: #{parameter[:name]}"
    end

    def api_for(class_name)
      @apis[class_name] ||= ReplyNodesGenerated.const_get(class_name).new(@api_client)
    end
  end
end
