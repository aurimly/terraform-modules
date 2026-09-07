# gcp/instance-group-manager

Map-keyed module for zonal Google Cloud managed instance groups (MIGs) with optional autoscaling.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `managers` | `map(object)` | — | Map of managed instance groups keyed by an arbitrary unique ID; each entry creates one `google_compute_instance_group_manager` plus, when `autoscaler` is set, one `google_compute_autoscaler` targeting it. |

### `managers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | MIG name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `base_instance_name` | `string` | — | Prefix for instance names created by the group (`<base>-<suffix>`); RFC1035-validated. Immutable; changing forces replacement. |
| `zone` | `string` | — | GCP zone the group lives in (e.g. `us-central1-a`). Shape-validated, not a zone list. |
| `versions` | `list(object)` | — | One or more; exactly one entry must omit `target_size` (API-enforced, validated). See the `versions` table. |
| `target_size` | `number` | — | Desired instance count. Omit when `autoscaler` is set (Terraform would fight the autoscaler on every apply) and note that omitting both creates an empty group. |
| `project_id` | `string` | — | Project the group lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `deletion_policy` | `string` | — | One of `DELETE` (default), `PREVENT`, `ABANDON` (validated). `PREVENT` fails `destroy`/plans that would delete the group. |
| `named_ports` | `list(object)` | `[]` | `{name, port}` entries for backend-service port mapping; port 1–65535 (validated). |
| `target_pools` | `list(string)` | — | Legacy target pool URLs. |
| `wait_for_instances` | `bool` | — | Block until instances are created; on boot failure this waits until timeout — prefer auto-healing + monitoring for long-lived groups. |
| `wait_for_instances_status` | `string` | — | `STABLE` or `UPDATED` (validated); only meaningful with `wait_for_instances`. |
| `list_managed_instances_results` | `string` | — | `PAGELESS` or `PAGINATED` (validated). |
| `auto_healing_policies` | `object` | — | `{health_check, initial_delay_sec}`; delay 0–3600 (validated). The health check must exist first (create it in a Terragrunt dependency). |
| `all_instances_config` | `object` | — | `{metadata, labels}` applied to every instance in the group. |
| `stateful_disks` | `list(object)` | `[]` | `{device_name, delete_rule}`; delete_rule `NEVER` (default) or `ON_PERMANENT_INSTANCE_DELETION` (validated). |
| `stateful_internal_ips` | `list(object)` | `[]` | `{interface_name, delete_rule}`; same delete_rule values (validated). |
| `stateful_external_ips` | `list(object)` | `[]` | `{interface_name, delete_rule}`; same delete_rule values (validated). |
| `update_policy` | `object` | — | Rolling-update behavior; see the `update_policy` table. |
| `instance_lifecycle_policy` | `object` | — | `{force_update_on_repair (YES/NO), default_action_on_failure (DO_NOTHING/REPAIR), on_failed_health_check (DEFAULT_ACTION/DO_NOTHING/REPAIR), on_repair = {allow_changing_zone (YES/NO)}}` (all validated). |
| `standby_policy` | `object` | — | `{mode (MANUAL/SCALE_OUT_POOL), initial_delay_sec (0–3600)}` (validated); pair with `target_stopped_size`/`target_suspended_size` for suspended/stopped pools. |
| `target_stopped_size` | `number` | — | Target number of stopped (standby) instances; ≥ 0 (validated). |
| `target_suspended_size` | `number` | — | Target number of suspended instances; ≥ 0 (validated). |
| `autoscaler` | `object` | — | Presence creates a `google_compute_autoscaler` targeting this group; see the `autoscaler` table. Its `name` defaults to the MIG name. |

### `versions` entry

| Attribute | Type | Default | Description |
|---|---|---|---|
| `instance_template` | `string` | — | Instance template self link or id; must contain the substring `instanceTemplates` (validated). Chain `gcp/instance-template`'s `template_self_link_uniques` output via a Terragrunt dependency. |
| `name` | `string` | — | Version name (defaults to a generated name); needed for canary version targeting. |
| `target_size` | `object` | — | `{fixed, percent}`; exactly one required when set, `percent` 0–100, `fixed` ≥ 0 (all validated). Exactly one version in the group must omit `target_size` — remaining instances run that version. |

