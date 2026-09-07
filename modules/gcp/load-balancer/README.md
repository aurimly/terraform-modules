# gcp/load-balancer

Map-keyed module for Google Cloud load balancing: global and regional HTTP(S) load balancers with health checks, backend services, backend buckets, URL maps, target proxies and forwarding rules.

Each input is a map of one resource kind, keyed by an arbitrary identifier. Kinds cross-reference each other by key (see Wiring below).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `health_checks` | `map(object)` | — | Global health checks (`google_compute_health_check`). |
| `regional_health_checks` | `map(object)` | — | Regional health checks (`google_compute_region_health_check`). |
| `backend_services` | `map(object)` | — | Global backend services (`google_compute_backend_service`). |
| `regional_backend_services` | `map(object)` | — | Regional backend services (`google_compute_region_backend_service`). |
| `backend_buckets` | `map(object)` | — | Backend buckets (`google_compute_backend_bucket`). |
| `url_maps` | `map(object)` | — | Global URL maps (`google_compute_url_map`). |
| `regional_url_maps` | `map(object)` | — | Regional URL maps (`google_compute_region_url_map`). |
| `http_proxies` | `map(object)` | — | Global target HTTP proxies (`google_compute_target_http_proxy`). |
| `https_proxies` | `map(object)` | — | Global target HTTPS proxies (`google_compute_target_https_proxy`). |
| `regional_http_proxies` | `map(object)` | — | Regional target HTTP proxies (`google_compute_region_target_http_proxy`). |
| `regional_https_proxies` | `map(object)` | — | Regional target HTTPS proxies (`google_compute_region_target_https_proxy`). |
| `global_forwarding_rules` | `map(object)` | — | Global forwarding rules (`google_compute_global_forwarding_rule`). |
| `forwarding_rules` | `map(object)` | — | Regional forwarding rules (`google_compute_forwarding_rule`). |

Every kind shares these conventions:

- `name` — resource name; 1–63 lowercase RFC1035 characters. Validated client-side.
- `project_id` — project; defaults to the provider-level project.
- Regional kinds additionally require `region`.

### `health_checks` / `regional_health_checks`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name. |
| `region` | `string` | — | Regional kind only; GCP region. |
| `project_id` | `string` | — | Project. |
| `description` | `string` | — | Human-readable description. |
| `check_interval_sec` | `number` | — | Seconds between probes; >= 1 (validated). |
| `timeout_sec` | `number` | — | Probe timeout; >= 1 (validated). |
| `healthy_threshold` | `number` | — | Consecutive successes to mark healthy; >= 1 (validated). |
| `unhealthy_threshold` | `number` | — | Consecutive failures to mark unhealthy; >= 1 (validated). |
| `source_regions` | `list(string)` | — | Global kind only; source regions for hybrid probes. |
| `http_health_check` / `https_health_check` / `http2_health_check` | `object` | — | See the HTTP-family block table. Exactly one protocol block per check (validated). |
| `tcp_health_check` / `ssl_health_check` | `object` | — | See the TCP/SSL block table. |
| `grpc_health_check` | `object` | — | See the gRPC block table. |
| `log_config` | `object` | — | `{enable}`. |

### HTTP-family health check block (`http_health_check`, `https_health_check`, `http2_health_check`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `host` | `string` | — | Host header. |
| `request_path` | `string` | — | URL path to probe (e.g. `/healthz`). |
| `response` | `string` | — | Expected response substring. |
| `port` | `number` | — | Fixed probe port. |
| `port_name` | `string` | — | Named port to probe. |
| `proxy_header` | `string` | — | `NONE` or `PROXY_V1` (validated). |
| `port_specification` | `string` | — | `USE_FIXED_PORT`, `USE_NAMED_PORT` or `USE_SERVING_PORT` (validated). |

At least one attribute must be set — the Compute API rejects fully empty protocol blocks.

### TCP/SSL health check block (`tcp_health_check`, `ssl_health_check`)

Same attributes as the HTTP family minus `host` and `request_path`: `request`, `response`, `port`, `port_name`, `proxy_header`, `port_specification`.

### gRPC health check block (`grpc_health_check`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `port` | `number` | — | Fixed probe port. |
| `port_name` | `string` | — | Named port to probe. |
| `port_specification` | `string` | — | `USE_FIXED_PORT`, `USE_NAMED_PORT` or `USE_SERVING_PORT` (validated). |
| `grpc_service_name` | `string` | — | gRPC service name for the health RPC. |

