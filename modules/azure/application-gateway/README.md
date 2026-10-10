# azure/application-gateway

Map-keyed module for Application Gateways on the v2 SKUs. Each entry creates
one `azurerm_application_gateway` in the named resource group; the gateway IP
configurations, frontends, ports, TLS certificates, probes, backends,
listeners and routing rules wire into the gateway resource through this
module — no gateway-ID plumbing on the consumer side. The v1 SKUs are
pinned out: they are deprecated upstream (V1 retirement) and new deployments
go `Standard_v2`/`WAF_v2`.

## Destroy semantics (read before using)

- Removing a gateway key destroys the gateway and all of its listeners,
  routings, probes and certificates inline — the backend targets (VMs,
  VMSS, private IPs) survive untouched.
- Removing a child entry (listener, rule, probe, …) removes just that wiring
  on the gateway.
- Changing a listener's frontend IP/Port or certificate rewires the gateway
  in place; routing-rule changes update the gateway.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `application_gateways` | `map(object)` | — | Map of gateways keyed by an arbitrary unique ID. |

Plan-time validation: `sku_name` v2-only; exactly one of `capacity`
(1–125) or `autoscale_configuration` (min 0–100, max 2–125, max > min);
zones `1`/`2`/`3`; `gateway_ip_configurations` at least one entry;
frontends exactly one of public (ARM ID) or private subnet with allocation
semantics; TLS certificates exactly one of data (+password)/Key Vault
secret, Key Vault needing an identity; listeners with Https requiring a
resolving cert key and `host_name` not competing with `host_names`;
probes restricted to Http/Https with timeout ≤ interval, one host sourcing
and a leading-slash path; backend pools non-empty; settings with port and
protocol checked, host assignment not doubled, draining bound 1–3600,
probe/trusted-root keys resolving; routing rules with unique priority
1–20000, listener key resolving, Basic carrying the pool+settings pair,
PathBasedRouting carrying the path map; url path maps with default targets
and paired path-rule targets; ssl_policy conflicts (disabled_protocols
against policy_name/policy_type, policy_name requiring policy_type); tags
respecting the 50/512/256 limits; map keys on every level without `.`;
names unique within each block family and gateway.

### `application_gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Gateway name. |
| `resource_group_name` | `string` | — | Resource group the gateway lives in. |
| `location` | `string` | — | Azure region. Immutable — forces replacement. |
| `sku_name` | `string` | `Standard_v2` | `Standard_v2` or `WAF_v2` (validated); tier carries the same value. WAF_v2 targets external WAF policy via `firewall_policy_id`. |
| `capacity` | `number` | `null` | Static instance count 1–125 — mutually exclusive with `autoscale_configuration` (validated). |
| `autoscale_configuration` | `object` | `null` | `{ min_capacity, max_capacity }` — min 0–100, max 2–125 optional, max > min (validated). Exactly one of capacity or this (validated). |
| `zones` | `list(string)` | `[]` | Availability zones `1`/`2`/`3`, v2-only. Changing zones forces replacement. |
| `http2_enabled` | `bool` | `null` | HTTP/2 on frontends. |
| `fips_enabled` | `bool` | `null` | FIPS-compliant cipher restrictions. |
| `firewall_policy_id` | `string` | `null` | External WAF-policy ARM ID (`azure/web-application-firewall`-created policy; out of this module). Only for WAF_v2. |
| `force_firewall_policy_association` | `bool` | `null` | Enforce the firewall policy on the gateway regardless of other posture. |
| `identity` | `object` | `null` | `{ type, identity_ids }` — user-assigned identity required for Key Vault TLS certificates (validated). |
| `gateway_ip_configurations` | `map(object)` | — | `{ name, subnet_id }` — the subnets the gateway's control plane attaches to; a dedicated subnet (no NICs, no delegation) is the Azure guidance, /27 or larger. |
| `frontend_ip_configurations` | `map(object)` | — | `{ name, subnet_id, private_ip_address, private_ip_address_allocation, public_ip_address_id }` — exactly one of public (ARM ID of a Standard/Static IP, validated) or subnet (private); Static allocation requires `private_ip_address` (validated). |
| `frontend_ports` | `map(object)` | — | `{ name, port }`. |
| `ssl_certificates` | `map(object)` | `{}` | `{ name, data, password, key_vault_secret_id }` — exactly one of data (base64 PFX, needs password) or Key Vault secret (needs `identity`, validated; enable soft delete on the vault). `key_vault_secret_id` takes the vault URI form (`https://<vault>.vault.azure.net/secrets/<name>`, versionless for rotation). |
| `trusted_root_certificates` | `map(object)` | `{}` | `{ name, data, key_vault_secret_id }` — exactly one per entry. |
| `probes` | `map(object)` | `{}` | Health probes — see the object table. |
| `backend_address_pools` | `map(object)` | — | `{ name, fqdns, ip_addresses }` — at least one of FQDNs or IPs (validated). VM/NIC/VMSS pool associations are separate resources (see Notes). |
| `backend_http_settings` | `map(object)` | — | Backend settings — see the object table. |
| `http_listeners` | `map(object)` | — | HTTP(S) listeners — see the object table. |
| `request_routing_rules` | `map(object)` | — | Routing rules — see the object table. |
| `url_path_maps` | `map(object)` | `{}` | Path-based routing — see the object table. |
| `ssl_policy` | `object` | `null` | Gateway-wide TLS posture — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the gateway. Authoritative — a change replaces the whole set. |

