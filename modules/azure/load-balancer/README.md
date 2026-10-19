# azure/load-balancer

Map-keyed module for Azure Standard Load Balancers (v2) with the full
frontend/backend/rule surface. Each entry creates one `azurerm_lb` in the
named resource group; backend address pools, pool addresses, NIC
associations, probes, load balancing rules, NAT rules, NAT pools and
outbound rules are separate resources the module flattens from nested maps
and wires together. The Basic SKU is retired upstream — `sku` is pinned
`Standard` and only the tier (`Regional`/`Global`) varies.

## Destroy semantics (read before using)

- Removing a load balancer key destroys the load balancer and every child
  created from its nested maps — pools, probes and rules included. The
  frontends' public IPs from `public_ips` are destroyed only when their
  keys are removed from that variable.
- Azure does not allow the complete removal of all previously attached
  frontend IP configurations; the module requires at least one
  `frontend_ip_configuration` per entry (validated), and removing them all
  anyway forces a replacement (destroy/create) of the load balancer.
- Renaming any resource (changing its `name`) replaces it.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `public_ips` | `map(object)` | `{}` | In-module public IPs for frontends, keyed by an arbitrary unique ID — see the object table. |
| `load_balancers` | `map(object)` | — | Map of load balancers keyed by an arbitrary unique ID — see the object table. |

Plan-time validation: map keys on every level without `.`; load balancer
names unique per resource group case-insensitively; `name`/
`resource_group_name`/`location` non-empty; `sku_tier` `Regional`/`Global`;
frontend zones `1`/`2`/`3`; at least one frontend per load balancer;
frontends either public (exactly one of `public_ip_key` or
`public_ip_address_id`) or private (`subnet_id`), with `public_ip_prefix_id`
restricted to public frontends and Static allocation requiring
`private_ip_address`; backend pool `synchronous_mode` required with
`virtual_network_id` and pool addresses in exactly one form; probe
protocol/path/port bounds; rule, NAT rule, NAT pool and outbound rule key
references resolving within the same entry, protocol and port ranges;
names unique within each family per load balancer; tags respecting the
50/512/256 limits.

### `public_ips` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Public IP name — unique within its resource group (validated). |
| `resource_group_name` | `string` | — | Resource group the IP lives in. |
| `location` | `string` | — | Azure region. |
| `availability_zone` | `string` | `null` | Availability zone: `1`, `2` or `3` (validated), or unset for no zone pinning. |
| `domain_name_label` | `string` | `null` | DNS label — the IP gets `<label>.<region>.cloudapp.azure.com`. |
| `tags` | `map(string)` | `{}` | Tags on the public IP. |

The IPs are created Standard/Static/IPv4 — the only shape a Standard load
balancer frontend accepts. Existing IPs are used by full ARM resource ID
(`public_ip_address_id`) instead.

### `load_balancers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Load balancer name — unique within its resource group (validated). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the load balancer lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. For `sku_tier = "Global"` this is the home region (see Notes). Immutable — changing it forces replacement. |
| `sku_tier` | `string` | `Regional` | `Regional` or `Global` (case-sensitive, validated) — Global is the cross-region tier. Changing it forces replacement. |
| `edge_zone` | `string` | `null` | Edge zone for extended-capacity deployments (e.g. `westeuropeaz`-style zone IDs). Changing it forces replacement. |
| `frontend_ip_configurations` | `map(object)` | — | Frontend IPs keyed by an arbitrary unique ID — see the object table. At least one required (validated). |
| `backend_address_pools` | `map(object)` | — | Backend address pools keyed by an arbitrary unique ID — see the object table. |
| `probes` | `map(object)` | `{}` | Health probes keyed by an arbitrary unique ID — see the object table. |
| `rules` | `map(object)` | `{}` | Load balancing rules keyed by an arbitrary unique ID — see the object table. |
| `nat_rules` | `map(object)` | `{}` | Inbound NAT rules keyed by an arbitrary unique ID — see the object table. |
| `nat_pools` | `map(object)` | `{}` | Inbound NAT pools keyed by an arbitrary unique ID — see the object table. |
| `outbound_rules` | `map(object)` | `{}` | Outbound rules keyed by an arbitrary unique ID — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the load balancer. The tag set is authoritative — see Notes. |

