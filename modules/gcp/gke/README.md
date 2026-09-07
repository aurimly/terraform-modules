# gcp/gke

Map-keyed module for Google Kubernetes Engine clusters with optional node pools and GKE backup plans.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | — | Map of GKE clusters keyed by an arbitrary unique ID; each entry creates one `google_container_cluster` plus optional node pools (`google_container_node_pool`) and backup plans (`google_gke_backup_backup_plan`). |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cluster name; 1–63 lowercase RFC1035 characters. Validated client-side. Changing forces cluster replacement. |
| `location` | `string` | — | GCP region (regional cluster, e.g. `us-central1`) or zone (zonal cluster, e.g. `us-central1-a`). Shape-validated. Changing forces replacement. |
| `project_id` | `string` | — | Project the cluster lives in; defaults to the provider-level project. Required (validated) when `workload_identity` is `true`. |
| `description` | `string` | — | Human-readable description. |
| `deletion_protection` | `bool` | — | Blocks API deletes; `terraform destroy` fails until unset. Provider default is `true` when unset. |
| `enable_autopilot` | `bool` | — | Create an Autopilot cluster instead of Standard. Autopilot entries must define no `node_pools` (validated). |
| `resource_labels` | `map(string)` | — | Cluster resource labels. |
| `default_max_pods_per_node` | `number` | — | Default maximum pods per node for the cluster. |
| `min_master_version` | `string` | — | Minimum control plane version. Mutually exclusive with `release_channel` (validated). |
| `release_channel` | `object` | — | `{channel}`; one of `UNSPECIFIED`, `RAPID`, `REGULAR`, `STABLE` (validated). Mutually exclusive with `min_master_version`. |
| `gateway_api_channel` | `string` | — | Gateway API release channel: `CHANNEL_STANDARD` or `CHANNEL_DISABLED` (validated). |
| `workload_identity` | `bool` | — | Enables Workload Identity; emits `workload_pool = "{project_id}.svc.id.goog"`. Requires per-entry `project_id` (validated) — see Notes. |
| `daily_maintenance_window` | `object` | — | `{start_time}` in `HH:MM` format, UTC. Mutually exclusive with `recurring_maintenance_window` (validated). |
| `recurring_maintenance_window` | `object` | — | `{start_time, end_time, recurrence}`; `start_time`/`end_time` are RFC3339 timestamps (e.g. `2099-01-01T00:00:00Z` — not `HH:MM`), `recurrence` is an RFC5545 RRULE (e.g. `FREQ=WEEKLY;BYDAY=SA,SU`). Mutually exclusive with `daily_maintenance_window`. |
| `network` | `string` | — | VPC network name or self link. |
| `subnetwork` | `string` | — | Subnetwork name or self link. |
| `ip_allocation_policy` | `object` | — | `{cluster_secondary_range_name, services_secondary_range_name}`; VPC-native pod/service ranges. Omitted range names let the provider auto-create ranges. |
| `master_authorized_networks_config` | `object` | — | `{cidr_blocks}`; each entry `{cidr_block, display_name}`, `cidr_block` must be a valid IPv4 CIDR (validated). |
| `private_cluster_config` | `object` | — | See the `private_cluster_config` table. |
| `network_policy` | `object` | — | `{enabled, provider}`; provider `PROVIDER_UNSPECIFIED` or `CALICO` (validated). Must not be set with `datapath_provider = "ADVANCED_DATAPATH"` (validated) — Dataplane V2 enforces policy with Cilium. |
| `addons_config` | `object` | — | Optional addon sub-objects: `horizontal_pod_autoscaling.disabled`, `http_load_balancing.disabled`, `gcs_fuse_csi_driver_config.enabled`, `gcp_filestore_csi_driver_config.enabled`, `gke_backup_agent_config.enabled`. |
| `vertical_pod_autoscaling` | `object` | — | `{enabled}`. |
| `datapath_provider` | `string` | — | `LEGACY_DATAPATH` or `ADVANCED_DATAPATH` (Dataplane V2; validated). |
| `enable_shielded_nodes` | `bool` | — | Shielded GKE nodes. |
| `enable_intranode_visibility` | `bool` | — | Same-VPC pod-to-pod visibility. |
| `enable_l4_ilb_subsetting` | `bool` | — | L4 internal load balancer subsetting. |
| `enable_fqdn_network_policy` | `bool` | — | FQDN network policies; requires `datapath_provider = "ADVANCED_DATAPATH"` (validated). |
| `enable_multi_networking` | `bool` | — | Multi-networking support. |
| `enable_cilium_clusterwide_network_policy` | `bool` | — | Clusterwide Cilium network policies (Dataplane V2). |
| `disable_l4_lb_firewall_reconciliation` | `bool` | — | Stops GKE from reconciling firewall rules for L4 LoadBalancer Services. |
| `logging_service` | `string` | — | Legacy logging integration. Mutually exclusive with `logging_config` (validated). |
| `logging_config` | `object` | — | `{enable_components}`; subset of `SYSTEM_COMPONENTS`, `APISERVER`, `CONTROLLER_MANAGER`, `SCHEDULER`, `WORKLOADS`. |
| `monitoring_service` | `string` | — | Legacy monitoring integration. Mutually exclusive with `monitoring_config` (validated). |
| `monitoring_config` | `object` | — | `{enable_components, managed_prometheus, advanced_datapath_observability_config}`; see the `monitoring_config` table. |
| `dns_config` | `object` | — | `{cluster_dns, cluster_dns_scope, cluster_dns_domain, additive_vpc_scope_dns_domain}`; `cluster_dns` one of `PROVIDER_UNSPECIFIED`, `PLATFORM_DEFAULT`, `CLOUD_DNS`, `KUBE_DNS`; scope one of `DNS_SCOPE_UNSPECIFIED`, `CLUSTER_SCOPE`, `VPC_SCOPE` (validated). |
| `security_posture_config` | `object` | — | `{mode, vulnerability_mode}`; mode one of `DISABLED`, `BASIC`, `ENTERPRISE`; vulnerability_mode one of `VULNERABILITY_DISABLED`, `VULNERABILITY_BASIC`, `VULNERABILITY_ENTERPRISE` (validated). |
| `binary_authorization` | `object` | — | `{evaluation_mode}`; `DISABLED` or `PROJECT_SINGLETON_POLICY_ENFORCE` (validated). |
| `confidential_nodes` | `object` | — | `{enabled}`. |
| `service_external_ips_config` | `object` | — | `{enabled}`; allows external IPs on Services. |
| `authenticator_groups_config` | `object` | — | `{security_group}`; RBAC security group (Google Groups for RBAC). |
| `notification_config` | `object` | — | `{pubsub}`; see the `notification_config` table. |
| `cost_management_config` | `object` | — | `{enabled}`; GKE cost allocation. |
| `database_encryption` | `object` | — | `{state, key_name}`; state `ENCRYPTED` or `DECRYPTED` (validated); `key_name` is a Cloud KMS key self link required with `ENCRYPTED`. |
| `resource_usage_export_config` | `object` | — | `{enable_network_egress_metering, enable_resource_consumption_metering, bigquery_destination}`; `bigquery_destination.dataset_id` required when set. |
| `node_pool_auto_config` | `object` | — | `{network_tags, resource_manager_tags, node_kubelet_config, linux_node_config}`; see the `node_pool_auto_config` table. |
| `node_pool_defaults` | `object` | — | `{node_config_defaults}`; see the `node_pool_defaults` table. |
| `cluster_autoscaling` | `object` | — | `{enabled, resource_limits, auto_provisioning_defaults}`; see the `cluster_autoscaling` table. |
| `secret_manager_config` | `object` | — | `{enabled (default true), rotation_config {enabled (default true), rotation_interval (default "120s")}}`. |
| `fleet` | `object` | — | `{project}`; fleet registration project. |
| `control_plane_endpoints_config` | `object` | — | `{dns_endpoint_config {allow_external_traffic}}`; cluster DNS endpoint. |
| `node_pools` | `list(object)` | `[]` | Node pools attached to the cluster; see the `node_pools` entry table. |
| `backup_plans` | `list(object)` | `[]` | GKE Backup plans for the cluster; see the `backup_plans` entry table. |