### `probes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Probe name — unique within the entry. |
| `protocol` | `string` | — | `Http` or `Https` only (validated) — Tcp and Tls probes belong to L4 listeners, which are out of this module. |
| `interval` | `number` | — | Seconds between probes, 1–86400 (validated). |
| `timeout` | `number` | — | Probe timeout, 1–86400 with `timeout ≤ interval` (validated). |
| `unhealthy_threshold` | `number` | — | Retries before the node flips unhealthy, 1–20 (validated). |
| `host` | `string` | `null` | Probe host — exactly one of this or `pick_host_name_from_backend_http_settings` (validated). Single-site gateways usually take `127.0.0.1` — see Notes. |
| `pick_host_name_from_backend_http_settings` | `bool` | `null` | Take the host from the attached backend settings (validated as either/or with `host`). |
| `path` | `string` | `null` | Probe URL path starting with `/` (validated). |
| `port` | `number` | `null` | Custom probe port 1–65535 (default: the backend settings port). |
| `minimum_servers` | `number` | `null` | Servers always marked healthy. |
| `match` | `object` | `null` | `{ status_code, body }` — statuses to treat as healthy and an optional body snippet. |

### `backend_http_settings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Settings name — unique within the entry. |
| `port` | `number` | — | Backend port 1–65535 (validated). |
| `protocol` | `string` | — | `Http` or `Https` (validated). |
| `cookie_based_affinity` | `string` | `Disabled` | `Enabled` or `Disabled` (validated). |
| `request_timeout` | `number` | `null` | Seconds, 1–86400 (provider default 30). |
| `path` | `string` | `null` | Prefix path for all requests. |
| `host_name` | `string` | `null` | Host header override — conflicts with `pick_host_name_from_backend_address` (validated). |
| `pick_host_name_from_backend_address` | `bool` | `null` | Take the host header from the backend's own address. |
| `affinity_cookie_name` | `string` | `null` | Custom affinity cookie name. |
| `probe_key` | `string` | `null` | Key into `probes` (validated to resolve). |
| `trusted_root_certificate_keys` | `list(string)` | `[]` | Keys into `trusted_root_certificates` (validated) — end-to-end TLS to `Https` backends wants these. |
| `connection_draining` | `object` | `null` | `{ enabled, drain_timeout_sec }` — timeout 1–3600 (validated). |

### `http_listeners` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Listener name — unique within the entry. |
| `frontend_ip_configuration_key` | `string` | — | Key into `frontend_ip_configurations` (validated). |
| `frontend_port_key` | `string` | — | Key into `frontend_ports` (validated). |
| `protocol` | `string` | — | `Http` or `Https`; Https requires `ssl_certificate_key` resolving to `ssl_certificates` (validated). |
| `host_name` | `string` | `null` | Listener host (multi-site) — conflicts with `host_names` (validated). |
| `host_names` | `list(string)` | `null` | Listener hosts with wildcard support. |
| `require_sni` | `bool` | `null` | Demand SNI for multi-site/Https listeners. |
| `ssl_certificate_key` | `string` | `null` | Key into `ssl_certificates` (validated). |
| `firewall_policy_id` | `string` | `null` | Per-listener WAF-policy ARM ID. |

