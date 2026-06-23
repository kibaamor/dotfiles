# Whatproxy Design Spec

## Overview

Whatproxy is a multi-protocol (HTTP/HTTPS/SOCKS5) proxy tool that supports MITM-based HTTPS decryption and scriptable request/response modification via embedded Lua and external process scripts.

## Architecture

```
                      ┌──────────────────────────────────────┐
                      │              Config                   │
                      │  (YAML parsing → structured model)    │
                      └──────┬───────────────────────────────┘
                             │
                             ▼
┌──────────┐     ┌──────────────────┐     ┌──────────────────┐
│ Listener │────▶│     Router       │────▶│  Script Pipeline │
│          │     │                  │     │                  │
│ • HTTP   │     │ • URL matching   │     │ • Embedded Lua   │
│ • HTTPS  │     │ • Stage routing  │     │ • External proc  │
│ • SOCKS5 │     │ • Script chain   │     │ • Pre/Post hooks │
└──────────┘     └──────────────────┘     └──────┬───────────┘
                                                  │
                                                  ▼
                                         ┌──────────────────┐
                                         │    Forwarder     │
                                         │                  │
                                         │ • HTTP forward   │
                                         │ • CONNECT tunnel │
                                         │ • SOCKS5 forward │
                                         └──────────────────┘
```

Request flow: Listener → Router → Script Pipeline (pre-request) → Forwarder → Script Pipeline (post-response) → Client.

## Internal Request Model

All protocols convert to a unified model before entering the pipeline.

```rust
struct RequestContext {
    id: Uuid,
    method: HttpMethod,
    url: Url,
    headers: Headers,
    body: Vec<u8>,
    metadata: RequestMetadata,
}

struct RequestMetadata {
    source_addr: SocketAddr,
    connection_scheme: Scheme, // Http | Https | Socks5
}

struct ResponseContext {
    request_id: Uuid,
    status_code: u16,
    headers: Headers,
    body: Vec<u8>,
}

enum Scheme { Http, Https, Socks5 }

// Script-accessible handle
trait RequestHandle {
    fn method(&self) -> &HttpMethod;
    fn set_method(&mut self, method: HttpMethod);
    fn url(&self) -> &Url;
    fn set_url(&mut self, url: Url);
    fn header(&self, name: &str) -> Option<&str>;
    fn set_header(&mut self, name: &str, value: &str);
    fn remove_header(&mut self, name: &str);
    fn body(&self) -> &[u8];
    fn set_body(&mut self, body: Vec<u8>);
}
```

SOCKS5 non-HTTP traffic bypasses the unified model and is tunneled directly.

## Listeners

Three listeners implementing the `Listener` trait:

```rust
trait Listener {
    async fn accept(&self) -> Result<AcceptedConnection>;
}

struct AcceptedConnection {
    stream: TcpStream,
    scheme: Scheme,
}
```

- **HTTP**: Parse HTTP request, construct `RequestContext`.
- **HTTPS**: Receive CONNECT → TLS handshake with dynamically-signed domain cert → decrypt → parse as HTTP.
- **SOCKS5**: Handshake → resolve target. If target port is 80/443, probe for HTTP traffic. If HTTP → MITM decrypt; otherwise → tunnel forward.

## Script Pipeline

Mixing Lua scripts and external process scripts, executed in configured order.

### Configuration

```yaml
rules:
  - url_pattern: "api.example.com/v1/*"
    request_scripts:
      - type: lua
        path: scripts/add-auth.lua
      - type: external
        command: ["node", "scripts/validate.js"]
    response_scripts:
      - type: lua
        path: scripts/mask-data.lua
```

### Lua Scripts

Exposed API:

```lua
function on_request(ctx)
    ctx:set_header("Authorization", "Bearer " .. ctx:get_cached_token())
end

function on_response(ctx)
    local body = json.decode(ctx:body())
    body.sensitive = nil
    ctx:set_body(json.encode(body))
end
```

Lua sandboxing restricts available standard libraries (no `os.execute`, restricted `io`).

### External Process

Communicates via stdin/stdout JSON protocol:

```
stdin:  {"method":"GET","url":"...","headers":{"Content-Type":["application/json"]},"body":"<base64>"}
stdout: {"method":"GET","url":"...","headers":{"Content-Type":["application/json"]},"body":"<base64>"}
```

Stderr is logged for debugging.

### Error Handling

| Scenario | Behavior |
|----------|----------|
| Script timeout | Skip the rule, log, pass original data |
| Script syntax error | Log at load time, skip rule; at runtime, pass original data |
| External process crash | Same as timeout, log stderr |
| Target unreachable | Return 502 Bad Gateway, skip response scripts |
| MITM cert error | Log error, return 502 |

## CA Certificate Management

- **Root CA**: Auto-generated on first run, stored in `~/.whatproxy/ca/`. User must trust the root CA in system/browser.
- **Dynamic signing**: Sign leaf certs per domain on first access using `rcgen`, cached in memory and on disk.
- **Security**: Root CA private key permissions set to `600`. RSA 4096 or ECDSA P-256.

```yaml
tls:
  ca_dir: "~/.whatproxy/ca"
  ca_cert_ttl_days: 3650
```

## Configuration

Full configuration file:

```yaml
listen:
  http: "127.0.0.1:8080"
  https: "127.0.0.1:8443"
  socks5: "127.0.0.1:1080"

tls:
  ca_dir: "~/.whatproxy/ca"
  ca_cert_ttl_days: 3650

upstream:
  enabled: false
  # proxy: "http://upstream-proxy:3128"

scripts:
  lua_search_path: "./scripts/?.lua"
  external_timeout_ms: 5000
  lua_sandbox: true

rules:
  - name: "add auth to api"
    url_pattern: "api.example.com/v1/*"
    request_scripts:
      - type: lua
        path: scripts/add-auth.lua
      - type: external
        command: ["node", "scripts/validate.js"]
        timeout_ms: 3000
    response_scripts:
      - type: lua
        path: scripts/mask-data.lua

  - name: "log all traffic"
    url_pattern: "*"
    response_scripts:
      - type: lua
        path: scripts/log.lua
```

### URL Pattern Matching

Glob-style patterns: `*` matches any single path segment, `**` matches recursively.

- `api.example.com/v1/*` matches `api.example.com/v1/users` but not `api.example.com/v1/users/posts`
- `api.example.com/**` matches everything under `api.example.com/`

## Technology Stack

- **Language**: Rust
- **Async runtime**: tokio
- **HTTP**: hyper
- **TLS**: rustls + rcgen (MITM cert signing)
- **Lua**: mlua (embeddable Lua runtime)
- **SOCKS5**: Custom implementation per RFC 1928

## Testing Strategy

- **Unit tests**: Router matching, Lua script API, config parsing
- **Integration tests**: Full proxy startup → real HTTP client → verify script modifications
- **Test helpers**: Embedded mock target server
- **External script tests**: Example Node/Python scripts validating the communication protocol