### `frontend_ip_configurations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Frontend name — unique within the load balancer (validated). |
| `public_ip_key` | `string` | `null` | Key of an in-module `public_ips` entry — exactly one of this or `public_ip_address_id` on a public frontend (validated). |
| `public_ip_address_id` | `string` | `null` | Full ARM resource ID of an existing public IP (validated shape). |
| `public_ip_prefix_id` | `string` | `null` | Full ARM resource ID of a public IP prefix — only valid on a public frontend (validated); Azure takes prefixes on outbound-rule frontends. |
| `subnet_id` | `string` | `null` | Subnet ARM ID for a private frontend — public and private references are mutually exclusive (validated). |
| `private_ip_address` | `string` | `null` | Static private IP from the subnet's range — required when `private_ip_address_allocation` is `Static` (validated). |
| `private_ip_address_allocation` | `string` | `Dynamic` | `Dynamic` or `Static`. |
| `private_ip_address_version` | `string` | `IPv4` | `IPv4` or `IPv6`. |
| `zones` | `list(string)` | `[]` | Availability zones (`1`/`2`/`3`, validated) — Standard SKU, select regions. Removing the zones from an existing frontend forces replacement. |

### `backend_address_pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Pool name — unique within the load balancer (validated). |
| `virtual_network_id` | `string` | `null` | Virtual network ARM ID — required with `synchronous_mode` (validated); used for cross-region backends attached by virtual network. |
| `synchronous_mode` | `string` | `null` | `Automatic` or `Manual` (case-sensitive, validated) — required when `virtual_network_id` is set. |
| `addresses` | `map(object)` | `{}` | IP-address members of the pool keyed by an arbitrary unique ID — see the object table. |
| `nic_associations` | `map(object)` | `{}` | NIC members of the pool keyed by an arbitrary unique ID — see the object table. |

### `backend_address_pools.addresses` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Address name — unique within its pool (validated). |
| `ip_address` | `string` | `null` | Backend private IP — regional form sets this together with `virtual_network_id`. |
| `virtual_network_id` | `string` | `null` | Virtual network the `ip_address` belongs to (validated pair). |
| `backend_address_ip_configuration_id` | `string` | `null` | Full ARM resource ID of a regional load balancer's frontend IP configuration — the cross-region form; exclusive with the `ip_address` pair (validated). |

### `backend_address_pools.nic_associations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network_interface_id` | `string` | — | NIC ARM ID to attach to the pool. |
| `ip_configuration_name` | `string` | — | Name of the NIC's IP configuration used as the backend address. |

### `probes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Probe name — unique within the load balancer (validated). |
| `protocol` | `string` | — | `Http`, `Https` or `Tcp` (case-sensitive, validated). |
| `port` | `number` | — | Probe port, 1–65535 (validated). |
| `request_path` | `string` | `null` | URI for HTTP(S) probes — required for `Http`/`Https`, starting with `/`; not allowed on `Tcp` (validated). |
| `interval_in_seconds` | `number` | `null` | Seconds between probes — at least 5 (validated), default 15. |
| `number_of_probes` | `number` | `null` | Consecutive failures before a backend is marked down — default 2; number of probes × interval must be at least 10 seconds (validated). |
| `probe_threshold` | `number` | `null` | Successful probes before a backend is marked up, 1–100 (validated). |
| `no_healthy_backends_behavior` | `string` | `null` | `AllProbedDown` or `AllProbedUp` (case-sensitive, validated) — what happens when no backend is healthy. |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within the load balancer (validated). |
| `frontend_ip_configuration_key` | `string` | — | Sibling `frontend_ip_configurations` key (validated). |
| `backend_address_pool_key` | `string` | — | Sibling `backend_address_pools` key (validated). |
| `probe_key` | `string` | `null` | Sibling `probes` key (validated). |
| `protocol` | `string` | — | `Tcp`, `Udp` or `All` (case-sensitive, validated). |
| `frontend_port` | `number` | — | 0–65534 (validated). |
| `backend_port` | `number` | — | 0–65535 (validated). |
| `load_distribution` | `string` | `Default` | `Default`, `SourceIP` or `SourceIPProtocol` (case-sensitive, validated) — session persistence. |
| `floating_ip_enabled` | `bool` | `null` | Direct-server-return mode (the frontend port equals the backend port). |
| `disable_outbound_snat` | `bool` | `null` | Stop sourcing the backends' outbound SNAT from this rule's frontend IP — set it when a dedicated outbound rule fronts the same backend pool instead. |
| `tcp_reset_enabled` | `bool` | `null` | Send TCP RST on idle timeout. |
| `idle_timeout_in_minutes` | `number` | `null` | 4–100 (validated). |

### `nat_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within the load balancer (validated). |
| `frontend_ip_configuration_key` | `string` | — | Sibling `frontend_ip_configurations` key (validated). |
| `protocol` | `string` | — | `Tcp`, `Udp` or `All` (case-sensitive, validated). |
| `backend_port` | `number` | — | 1–65535 (validated). |
| `frontend_port` | `number` | `null` | Single-port form (VM/NIC backends): 1–65534 — exclusive with the range form (validated). |
| `frontend_port_start` | `number` | `null` | NAT-rule-v2 form (VMSS backends): range start, 1–65534 — set together with `frontend_port_end` and `backend_address_pool_key` (validated). |
| `frontend_port_end` | `number` | `null` | Range end, 1–65534, ≥ start (validated). |
| `backend_address_pool_key` | `string` | `null` | Sibling `backend_address_pools` key the v2 form ports map to (validated). |
| `floating_ip_enabled` | `bool` | `null` | Floating IP on the NAT rule. |
| `tcp_reset_enabled` | `bool` | `null` | Send TCP RST on idle timeout. |
| `idle_timeout_in_minutes` | `number` | `null` | 4–30 (validated). |

