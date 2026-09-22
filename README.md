# ReplyNodes Ruby SDK

Ruby client for the authenticated, read-only ReplyNodes API.

This repository is the source for the `replynodes` gem. The generated HTTP
client is isolated under `lib/replynodes/generated/`; the public `ReplyNodes::Client`
API is maintained separately so generated files can be regenerated safely.

Implementation is being developed from the canonical ReplyNodes Fetcher
OpenAPI contract.

