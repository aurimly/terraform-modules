# gcp/vpc-service-controls

Map-keyed module for the Access Context Manager layer of VPC Service Controls:
access policies (`google_access_context_manager_access_policy`), access levels
(`google_access_context_manager_access_level`), service perimeters
(`google_access_context_manager_service_perimeter`), and perimeter resource
additions (`google_access_context_manager_service_perimeter_resource`).

Complements `gcp/org-policy` (constraint policies): this module manages the ACM
side — who/what may cross the perimeter. Resources are referenced by keys, and
the module composes `parent` and full resource names from the referenced access
policy, so consumers never hand-build `accessPolicies/{id}/...` strings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `access_policies` | `map(object)` | `{}` | Map of access policies keyed by an arbitrary unique ID (usually one). |
| `access_levels` | `map(object)` | `{}` | Map of access levels keyed by an arbitrary unique ID; each references a policy via `policy_key`. |
| `service_perimeters` | `map(object)` | `{}` | Map of service perimeters; each references a policy via `policy_key`. |
| `perimeter_resources` | `map(object)` | `{}` | Map of perimeter resource entries; each references a perimeter via `perimeter_key`. |

### `access_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `parent` | `string` | — | `organizations/{id}` or `folders/{id}` (validated); project parents are rejected by the API. Immutable. |
| `title` | `string` | — | Human-readable title. |
| `scopes` | `list(string)` | — | Limits the policy to specific folders/projects, e.g. `folders/{id}` or `projects/{project_number}`. Immutable once set. |
| `deletion_policy` | `string` | DELETE | `DELETE`, `ABANDON` or `PREVENT` (validated). |

### `access_levels` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `policy_key` | `string` | — | Key into `access_policies` (plan-fail if missing). |
| `name` | `string` | — | Short name: starts with a letter, letters/digits/underscores (validated); the module composes the full name. |
| `title` | `string` | — | Human-readable title, unique within the policy. |
| `description` | `string` | — | Free-text description. |
| `deletion_policy` | `string` | DELETE | `DELETE`, `ABANDON` or `PREVENT` (validated). |
| `basic` | `object` | — | Predefined conditions; exactly one of `basic`/`custom` (validated). |
| `custom` | `object` | — | `{expr = {expression, title?, description?, location?}}` — CEL expression. |

#### `basic` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `combining_function` | `string` | AND | `AND` or `OR` (validated). |
| `conditions` | `list(object)` | — | See the `conditions` object table. |

#### `conditions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ip_subnetworks` | `list(string)` | — | CIDR ranges the request must originate from (truncated blocks). |
| `required_access_levels` | `list(string)` | — | Access level resource names that must be satisfied, format `accessPolicies/{policy_id}/accessLevels/{short_name}` — wire from this module's `access_level_names` output. |
| `members` | `list(string)` | — | Allowed principals (`user:`, `serviceAccount:`); groups unsupported. |
| `negate` | `bool` | — | Invert the condition. |
| `regions` | `list(string)` | — | ISO 3166-1 alpha-2 country/region codes. |
| `device_policy` | `object` | — | `{require_screen_lock?, require_admin_approval?, require_corp_owned?, allowed_encryption_statuses?, allowed_device_management_levels?, os_constraints?}`. |
| `os_constraints` | `list(object)` | `[]` | `{os_type, minimum_version?, require_verified_chrome_os?}`; `os_type` in `OS_UNSPECIFIED`, `DESKTOP_MAC`, `DESKTOP_WINDOWS`, `DESKTOP_LINUX`, `DESKTOP_CHROME_OS`, `ANDROID`, `IOS` (validated). |
| `vpc_network_sources` | `list(object)` | `[]` | `{vpc_subnetwork = {network, vpc_ip_subnetworks?}}`; only IPv4 ranges. |

### `service_perimeters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `policy_key` | `string` | — | Key into `access_policies` (plan-fail if missing). |
| `name` | `string` | — | Short name: starts with a letter, letters/digits/underscores (validated); the module composes the full name. |
| `title` | `string` | — | Human-readable title, unique within the policy. |
| `description` | `string` | — | Free-text description. |
| `perimeter_type` | `string` | REGULAR | `PERIMETER_TYPE_REGULAR` or `PERIMETER_TYPE_BRIDGE` (validated); bridges only contain resources (validated). |
| `use_explicit_dry_run_spec` | `bool` | — | Required `true` when `spec` is set (validated). |
| `deletion_policy` | `string` | DELETE | `DELETE`, `ABANDON` or `PREVENT` (validated). |
| `status` | `object` | — | Enforced config; see the `status_spec` object table. |
| `spec` | `object` | — | Dry-run config, same shape as `status`. |

