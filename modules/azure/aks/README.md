# azure/aks

Map-keyed module for Azure Kubernetes Service clusters. Each entry creates one
`azurerm_kubernetes_cluster`; additional node pools go in the `node_pools`
variable and bind to a cluster via its `cluster_key`, producing composite
resource keys of the form `<cluster_key>.<pool_key>`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | — | Map of clusters keyed by an arbitrary unique ID. Map keys must not contain `.` — they are composed into node pool output keys. |
| `node_pools` | `map(object)` | `{}` | Additional node pools keyed by an arbitrary unique ID (no `.`), each with the `cluster_key` it attaches to. |

Plan-time validation covers cluster and pool name formats, exactly one of
`dns_prefix`/`dns_prefix_private_cluster`, exactly one of
`identity`/`service_principal`, autoscaler min/max rules, the network plugin /
policy / data plane / outbound-type exclusivity matrix, load balancer and NAT
gateway profile rules, OIDC/workload identity pairing, maintenance window
frequency and 4–24h duration bounds, SKU/Self-plan enums, cost-analysis SKU
gating, private DNS zone ID shapes, and tag limits.

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cluster name, ≤63 chars. Immutable. |
| `location` | `string` | — | Azure region, e.g. `westeurope`. Immutable. |
| `resource_group_name` | `string` | — | Cluster's resource group. Immutable. |
| `dns_prefix` | `string` | `null` | DNS prefix for public clusters (≤54 chars). Exactly one of this and `dns_prefix_private_cluster`. Immutable. |
| `dns_prefix_private_cluster` | `string` | `null` | DNS prefix for private clusters. Immutable. |
| `kubernetes_version` | `string` | `null` | Pinned version or minor alias (`1.31`); omitted picks the latest recommended version at creation time. |
| `sku_tier` | `string` | `Free` | `Free`, `Standard` or `Premium`. `Standard`/`Premium` gate uptime SLA and some features (e.g. cost analysis). |
| `support_plan` | `string` | `KubernetesOfficial` | `KubernetesOfficial` or `AKSLongTermSupport`. |
| `node_provisioning_profile` | `object` | `Manual`/`Auto` | `{ mode, default_node_pools }` — the provider requires this block; the module renders it with `mode = Manual` and `default_node_pools = Auto` when unset. `mode` must be `Auto` or `Manual`; `default_node_pools` `Auto` or `None`. |
| `identity` | `object` | `null` | `{ type, identity_ids }` — `SystemAssigned` or `UserAssigned` (requires exactly one `identity_ids`; pair with `azure/managed-identity`). Required unless `service_principal` is set. |
| `service_principal` | `object` | `null` | `{ client_id, client_secret }` — legacy auth, deprecated by Azure in favour of `identity`. |
| `default_node_pool` | `object` | — | See below. Required. |
| `network_profile` | `object` | `null` | See below. Omitted means `kubenet` with defaults. Immutable — changing it forces cluster replacement (except kubenet→azure upgrade). |
| `private_cluster_enabled` | `bool` | `false` | API server only on private IPs. Immutable. |
| `private_dns_zone_id` | `string` | `null` | For private clusters: `System`, `None` or an ARM private DNS zone ID (from `azure/dns-zone` or `azure/private-endpoint`). Immutable. |
| `private_cluster_public_fqdn_enabled` | `bool` | `false` | Public FQDN addition on private clusters. |
| `oidc_issuer_enabled` | `bool` | `null` | OIDC issuer, defaults to `true` at the API. **One-way door:** disabling it later forces a new cluster. |
| `workload_identity_enabled` | `bool` | `false` | Azure AD workload identity (requires the OIDC issuer enabled). |
| `role_based_access_control_enabled` | `bool` | `true` | Kubernetes RBAC. Immutable. |
| `local_account_disabled` | `bool` | `null` | Disables static local accounts — recommend with Azure AD RBAC integration; requires RBAC and AAD integration when `true`. |
| `azure_active_directory_role_based_access_control` | `object` | `null` | `{ tenant_id, admin_group_object_ids, azure_rbac_enabled }` — managed Azure AD integration. |
| `api_server_access_profile` | `object` | `null` | `{ authorized_ip_ranges, subnet_id, virtual_network_integration_enabled }` — restrict or integrate the API server endpoint. |
| `auto_scaler_profile` | `object` | `null` | Cluster-autoscaler tuning — expander, scan intervals, scale-down delays/utilization, unready thresholds, DaemonSet eviction variants, local-storage/system-pods skipping. |
| `maintenance_window` | `object` | `null` | `{ allowed, not_allowed }` — plain plan/manual window: `allowed` map of `{ day, hours }` (0–23), `not_allowed` map of `{ start, end }` RFC3339 spans. |
| `maintenance_window_auto_upgrade` | `object` | `null` | `{ frequency, interval, duration, day_of_week, day_of_month, week_index, start_time, utc_offset, start_date, not_allowed }` — required keys: `frequency` (Daily/Weekly/AbsoluteMonthly/RelativeMonthly), `interval`, `duration` 4–24h. |
| `maintenance_window_node_os` | `object` | `null` | Same shape as `maintenance_window_auto_upgrade`, for node OS upgrades. |
| `microsoft_defender` | `object` | `null` | `{ log_analytics_workspace_id }` — Defender for containers. |
| `monitor_metrics` | `object` | `null` | `{ annotations_allowed, labels_allowed }` — managed Prometheus metrics scrape config. |
| `key_management_service` | `object` | `null` | `{ key_vault_key_id, key_vault_network_access }` — etcd CMK encryption (pair with `azure/key-vault`). |
| `key_vault_secrets_provider` | `object` | `null` | `{ secret_rotation_enabled, secret_rotation_interval }` — CSI secrets store rotation. |
| `azure_policy_enabled` / `cost_analysis_enabled` / `image_cleaner_enabled` / `image_cleaner_interval_hours` | `bool`/`number` | `null` | Feature switches (cost analysis requires Standard/Premium tier). |
| `disk_encryption_set_id` / `node_resource_group` / `edge_zone` | `string` | `null` | CMK for OS disks, dedicated node RG name, extended zone identifier. Immutable where noted by the provider. |
| `automatic_upgrade_channel` / `node_os_upgrade_channel` | `string` | `null` | `patch`/`rapid`/`node-image`/`stable` and `Unmanaged`/`SecurityPatch`/`NodeImage`/`None`. `automatic_upgrade_channel = "node-image"` requires `node_os_upgrade_channel = "NodeImage"`. |
| `run_command_enabled` | `bool` | `null` | Run command feature (`true` default at the API). |
| `tags` | `map(string)` | `{}` | Tags. |