### `request_routing_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within the entry. |
| `priority` | `number` | — | Evaluation order 1–20000, unique per gateway (validated) — required on v2. |
| `rule_type` | `string` | — | `Basic` (needs the backend pool+settings pair, validated) or `PathBasedRouting` (needs `url_path_map_key`, validated); redirect configurations are out of this module. |
| `http_listener_key` | `string` | — | Key into `http_listeners` (validated). |
| `backend_address_pool_key` | `string` | `null` | Key into `backend_address_pools` (validated). |
| `backend_http_settings_key` | `string` | `null` | Key into `backend_http_settings` (validated). |
| `url_path_map_key` | `string` | `null` | Key into `url_path_maps` (validated, PathBasedRouting only). |

### `url_path_maps` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Map name — unique within the entry. |
| `default_backend_address_pool_key` | `string` | — | Key into `backend_address_pools` for unmatched paths (validated). |
| `default_backend_http_settings_key` | `string` | — | Key into `backend_http_settings` for unmatched paths (validated). |
| `path_rules` | `map(object)` | — | `{ name, paths, backend_address_pool_key, backend_http_settings_key }` — non-empty paths, pool+settings pair together (both validated to resolve). |

### `ssl_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `disabled_protocols` | `string` | `null` | List like `TLSv1_0`, `TLSv1_1`, `TLSv1_2`, `TLSv1_3` — conflicts with `policy_name`/`policy_type` (validated). |
| `policy_type` | `string` | `null` | `Predefined`, `Custom` or `CustomV2` (validated); `policy_name` requires it (validated). |
| `policy_name` | `string` | `null` | Predefined policy name (e.g. `AppGwSslPolicy20170401S`) — Predefined only; the live list is Azure-documented. |
| `cipher_suites` | `list(string)` | `null` | Accepted cipher suites (Custom/CustomV2). |
| `min_protocol_version` | `string` | `null` | `TLSv1_0` … `TLSv1_3` (Custom/CustomV2). |

## Outputs

| Name | Description |
|---|---|
| `gateway_ids` | Map of gateway key => full ARM resource ID. |
| `gateway_names` | Map of gateway key => gateway name. |
| `gateway_private_ip_addresses` | Map of gateway key => list of private frontend IPs. |
| `backend_address_pool_ids` | Map of `<gateway_key>:backend_address_pools:<name>` => pool ARM ID — the value the backend association resources take. |
| `backend_http_settings_ids` | Map of `<gateway_key>:backend_http_settings:<name>` => settings ARM ID. |
| `http_listener_ids` | Map of `<gateway_key>:http_listeners:<name>` => listener ARM ID. |
| `request_routing_rule_ids` | Map of `<gateway_key>:request_routing_rules:<name>` => rule ARM ID. |
| `url_path_map_ids` | Map of `<gateway_key>:url_path_maps:<name>` => path-map ARM ID. |
| `probe_ids` | Map of `<gateway_key>:probes:<name>` => probe ARM ID. |
| `frontend_port_ids` | Map of `<gateway_key>:frontend_ports:<name>` => frontend-port ARM ID. |
| `ssl_certificate_public_cert_datas` | Map of `<gateway_key>:ssl_certificates:<name>` => public certificate data (sensitive — public certificates only, but flows out through a sensitive-attribute chain). |

## Example

