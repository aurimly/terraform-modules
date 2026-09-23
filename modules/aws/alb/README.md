# aws/alb

Map-keyed module for Elastic Load Balancing (application, network and
gateway LBs) with nested target groups, target attachments, listeners,
and listener rules — one entry deploys a complete LB stack.

## Destroy semantics (read before using)

- Removing a load balancer key destroys the LB plus **all its target
  groups, listeners and rules** in this module (they are nested under the
  entry).
- `deletion_protection = true` (default `false`) blocks LB deletion at
  the API level; disable it first when you really want the LB gone.
- Removing a target group key detaches its attachments; targets keep
  running, only the routing entry disappears.
- Listener rule priorities are per-listener; removing a rule frees the
  priority for reuse.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `load_balancers` | `map(object)` | `{}` | Map of load balancers keyed by an arbitrary unique ID. |

### `load_balancers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | LB name, up to 32 chars of alphanumerics/hyphens (validated). Set this **or** `name_prefix` (validated). |
| `name_prefix` | `string` | — | Prefix for a generated unique name, up to 6 chars of alphanumerics (validated). |
| `internal` | `bool` | `false` | Internal LB. Gateway LBs are inherently internal (validated). |
| `load_balancer_type` | `string` | `application` | One of `application`, `network`, `gateway` (validated). |
| `security_group_ids` | `list(string)` | `[]` | Security groups (application LBs only — the API rejects them on network/gateway). |
| `subnet_ids` | `list(string)` | `[]` | Subnets; at least two AZs for internet-facing LBs in production. Required (precondition). |
| `ip_address_type` | `string` | — | `ipv4`, `dualstack`, `dualstack-without-public-ipv4` (validated). |
| `customer_owned_ipv4_pool` | `string` | — | Customer-owned IPv4 pool (outposts). |
| `desync_mitigation_mode` | `string` | — | `monitor`, `defensive`, `strictest` (validated); application LBs. |
| `dns_record_client_routing_policy` | `string` | — | `availability_zone_affinity`, `partial_availability_zone_affinity`, `any_availability_zone` (validated); network LBs. |
| `drop_invalid_header_fields` | `bool` | — | Drop HTTP header fields with invalid characters (application LBs). |
| `deletion_protection` | `bool` | `false` | Block API-level LB deletion. |
| `enable_http2` | `bool` | — | HTTP/2 on application LBs. |
| `enable_tls_version_and_cipher_suite_headers` | `bool` | — | Emit TLS version/cipher headers. |
| `enable_xff_client_port` | `bool` | — | X-Forwarded-For client port (application LBs). |
| `enable_waf_fail_open` | `bool` | — | Allow traffic when WAF is unavailable (application LBs). |
| `idle_timeout` | `number` | — | Idle timeout in seconds (application LBs, 1–4000). |
| `preserve_host_header` | `bool` | — | Pass the Host header to targets unmodified (application LBs). |
| `xff_header_processing_mode` | `string` | — | `append`, `preserve`, `remove` (validated). |
| `access_logs` | `object` | — | `{bucket, prefix}` — presence enables access log delivery to the named S3 bucket. |
| `target_groups` | `map(object)` | `{}` | Map of target groups under this LB; see the `target_groups` object table. |
| `listeners` | `map(object)` | `{}` | Map of listeners under this LB; see the `listeners` object table. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `target_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `vpc_id` | `string` | — | VPC of the target group (required for instance/ip/lambda-with-HTTP types; the API rejects lambda target groups with a VPC — pass `target_type = "lambda"` without port/protocol and the module still requires a vpc_id value syntactically; use any valid VPC). |
| `name` | `string` | — | Target group name, up to 32 chars (validated). Set this **or** `name_prefix` (validated). |
| `name_prefix` | `string` | — | Prefix for a generated name, up to 6 chars (validated). |
| `port` | `number` | — | Target port; forbidden on lambda target groups (validated). |
| `protocol` | `string` | — | `HTTP`, `HTTPS`, `TCP`, `TLS`, `UDP`, `TCP_UDP`, `GENEVE` (validated); forbidden on lambda target groups (validated). |
| `target_type` | `string` | `instance` | `instance`, `ip`, `lambda`, `alb` (validated). |
| `deregistration_delay` | `number` | — | Deregistration delay in seconds (0–3600). |
| `load_balancing_algorithm_type` | `string` | — | `round_robin`, `least_outstanding_requests`, `flow_hash` (validated). |
| `load_balancing_cross_zone_enabled` | `bool` | — | Cross-zone load balancing for this target group. |
| `load_balancing_anomaly_mitigation` | `string` | — | `on`, `off` (validated; least_outstanding_requests only). |
| `slow_start` | `number` | — | Slow-start window in seconds; 0 disables, otherwise 30–900 (validated). |
| `connection_termination` | `bool` | — | Terminate connections on deregistration (network LBs). |
| `protocol_version` | `string` | — | `GRPC`, `HTTP1`, `HTTP2` (validated). |
| `preserve_client_ip` | `bool` | — | Client IP preservation (network LBs). |
| `proxy_protocol_v2` | `bool` | — | PROXY protocol v2 (network LBs). |
| `ip_address_type` | `string` | — | Target IP type: `ipv4`, `ipv6`, `all` for ip-type target groups. |
| `health_check` | `object` | — | `{enabled, healthy_threshold, interval, matcher, path, port, protocol, timeout, unhealthy_threshold}`. |
| `stickiness` | `object` | — | `{enabled, type, cookie_duration, cookie_name}`; `type` one of `lb_cookie`, `app_cookie`, `source_ip` (validated); `cookie_name` only for `app_cookie` (validated). |
| `attachments` | `map(object)` | `{}` | Map of static target attachments: `{target_id, port, availability_zone}`. `availability_zone` only for ip-type targets (validated). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `listeners` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `port` | `number` | — | Listen port. |
| `protocol` | `string` | — | `HTTP`, `HTTPS`, `TCP`, `TLS`, `UDP`, `TCP_UDP`, `GENEVE` (validated). |
| `ssl_policy` | `string` | — | TLS policy; required for HTTPS/TLS listeners (validated). |
| `certificate_arn` | `string` | — | Default certificate ARN. |
| `alpn_policy` | `string` | — | ALPN policy (TLS listeners). |
| `tcp_idle_timeout_seconds` | `number` | — | TCP idle timeout (network LBs, 60–6000). |
| `default_action` | `object` | — | `{type, order, target_group_arn, target_group_key, redirect, fixed_response, authenticate_cognito, authenticate_oidc}`. `type` one of `forward`, `redirect`, `fixed-response`, `authenticate-cognito`, `authenticate-oidc` (validated). Forward actions require **exactly one** of `target_group_arn` (external ARN) or `target_group_key` (a key in this LB's `target_groups` map, resolved internally — both validated); non-forward actions must set neither. `redirect` block exactly for redirect (status_code 301/302 validated); `fixed_response` block exactly for fixed-response (validated). |
| `rules` | `map(object)` | `{}` | Listener rules; see the `rules` object table. |
| `tags` | `map(string)` | `{}` | Tags. |

### `rules` object

| Attribute | Type | Description |
|---|---|---|
| `priority` | `number` | 1–50000 (validated); omit for auto-assignment. |
| `actions` | `list(object)` | Same shape as `default_action` minus authenticate actions (`forward`, `redirect`, `fixed-response` validated). Forward actions require exactly one of `target_group_arn` or `target_group_key` (same-LB `target_groups` key, validated). |
| `conditions` | `list(object)` | `{host_header, http_header, http_request_method, path_pattern, query_string, source_ip}`; each condition sets exactly one matcher (validated); `query_string` is a list of `{key, value}` pairs. |

## Outputs

`lb_arns` — map of LB key => LB ARN.
`lb_ids` — map of LB key => LB ID.
`lb_dns_names` — map of LB key => DNS name.
`lb_zone_ids` — map of LB key => Route 53 zone ID (alias targets).
`lb_listener_arns` — map of `"lb-key.listener-key"` => listener ARN.
`target_group_arns` — map of `"lb-key.target-group-key"` => target group ARN.
`target_group_names` — map of `"lb-key.target-group-key"` => name.
`listener_rule_arns` — map of `"lb-key.listener-key.rule-key"` => rule ARN.

## Example

```hcl
load_balancers = {
  "main" = {
    name              = "example-alb"
    security_group_ids = ["sg-0123456789abcdef0"]
    subnet_ids        = ["subnet-0a", "subnet-0b"]
    access_logs = {
      bucket = "example-alb-logs"
    }
    target_groups = {
      "web" = {
        vpc_id   = "vpc-0123456789abcdef0"
        name     = "example-web"
        port     = 8080
        protocol = "HTTP"
        health_check = {
          path    = "/healthz"
          matcher = "200"
        }
        attachments = {
          "one" = { target_id = "i-0123456789abcdef0" }
          "two" = { target_id = "i-0fedcba9876543210" }
        }
      }
      "api" = {
        vpc_id   = "vpc-0123456789abcdef0"
        name     = "example-api"
        port     = 9090
        protocol = "HTTP"
      }
    }
    listeners = {
      "http" = {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "redirect"
          redirect = {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "301"
          }
        }
      }
      "https" = {
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        certificate_arn = "arn:aws:acm:eu-central-1:111111111111:certificate/example"
        default_action = {
          type             = "forward"
          target_group_key = "web"
        }
        rules = {
          "api" = {
            priority = 10
            actions = [{
              type             = "forward"
              target_group_key = "api"
            }]
            conditions = [{
              path_pattern = { values = ["/api/*"] }
            }]
          }
        }
      }
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers; composite keys
  (`lb.tg`, `lb.listener.rule`) are built from them and surface in the
  outputs.
- Listener and rule forward actions take `target_group_arn` **or**
  `target_group_key`: use `target_group_key` to reference a target group
  managed under the same load balancer entry (works in a single apply),
  and `target_group_arn` for target groups managed elsewhere (another
  module instance, a dependency output, or an external resource).
- Access logs require the bucket with the ELB log-delivery policy; the
  module only wires the config.
- Pair with `aws/route53-records` alias records using `lb_zone_ids` and
  `lb_dns_names` outputs.

## Import

`aws_lb` ← LB ARN.
`aws_lb_target_group` ← target group ARN.
`aws_lb_target_group_attachment` ← `<target-group-arn>/<target-id>[/<port>]`
(port omitted for lambda targets).
`aws_lb_listener` ← listener ARN.
`aws_lb_listener_rule` ← rule ARN.
Import addresses follow the composite key shape of the outputs
(`target_group["lb.tg"]` etc.).