### `private_cluster_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enable_private_nodes` | `bool` | — | Private nodes (no external IPs). Required `true` for a private endpoint. |
| `enable_private_endpoint` | `bool` | — | Private control plane endpoint; requires `enable_private_nodes` (validated). |
| `master_ipv4_cidr_block` | `string` | — | `/28` CIDR for the control plane (validated when `enable_private_nodes` is `true`); required in that case. |
| `master_global_access_config` | `object` | — | `{enabled}`; global access to the private control plane. |

### `monitoring_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enable_components` | `list(string)` | — | Subset of `SYSTEM_COMPONENTS`, `APISERVER`, `CONTROLLER_MANAGER`, `SCHEDULER`, `WORKLOADS`. |
| `managed_prometheus` | `object` | — | `{enabled}`. |
| `advanced_datapath_observability_config` | `object` | — | `{enable_metrics, enable_relay}`; Dataplane V2 observability. |

### `notification_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `pubsub` | `object` | — | Required. `{enabled, topic, filter}`; `topic` is a Pub/Sub topic self link. |
| `pubsub.filter` | `object` | — | `{event_type}`; entries from `UPGRADE_AVAILABLE_EVENT`, `UPGRADE_EVENT`, `SECURITY_BULLETIN_EVENT`, `UPGRADE_INFO_EVENT` (validated). |