### `backend_services` / `regional_backend_services`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name. |
| `region` | `string` | — | Regional kind only; GCP region. |
| `project_id` | `string` | — | Project. |
| `description` | `string` | — | Human-readable description. |
| `affinity_cookie_ttl_sec` | `number` | — | Cookie affinity TTL. |
| `compression_mode` | `string` | — | Global kind only; `NONE`, `GZIP` or `DEFLATE`. |
| `connection_draining_timeout_sec` | `number` | — | Draining timeout. |
| `custom_request_headers` | `list(string)` | — | Headers injected into requests to backends. |
| `custom_response_headers` | `list(string)` | — | Headers injected into responses. |
| `enable_cdn` | `bool` | — | Cloud CDN. |
| `health_checks` | `list(string)` | `[]` | Keys into `health_checks` (global kind) or `regional_health_checks` (regional kind); resolved to the referenced check IDs and validated at plan time. The API accepts at most one health check per service. |
| `load_balancing_scheme` | `string` | — | e.g. `EXTERNAL`, `EXTERNAL_MANAGED`, `INTERNAL`, `INTERNAL_SELF_MANAGED` (kind-dependent; the API enforces the valid set). |
| `locality_lb_policy` | `string` | — | e.g. `ROUND_ROBIN`, `LEAST_REQUEST`. |
| `network` | `string` | — | Regional kind only; VPC network for internal schemes. |
| `port_name` | `string` | — | Backend named port (HTTP family). |
| `protocol` | `string` | — | e.g. `HTTP`, `HTTPS`, `HTTP2`, `TCP`, `SSL`, `GRPC`. |
| `security_policy` | `string` | — | Cloud Armor security policy self link. |
| `session_affinity` | `string` | — | e.g. `CLIENT_IP`, `GENERATED_COOKIE`, `NONE`. |
| `timeout_sec` | `number` | — | Request timeout. |
| `service_lb_policy` | `string` | — | Global kind only; service LB policy self link. |
| `backends` | `list(object)` | `[]` | See the `backends` entry table. |
| `log_config` | `object` | — | `{enable, sample_rate}`; sample rate 0.0–1.0. |

### `backends` entry (backend services)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `group` | `string` | — | Instance group, zonal NEG or serverless NEG self link. Non-empty (validated). Sources: `gcp/instance-group-manager` `instance_group_urls`, `gcp/gke` `node_pool_instance_group_urls`. |
| `balancing_mode` | `string` | — | `UTILIZATION`, `RATE` or `CONNECTION` (validated). |
| `capacity_scaler` | `number` | — | Capacity multiplier; >= 0 (validated), 0 drains the backend. |
| `description` | `string` | — | Human-readable description. |
| `max_connections` | `number` | — | Max connections for the group. |
| `max_connections_per_instance` | `number` | — | Max connections per instance. |
| `max_connections_per_endpoint` | `number` | — | Max connections per endpoint. |
| `max_rate` | `number` | — | Max requests per second for the group. |
| `max_rate_per_instance` | `number` | — | Max requests per second per instance. |
| `max_rate_per_endpoint` | `number` | — | Max requests per second per endpoint. |
| `max_utilization` | `number` | — | Target backend utilization (0.0–1.0). |

### `backend_buckets`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name. |
| `bucket_name` | `string` | — | Cloud Storage bucket serving the content. |
| `project_id` | `string` | — | Project. |
| `description` | `string` | — | Human-readable description. |
| `enable_cdn` | `bool` | — | Cloud CDN. |
| `compression_mode` | `string` | — | `NONE`, `GZIP` or `DEFLATE`. |
| `edge_security_policy` | `string` | — | Cloud Armor edge security policy self link. |
| `custom_response_headers` | `list(string)` | — | Headers injected into responses. |
| `cdn_policy` | `object` | — | See the `cdn_policy` table. |

### `cdn_policy` object (backend buckets)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `signed_url_cache_max_age_sec` | `number` | — | Signed URL cache TTL; >= 0 (validated). |
| `default_ttl` | `number` | — | Default cache TTL; >= 0 (validated). |
| `max_ttl` | `number` | — | Max cache TTL; >= 0 (validated). |
| `client_ttl` | `number` | — | Client cache TTL; >= 0 (validated). |
| `negative_caching` | `bool` | — | Cache error responses. |
| `cache_mode` | `string` | — | `CACHE_ALL_STATIC`, `USE_ORIGIN_HEADERS` or `FORCE_CACHE_ALL` (validated). |
| `serve_while_stale` | `number` | — | Seconds to serve stale; >= 0 (validated). |
| `request_coalescing` | `bool` | — | Coalesce simultaneous cache-miss requests. |
| `cache_key_policy` | `object` | — | `{query_string_whitelist, include_http_headers}`. |