### `nat_pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Pool name — unique within the load balancer (validated). |
| `frontend_ip_configuration_key` | `string` | — | Sibling `frontend_ip_configurations` key (validated). |
| `protocol` | `string` | — | `Tcp`, `Udp` or `All` (case-sensitive, validated). |
| `frontend_port_start` | `number` | — | 1–65534 (validated). |
| `frontend_port_end` | `number` | — | 1–65534, ≥ start (validated). |
| `backend_port` | `number` | — | 1–65535 (validated). |
| `floating_ip_enabled` | `bool` | `null` | Floating IP on the pool. |
| `tcp_reset_enabled` | `bool` | `null` | Send TCP RST on idle timeout. |
| `idle_timeout_in_minutes` | `number` | `null` | 4–30 (validated). |

### `outbound_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within the load balancer (validated). |
| `backend_address_pool_key` | `string` | — | Sibling `backend_address_pools` key (validated) — the pool whose backends get outbound SNAT. |
| `frontend_ip_configuration_keys` | `list(string)` | — | Non-empty list of sibling `frontend_ip_configurations` keys (validated) — the public IPs outbound traffic sources from. |
| `protocol` | `string` | — | `Tcp`, `Udp` or `All` (case-sensitive, validated). |
| `allocated_outbound_ports` | `number` | `null` | Outbound ports per backend — default 1024. |
| `idle_timeout_in_minutes` | `number` | `null` | Idle timeout for outbound flows. |
| `tcp_reset_enabled` | `bool` | `null` | Send TCP RST on idle timeout — only applies when `protocol` is `Tcp` (see Notes). |

## Outputs

| Name | Description |
|---|---|
| `load_balancer_ids` | Map of load balancer key => full ARM resource ID. |
| `load_balancer_names` | Map of load balancer key => load balancer name. |
| `load_balancer_private_ip_addresses` | Map of load balancer key => list of private frontend IP addresses (empty for public-only). |
| `frontend_ip_configuration_ids` | Map of `<lb_key>.<frontend_key>` => frontend IP configuration ARM ID (`<lb_id>/frontendIPConfigurations/<name>`). |
| `public_ip_ids` | Map of public_ip key => public IP ARM ID — in-module `public_ips` only. |
| `backend_address_pool_ids` | Map of `<lb_key>.<pool_key>` => backend address pool ARM ID. |
| `backend_address_pool_address_ids` | Map of `<lb_key>.<pool_key>.<address_key>` => pool address ARM ID. |
| `nic_backend_address_pool_association_ids` | Map of `<lb_key>.<pool_key>.<assoc_key>` => association Terraform ID (composite — see Import). |
| `probe_ids` | Map of `<lb_key>.<probe_key>` => probe ARM ID. |
| `rule_ids` | Map of `<lb_key>.<rule_key>` => load balancing rule ARM ID. |
| `nat_rule_ids` | Map of `<lb_key>.<nat_rule_key>` => inbound NAT rule ARM ID. |
| `nat_pool_ids` | Map of `<lb_key>.<nat_pool_key>` => inbound NAT pool ARM ID. |
| `outbound_rule_ids` | Map of `<lb_key>.<outbound_rule_key>` => outbound rule ARM ID. |

## Example

