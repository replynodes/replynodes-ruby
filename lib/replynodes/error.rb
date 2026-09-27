# frozen_string_literal: true

require "json"

module ReplyNodes
  class Error < StandardError
    attr_reader :status, :code, :request_id, :response_headers, :response_body, :cause

    def initialize(status:, code:, message:, request_id: nil, response_headers: {}, response_body: nil, cause: nil)
      @status = status
      @code = code
      @request_id = request_id
      @response_headers = response_headers || {}
      @response_body = response_body
      @cause = cause
      @detail_message = message
      super(message)
    end

    def message
      "ReplyNodes request failed (status=#{status || "n/a"}, code=#{code || "n/a"}, " \
        "message=#{@detail_message}, request_id=#{request_id || "n/a"})"
    end

    def to_s
      message
    end

    def self.from_exception(exception)
      body = exception.respond_to?(:response_body) ? exception.response_body : nil
      headers = exception.respond_to?(:response_headers) ? exception.response_headers : {}
      status = exception.respond_to?(:code) && exception.code.to_i.positive? ? exception.code.to_i : nil
      payload = parse_body(body)
      detail = payload.is_a?(Hash) ? (payload["error"] || payload[:error] || {}) : {}
      detail = {} unless detail.is_a?(Hash)
      request_id = detail["request_id"] || detail[:request_id] || header_value(headers, "x-request-id")
      code = detail["code"] || detail[:code] || (status ? "http_#{status}" : "network_error")
      message = detail["message"] || detail[:message] || exception.message.to_s

      if exception.is_a?(ReplyNodesGenerated::ApiError) && exception.message.to_s.match?(/timed out/i)
        code = "timeout"
        message = "Request timed out"
      end

      new(
        status: status,
        code: code,
        message: message,
        request_id: request_id,
        response_headers: headers,
        response_body: body,
        cause: exception
      )
    end

    def self.parse_body(body)
      return {} unless body.is_a?(String) && !body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end
    private_class_method :parse_body

    def self.header_value(headers, wanted)
      headers.to_h.each do |key, value|
        return value if key.to_s.downcase == wanted
      end
      nil
    end
    private_class_method :header_value
  end
end