### `update_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `PROACTIVE` or `OPPORTUNISTIC` (validated). |
| `minimal_action` | `string` | — | One of `NONE`, `REFRESH`, `RESTART`, `REPLACE` (validated). |
| `most_disruptive_allowed_action` | `string` | — | Same enum as `minimal_action` (validated). |
| `max_surge_fixed` | `number` | — | Extra instances during updates; conflicts with `max_surge_percent` (validated); both cannot be 0. |
| `max_surge_percent` | `number` | — | 0–100 inclusive (validated). |
| `max_unavailable_fixed` | `number` | — | Instances that may be unavailable during updates; conflicts with `max_unavailable_percent` (validated). |
| `max_unavailable_percent` | `number` | — | 0–100 inclusive (validated). |
| `replacement_method` | `string` | — | `RECREATE` (names preserved) or `SUBSTITUTE` (default; new random names); `RECREATE` requires `max_unavailable_fixed` or `max_unavailable_percent` > 0 (validated). |

### `autoscaler` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Autoscaler name; defaults to the MIG name. RFC1035-validated when set. |
| `description` | `string` | — | Human-readable description. |
| `deletion_policy` | `string` | — | One of `DELETE` (default), `PREVENT`, `ABANDON` (validated). |
| `autoscaling_policy` | `object` | — | See the sub-tables. Requires at least one scaling signal (`cpu_utilization`, `metric`, `load_balancing_utilization` or `scaling_schedules` — validated). |

`autoscaling_policy`:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `min_replicas` | `number` | — | ≥ 0 (validated). With no `target_size`, this sets the initial instance count. |
| `max_replicas` | `number` | — | Must be ≥ `min_replicas` (validated). |
| `cooldown_period` | `number` | — | Seconds between scaling decisions. |
| `stabilization_period` | `number` | — | Seconds of historical look-back for scale-down recommendations. |
| `mode` | `string` | — | `ON`, `OFF` or `ONLY_SCALE_OUT` (validated). |
| `cpu_utilization` | `object` | — | `{target, predictive_method}`; target in (0, 1] (validated), method `NONE` or `OPTIMIZE_AVAILABILITY`. |
| `metric` | `list(object)` | `[]` | `{name, target, single_instance_assignment, type, filter}`; type `GAUGE`, `DELTA_PER_SECOND` or `DELTA_PER_MINUTE` (validated); `target` > 0 when set; `single_instance_assignment` pins the metric value attributed to one instance. |
| `load_balancing_utilization` | `object` | — | `{target}`; fraction of backend capacity utilization, > 0 (validated). |
| `scaling_schedules` | `list(object)` | `[]` | `{name, min_required_replicas, schedule, duration_sec, time_zone, disabled, description}`; `duration_sec` ≥ 300 (validated). |
| `scale_in_control` | `object` | — | `{time_window_sec, max_scaled_in_replicas = {fixed, percent}}`; percent 0–100, fixed a positive integer (validated). |

## Outputs

`manager_names` — map of manager key => MIG name.
`manager_ids` — map of manager key => MIG ID (`projects/{project}/zones/{zone}/instanceGroupManagers/{name}`).
`manager_self_links` — map of manager key => MIG self link.
`instance_group_urls` — map of manager key => underlying instance group URL; pass this to backend services.
`autoscaler_names` — map of manager key => autoscaler name (only for entries with an autoscaler).
`autoscaler_self_links` — map of manager key => autoscaler self link (only for entries with an autoscaler).

## Example

