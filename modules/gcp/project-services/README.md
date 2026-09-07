# gcp/project-services

Map-keyed module for enabling Google Cloud APIs (services) in projects.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `services` | `map(object)` | — | Map of API enablements keyed by an arbitrary unique ID. |

### `services` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service` | `string` | — | Service in full form, e.g. `pubsub.googleapis.com` (validated; the Service Usage API expects the full form). |
| `project_id` | `string` | — | Project to enable the service in; defaults to the provider-level project. Format validated. |
| `disable_dependent_services` | `bool` | `false` | Also disable services that depend on this one when the service is destroyed. |
| `disable_on_destroy` | `bool` | `false` | Disable the service when the resource is destroyed. Module default is `false`; provider v6 defaulted `true`, v7 changed the default to `false`. Keeping `false` means destroying this unit never kills an API other things may depend on. |

## Outputs

`service_ids` — map of service key => resource id (`{project_id}/{service}`).

## Example

```hcl
services = {
  "pubsub-prod" = {
    project_id = "example-project-1234"
    service    = "pubsub.googleapis.com"
  }
  "storage-prod" = {
    project_id         = "example-project-1234"
    service            = "storage.googleapis.com"
    disable_on_destroy = true
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not service names — the same API can be
  enabled in several projects under different keys. Duplicate `(project_id,
  service)` pairs across keys are rejected at plan time; entries without
  `project_id` resolve to the provider default project and cannot be deduplicated
  against it (validated on the empty-string stand-in).
- This module is the single owner of API enablement. Other modules in this repo
  (e.g. `gcp/bucket`) pair with it instead of enabling APIs inline — give the
  owning unit the API keys it needs.
- Enablement is eventually consistent; when a downstream resource in a separate
  unit depends on a freshly enabled API, add a Terragrunt `dependency`/
  `depends_on` so the enablement applies first.
- Disabling is the destructive direction: `disable_dependent_services = true` can
  cascade to APIs you did not name. The module never disables on its own.

## Import

`google_project_service` ← `{project_id}/{service}`. Note that apply (not just
import) adopts already-enabled services without change.
