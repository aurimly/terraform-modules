# gcp/target-proxies

Map-keyed module for the load-balancer target proxies `gcp/load-balancer`
does not cover: TCP (global and regional), SSL (global-only) and gRPC
(global-only). HTTP/HTTPS proxies live in `gcp/load-balancer`.

SSL and gRPC proxies are global resources — the provider has no regional
variants for them; regional TCP proxies exist for cross-region internal
load balancers.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `tcp_proxies` | `map(object)` | — | Global target TCP proxies (`google_compute_target_tcp_proxy`). |
| `regional_tcp_proxies` | `map(object)` | — | Regional target TCP proxies (`google_compute_region_target_tcp_proxy`). |
| `ssl_proxies` | `map(object)` | — | Global target SSL proxies (`google_compute_target_ssl_proxy`). |
| `grpc_proxies` | `map(object)` | — | Global target gRPC proxies (`google_compute_target_grpc_proxy`). |

Unused kinds emit empty maps of outputs.

### `tcp_proxies` / `regional_tcp_proxies`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name (validated). |
| `backend_service` | `string` | — | Backend service self link — wire from `gcp/load-balancer` `backend_service_self_links` / `regional_backend_service_self_links`. Required (validated): the only documented optional case belongs to the beta `load_balancing_scheme`, which is not in scope (see Notes). |
| `region` | `string` | — | Regional kind only; GCP region (validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `proxy_header` | `string` | — | `NONE` (API default) or `PROXY_V1` (validated). |
| `description` | `string` | — | Human-readable description. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |

### `ssl_proxies`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name (validated). |
| `backend_service` | `string` | — | Backend service self link (provider-required). |
| `ssl_certificates` | `list(string)` | — | Certificate IDs or self links (bring your own — pair with `gcp/managed-ssl-certificate`). |
| `certificate_map` | `string` | — | Certificate Manager certificate map URI `//certificatemanager.googleapis.com/...` (prefix validated). |
| `ssl_policy` | `string` | — | SSL policy self link (pair with `gcp/ssl-policy`). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `proxy_header` | `string` | — | `NONE` or `PROXY_V1` (validated). |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |

At least one of `ssl_certificates` (non-empty) or `certificate_map` — the
API rejects a target SSL proxy without any certificate (validated).

### `grpc_proxies`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name (validated). |
| `url_map` | `string` | — | URL map self link — wire from `gcp/load-balancer` `url_map_self_links`. Required (validated) even though the API allows omitting it; without a URL map the proxy has no routing target. |
| `validate_for_proxyless` | `bool` | — | Run proxyless gRPC configuration checks (route rules must use the `PathPrefixMatch` service). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |

## Outputs

Maps keyed by the input entry key:

- `tcp_proxy_names`, `tcp_proxy_self_links`
- `regional_tcp_proxy_names`, `regional_tcp_proxy_self_links`
- `ssl_proxy_names`, `ssl_proxy_self_links`
- `grpc_proxy_names`, `grpc_proxy_self_links`

## Example

```hcl
tcp_proxies = {
  "app" = {
    name            = "example-app-tcp-proxy"
    backend_service = module.lb.backend_service_self_links["tcp-app"]
    deletion_policy = "ABANDON"
  }
}

ssl_proxies = {
  "tls" = {
    name             = "example-tls-ssl-proxy"
    backend_service  = module.lb.backend_service_self_links["tls"]
    ssl_certificates = [module.cert.self_links["example-cert"]]
    ssl_policy       = module.ssl-policy.self_links["example"]
  }
}

grpc_proxies = {
  "grpc" = {
    name                   = "example-grpc-proxy"
    url_map                = module.lb.url_map_self_links["grpc"]
    validate_for_proxyless = true
  }
}
```

## Wiring

`backend_service` and `url_map` are free-string self links (same convention
as `gcp/load-balancer` `forwarding_rules.target`): take them from that
module's `backend_service_self_links` / `url_map_self_links` outputs, then
point forwarding rules (`target`) at this module's
`*_proxy_self_links`. They are not graph-visible to this module, so clear
such references (or destroy both sides in one apply) before removing a
referenced backend service or URL map — the API rejects deleting resources
that are in use.

## Not yet in scope

`load_balancing_scheme` and `proxy_bind` on TCP proxies: the field is
beta-launched (its examples use the beta provider) and is deferred until it
is proven against the GA API; with the scheme unavailable, `backend_service`
is required and `proxy_bind` is not exposed. Add-back is a minor release.

## Import

- Target TCP proxy: `projects/{project}/global/targetTcpProxies/{name}`; regional: `projects/{project}/regions/{region}/targetTcpProxies/{name}`
- Target SSL proxy: `projects/{project}/global/targetSslProxies/{name}`
- Target gRPC proxy: `projects/{project}/global/targetGrpcProxies/{name}`