#### `status_spec` object (used by both `status` and `spec`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `resources` | `list(string)` | `[]` | `projects/{project_number}` entries inside the perimeter. |
| `access_levels` | `list(string)` | `[]` | Access level resource names `accessPolicies/{policy_id}/accessLevels/{short_name}` — wire from this module's `access_level_names` output. |
| `restricted_services` | `list(string)` | `[]` | Services restricted by the perimeter, e.g. `storage.googleapis.com`. |
| `vpc_accessible_services` | `object` | — | `{enable_restriction, allowed_services}`. |
| `ingress_policies` | `list(object)` | `[]` | `{title?, ingress_from?, ingress_to?}`; identities/source shape see below. |
| `egress_policies` | `list(object)` | `[]` | `{title?, egress_from?, egress_to?}`; egress_to adds `external_resources` (e.g. `s3://bucket/path`) and egress_from adds `source_restriction` (`SOURCE_RESTRICTION_ENABLED`|`DISABLED`). |

`ingress_from`/`egress_from`: `{identity_type?, identities?, sources[]?}` with
`identity_type` in `IDENTITY_TYPE_UNSPECIFIED`, `ANY_IDENTITY`,
`ANY_USER_ACCOUNT`, `ANY_SERVICE_ACCOUNT` (validated, on every entry).
`sources` entries: `{access_level? | resource? | psc_endpoint = {forwarding_rule?}}`.
`ingress_to`/`egress_to`: `{resources?|external_resources?, roles?, operations[]}` with
operations `{service_name?, method_selectors =[{method?|permission?}]}`.

### `perimeter_resources` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `perimeter_key` | `string` | — | Key into `service_perimeters` (plan-fail if missing). |
| `resource` | `string` | — | `projects/{project_number}`; the API takes project numbers, not IDs (validated). |

## Outputs

| Name | Description |
|---|---|
| `access_policy_names` | Map of policy key => numeric policy ID. |
| `access_policy_titles` | Map of policy key => title. |
| `access_level_names` | Map of access level key => full resource name. |
| `service_perimeter_names` | Map of perimeter key => full resource name. |
| `service_perimeter_etags` | Map of perimeter key => etag. |

## Example

Access policy + an access level + a regular perimeter restricting Storage with
an egress rule:

```hcl
module "vpc_sc" {
  source = "git::ssh://git@github.com/<org>/terraform-modules.git//modules/gcp/vpc-service-controls?ref=v1.25.0"

  access_policies = {
    "org" = {
      parent = "organizations/123456789"
      title  = "example-org-policy"
    }
  }

  access_levels = {
    "corp" = {
      policy_key = "org"
      name       = "corp_verified"
      title      = "Corp devices"
      basic = {
        conditions = [
          {
            device_policy = {
              require_screen_lock = true
              require_corp_owned  = true
              os_constraints      = [{ os_type = "DESKTOP_CHROME_OS" }]
            }
            regions = ["CH", "IT", "US"]
          }
        ]
      }
    }
  }

  service_perimeters = {
    "storage" = {
      policy_key      = "org"
      name            = "restrict_storage"
      title           = "Restrict Storage"
      perimeter_type  = "PERIMETER_TYPE_REGULAR"
      use_explicit_dry_run_spec = true
      status = {
        restricted_services = ["storage.googleapis.com"]
        access_levels       = [module.vpc_sc.access_level_names["corp"]]
        egress_policies = [
          {
            egress_from = {
              identity_type = "ANY_SERVICE_ACCOUNT"
            }
            egress_to = {
              resources = ["projects/987654321"]
              operations = [
                {
                  service_name = "storage.googleapis.com"
                  method_selectors = [
                    { method = "google.storage.objects.create" }
                  ]
                }
              ]
            }
          }
        ]
      }
      spec = {
        restricted_services = ["storage.googleapis.com"]
        access_levels       = [module.vpc_sc.access_level_names["corp"]]
      }
    }
  }
}
```

## Import

- `google_access_context_manager_access_policy` ← `{{name}}` (the numeric policy
  ID only, no `accessPolicies/` prefix)
- `google_access_context_manager_access_level` ← `{{name}}` (full resource name)
- `google_access_context_manager_service_perimeter` ← `{{name}}` (full resource name)
- `google_access_context_manager_service_perimeter_resource` ← `{{perimeter_name}}/{{resource}}`

## Notes

- User ADCs require `billing_project` and `user_project_override = true` in the
  provider config (`serviceusage.services.use` permission on the billing
  project); otherwise the ACM API returns 403.
- ACM resources live at org/folder scope; the provider-level `project` is
  irrelevant and not set by this module.
- When `perimeter_resources` adds a project to a perimeter managed by
  `service_perimeters`, the perimeter must add
  `lifecycle { ignore_changes = [status[0].resources] }` consumer-side — the two
  resource types fight over `status[0].resources` otherwise.
- Adding a `perimeter_resources` entry does not make the resource appear in the
  enforced perimeter until the dry-run `spec` is promoted; keep the two in sync
  deliberately.
