# stackit/ske_kubeconfig

Map-keyed module for short-lived STACKIT SKE kubeconfigs for existing
clusters (see stackit/ske for full cluster management).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `kubeconfigs` | `map(object)` | — | Map of kubeconfigs keyed by an arbitrary unique ID. |

### `kubeconfigs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the cluster lives in (validated). Changing it replaces the kubeconfig. |
| `cluster_name` | `string` | — | Name of an existing SKE cluster. Must not contain a comma (the import ID is comma-joined, validated). Changing it replaces the kubeconfig. |
| `region` | `string` | `null` | Cluster region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the kubeconfig. |
| `expiration` | `number` | API default (`3600`) | Kubeconfig validity in seconds; must be greater than 0 (validated). Changing it replaces the kubeconfig. |
| `refresh` | `bool` | `null` | Rotate the kubeconfig in place on apply. Changing it replaces the kubeconfig. |
| `refresh_before` | `number` | `null` | Rotate this many seconds before expiry; requires `refresh = true` (validated — the module is stricter than the provider here, see the notes). Updates in place. |

## Outputs

`kubeconfigs` (**sensitive**) — map of kubeconfig key => object:

| Attribute | Description |
|---|---|
| `kube_config` | Raw admin kubeconfig. Short-lived — do not treat it as static. |
| `expires_at` | Expiry timestamp. |
| `kube_config_id` | Kubeconfig UUID (provider-generated; the SKE API returns no identifier). |
| `creation_time` | Creation timestamp. |
| `id` | `"{project_id},{cluster_name},{kube_config_id}"` — the import ID. |

## Example

```hcl
module "ske_kubeconfig" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/ske_kubeconfig?ref=v1.3.0"

  kubeconfigs = {
    "ci" = {
      project_id   = "12345678-1234-1234-1234-123456789012"
      cluster_name = "example-prod"
      region       = "eu01"
      expiration   = 7200
    }
    "ops" = {
      project_id     = "12345678-1234-1234-1234-123456789012"
      cluster_name   = "example-prod"
      region         = "eu01"
      expiration     = 7200
      refresh        = true
      refresh_before = 3600
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not cluster names — multiple
  entries may target the same cluster.
- The kubeconfig is a **short-lived admin credential** (default expiry
  3600 s): never treat it as static, and pull it from the state/pipeline,
  not logs.
- Rotation: changing `expiration` or `refresh` forces destroy + create,
  which produces a fresh credential; with `refresh = true` and
  `refresh_before` set, the credential rotates in place ahead of expiry
  on applies. There is no `rotate_when_changed` on this resource — the
  expiration/refresh change is the rotation trigger.
- **Do not use this module together with stackit/ske's `kubeconfig`
  block for the same cluster.** Creating any kubeconfig resource for a
  cluster disables the cluster's deprecated credential endpoints
  (provider warning), and each kubeconfig resource creates its own
  independent short-lived credential. Use stackit/ske's `kubeconfig`
  block when that module also manages the cluster; use this module when
  the cluster is managed elsewhere or the kubeconfig lifecycle must be
  decoupled from the cluster unit.
- For pipeline-scoped access without a persisted credential, prefer the
  provider's ephemeral `stackit_ske_kubeconfig` resource (provider
  >= 0.113.0) instead.
- Region: a per-entry `region` replaces the kubeconfig when changed;
  unset falls back to the provider's configured region.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, no-comma names, `expiration > 0`) plus the
  `refresh_before`-requires-`refresh` guard.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; the
  kubeconfig resource's `refresh`/`refresh_before` predate it, so no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_ske_kubeconfig` ← `{project_id},{cluster_name},{kube_config_id}`
