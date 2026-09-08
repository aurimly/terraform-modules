# stackit/ske

Map-keyed module for STACKIT Kubernetes Engine (SKE) clusters with node
pools and optional short-lived kubeconfigs.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | — | Map of SKE clusters keyed by an arbitrary unique ID. |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cluster name. Must not contain a comma (the import ID is comma-joined, validated). Changing it replaces the cluster. |
| `project_id` | `string` | — | STACKIT project UUID the cluster is created in (validated). Changing it replaces the cluster. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the cluster. |
| `kubernetes_version_min` | `string` | `null` | Minimum Kubernetes version: `major.minor` (e.g. `1.31`) or full semver (validated). The resolved version is in the `kubernetes_version_used` output. |
| `node_pools` | `map(object)` | — | Node pools; see the `node_pools` object table. |
| `access` | `object` | `null` | `{idp = {enabled, type}}` — STACKIT IAM identity provider for cluster access; `type` must be `stackit` when set (validated). |
| `audit` | `object` | `null` | `{enabled}` — audit logging. |
| `extensions` | `object` | `null` | Cluster extensions; see the `extensions` object table. |
| `hibernations` | `list(object)` | `null` | List of `{start, end, timezone}` hibernation schedules. `start`/`end` are crontab expressions (e.g. `0 18 * * *`), `timezone` an IANA zone (e.g. `Europe/Berlin`) — note the different format from `maintenance.start`/`end`, which are clock times. |
| `maintenance` | `object` | `null` | Maintenance window; see the `maintenance` object table. |
| `network` | `object` | `null` | SKE-network integration; see the `network` object table. |
| `kubeconfig` | `object` | `null` | Presence creates a short-lived admin kubeconfig resource; see the `kubeconfig` object table. |

### `node_pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Node pool name; the API identifies pools by name, so names must be unique within a cluster (validated). |
| `machine_type` | `string` | — | Machine type (e.g. `b2c-4-8`). |
| `availability_zones` | `list(string)` | — | Availability zones for the pool. |
| `minimum` | `number` | — | Minimum number of nodes, 0 or greater (validated). |
| `maximum` | `number` | — | Maximum number of nodes, greater than or equal to `minimum` (validated). |
| `allow_system_components` | `bool` | API default (`true`) | Whether system components run on the pool. |
| `cri` | `string` | API default (`containerd`) | Container runtime. |
| `os_name` | `string` | API default (`flatcar`) | Node operating system name. |
| `os_version_min` | `string` | `null` | Minimum node OS version: `major.minor` or full semver (validated); the resolved version is in the `node_pools` output. |
| `max_surge` | `number` | `null` | Extra nodes during upgrades. At least one of `max_surge`/`max_unavailable` must be set; each set value must be greater than 0 and at least the number of `availability_zones` (API rule, validated). |
| `max_unavailable` | `number` | `null` | Nodes that may be unavailable during upgrades; same rule as `max_surge`. |
| `volume_type` | `string` | API default (`storage_premium_perf1`) | Node volume type. |
| `volume_size` | `number` | API default (`20`) | Node volume size in GB. |
| `labels` | `map(string)` | `null` | Kubernetes labels for the pool's nodes. |
| `taints` | `list(object)` | `null` | List of `{key, effect, value}` taints; `effect` must be `NoSchedule`, `PreferNoSchedule` or `NoExecute` (validated). |

### `extensions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `acl` | `object` | `null` | `{enabled, allowed_cidrs}` — restrict cluster access to the listed IPv4 CIDRs (validated). |
| `dns` | `object` | `null` | `{enabled, gateway_api, zones}` — DNS integration. `zones` entries are zone names and must not be UUIDs (provider rule). |
| `observability` | `object` | `null` | `{enabled, instance_id}` — metrics integration; `instance_id` is required when `enabled = true` (validated). |
| `application_load_balancer` | `object` | `null` | `{enabled}` — ALB integration (`enabled` must be set when the block is present). Private preview: requests are rejected for projects not enabled for it. |

### `maintenance` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enable_kubernetes_version_updates` | `bool` | API default applies | Auto-update the Kubernetes version up to `kubernetes_version_min`. |
| `enable_machine_image_version_updates` | `bool` | API default applies | Auto-update node machine image versions up to `os_version_min`. |
| `start` | `string` | `null` | Window start as an RFC3339 full-time (e.g. `01:23:45Z`, validated). Must be set together with `end` (validated). |
| `end` | `string` | `null` | Window end, same format and rule as `start`. |

### `network` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `id` | `string` | `null` | STACKIT network UUID to integrate (e.g. from stackit/network's `networks` output), validated as a UUID. Changing it replaces the cluster. |
| `control_plane.access_scope` | `string` | API default (`PUBLIC`) | `PUBLIC` or `SNA` (validated). Private preview: requests are rejected for projects not enabled for it. Immutable after create. |

### `kubeconfig` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `expiration` | `number` | API default (`3600`) | Kubeconfig validity in seconds; must be greater than 0 (validated). |
| `refresh` | `bool` | `null` | Rotate the kubeconfig in place on apply. |
| `refresh_before` | `number` | `null` | Rotate this many seconds before expiry; requires `refresh = true` (validated — the module is stricter than the provider here, see the notes). |

