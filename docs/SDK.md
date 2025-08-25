# SDK — Tools & Extensibility (v0.2.0)

## Tool Manifest Schema
```json
{
  "name":"tool.name",
  "version":"1",
  "inputs":{"field":"type"},
  "outputs":{"field":"type"},
  "timeouts_s":{"soft":30,"hard":60},
  "policies":{"network":"read_only","fs":"sandboxed"}
}