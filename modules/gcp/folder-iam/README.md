# gcp/folder-iam

Map-keyed module for IAM on a Google Cloud folder. Manages one of three IAM
resource families, selected by `mode` — member (default, non-authoritative),
binding (authoritative per role) or policy (authoritative whole-policy) — plus
optional audit log configuration.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `folder_id` | `string` | — | Bare numeric folder ID (e.g. `"123456789012"`). |
| `mode` | `string` | `"member"` | One of `"member"`, `"binding"`, `"policy"`. Selects which resource family is created. |
| `members` | `map(object)` | `{}` | IAM grants, one resource per entry role. Only used when `mode = "member"`. |
| `bindings` | `map(object)` | `{}` | IAM bindings, one resource each. Only used when `mode = "binding"`. |
| `policy_data` | `string` | `null` | JSON-encoded IAM policy, one resource. Only used when `mode = "policy"`. |
| `audit_configs` | `map(object)` | `{}` | Audit log configurations, one resource per service. |
| `audit_config_enabled` | `bool` | `true` | Master toggle for the audit config resources. When false, `audit_configs` must be empty. |

Plan-time validation: only the input matching `mode` may be set (the others
must be empty/null), each members entry needs at least one role and must not
repeat a role within the entry, members are checked against the
`user|serviceAccount|group|domain:<id>` (plus `deleted:user|serviceAccount|group:<id>`)
/ `allUsers` / `allAuthenticatedUsers` formats, roles must be `roles/...` or
custom `organizations/<org id>/roles/...`, bindings must not repeat a role
and audit configs must not repeat a service.

### `members` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `member` | `string` | — | Identity to grant the roles to. |
| `roles` | `list(string)` | — | Roles to grant; at least one, no repeats within the entry. |
| `condition` | `object` | `null` | Optional IAM condition, applied to all of the entry's roles. |

### `bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | Role to grant. Only one binding per role. |
| `members` | `list(string)` | — | Identities to grant the role to. |
| `condition` | `object` | `null` | Optional IAM condition. |

### `condition` object (members and bindings)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `title` | `string` | — | Condition title, e.g. `expires_after_2026_12_31`. |
| `description` | `string` | `null` | Optional longer description. |
| `expression` | `string` | — | CEL expression. |

### `audit_configs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service` | `string` | — | Service to enable audit logging for, e.g. `allServices` or `iam.googleapis.com`. |
| `audit_log_configs` | `list(object)` | — | One entry per log type; at least one required. |

### `audit_log_configs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `log_type` | `string` | — | One of `DATA_READ`, `DATA_WRITE`, `ADMIN_READ`. |
| `exempted_members` | `list(string)` | `[]` | Identities exempt from logging for this log type. |

## Outputs

| Name | Description |
|---|---|
| `members` | Map of `"<entry key>/<role>"` (conditional grants append `"/<condition title>"`) => `{ folder, role, member, etag }`, one entry per granted role. Empty unless `mode = "member"`. |
| `bindings` | Map of binding key => `{ folder, role, members, etag }`. Empty unless `mode = "binding"`. |
| `policy` | `{ folder, etag }` of the folder policy, or `null` unless `mode = "policy"`. |
| `audit_configs` | Map of audit config key => `{ folder, service, etag }`. Empty when `audit_config_enabled = false`. |

## Example

Member mode (default) with multiple roles for one identity plus audit logging:

```hcl
folder_id = "123456789012"

members = {
  "data-eng" = {
    member = "group:data-eng@example.com"
    roles = [
      "roles/bigquery.dataViewer",
      "roles/compute.viewer",
    ]
  }
  "ops-expiring-admin" = {
    member = "user:ops@example.com"
    roles  = ["roles/resourcemanager.projectIamAdmin"]
    condition = {
      title       = "expires_after_2026_12_31"
      description = "Expiring at midnight of 2026-12-31"
      expression  = "request.time < timestamp(\"2027-01-01T00:00:00Z\")"
    }
  }
}

audit_configs = {
  "all-services" = {
    service = "allServices"
    audit_log_configs = [
      { log_type = "ADMIN_READ" },
      {
        log_type         = "DATA_READ"
        exempted_members = ["user:auditor@example.com"]
      },
    ]
  }
}
```