### `url_maps` / `regional_url_maps`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name. |
| `region` | `string` | — | Regional kind only; GCP region. |
| `project_id` | `string` | — | Project. |
| `description` | `string` | — | Human-readable description. |
| `default_service` | `string` | — | Free string: backend service or backend bucket self link (or name) — typically wired from this module's own outputs. Exactly one of `default_service`/`default_url_redirect` (validated). |
| `default_url_redirect` | `object` | — | `{strip_query, https_redirect, redirect_response_code}`; `strip_query` required. `redirect_response_code` one of `MOVED_PERMANENTLY_DEFAULT`, `FOUND`, `SEE_OTHER`, `TEMPORARY_REDIRECT`, `PERMANENT_REDIRECT` (validated). |
| `default_route_action` | `object` | — | `{cors_policy}`; see the `cors_policy` table. |
| `host_rules` | `list(object)` | `[]` | `{description, hosts, path_matcher}`; `hosts` non-empty (validated), `path_matcher` references a `path_matchers[].name`. |
| `path_matchers` | `list(object)` | `[]` | `{name, description, default_service, path_rules}`; `name` RFC1035 and unique within the entry (validated). |
| `path_matchers[].path_rules` | `list(object)` | `[]` | `{service, paths}`; `service` free string (backend service/bucket), `paths` non-empty (validated). |

### `cors_policy` object (URL maps)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `allow_credentials` | `bool` | — | Allow credentials in CORS responses. |
| `allow_headers` | `list(string)` | — | Allowed request headers. |
| `allow_methods` | `list(string)` | — | Allowed HTTP methods. |
| `allow_origin_regexes` | `list(string)` | — | Allowed origin regexes. |
| `allow_origins` | `list(string)` | — | Allowed origins. |
| `disabled` | `bool` | — | Disables the CORS policy. |
| `expose_headers` | `list(string)` | — | Response headers exposed to browsers. |
| `max_age` | `number` | — | Preflight cache seconds. |

### `http_proxies` / `https_proxies` / `regional_http_proxies` / `regional_https_proxies`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name. |
| `region` | `string` | — | Regional kinds only; GCP region. |
| `url_map` | `string` | — | Key into `url_maps` (global kinds) or `regional_url_maps` (regional kinds); resolved to the referenced self link and validated at plan time. |
| `project_id` | `string` | — | Project. |
| `description` | `string` | — | Human-readable description. |
| `proxy_bind` | `bool` | — | Global HTTP kind only; bind the proxy to the forwarding rule IP. |
| `http_keep_alive_timeout_sec` | `number` | — | Keep-alive timeout (all kinds). |
| `quic_override` | `string` | — | Global HTTPS kind only; `ALLOW`, `NONE` or `UPGRADE` (validated). |
| `tls_early_data` | `string` | — | Global HTTPS kind only; `ACCEPTED`, `REJECTED` or `PERMISSIVE` (validated). |
| `ssl_certificates` | `list(string)` | — | Certificate IDs or self links (bring your own — see Notes). |
| `certificate_map` | `string` | — | Certificate Manager certificate map self link (global HTTPS kind only). |
| `certificate_manager_certificates` | `list(string)` | — | Certificate Manager certificate paths (global and regional HTTPS kinds). |
| `ssl_policy` | `string` | — | SSL policy self link. |
| `server_tls_policy` | `string` | — | Server TLS policy self link. |

HTTPS proxies must set at least one certificate source (`ssl_certificates`, `certificate_map` or `certificate_manager_certificates` for the global kind; `ssl_certificates` or `certificate_manager_certificates` for the regional kind — validated).

