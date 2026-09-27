# frozen_string_literal: true

module ReplyNodes
  class Response
    attr_reader :data, :meta, :status, :headers, :raw

    def initialize(raw, status, headers)
      @raw = raw
      @status = status
      @headers = headers || {}
      @data = raw.respond_to?(:data) ? raw.data : nil
      @meta = raw.respond_to?(:meta) ? raw.meta : nil
    end

    def request_id
      return meta.request_id if meta.respond_to?(:request_id)

      header_value("x-request-id")
    end

    def next_cursor
      if meta.respond_to?(:next_cursor) && !meta.next_cursor.nil?
        return meta.next_cursor
      end

      pagination_value(:next_cursor)
    end

    def has_more?
      value = pagination_value(:has_more)
      value == true
    end

    def pagination
      source = data_hash
      return nil unless source

      value = source[:pagination] || source["pagination"]
      value.respond_to?(:to_h) ? value.to_h : nil
    end

    def to_h
      { data: data, meta: meta, status: status, headers: headers }
    end

    private

    def header_value(wanted)
      headers.to_h.each do |key, value|
        return value if key.to_s.downcase == wanted
      end
      nil
    end

    def pagination_value(key)
      source = data_hash
      return nil unless source.is_a?(Hash)

      pagination = source[:pagination] || source["pagination"]
      return pagination[key] || pagination[key.to_s] if pagination.is_a?(Hash)

      source[key] || source[key.to_s]
    end

    def data_hash
      return data.to_h if data.respond_to?(:to_h)
      return data if data.is_a?(Hash)

      nil
    end
  end
end