```hcl
application_gateways = {
  "store-eu" = {
    name                = "appgw-store-eu-01"
    resource_group_name = "rg-store-prod"
    location            = "westeurope"

    autoscale_configuration = {
      min_capacity = 2
      max_capacity = 10
    }
    zones         = ["1", "2", "3"]
    http2_enabled = true

    identity = {
      type         = "UserAssigned"
      identity_ids = ["/subscriptions/<id>/resourceGroups/rg-store-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-appgw-eu"]
    }

    gateway_ip_configurations = {
      "primary" = {
        name      = "gw-ip"
        subnet_id = dependency.subnet.outputs.subnet_ids["appgw"]
      }
    }

    frontend_ip_configurations = {
      "public" = {
        name                 = "fip-public"
        public_ip_address_id = dependency.public_ip.outputs.public_ip_ids["edge"]
      }
      "private" = {
        name                          = "fip-private"
        subnet_id                     = dependency.subnet.outputs.subnet_ids["appgw-endpoint"]
        private_ip_address_allocation = "Dynamic"
      }
    }

    frontend_ports = {
      "https" = { name = "port-443", port = 443 }
      "http"  = { name = "port-80", port = 80 }
    }

    ssl_certificates = {
      "wildcard" = {
        name                = "store-eu-cert"
        key_vault_secret_id = "https://kv-store-eu.vault.azure.net/secrets/store-eu-cert"
      }
    }

    probes = {
      "default" = {
        name                = "probe-default"
        protocol            = "Https"
        interval            = 30
        timeout             = 15
        unhealthy_threshold = 3
        path                = "/healthz"
        pick_host_name_from_backend_http_settings = true
      }
    }

    backend_address_pools = {
      "api" = {
        name  = "pool-api"
        fqdns = ["api1.internal.example.net", "api2.internal.example.net"]
      }
    }

    backend_http_settings = {
      "api" = {
        name            = "settings-api"
        port            = 443
        protocol        = "Https"
        request_timeout = 60
        pick_host_name_from_backend_address = true
        probe_key       = "default"
        connection_draining = {
          enabled           = true
          drain_timeout_sec = 60
        }
      }
    }

    http_listeners = {
      "https" = {
        name                          = "listener-https"
        frontend_ip_configuration_key = "public"
        frontend_port_key             = "https"
        protocol                      = "Https"
        ssl_certificate_key           = "wildcard"
        require_sni                   = true
      }
      "http" = {
        name                          = "listener-http"
        frontend_ip_configuration_key = "public"
        frontend_port_key             = "http"
        protocol                      = "Http"
      }
    }

    request_routing_rules = {
      "https" = {
        name              = "rule-https"
        priority          = 100
        rule_type         = "Basic"
        http_listener_key = "https"
        backend_address_pool_key  = "api"
        backend_http_settings_key = "api"
      }
      "http" = {
        name              = "rule-http"
        priority          = 200
        rule_type         = "Basic"
        http_listener_key = "http"
        backend_address_pool_key  = "api"
        backend_http_settings_key = "api"
      }
    }
  }
}
```

## Notes

- **Dedicated subnet**: the Azure guidance is one gateway per subnet, sized
  /27 or larger, without delegations or other resources — inspect and
  validate your `azure/subnet` output before wiring
  `gateway_ip_configurations`.
- **Key Vault TLS**: certificates sourced from Key Vault reference the vault
  URI (`https://<vault>.vault.azure.net/secrets/<name>`, versionless so the
  gateway rotates alongside the secret) and need (1) a user-assigned
  identity on the gateway (validated here), (2) Key Vault get access granted
  to that identity, and (3) soft delete enabled on the vault — all
  consumer-side.
- **Set-vs-list churn**: the provider stores several nested block families
  as Sets; a one-element change shows as churn of the full family in plans.
  That is provider behaviour, not a module defect — group gateway edits in
  one apply.
- **HTTPS redirect shorthand**: the module carries no
  `redirect_configuration` blocks (out of scope) — the classic
  HTTP→HTTPS redirect is expressed with two listeners/two Basic rules
  pointing the port-80 listener at a redirect-capable setup or simply
  serving the same backends (see the example) until a later minor pass adds
  redirects.
- **Backend associations**: VM, NIC and VMSS backend associations are the
  separate `azurerm_*_application_gateway_backend_address_pool_association`
  resources — wire them consumer-side from `backend_address_pool_ids`.
- **Public IPs**: public frontend IPs are external (Standard, static) —
  produce them with the `azure/public-ip` module and pass the ARM ID;
  this module returns private IPs only.
- **Host single-site note**: `probes` with a single site conventionally use
  `host = "127.0.0.1"`; `pick_host_name_from_backend_http_settings` pairs
  the probe with each settings' host resolution instead (validated
  either/or).
- Tags are authoritative — a change replaces the whole tag set; RBAC needed
  is `Microsoft.Network/applicationGateways/write`.

## Import

```
tofu import 'azurerm_application_gateway.gateway["store-eu"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/applicationGateways/<name>"
```