### `clusters.default_node_pool` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | System node pool name (lowercase, ≤12 chars). |
| `vm_size` | `string` | `null` | VM SKU, e.g. `Standard_D2_v2`. Resizes require `temporary_name_for_rotation`. |
| `node_count` / `auto_scaling_enabled` / `min_count` / `max_count` | | `null`/`false` | Autoscaling: on ⇒ min/max required, off ⇒ min/max must be null. min/max 1–1000. |
| `max_pods`, `os_disk_size_gb`, `os_disk_type` (`Ephemeral`/`Managed`), `os_sku` (no `os_type` on the default pool — the provider takes the pool's OS from `os_sku`), `vnet_subnet_id`, `pod_subnet_id`, `zones`, `node_labels`, `only_critical_addons_enabled`, `ultra_ssd_enabled`, `fips_enabled`, `host_encryption_enabled`, `node_public_ip_enabled`, `scale_down_mode`, `temporary_name_for_rotation`, `upgrade_settings` (`max_surge` required, `drain_timeout_in_minutes`, `node_soak_duration_in_minutes`), `tags` | | | Linear agent-pool surface — attribute names follow the provider; changes to most physical properties require `temporary_name_for_rotation` (see Notes). |

### `node_pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_key` | `string` | — | Key of the cluster this pool attaches to — must exist in `clusters`. |
| `name` | `string` | — | Pool name: lowercase, 1–12 chars starting with a letter, alphanumeric with internal hyphens; ≤6 chars for Windows pools. Immutable. |
| `vm_size` | `string` | — | VM SKU. Required. |
| `mode` / `os_type` / `os_sku` | `string` | `User`/`Linux` | `System` or `User`; `Linux` or `Windows`. |
| scaling, disks, subnets, zones, labels, taints, `priority` (`Regular`/`Spot`), `spot_max_price`, `eviction_policy`, `scale_down_mode`, `orchestrator_version`, `fips_enabled`, `host_encryption_enabled`, `node_public_ip_enabled`, `ultra_ssd_enabled`, `kubelet_disk_type`, `temporary_name_for_rotation`, `upgrade_settings`, `tags` | | | Same surface as the default pool; spot settings only on `priority = Spot` pools. |

## Outputs

| Name | Description |
|---|---|
| `cluster_ids` | Map of cluster key => full ARM resource ID. |
| `cluster_names` | Map of cluster key => name. |
| `cluster_fqdns` | Map of cluster key => API server FQDN. |
| `cluster_private_fqdns` | Map of cluster key => private FQDN (private clusters). |
| `cluster_kube_config_raw` | Map of cluster key => kube config YAML. Sensitive. |
| `cluster_kube_admin_config_raw` | Map of cluster key => admin kube config YAML. Sensitive. |
| `cluster_client_certificates` | Map of cluster key => client certificate. Sensitive. |
| `cluster_oidc_issuer_urls` | Map of cluster key => OIDC issuer URL — wire federated credentials onto user-assigned identities with this. |
| `cluster_identity_principal_ids` / `cluster_identity_object_ids` | Map of cluster key => identity principal/object ID — feed role assignments. |
| `cluster_kubelet_identities` | Map of cluster key => `{ client_id, object_id, user_assigned_identity_id }`. |
| `node_pool_ids` / `node_pool_names` | Map of `<cluster_key>.<pool_key>` => node pool ARM ID / name. |

## Example

```hcl
clusters = {
  "platform" = {
    name                = "aks-platform-prod"
    location            = "westeurope"
    resource_group_name = "rg-platform-prod"
    dns_prefix          = "aks-platform-prod"

    identity = {
      type = "SystemAssigned"
    }

    default_node_pool = {
      name    = "general"
      vm_size = "Standard_D2_v2"
      auto_scaling_enabled = true
      min_count = 1
      max_count = 3
      vnet_subnet_id = dependency.subnet.outputs.subnet_ids["aks"]
    }

    network_profile = {
      network_plugin      = "azure"
      network_plugin_mode = "overlay"
      network_data_plane  = "cilium"
    }

    private_cluster_enabled     = true
    private_dns_zone_id         = "System"
    oidc_issuer_enabled         = true
    workload_identity_enabled   = true
    local_account_disabled      = true
    azure_active_directory_role_based_access_control = {
      admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
      azure_rbac_enabled     = true
    }
  }
}

node_pools = {
  "platform" = {
    cluster_key = "platform"
    name        = "apps"
    vm_size     = "Standard_D4_v2"
    vnet_subnet_id = dependency.subnet.outputs.subnet_ids["aks"]
    auto_scaling_enabled = true
    min_count = 0
    max_count = 10
  }
  "platform-batch" = {
    cluster_key = "platform"
    name        = "batch"
    vm_size     = "Standard_F4s_v2"
    priority    = "Spot"
    eviction_policy = "Delete"
  }
}
```

## Notes

- **Provider floor.** Verified against azurerm 5.7.0 (latest stable at the time
  of writing) — the required `node_provisioning_profile` block and the 3.x→4.x
  `enable_*` → `*_enabled` renames mean older provider releases fail
  validation. Use a recent-or-latest azurerm; AKS moves fast and the provider
  tracks it.
- **Destroy semantics.** Destroying the cluster destroys its node pools (there
  is no ordering trick); pools outlive nothing. Some attribute changes are
  only possible by cycling the default node pool — set
  `temporary_name_for_rotation` (a collision-free pool name) when changing
  `vm_size`, disks, `max_pods`, subnets, zones, encryption flags, etc. — a
  rotation with no cordon/drain, so pods on the old pool get disrupted.
- **One-way doors.** `oidc_issuer_enabled` cannot be disabled once enabled —
  toggling it off forces a new cluster. `identity` migrates from
  `service_principal` forward but not back cheaply.
- `api_server_access_profile.subnet_id` (virtual network integration) and
  `authorized_ip_ranges` are alternative endpoint models — the API rejects
  IP ranges on vnet-integrated API servers.
- Out-of-scope here: add-on integrations (Container Insights/OMS Agent,
  Application Gateway ingress, Service Mesh, HTTP proxy config), and the AKS
  registry attachment — surface them with dedicated resources in the consumer
  if needed.
- Cluster-upgrade of node pools is independent: `orchestrator_version` on
  pools supports minor aliases; the control plane must be at or above the pool
  version.
- Upgrades to `network_policy`/`network_data_plane` cilium are in-place; other
  network changes force a new cluster.
- The caller needs `Microsoft.ContainerService/managedClusters/write` and
  delete, plus identity/role wiring permissions for the identities it
  supplies.

## Import

```shell
tofu import 'azurerm_kubernetes_cluster.cluster["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ContainerService/managedClusters/<name>"
tofu import 'azurerm_kubernetes_cluster_node_pool.node_pool["<key>.<pool_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ContainerService/managedClusters/<clusterName>/agentPools/<poolName>"
```
