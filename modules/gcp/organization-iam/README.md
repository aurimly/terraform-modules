# gcp/organization-iam

Map-keyed module for IAM on a Google Cloud organization. Manages one of
three IAM resource families, selected by `mode` — member (default,
non-authoritative), binding (authoritative per role) or policy
(authoritative whole-policy) — plus optional audit log configuration.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `organization_id` | `string` | — | Bare numeric organization ID (e.g. `"123456789012"`). |
| `mode` | `string` | `"member"` | One of `"member"`, `"binding"`, `"policy"`. Selects which resource family is created. |
| `members` | `map(object)` | `{}` | IAM members, one resource each. Only used when `mode = "member"`. |
| `bindings` | `map(object)` | `{}` | IAM bindings, one resource each. Only used when `mode = "binding"`. |
| `policy_data` | `string` | `null` | JSON-encoded IAM policy, one resource. Only used when `mode = "policy"`. |
| `audit_configs` | `map(object)` | `{}` | Audit log configurations, one resource per service. |
| `audit_config_enabled` | `bool` | `true` | Master toggle for the audit config resources. When false, `audit_configs` must be empty. |

Plan-time validation: only the input matching `mode` may be set (the others
must be empty/null), members are checked against the
`user|serviceAccount|group|domain:<id>` (plus `deleted:user|serviceAccount|group:<id>`)
/ `allUsers` / `allAuthenticatedUsers` formats, roles must be `roles/...` or
custom `organizations/<organization_id>/roles/...`, bindings must not repeat
a role and audit configs must not repeat a service.

### `members` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | Role to grant. |
| `member` | `string` | — | Identity to grant the role to. |
| `condition` | `object` | `null` | Optional IAM condition. |

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
| `members` | Map of member key => `{ org_id, role, member, etag }`. Empty unless `mode = "member"`. |
| `bindings` | Map of binding key => `{ org_id, role, members, etag }`. Empty unless `mode = "binding"`. |
| `policy` | `{ org_id, etag }` of the organization policy, or `null` unless `mode = "policy"`. |
| `audit_configs` | Map of audit config key => `{ org_id, service, etag }`. Empty when `audit_config_enabled = false`. |

## Example

Member mode (default) with two roles for one identity plus audit logging:

```hcl
organization_id = "123456789012"

members = {
  "data-eng-viewer" = {
    role   = "roles/bigquery.dataViewer"
    member = "group:data-eng@example.com"
  }
  "data-eng-compute" = {
    role   = "roles/compute.viewer"
    member = "group:data-eng@example.com"
  }
  "ops-expiring-admin" = {
    role   = "roles/resourcemanager.projectIamAdmin"
    member = "user:ops@example.com"
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

- The policy resource is authoritative and replaces the entire organization
  policy. New organizations carry default policies that would be overwritten;
  misusing it can remove your own access (only Google Support can restore
  it). Prefer member/binding mode unless the whole policy is managed here,
  and study the plan closely when first adopting it. It cannot be combined
  with member, binding or audit config resources — the module rejects that
  combination at plan time. (The provider's own `policy_data` description
  claims the policy "will be merged with any existing policy" — that is a
  doc error; the resource replaces the policy.)
- Binding resources are authoritative per role: a role in `bindings` must
  not be granted by any other module. Bindings and members can coexist only
  if they do not grant the same role. A binding with `roles/owner` whose
  members you can't authenticate as locks you out.
- Audit configs are authoritative per service. If two audit configs cover
  `allServices` and a specific service, the union applies: all `log_type`s
  are enabled and all `exempted_members` are exempted.
- Terraform treats role plus condition content (`title` + `description` +
  `expression`) as the identity of a binding/member. Changing any part of a
  condition out-of-band makes Terraform see a different resource and
  replace it.
- Keys are arbitrary unique identifiers, not resource names — e.g. several
  member entries can share the same member or role.
- The runner needs `roles/resourcemanager.organizationAdmin` or equivalent
  on the organization.

## Import

- Member: `terraform import google_organization_iam_member.member["<key>"] "<org_id> <role> <member>"`
- Binding: `terraform import google_organization_iam_binding.binding["<key>"] "<org_id> <role>"`
- Conditional binding/member: append the condition title as a final
  space-delimited component, e.g. `"<org_id> <role> condition-title"`.
- Policy: `terraform import google_organization_iam_policy.policy[0] "<org_id>"`
- Audit config: `terraform import google_organization_iam_audit_config.audit_config["<key>"] "<org_id> <service>"`

Custom roles must be imported with their full name
(`organizations/<org_id>/roles/<role_id>`).