### `global_forwarding_rules`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name. |
| `target` | `string` | — | Target HTTP/HTTPS/SSL/TCP proxy self link (free string; wire from this module's proxy outputs). |
| `project_id` | `string` | — | Project. |
| `description` | `string` | — | Human-readable description. |
| `ip_address` | `string` | — | Reserved IP self link (pair with `gcp/static-ip`) or a literal IP. |
| `ip_protocol` | `string` | — | `TCP`, `UDP`, `SCTP`, `ESP`, `AH`, `ICMP` or `L3_DEFAULT` (validated). |
| `ip_version` | `string` | — | `IPV4` or `IPV6`. |
| `labels` | `map(string)` | — | Resource labels. |
| `load_balancing_scheme` | `string` | — | `EXTERNAL`, `EXTERNAL_MANAGED` or `INTERNAL_SELF_MANAGED` (validated). |
| `network` | `string` | — | VPC network for `INTERNAL_SELF_MANAGED`. |
| `port_range` | `string` | — | e.g. `443-443` for HTTPS, `80-80` for HTTP. |
| `subnetwork` | `string` | — | Subnetwork for `EXTERNAL_MANAGED` with `STANDARD` tier. |
| `source_ip_ranges` | `list(string)` | — | Source IP ranges for proxyless gRPC. |
| `no_automate_dns_zone` | `bool` | — | Disable automatic DNS zone creation. |
| `service_directory_registrations` | `object` | — | `{namespace, service_directory_region}`. |

### `forwarding_rules` (regional)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name. |
| `region` | `string` | — | GCP region. |
| `target` | `string` | — | Target proxy self link for proxy-based LBs (free string; wire from this module's outputs). |
| `project_id` | `string` | — | Project. |
| `description` | `string` | — | Human-readable description. |
| `ip_address` | `string` | — | Reserved IP self link or literal IP. |
| `ip_protocol` | `string` | — | `TCP`, `UDP`, `SCTP`, `ESP`, `AH`, `ICMP` or `L3_DEFAULT` (validated). |
| `backend_service` | `string` | — | Backend service for pass-through LBs (no target proxy). |
| `load_balancing_scheme` | `string` | — | `EXTERNAL`, `EXTERNAL_MANAGED`, `INTERNAL` or `INTERNAL_MANAGED` (validated). |
| `network` | `string` | — | VPC network (internal schemes). |
| `port_range` | `string` | — | Single-port range for TCP/UDP external rules. |
| `ports` | `list(string)` | — | Numeric strings 1–65535 (validated); used with `INTERNAL`/`INTERNAL_MANAGED` instead of `port_range`. Forbidden with `all_ports` (validated). |
| `subnetwork` | `string` | — | Subnetwork; required for internal schemes. |
| `allow_global_access` | `bool` | — | Reachable from any region. |
| `all_ports` | `bool` | — | Forward all ports (TCP/UDP internal). |
| `network_tier` | `string` | — | `PREMIUM` or `STANDARD` (validated). |
| `service_label` | `string` | — | Single lowercase RFC1035 label for internal DNS names (validated). |
| `source_ip_ranges` | `list(string)` | — | Source IP ranges for proxyless gRPC. |
| `allow_psc_global_access` | `bool` | — | Global access for Private Service Connect consumers. |
| `no_automate_dns_zone` | `bool` | — | Disable automatic DNS zone creation. |
| `ip_version` | `string` | — | `IPV4` or `IPV6`. |
| `recreate_closed_psc` | `bool` | — | Recreate the rule when a PSC connection closes. |
| `is_mirroring_collector` | `bool` | — | Packet mirroring collector rule. |
| `service_directory_registrations` | `object` | — | `{namespace, service}`. |

## Outputs

Per kind, `*_names` and `*_self_links` are maps keyed by the input entry key. `*_ids` are additionally provided for URL maps and forwarding rules:

- `health_check_names`, `health_check_self_links`
- `regional_health_check_names`, `regional_health_check_self_links`
- `backend_service_names`, `backend_service_self_links`
- `regional_backend_service_names`, `regional_backend_service_self_links`
- `backend_bucket_names`, `backend_bucket_self_links`
- `url_map_names`, `url_map_self_links`, `url_map_ids`
- `regional_url_map_names`, `regional_url_map_self_links`, `regional_url_map_ids`
- `http_proxy_names`, `http_proxy_self_links`
- `https_proxy_names`, `https_proxy_self_links`
- `regional_http_proxy_names`, `regional_http_proxy_self_links`
- `regional_https_proxy_names`, `regional_https_proxy_self_links`
- `global_forwarding_rule_names`, `global_forwarding_rule_self_links`, `global_forwarding_rule_ids`
- `forwarding_rule_names`, `forwarding_rule_self_links`, `forwarding_rule_ids`

Unused kinds emit empty maps.

## Wiring

- **Key references (validated at plan time):** backend service `health_checks` must be keys of the same scope's health-check map; proxy `url_map` must be a key of the same scope's URL-map map. The module resolves them to IDs/self links, which also orders applies.
- **Free strings:** URL map `default_service`, `path_matchers[].default_service`, `path_rules[].service` and forwarding rule `target` accept any backend service/bucket/proxy self link — wire them from this module's own outputs or from other units. They are not graph-visible to this module, so clear such references (or destroy both sides in one apply) before removing a referenced backend service or proxy; the Compute API rejects deleting in-use resources.

## Example

```hcl
module "lb" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/gcp/load-balancer?ref=v1.1.0"

  health_checks = {
    "web" = {
      name               = "example-web-hc"
      check_interval_sec = 10
      timeout_sec        = 5
      http_health_check = {
        request_path = "/healthz"
      }
    },
  }

  backend_services = {
    "app" = {
      name          = "example-app-bes"
      port_name     = "http"
      protocol      = "HTTP"
      health_checks = ["web"]
      backends = [
        { group = module.mig.instance_group_urls["app"][0] },
      ]
    },
  }

  url_maps = {
    "web" = {
      name            = "example-web-urlmap"
      default_service = module.lb.backend_service_self_links["app"]
      host_rules = [
        { hosts = ["example.example.com"], path_matcher = "example-paths" },
      ]
      path_matchers = [
        {
          name            = "example-paths"
          default_service = module.lb.backend_service_self_links["app"]
          path_rules = [
            { service = module.lb.backend_service_self_links["app"], paths = ["/api/*"] },
          ]
        },
      ]
    },
  }

  https_proxies = {
    "web" = {
      name             = "example-web-https-proxy"
      url_map          = "web"
      ssl_certificates = ["projects/example-project-1234/global/sslCertificates/example-cert"]
    },
  }

  global_forwarding_rules = {
    "web" = {
      name       = "example-web-https-fr"
      target     = module.lb.https_proxy_self_links["web"]
      port_range = "443-443"
      ip_address = module.ip.addresses["web"]
    },
  }
}
```

For an internal regional HTTPS load balancer, use `regional_health_checks`, `regional_backend_services`, `regional_url_maps`, `regional_https_proxies` and `forwarding_rules` with `load_balancing_scheme = "INTERNAL_MANAGED"`.

## Notes

- **Certificates are bring-your-own**: this module does not create SSL certificate resources. Pass certificate IDs/self links, a Certificate Manager `certificate_map`, or `certificate_manager_certificates`.
- **IP addresses are bring-your-own**: pass a reserved address self link from `gcp/static-ip` (or a literal IP) as `ip_address`; the module does not create or look up addresses.
- **Schemes and scopes**: global kinds serve external HTTP(S) and Traffic Director; regional kinds serve internal (and external-managed) load balancing. `load_balancing_scheme` values are validated per kind; the API enforces the remaining combinations (e.g. `subnetwork` for internal rules).
- **Minimum toolchain**: the plan-time cross-references (health-check and URL-map key validations) use validations that reference other variables, which requires Terraform 1.9+ or a recent OpenTofu. On older toolchains these validations are not supported.

## Not yet in scope

Managed certificate resources (`google_compute_ssl_certificate`, `google_compute_managed_ssl_certificate`), URL map route-rule advanced actions (fault injection, weighted backends, traffic policies), PSC forwarding targets, and target pools/target instances.

## Import

All resources import by their GCP resource path:

- Backend service: `projects/{project}/global/backendServices/{name}`; regional: `projects/{project}/regions/{region}/backendServices/{name}`
- Backend bucket: `projects/{project}/global/backendBuckets/{name}`
- Health check: `projects/{project}/global/healthChecks/{name}`; regional: `projects/{project}/regions/{region}/healthChecks/{name}`
- URL map: `projects/{project}/global/urlMaps/{name}`; regional: `projects/{project}/regions/{region}/urlMaps/{name}`
- Target HTTP proxy: `projects/{project}/global/targetHttpProxies/{name}`; regional: `projects/{project}/regions/{region}/targetHttpProxies/{name}`
- Target HTTPS proxy: `projects/{project}/global/targetHttpsProxies/{name}`; regional: `projects/{project}/regions/{region}/targetHttpsProxies/{name}`
- Global forwarding rule: `projects/{project}/global/forwardingRules/{name}`
- Forwarding rule: `projects/{project}/regions/{region}/forwardingRules/{name}`