Binding mode, authoritative per role:

```hcl
mode    = "binding"
members = {}
bindings = {
  "viewers" = {
    role = "roles/viewer"
    members = [
      "group:platform@example.com",
      "user:auditor@example.com",
    ]
  }
}
```

Policy mode, fully authoritative:

```hcl
mode = "policy"
policy_data = jsonencode({
  bindings = [
    {
      role    = "roles/viewer"
      members = ["group:platform@example.com"]
    },
  ]
})
audit_config_enabled = false
```

## Notes

- Folder IAM is inherited down the hierarchy: every grant here applies to all
  subfolders and projects beneath the folder. Check what already cascades
  before adding an authoritative binding or policy.
- The policy resource is authoritative and replaces the entire folder policy;
  deleting it removes access for anyone who does not hold equivalent roles on
  a parent folder or the organization. Prefer member/binding mode unless the
  whole policy is managed here, and study the plan closely when first adopting
  it; importing the existing policy before the first apply shows exactly what
  would be replaced. It cannot be combined with member, binding or audit
  config resources — the module rejects that combination at plan time. (The
  provider's own `policy_data` description claims the policy "will be merged
  with any existing policy" — that is a doc error; the resource replaces the
  policy.)
- Binding resources are authoritative per role: a role in `bindings` must
  not be granted by any other module. Bindings and members can coexist only
  if they do not grant the same role. A binding with `roles/owner` whose
  members you can't authenticate as locks you out.
- IAM conditions cannot be used with basic roles such as Owner, Editor or
  Viewer — the API rejects the binding with a 400.
- Audit configs are authoritative per service. If two audit configs cover
  `allServices` and a specific service, the union applies: all `log_type`s
  are enabled and all `exempted_members` are exempted.
- Terraform treats role plus condition content (`title` + `description` +
  `expression`) as the identity of a binding/member. Changing any part of a
  condition out-of-band makes Terraform see a different resource and
  replace it.
- Keys are arbitrary unique identifiers, not resource names — e.g. several
  member entries can share the same member or role.
- One members entry's condition applies to all of its roles. A member needing
  different conditions per role gets one entry per condition, keyed
  arbitrarily.
- Each members entry expands to one resource per role, so the `members`
  output is keyed `"<entry key>/<role>"` (with the condition title appended
  when conditional) rather than by the input map keys — a deliberate
  deviation from the repo-wide "outputs keyed identically to inputs"
  convention.
- Two entries granting the same member the same role with the same condition
  create two resources for one grant — keep grants distinct.
- Custom roles live at the organization level, not on folders; custom roles
  granted here come from the org that owns the folder.
- The outputs' `folder` field carries the full resource name
  (`folders/<id>`) as the provider stores it, while the `folder_id` input
  takes the bare numeric ID.
- The runner needs `roles/resourcemanager.folderAdmin`,
  `roles/resourcemanager.folderIamAdmin` or equivalent
  (`resourcemanager.folders.setIamPolicy`) on the folder.

## Import

- Member: `terraform import google_folder_iam_member.member["<entry key>/<role>"] "<folders/N or N> <role> <member>"`
- Conditional member: the import ID carries four components
  `"<folder> <role> <member> <condition title>"` and the address key carries
  the title too: `member["<entry key>/<role>/<condition title>"]`.
- Binding: `terraform import google_folder_iam_binding.binding["<key>"] "<folders/N or N> <role>"`
- Conditional binding: append the condition title as a final
  space-delimited component, e.g. `"<folder> <role> <condition-title>"`.
- Policy: `terraform import google_folder_iam_policy.policy[0] "<folders/N or N>"`
- Audit config: `terraform import google_folder_iam_audit_config.audit_config["<key>"] "<folders/N or N> <service>"`

Custom roles must be imported with their full name
(`organizations/<org_id>/roles/<role_id>`).

Caution: several import examples on the provider's registry page use a
singular `folder/<id>` prefix that does not round-trip — use
`folders/<id>` or the bare numeric ID.