### `node_pool_auto_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network_tags` | `object` | — | `{tags}`; network tags for auto-provisioned node pools. |
| `resource_manager_tags` | `map(string)` | — | Resource Manager tags for auto-provisioned node pools. |
| `node_kubelet_config` | `object` | — | `{insecure_kubelet_readonly_port_enabled}`; the strings `TRUE` or `FALSE` (validated). |
| `linux_node_config` | `object` | — | `{cgroup_mode}`; e.g. `CGROUP_MODE_V2`. |

### `node_pool_defaults` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `node_config_defaults` | `object` | — | `{insecure_kubelet_readonly_port_enabled (TRUE/FALSE, validated), logging_variant (DEFAULT or MAX_THROUGHPUT, validated), gcfs_config {enabled}}`. |

### `cluster_autoscaling` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | — | Enables cluster-level autoscaling (node auto-provisioning). |
| `resource_limits` | `list(object)` | `[]` | `{resource_type, minimum, maximum}`; e.g. `cpu`, `memory`. |
| `auto_provisioning_defaults` | `object` | — | `{service_account}`. |

### `node_pools` entry

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Pool name; RFC1035, unique within the cluster entry (validated). Changing forces pool replacement. |
| `node_count` | `number` | — | Static node count; must be `>= 1` and is required (validated) when `autoscaling` is unset — zero-size pools are only valid with autoscaling. Mutually exclusive with `autoscaling`. |
| `node_locations` | `list(string)` | — | Zones for the pool's nodes (regional clusters); defaults to all cluster zones. |
| `max_pods_per_node` | `number` | — | Maximum pods per node. |
| `autoscaling` | `object` | — | `{min_node_count, max_node_count, total_min_node_count, total_max_node_count, location_policy}`; per-zone limits XOR total limits (validated), min ≤ max (validated), `location_policy` `BALANCED` or `ANY` (validated). |
| `management` | `object` | — | `{auto_repair, auto_upgrade}`. |
| `upgrade_settings` | `object` | — | `{max_surge, max_unavailable}`; both required and `>= 0` (validated). Blue-green (`strategy`) upgrades are not yet in scope. |
| `node_config` | `object` | — | See the `node_config` object table. |

