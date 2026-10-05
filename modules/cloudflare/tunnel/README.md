# cloudflare/tunnel

Map-keyed module for Cloudflare Tunnels (cloudflared). Manages the tunnel,
its private network routes, and optionally its remotely-managed ingress
config.

The provider's tunnel family is `cloudflare_zero_trust_tunnel_cloudflared{,_route,_config}`
in v5 (renamed from v4's `cloudflare_tunnel*` family — consumers arriving
from v4 docs should search for the new names). Researched against provider
5.24.0; the `required_providers` floor stays the repo-wide `>= 5.0.0`, but
5.24 itself removed an attribute inside this family, so consumers far below
it may hit drift or churn.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Cloudflare account ID. |
| `expose_tokens` | `bool` | `false` | Read connector tokens for the `tunnel_tokens` output; see Notes. |
| `tunnels` | `map(object)` | — | Map of tunnels keyed by an arbitrary unique ID. |

### `tunnels` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Tunnel name. Renaming is an in-place update. |
| `tunnel_secret` | `string` | `null` | Base64-encoded secret (build it with `base64encode`), ≥ 32 bytes decoded. Required for locally-managed tunnels — connectors authenticate with it. |
| `config_src` | `string` | `"local"` | `local` (ingress YAML on the origin) or `cloudflare` (remote ingress via the `config` object). Changing it replaces the tunnel. |
| `routes` | `map(object)` | `{}` | Private network routes, keyed by an arbitrary route ID: `network` (CIDR, required), `comment`, `virtual_network_id` (all optional). |
| `config` | `object` | `null` | Remote ingress config; requires `config_src = "cloudflare"`. See below. |

### `config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ingress` | `list(object)` | `null` | Ordered ingress rules, see below. |
| `origin_request` | `object` | `null` | Tunnel-level origin request settings; same shape as per-ingress `origin_request`. |

### `ingress` rules (ordered list)

Ingress is an ordered list, not a map, because the API is first-match —
the catch-all (service `http_status:404`) must come last. This is the
repo's established treatment for order-semantic sub-collections
(see `aws/alb` `actions`, `aws/s3-bucket` `lifecycle_rules`).

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service` | `string` | — | Target service, e.g. `http://localhost:8080`, `http_status:404`. |
| `hostname` | `string` | — | Public hostname to match. |
| `path` | `string` | — | Path regex to match. |
| `origin_request` | `object` | `null` | Per-rule origin request settings; same shape as tunnel-level. |

### `origin_request` object (per-ingress and tunnel-level)

All fields optional except where noted; the union of provider fields.

| Attribute | Type | Description |
|---|---|---|
| `access` | `object` | Zero Trust Access check: `aud_tag` (list of strings, required), `team_name` (string, required), `required` (bool). |
| `ca_pool` | `string` | Path to the origin CA. |
| `connect_timeout` | `number` | Timeout establishing the connection, seconds. |
| `disable_chunked_encoding` | `bool` | Disable chunked transfer encoding. |
| `http2_origin` | `bool` | Use HTTP/2 to the origin. |
| `http_host_header` | `string` | Host header to send to the origin. |
| `keep_alive_connections` | `number` | Max keep-alive connections. |
| `keep_alive_timeout` | `number` | Keep-alive timeout, seconds. |
| `match_sn_ito_host` | `bool` | Match the origin's SNI to the host header. |
| `no_happy_eyeballs` | `bool` | Disable happy eyeballs. |
| `no_tls_verify` | `bool` | Skip origin TLS verification. |
| `origin_server_name` | `string` | SNI to the origin. |
| `proxy_type` | `string` | Proxy type for the connection (`socks`, ...). |
| `tcp_keep_alive` | `number` | TCP keep-alive, seconds. |
| `tls_timeout` | `number` | TLS handshake timeout, seconds. |

## Outputs

- `tunnel_ids`, `tunnel_names`, `tunnel_statuses`, `tunnel_config_srcs` — keyed by tunnel key.
- `tunnel_tokens` — connector tokens (sensitive), keyed by tunnel key; only populated when `expose_tokens = true`.
- `tunnel_secrets` — input secrets echoed back (sensitive), keyed by tunnel key.
- `route_ids`, `route_networks` — keyed by composite key `"<tunnel_key>/<route_key>"`.
- `config_versions` — remotely-managed config version, keyed by tunnel key.

## Notes

- **`expose_tokens` and permissions**: reading tokens requires Write-scoped
  API permissions (`Cloudflare Tunnel Write`, `Cloudflare One Connector:
  cloudflared Write`, `Cloudflare One Connectors Write`); a Read-only
  consumer with `expose_tokens = true` fails every plan. With the default
  `false`, no token reads happen at all. Exposed token values land in state
  and are visible to anyone with state access.
- **Secrets in state**: `tunnel_tokens` and `tunnel_secrets` are sensitive,
  but sensitive values still land in state and are visible to anyone with
  state access.
- **Secret rotation** is an in-place update, but running connectors keep
  using the old secret until restarted.
- **`config_src` flip replaces the tunnel**: switching `local` →
  `cloudflare` (or back) destroys and recreates the tunnel — connectors
  must re-enroll with a new token; routes and config follow the new tunnel
  ID automatically.
- **Keys are arbitrary unique identifiers**; the composite route key is
  `"<tunnel_key>/<route_key>"` — avoid `/` inside tunnel and route keys.
- Tunnels for consumers with Read-only credentials: keep `expose_tokens`
  at its default.
- The config resource cannot be destroyed via Terraform once applied;
  removing `config` clears it through the API instead.

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

tunnels = {
  "edge-db" = {
    name          = "example-edge-db"
    tunnel_secret = base64encode("example-example-example-example-32")
    routes = {
      "db" = {
        network = "10.0.0.0/24"
        comment = "example database subnet"
      }
    }
  }
  "edge-http" = {
    name       = "example-edge-http"
    config_src = "cloudflare"
    config = {
      ingress = [
        {
          hostname = "app.example.com"
          service  = "http://localhost:8080"
        },
        {
          service = "http_status:404"
        },
      ]
    }
  }
}
```

## Import

Name the resource type — tunnel and config import strings are
byte-identical (`<account_id>/<tunnel_id>`), so importing the tunnel ID
into the config resource, or vice versa, misbehaves:

- `cloudflare_zero_trust_tunnel_cloudflared` ← `<account_id>/<tunnel_id>`
- `cloudflare_zero_trust_tunnel_cloudflared_route` ← `<account_id>/<route_id>`
- `cloudflare_zero_trust_tunnel_cloudflared_config` ← `<account_id>/<tunnel_id>`
