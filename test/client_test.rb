# frozen_string_literal: true

require_relative "test_helper"

class ClientTest < Minitest::Test
  def test_auth_path_query_encoding_and_envelope
    server = FakeServer.new(body: { data: { "ok" => true }, meta: { request_id: "req-auth" } })
    client = ReplyNodes::Client.new(api_key: "test-token", base_url: server.url)

    response = client.google_search(text: "cats & dogs", engines: "google,bing", start: 1)

    assert_equal true, response.data[:ok]
    assert_equal "req-auth", response.request_id
    assert_equal 200, response.status
    request = wait_for_request(server)
    assert_match(%r{GET /v1/web/search\?}, request[:line])
    assert_includes request[:line], "text=cats+%26+dogs"
    assert_includes request[:line], "engines=google%2Cbing"
    assert_includes request[:line], "start=1"
    assert_equal "Bearer test-token", request[:headers]["Authorization"]
  ensure
    server&.stop
  end

  def test_false_and_zero_optional_values_are_present
    server = FakeServer.new(body: { data: {}, meta: { request_id: "req-values" } })
    client = ReplyNodes::Client.new(api_key: "test-token", base_url: server.url)

    client.app_store_app(id: "42", ratings: false)
    client.hacker_news_search(q: "ruby", page: 0)

    request = wait_for_request(server)
    assert_includes request[:line], "id=42"
    assert_includes request[:line], "ratings=false"
    100.times { break if server.requests.length == 2; sleep 0.01 }
    assert_includes server.requests[1][:line], "page=0"
  ensure
    server&.stop
  end

  def test_http_error_contains_status_code_message_and_request_id
    server = FakeServer.new(
      status: 429,
      headers: { "X-Request-Id" => "header-request" },
      body: { error: { code: "rate_limited", message: "slow down", request_id: "req-error" } }
    )
    client = ReplyNodes::Client.new(api_key: "test-token", base_url: server.url)

    error = assert_raises(ReplyNodes::Error) { client.app_store_app }

    assert_equal 429, error.status
    assert_equal "rate_limited", error.code
    assert_equal "req-error", error.request_id
    assert_includes error.message, "slow down"
    assert_includes error.to_s, "status=429"
  ensure
    server&.stop
  end

  def test_timeout_is_reported_and_a_503_is_not_retried
    server = FakeServer.new(status: 503, body: { error: { code: "unavailable", message: "try later", request_id: "req-503" } })
    client = ReplyNodes::Client.new(api_key: "test-token", base_url: server.url, timeout: 1)

    begin
      error = assert_raises(ReplyNodes::Error) { client.app_store_app }

      assert_equal 503, error.status
      sleep 0.05
      assert_equal 1, server.requests.length
    ensure
      server.stop
    end

    timeout_server = FakeServer.new(body: { data: {}, meta: { request_id: "never" } }, delay: 0.5)
    timeout_client = ReplyNodes::Client.new(api_key: "test-token", base_url: timeout_server.url, timeout: 0.05)
    begin
      timeout_error = assert_raises(ReplyNodes::Error) { timeout_client.app_store_app }
      assert_nil timeout_error.status
      assert_equal "timeout", timeout_error.code
    ensure
      timeout_server.stop
    end
  end

  def test_pagination_helpers_read_the_response_data
    server = FakeServer.new(
      body: {
        data: { items: [], pagination: { next_cursor: "cursor-2", has_more: true } },
        meta: { request_id: "req-page" }
      }
    )
    client = ReplyNodes::Client.new(api_key: "test-token", base_url: server.url)

    response = client.web_map(url: "https://example.com")

    assert_equal "cursor-2", response.next_cursor
    assert response.has_more?
    assert_equal({ next_cursor: "cursor-2", has_more: true }, response.pagination)
  ensure
    server&.stop
  end

  private

  def wait_for_request(server)
    100.times do
      return server.requests.first if server.requests.any?

      sleep 0.01
    end
    flunk "fake server did not receive a request"
  end
end
