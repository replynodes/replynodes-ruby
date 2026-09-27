# ReplyNodes Ruby SDK (legacy)

This repository contains a generated REST SDK whose public contract is pending audit. It is retained for historical reference only and is not a current installation or endpoint guide.

Do not use the retired REST default from older examples. The canonical current agent-facing surface is the ReplyNodes MCP:

- Repository: https://github.com/replynodes/replynodes-mcp
- Endpoint: `https://mcp.replynodes.com/mcp`

The MCP is not a drop-in REST replacement for this generated Ruby client. Contract and release decisions for the SDK are tracked separately; this documentation intentionally does not provide a replacement REST base URL.

## Development

Generated sources remain under `lib/replynodes/generated/` and are produced from the vendored OpenAPI contract. Do not treat the generated surface as current production guidance until the SDK contract audit is complete.