### `node_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `image_type` | `string` | — | e.g. `COS_CONTAINERD`. |
| `machine_type` | `string` | — | e.g. `e2-standard-4`. |
| `min_cpu_platform` | `string` | — | e.g. `Intel Cascade Lake`. |
| `disk_size_gb` | `number` | — | Boot disk size. |
| `disk_type` | `string` | — | e.g. `pd-balanced`. |
| `preemptible` | `bool` | — | Preemptible nodes; conflicts with `spot` (validated). |
| `spot` | `bool` | — | Spot VMs; conflicts with `preemptible` (validated). |
| `service_account` | `string` | — | Node service account email. |
| `oauth_scopes` | `list(string)` | — | OAuth scopes; non-empty when set (validated). |
| `tags` | `list(string)` | — | Network tags for firewall rule targeting. |
| `labels` | `map(string)` | — | Kubernetes node labels. |
| `metadata` | `map(string)` | — | Node metadata. |
| `taints` | `list(object)` | `[]` | `{key, value, effect}`; effect `NO_SCHEDULE`, `PREFER_NO_SCHEDULE` or `NO_EXECUTE` (validated). |
| `shielded_instance_config` | `object` | — | `{enable_secure_boot, enable_integrity_monitoring}`. |
| `workload_metadata_config` | `object` | — | `{mode}`; `GCE_METADATA` or `GKE_METADATA` (validated). |
| `guest_accelerators` | `list(object)` | `[]` | `{type, count, gpu_partition_size, gpu_driver_installation_config, gpu_sharing_config}`; `count >= 1`, driver version `DEFAULT`/`LATEST`, sharing strategy `TIME_SHARING`/`MPS` (validated). |

### `backup_plans` entry

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Plan name; RFC1035, unique within the cluster entry (validated). |
| `description` | `string` | — | Human-readable description. |
| `deactivated` | `bool` | — | Deactivates the plan without deleting it. |
| `labels` | `map(string)` | — | Backup plan labels. |
| `retention_policy` | `object` | — | See the `retention_policy` table. |
| `backup_schedule` | `object` | — | `{cron_schedule, paused, rpo_config}`; exactly one of `cron_schedule` or `rpo_config` (validated). See the `backup_schedule` table. |
| `backup_config` | `object` | — | See the `backup_config` table. |

### `retention_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `backup_delete_lock_days` | `number` | — | Minimum retention; 0–90 (validated) and ≤ `backup_retain_days` (validated). Cannot be reduced once set. |
| `backup_retain_days` | `number` | — | Maximum retention; 0–365 (validated). |
| `locked` | `bool` | — | Locks the retention policy. |

### `backup_schedule` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cron_schedule` | `string` | — | Standard cron expression; XOR `rpo_config` (validated). |
| `paused` | `bool` | — | Pauses the schedule. |
| `rpo_config` | `object` | — | `{target_rpo_minutes, exclusion_windows}`; RPO 60–86400 minutes (validated). `exclusion_windows` entries are `{duration, start_time, single_occurrence_date, days_of_week}` with `duration` in seconds (e.g. `3600s`), `start_time` as `{hours, minutes, seconds, nanos}`, `single_occurrence_date` as `{day, month, year}`, `days_of_week` as `{days_of_week: [MONDAY, ...]}`. |

### `backup_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `include_volume_data` | `bool` | — | Include PersistentVolume data. |
| `include_secrets` | `bool` | — | Include Kubernetes Secrets. |
| `all_namespaces` | `bool` | — | Back up all namespaces. Exactly one of `all_namespaces`, `selected_namespaces`, `selected_applications` (validated). |
| `permissive_mode` | `bool` | — | Back up resources outside the supported scope. |
| `encryption_key` | `object` | — | `{gcp_kms_encryption_key}`; Cloud KMS key self link. |
| `selected_namespaces` | `object` | — | `{namespaces}`; non-empty list (validated). |
| `selected_applications` | `object` | — | `{namespaced_names}`; entries `{name, namespace}` (validated). |

## Outputs

