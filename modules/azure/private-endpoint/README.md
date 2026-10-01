# azure/private-endpoint

Map-keyed module for Azure private endpoints. Each entry creates one
`azurerm_private_endpoint` with its service connection, optionally a DNS zone
group and static IP configurations. Private DNS zones and their virtual
network links can be created alongside the endpoints via `private_dns_zones`,
or supplied zone IDs from the `azure/dns-zone` module — both paths work.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `private_endpoints` | `map(object)` | — | Map of private endpoints keyed by an arbitrary unique ID. |
| `private_dns_zones` | `map(object)` | `{}` | Optional map of private DNS zones keyed by an arbitrary unique ID. Zone map keys must not contain `.` — they are composed into link output keys. |

Plan-time validation: names/resource groups non-empty, `subnet_id` and all ID
references are ARM-format, exactly one of
`private_connection_resource_id`/`private_connection_resource_alias`,
`request_message` only on manual connections and ≤140 characters, tag limits,
zone names are valid DNS names and unique per resource group, link names
unique within their zone.

### `private_endpoints` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Private endpoint name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the endpoint is created in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region, e.g. `westeurope`. Immutable — changing it forces replacement. |
| `subnet_id` | `string` | — | Subnet to allocate the private IP from (typically `dependency.subnet.outputs.subnet_ids["endpoints"]` with the `azure/subnet` module). Immutable — changing it forces replacement. |
| `custom_network_interface_name` | `string` | `null` | Custom name for the endpoint's NIC. Immutable — changing it forces replacement. |
| `edge_zone` | `string` | `null` | Extended zone (formerly edge zone) identifier. Immutable — changing it forces replacement. |
| `private_service_connection` | `object` | — | See below — every attribute forces replacement when changed. |
| `private_dns_zone_group` | `object` | `null` | `{ name, private_dns_zone_ids }` — attaches zones for automatic DNS record management. `name` defaults to `default`. Omit for BYO-DNS setups. |
| `ip_configurations` | `map(object)` | `{}` | Static IP configurations keyed by an arbitrary identifier: `{ name, private_ip_address, subresource_name, member_name }`. |
| `tags` | `map(string)` | `{}` | Tags. |

### `private_service_connection` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name of the private service connection. |
| `is_manual_connection` | `bool` | — | `true` when the endpoint needs manual approval from the resource owner (or when connecting via alias); `false` for automatic, RBAC-approved connections. |
| `private_connection_resource_id` | `string` | `null` | ARM ID of the remote resource, e.g. the `storage_account_ids` output of `azure/storage-account` or `key_vault_ids` of `azure/key-vault`. Exactly one of this and `private_connection_resource_alias` is required. For web app or function app slots, use the parent web app's ID. |
| `private_connection_resource_alias` | `string` | `null` | Service alias of the remote resource, when connecting to a resource you do not own. |
| `subresource_names` | `list(string)` | `[]` | Subresources (group IDs) targeted, e.g. `["blob"]`, `["vault"]`, `["postgresqlServer"]`. Some resources, notably storage accounts, support a single subresource per endpoint. See Azure's [private-link documentation](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource) for the per-service values. |
| `request_message` | `string` | `null` | Message for the remote resource's owner, only valid on manual connections. Set one for alias-based connections so approval is actionable. Provider limit is 140 characters (SQL allows 128). |

### `private_dns_zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Zone name, lowercase DNS name, e.g. `privatelink.blob.core.windows.net`. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group. |
| `soa_record` | `object` | `null` | `{ email, expire_time, minimum_ttl, refresh_time, retry_time, ttl }` — set to tune the zone's defaults. |
| `virtual_network_links` | `map(object)` | `{}` | Links into vnets keyed by an arbitrary ID: `{ name, virtual_network_id, registration_enabled, resolution_policy, tags }`. `resolution_policy` accepts `Default` or `NxDomainRedirect` (newer than `azure/dns-zone`, which cannot set it today). |
| `tags` | `map(string)` | `{}` | Tags. |