```hcl
managers = {
  "web" = {
    name               = "example-web-mig"
    base_instance_name = "example-web"
    zone               = "us-central1-a"
    versions = [
      {
        instance_template = "https://www.googleapis.com/compute/v1/projects/example-project-1234/global/instanceTemplates/example-web-20260907abc123def4"
      },
    ]
    target_size     = 3
    deletion_policy = "PREVENT"
    named_ports     = [
      { name = "http", port = 80 },
    ]
    auto_healing_policies = {
      health_check      = "projects/example-project-1234/global/healthChecks/example-web-hc"
      initial_delay_sec = 300
    }
    update_policy = {
      type                    = "OPPORTUNISTIC"
      minimal_action          = "RESTART"
      max_unavailable_fixed   = 1
    }
  }
  "web-autoscaled" = {
    name               = "example-web-autoscaled"
    base_instance_name = "example-web-auto"
    zone               = "us-central1-a"
    versions = [
      {
        instance_template = "https://www.googleapis.com/compute/v1/projects/example-project-1234/global/instanceTemplates/example-web-20260907abc123def4"
      },
    ]
    autoscaler = {
      autoscaling_policy = {
        min_replicas = 2
        max_replicas = 10
        cpu_utilization = {
          target = 0.6
        }
        scale_in_control = {
          time_window_sec = 180
          max_scaled_in_replicas = {
            percent = 20
          }
        }
      }
    }
  }
}
```

## Notes

- `versions` rule: exactly one version per group must omit `target_size`
  (API-enforced; validated here). The group provisions any remaining
  instances with that version — a single version needs no `target_size` at
  all; a canary adds a second version whose `target_size.percent` claims a
  share of the group.
- Templates are immutable: point `versions[].instance_template` at a fresh
  `gcp/instance-template` output (prefer `template_self_link_uniques`) on
  each release, with the MIG's `update_policy` rolling instances over.
  Chained from a Terragrunt unit the pattern looks like:

  ```hcl
  dependency "template" {
    config_path = "../instance-template"
    mock_outputs = {
      template_self_link_uniques = { "web" = "https://www.googleapis.com/compute/v1/projects/mock/global/instanceTemplates/mock" }
    }
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }

  inputs = {
    managers = {
      "web" = {
        # ...
        versions = [
          { instance_template = dependency.template.outputs.template_self_link_uniques["web"] },
        ]
      }
    }
  }
  ```
- With an `autoscaler` set, omit `target_size` — Terraform and the
  autoscaler fight over the count on every apply otherwise (the autoscaler
  wins; the API accepts both, so this is not rejected client-side). Omitting
  both `target_size` and `autoscaler` creates an empty group (0 instances).
- `wait_for_instances = true` blocks until every instance reports `STABLE`
  (or the status given by `wait_for_instances_status`) — a stuck boot fails
  the apply at timeout; auto-healing policies are usually the better wait.
- Auto-healing needs a pre-existing health check; create it in a Terragrunt
  dependency and pass its self link as `auto_healing_policies.health_check`.
- Stateful disks/IPs are keyed by device/interface name and survive VM
  recreation; `delete_rule` controls what happens on permanent instance
  deletion (`NEVER` detaches, `ON_PERMANENT_INSTANCE_DELETION` deletes).
- Zonal only: regional MIGs (`google_compute_region_instance_group_manager`)
  are future scope.
- Pair with `gcp/instance-template` (versions), `gcp/firewall` (instance
  network tags), and `gcp/static_ip` (stateful external IPs).

- Not yet in scope (future additions): regional instance group managers and
  regional autoscalers, `update_policy.min_ready_sec` (beta-gated on the
  stable provider; the reference modules exposed it via google-beta),
  `params` (beta), `target_size_policy`, `resource_policies.workload_policy`,
  and autoscaler `scale_down_control` (beta-gated on the stable provider).

## Import

`google_compute_instance_group_manager` ←
`projects/{project}/zones/{zone}/instanceGroupManagers/{name}` (also
`{project}/{zone}/{name}`, `{project}/{name}`, and the bare `{name}` within
the provider's default zone).

`google_compute_autoscaler` ←
`projects/{project}/zones/{zone}/autoscalers/{name}` (also
`{project}/{zone}/{name}`, `{project}/{name}`, and the bare `{name}`).