`cluster_names` — map of cluster key => cluster name.
`cluster_self_links` — map of cluster key => cluster self link.
`cluster_ids` — map of cluster key => cluster ID (`projects/{project}/locations/{location}/clusters/{name}`).
`cluster_endpoints` — map of cluster key => API server endpoint.
`cluster_locations` — map of cluster key => location (region or zone as configured).
`node_pool_names` — map of node pool key => pool name.
`node_pool_ids` — map of node pool key => pool ID (`projects/{project}/locations/{location}/clusters/{cluster}/nodePools/{name}`).
`node_pool_instance_group_urls` — map of node pool key => list of instance group URLs (one per zone), usable as load-balancer backend service groups.
`backup_plan_names` — map of backup plan key => plan name.
`backup_plan_ids` — map of backup plan key => plan ID (`projects/{project}/locations/{location}/backupPlans/{name}`).

Child keys are `"<cluster_key>/<pool_name>"` and `"<cluster_key>/<plan_name>"` — pool and plan names are RFC1035 (no `/`), so the last `/` in a key splits it unambiguously.

## Example

```hcl
module "gke" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/gcp/gke?ref=v1.1.0"

  clusters = {
    "main" = {
      name       = "example-cluster"
      location   = "us-central1"
      project_id = "example-project-1234"
      release_channel = {
        channel = "REGULAR"
      }
      workload_identity = true
      ip_allocation_policy = {
        cluster_secondary_range_name  = "example-pods"
        services_secondary_range_name = "example-services"
      }
      master_authorized_networks_config = {
        cidr_blocks = [
          { cidr_block = "10.10.0.0/16", display_name = "example-vpc" },
        ]
      }
      node_pools = [
        {
          name = "example-pool"
          autoscaling = {
            min_node_count  = 1
            max_node_count  = 3
            location_policy = "BALANCED"
          }
          upgrade_settings = {
            max_surge       = 1
            max_unavailable = 0
          }
          node_config = {
            machine_type   = "e2-standard-4"
            disk_type      = "pd-balanced"
            oauth_scopes   = ["https://www.googleapis.com/auth/cloud-platform"]
            workload_metadata_config = {
              mode = "GKE_METADATA"
            }
          }
        },
      ]
      backup_plans = [
        {
          name = "example-backup"
          retention_policy = {
            backup_retain_days = 30
          }
          backup_schedule = {
            rpo_config = {
              target_rpo_minutes = 240
            }
          }
          backup_config = {
            all_namespaces = true
          }
        },
      ]
    },
  }
}
```

Zonal clusters: set `location` to a zone (e.g. `us-central1-a`). Autopilot: set `enable_autopilot = true` and omit `node_pools`.

## Notes

- **Default node pool**: each standard cluster creates a one-node bootstrap default pool that is removed immediately after creation (`remove_default_node_pool = true`); its `initial_node_count` and `node_config` are in `ignore_changes`. The bootstrap pool runs with secure boot and integrity monitoring enabled so cluster creation passes org policies that enforce Shielded VM settings. The bootstrap pool's config cannot be customized.
- **API enablement**: enable `container.googleapis.com` (and `gkebackup.googleapis.com` when using `backup_plans`) in the project before applying — see `gcp/project-services`. Backup plans additionally need `addons_config.gke_backup_agent_config.enabled = true` on the cluster.
- **Workload Identity**: `workload_identity = true` requires `project_id` on the cluster entry; the workload pool (`{project}.svc.id.goog`) is built from it — a provider-level default project is not picked up.
- **Versioning**: `min_master_version` and `release_channel` are mutually exclusive; release channels manage upgrades for you.
- **No google-beta**: everything this module exposes is GA in the `google` provider.
- **Autopilot**: entries with `enable_autopilot = true` must define no `node_pools`; the API enforces the remaining Autopilot constraints (e.g. no node config customization).

## Not yet in scope

Node pool blue-green (`strategy`) upgrades, Windows node configs, node boot disk encryption with customer-managed keys, and fleet membership details beyond `fleet.project`.

## Import

Clusters, node pools and backup plans can be imported:

- Cluster: `projects/{project}/locations/{location}/clusters/{name}`
- Node pool: `projects/{project}/locations/{location}/clusters/{cluster}/nodePools/{name}`
- Backup plan: `projects/{project}/locations/{location}/backupPlans/{name}`