## Outputs

| Name | Description |
|---|---|
| `private_endpoint_ids` | Map of key => full ARM resource ID. |
| `private_endpoint_names` | Map of key => endpoint name. |
| `private_endpoint_network_interface_ids` | Map of key => ARM ID of the attached NIC. |
| `private_endpoint_custom_dns_configs` | Map of key => `{ fqdn, ip_addresses }` — populated when no zone group is attached. |
| `private_ip_addresses` | Map of key => private IP assigned to the endpoint. |
| `private_dns_zone_ids` | Map of zone key => zone ARM ID (module-created zones only). |
| `private_dns_zone_names` | Map of zone key => zone name. |
| `virtual_network_link_ids` | Map of `<zone_key>.<link_key>` => link ARM ID. |

## Example

Private endpoint to a storage account blob subresource with module-managed DNS:

```hcl
private_endpoints = {
  "storage-blob" = {
    name                = "pe-storage-blob"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    subnet_id           = dependency.subnet.outputs.subnet_ids["endpoints"]

    private_service_connection = {
      name                           = "storage-blob"
      is_manual_connection           = false
      private_connection_resource_id = dependency.storage.outputs.storage_account_ids["platform"]
      subresource_names = [
        "blob",
      ]
    }

    private_dns_zone_group = {
      private_dns_zone_ids = [
        module.private_endpoint.private_dns_zone_ids["storage-blob"],
      ]
    }
  }
}

private_dns_zones = {
  "storage-blob" = {
    name                = "privatelink.blob.core.windows.net"
    resource_group_name = "rg-platform-prod"
    virtual_network_links = {
      "platform" = {
        name               = "link-platform-prod"
        virtual_network_id = dependency.vnet.outputs.virtual_network_ids["platform"]
      }
    }
  }
}
```

## Notes

- **DNS zone groups vs BYO zones.** With a `private_dns_zone_group`, the
  endpoint manages A records in the zone automatically; `custom_dns_configs`
  then resolves empty. Without one, resolve via the `custom_dns_configs`
  output. Zones can come from `azure/dns-zone` (pass its `dns_zone_ids`
  output) or from this module's `private_dns_zones` — both are ID pass-through.
- `private_dns_zone_group` name is required by the provider; the module
  resolves the optional input to `default` and applies whatever ID(s) are
  passed.
- `subresource_names` values are service-specific and drift with Azure — the
  module validates shape only; pick values from the Azure private-link docs
  table linked in the input table above.
- `ip_configurations.member_name` falls back to `subresource_name` in the
  provider today and becomes required in the provider's next major — set it
  explicitly to be prepared for a floor bump.
- Storage accounts (and other single-subresource services) need one endpoint
  per subresource, e.g. separate entries for `blob` and `file`.
- The NIC's ARM ID (`private_endpoint_network_interface_ids`) is the object
  NSGs evaluate against for private endpoint traffic; pair with
  `private_endpoint_network_policies = Enabled` on the subnet when using
  `azure/subnet` + NSG enforcement.
- Manual connections (`is_manual_connection = true`) create the endpoint in a
  pending state until approved remotely; `private_ip_addresses` still resolves.
- The caller needs `Microsoft.Network/privateEndpoints/write` and delete, plus
  `read` on the remote service's `.../providers/Microsoft.Network/privateEndpoints`
  linking permissions (service-specific, e.g. storage's
  `.../joinPrivateEndpointAction`).

## Import

```shell
tofu import 'azurerm_private_endpoint.endpoint["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateEndpoints/<name>"
tofu import 'azurerm_private_dns_zone.private_dns_zone["<zone_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<name>"
tofu import 'azurerm_private_dns_zone_virtual_network_link.link["<zone_key>.<link_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<name>/virtualNetworkLinks/<linkName>"
```
