# ReplyNodes Ruby SDK

Ruby client for the authenticated, read-only ReplyNodes API.

## Install

The gem is versioned in this repository and can be built locally with:

```sh
gem build replynodes.gemspec
gem install ./replynodes-0.1.0.gem
```

No live upstream or credentials are needed for the test suite.

## Usage

Pass the raw ReplyNodes API key. The SDK adds the `Bearer` prefix and never
logs the key.

```ruby
require "replynodes"

client = ReplyNodes::Client.new(
  api_key: ENV.fetch("REPLYNODES_API_KEY"),
  base_url: ENV.fetch("REPLYNODES_BASE_URL", "https://api.replynodes.com"),
  timeout: 30
)

response = client.app_store_search(term: "ruby", ids_only: false)
puts response.data
puts response.meta.request_id
puts response.next_cursor if response.next_cursor
```

Every canonical GET operation is available as a snake_case client method,
including `google_search`, `reddit_search`, `youtube_video`, and all other
operations in the canonical OpenAPI contract. Required path/query parameters
can be positional or keyword arguments; optional parameters are keywords. Ruby
`false` and `0` values are preserved and sent when supplied.

Successful calls return a `ReplyNodes::Response` envelope with `data`, `meta`,
`status`, `headers`, `request_id`, and pagination helpers. Non-2xx responses
raise `ReplyNodes::Error`, which exposes `status`, `code`, `message`, and
`request_id`.

The client performs one HTTP request per operation and does not retry. Timeout
and base URL settings are configurable per client.

## Development

The generated client is isolated under `lib/replynodes/generated/`. It is
reproducibly produced by OpenAPI Generator 7.10.0 from
`openapi/replynodes-fetcher.openapi.json`. The public client and response/error
wrappers are maintained outside that directory.

```sh
scripts/generate
scripts/check_generation.sh
ruby scripts/check_surface.rb
bundle exec rake test
```

The repository intentionally does not claim public registry publication,
release/tag alignment, trusted publishing, or authenticated live E2E evidence.