## Outputs

`clusters` — map of cluster key => object:

| Attribute | Description |
|---|---|
| `name` | Cluster name. |
| `kubernetes_version_used` | Kubernetes version resolved by the API from `kubernetes_version_min`. |
| `egress_address_ranges` | CIDR ranges the cluster egresses from — useful for firewall allowlists. |
| `pod_address_ranges` | Pod CIDR ranges. |
| `service_account_issuer` | Service account token issuer URL. |
| `node_pools` | Map of node pool name => resolved OS version (`os_version_used`). |
| `id` | `"{project_id},{region},{name}"` — the import ID. |

`kubeconfigs` (**sensitive**) — map of cluster key => object; present only for entries with a `kubeconfig` block:

| Attribute | Description |
|---|---|
| `kube_config` | Raw admin kubeconfig. Short-lived — do not treat it as static. |
| `expires_at` | Expiry timestamp. |
| `kube_config_id` | Kubeconfig UUID. |
| `creation_time` | Creation timestamp. |
| `id` | `"{project_id},{cluster_name},{kube_config_id}"` — the import ID. |

## Example

```hcl
module "ske" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/ske?ref=v1.3.0"

  clusters = {
    "prod" = {
      project_id             = "12345678-1234-1234-1234-123456789012"
      name                   = "example-prod"
      region                 = "eu01"
      kubernetes_version_min = "1.31"
      node_pools = {
        "system" = {
          name               = "system"
          machine_type       = "b2c-4-8"
          availability_zones = ["eu01-1", "eu01-2"]
          minimum            = 2
          maximum            = 2
          max_surge          = 2
          max_unavailable    = 2
        }
        "apps" = {
          name               = "apps"
          machine_type       = "b2c-8-16"
          availability_zones = ["eu01-1", "eu01-2", "eu01-3"]
          minimum            = 2
          maximum            = 6
          labels = {
            "workload" = "apps"
          }
          taints = [
            { key = "dedicated", effect = "NoSchedule", value = "apps" },
          ]
        }
      }
      maintenance = {
        enable_kubernetes_version_updates    = true
        enable_machine_image_version_updates = true
        start                                = "01:23:45Z"
        end                                  = "02:23:45Z"
      }
      kubeconfig = {
        expiration     = 3600
        refresh        = true
        refresh_before = 600
      }
    }
    "dev" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-dev"
      region     = "eu01"
      node_pools = {
        "system" = {
          name               = "system"
          machine_type       = "b2c-2-4"
          availability_zones = ["eu01-1"]
          minimum            = 1
          maximum            = 1
          max_surge          = 1
        }
      }
      hibernations = [
        { start = "0 18 * * *", end = "0 8 * * 1-5", timezone = "Europe/Berlin" },
      ]
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names — cluster and node pool
  keys alike. Node pool names may repeat across clusters but not within
  one.
- Map-to-list ordering: the module converts the `node_pools` map to the
  provider's list by iterating the keys in lexicographic order. The
  provider plans list entries by index while the API applies changes by
  name, so add new pools with keys sorting after the existing ones to
  keep plans readable; renaming a key only reorders the list (a no-op
  upstream, but a confusing diff).
- Replacements: `project_id`, `name`, `region` and `network.id` replace
  the cluster when changed — renaming a cluster or moving it to another
  project re-creates it. Everything else updates in place.
- `kubernetes_version_min` sets a floor, not an exact pin: with
  `enable_kubernetes_version_updates` the cluster upgrades to at least
  that version, and `kubernetes_version_used` reports the actual one.
  Same pattern per pool for `os_version_min`/`os_version_used`.
- Hibernation schedules use crontab syntax (`0 18 * * *`) while
  `maintenance.start`/`end` are clock times (`01:23:45Z`) — different
  formats on purpose.
- The kubeconfig is a short-lived admin credential: it expires
  (`expiration`, default 3600 s) and must not be treated as static.
  `refresh = true` rotates it in place on each apply; `refresh_before`
  rotates ahead of expiry but requires `refresh = true` — the module
  rejects that combination while the provider silently ignores it. For
  pipeline-scoped access without a persisted credential, consider the
  provider's ephemeral `stackit_ske_kubeconfig` resource (provider
  >= 0.113.0) instead.
- `network.control_plane` (SNA access scope) and
  `extensions.application_load_balancer` are private preview: applies
  fail for projects not enabled for the features.
- The deprecated `os_version` node pool attribute and the removed
  `extensions.argus` (gone since 2026-01-06) are intentionally out of
  scope.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, no-comma names, version shapes) and the documented API rules
  (node pool upgrade settings, maintenance window format and pairing,
  unique pool names, taint effects); CIDR checks use Terraform's IP
  functions so they match the provider's parser exactly.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; the
  newest attributes used here (`network.control_plane`, the kubeconfig
  resource's `refresh`/`refresh_before`) predate it, so no behavior in
  this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_ske_cluster` ← `{project_id},{region},{name}`

`stackit_ske_kubeconfig` ← `{project_id},{cluster_name},{kube_config_id}`
