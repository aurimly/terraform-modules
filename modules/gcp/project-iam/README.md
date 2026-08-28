# gcp/project-iam

Map-keyed module for IAM on a Google Cloud project. Manages one of three IAM
resource families, selected by `mode` — member (default, non-authoritative),
binding (authoritative per role) or policy (authoritative whole-policy) — plus
optional audit log configuration.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | Project ID (e.g. `"my-project"`). Not inferred from the provider default. |
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
custom `projects/<project id>/roles/...` / `organizations/<org id>/roles/...`,
bindings must not repeat a role and audit configs must not repeat a service.

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
| `members` | Map of `"<entry key>/<role>"` (conditional grants append `"/<condition title>"`) => `{ project, role, member, etag }`, one entry per granted role. Empty unless `mode = "member"`. |
| `bindings` | Map of binding key => `{ project, role, members, etag }`. Empty unless `mode = "binding"`. |
| `policy` | `{ project, etag }` of the project policy, or `null` unless `mode = "policy"`. |
| `audit_configs` | Map of audit config key => `{ project, service, etag }`. Empty when `audit_config_enabled = false`. |

## Example

Member mode (default) with multiple roles for one identity plus audit logging:

```hcl
project_id = "my-project"

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
    roles  = ["roles/iam.serviceAccountUser"]
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

- Project IAM is the leaf of the hierarchy: grants here apply only to this
  project's resources, while organization- and folder-level grants cascade
  in. Check what already cascades before adding an authoritative binding or
  policy.
- The policy resource is authoritative and replaces the entire project
  policy; deleting it removes access for anyone without organization-level
  access to the project. Prefer member/binding mode unless the whole policy
  is managed here, and study the plan closely when first adopting it;
  importing the existing policy before the first apply shows exactly what
  would be replaced. It cannot be combined with member, binding or audit
  config resources — the module rejects that combination at plan time. (The
  provider's own `policy_data` description claims the policy "will be merged
  with any existing policy" — that is a doc error; the same page's intro
  says the resource replaces any existing policy.)
- Binding resources are authoritative per role: a role in `bindings` must
  not be granted by any other module. Bindings and members can coexist only
  if they do not grant the same role. A binding with `roles/owner` whose
  members you can't authenticate as locks you out.
- IAM conditions cannot be used with basic roles such as Owner, Editor or
  Viewer — the API rejects the binding with a 400.
- Google APIs can recreate grants to their own service agents after they are
  removed; removing such members with member mode may not stick.
- Audit configs are authoritative per service. If two audit configs cover
  `allServices` and a specific service, the union applies: all `log_type`s
  are enabled and all `exempted_members` are exempted.
- Terraform treats role plus condition content (`title` + `description` +
  `expression`) as the identity of a binding/member. Changing any part of a
  condition out-of-band makes Terraform see a different resource and
  replace it.
- Keys are arbitrary unique identifiers, not resource names — e.g. several
  member entries can share the same member or role. Keep keys free of `/`:
  member grants are keyed `"<entry key>/<role>"` (plus `"/<condition title>"`
  when conditional), and a `/` inside an entry key could collide with another
  entry's key/role pair — surfacing as a duplicate-key plan error.
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
- Project-scoped custom roles live on this project
  (`projects/<project_id>/roles/...`), org-scoped custom roles on the owning
  organization — both are grantable here.
- The outputs' `project` field carries the project ID the provider stores,
  identical to the `project_id` input.
- The runner needs `roles/resourcemanager.projectIamAdmin` or equivalent
  (`resourcemanager.projects.setIamPolicy`) on the project.

## Import

- Member: `terraform import google_project_iam_member.member["<entry key>/<role>"] "<project_id> <role> <member>"`
- Conditional member: the provider accepts a fourth space-delimited
  component, the condition title
  (`"<project_id> <role> <member> <condition title>"`), and the address key
  carries the title too: `member["<entry key>/<role>/<condition title>"]`.
- Binding: `terraform import google_project_iam_binding.binding["<key>"] "<project_id> <role>"`
- Conditional binding: append the condition title as a final
  space-delimited component, e.g. `"<project_id> <role> <condition-title>"`.
- Policy: `terraform import google_project_iam_policy.policy[0] "<project_id>"`
- Audit config: `terraform import google_project_iam_audit_config.audit_config["<key>"] "<project_id> <service>"`

Custom roles must be imported with their full name
(`projects/<project_id>/roles/<role_id>` or
`organizations/<org_id>/roles/<role_id>`).

Caution: the provider's binding import section says the import ID "contains
the `org_id` and role" — that is a copy-paste from the organization page;
the correct first component is the project id.