```hcl
public_ips = {
  "edge" = {
    name                = "pip-lb-web-prod"
    resource_group_name = "rg-web-prod"
    location            = "westeurope"
    availability_zone   = "1"
    domain_name_label   = "web-prod"
  }
}

load_balancers = {
  "web" = {
    name                = "lb-web-prod"
    resource_group_name = "rg-web-prod"
    location            = "westeurope"

    frontend_ip_configurations = {
      "public" = {
        name          = "web-frontend-public"
        public_ip_key = "edge"
        zones         = ["1", "2", "3"]
      }
      "private" = {
        name                          = "web-frontend-internal"
        subnet_id                     = dependency.subnet.outputs.subnet_ids["web"]
        private_ip_address            = "10.20.1.10"
        private_ip_address_allocation = "Static"
      }
    }

    backend_address_pools = {
      "vms" = {
        name = "web-backend-vms"
        addresses = {
          "vm1" = {
            name               = "vm1"
            ip_address         = "10.20.1.21"
            virtual_network_id = dependency.vnet.outputs.virtual_network_ids["hub"]
          }
        }
        nic_associations = {
          "vm2" = {
            network_interface_id  = dependency.nic.outputs.network_interface_ids["vm2"]
            ip_configuration_name = "ipconfig1"
          }
        }
      }
    }

    probes = {
      "http" = {
        name                = "probe-http"
        protocol            = "Http"
        port                = 8080
        request_path        = "/health"
        interval_in_seconds = 15
        number_of_probes    = 2
      }
    }

    rules = {
      "http" = {
        name                          = "rule-http"
        frontend_ip_configuration_key = "public"
        backend_address_pool_key      = "vms"
        probe_key                     = "http"
        protocol                      = "Tcp"
        frontend_port                 = 80
        backend_port                  = 8080
      }
    }

    nat_rules = {
      "ssh" = {
        name                          = "nat-ssh"
        frontend_ip_configuration_key = "public"
        protocol                      = "Tcp"
        frontend_port                 = 2201
        backend_port                  = 22
      }
    }

    outbound_rules = {
      "out" = {
        name                           = "outbound-all"
        backend_address_pool_key       = "vms"
        frontend_ip_configuration_keys = ["public"]
        protocol                       = "All"
      }
    }

    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- **Inbound NAT pools are Inbound NAT v1** — Azure retires them on
  2027-09-30, and they cannot be used with virtual machines (only scale
  sets). Prefer `nat_rules` in the v2 form (`frontend_port_start`/
  `frontend_port_end` + `backend_address_pool_key`) for VMSS backends; the
  pool input exists for legacy topologies.
- **Cross-region (Global tier)**: the load balancer lives in a supported
  home region — `location` stays a real region (Azure publishes the home
  region list). The public IP frontends must be Global-tier, and backends
  attach as regional load balancer frontends via
  `backend_address_ip_configuration_id` rather than VM IPs.
- `outbound_rules.tcp_reset_enabled` only applies when `protocol` is `Tcp`
  — setting it on `Udp`/`All` outbound rules is silently ignored by the
  API.
- `disable_outbound_snat` pairs with the `outbound_rules` family — when an
  outbound rule sources from a different frontend, the load balancing rules
  over the same backend pool set it so backends' outbound traffic sources
  from the outbound rule's frontend.
- Probes: `number_of_probes` × `interval_in_seconds` must reach 10 seconds
  (validated); HTTP(S) probes need a `request_path` starting with `/`,
  TCP probes reject one (validated).
- Tags are authoritative — a change replaces the whole tag set; RBAC
  needed is `Microsoft.Network/loadBalancers/write` plus the children
  (`backendAddressPools`, `probes`, `loadBalancingRules`, `inboundNatRules`,
  `inboundNatPools`, `outboundRules`) on scope.
- Not exposed, deliberately (pass-through candidates for a later minor
  release): `tunnel_interface` blocks on backend pools and
  `gateway_load_balancer_frontend_ip_configuration_id` on frontends (both
  Gateway-LB chaining, which needs the service-team-registered
  `Microsoft.Network/AllowGatewayLoadBalancer` feature), diagnostic
  settings, and the second backend pool of Gateway-SKU rules.

## Import

Load balancers import by ARM ID; children by theirs (the public IP by its
ARM ID):

```
tofu import 'azurerm_lb.lb["web"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/loadBalancers/<name>"
tofu import 'azurerm_public_ip.pip["edge"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>"
tofu import 'azurerm_lb_backend_address_pool.pool["web.vms"]' "<lb_id>/backendAddressPools/<pool-name>"
tofu import 'azurerm_lb_backend_address_pool_address.address["web.vms.vm1"]' "<pool_id>/addresses/<address-name>"
tofu import 'azurerm_network_interface_backend_address_pool_association.nic["web.vms.vm2"]' "<nic-id>/ipConfigurations/<ip-config-name>|<pool-id>"
tofu import 'azurerm_lb_probe.probe["web.http"]' "<lb_id>/probes/<probe-name>"
tofu import 'azurerm_lb_rule.rule["web.http"]' "<lb_id>/loadBalancingRules/<rule-name>"
tofu import 'azurerm_lb_nat_rule.nat_rule["web.ssh"]' "<lb_id>/inboundNatRules/<rule-name>"
tofu import 'azurerm_lb_nat_pool.nat_pool["web.ssh-pool"]' "<lb_id>/inboundNatPools/<pool-name>"
tofu import 'azurerm_lb_outbound_rule.outbound_rule["web.out"]' "<lb_id>/outboundRules/<rule-name>"
```

The NIC-association import ID is a Terraform-specific composite of the
NIC's IP configuration ID and the backend pool ID joined by `|` — it is
not an ARM resource ID.
