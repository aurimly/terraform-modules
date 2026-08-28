# gcp/service-account-iam

Map-keyed module for IAM on Google Cloud service accounts — granting
identities the ability to act as a service account, mint tokens for it, or
federate into it. Manages one of three IAM resource families, selected by
`mode` — member (default, non-authoritative), binding (authoritative per
role) or policy (authoritative whole-policy). Service accounts have no audit
config resource, unlike organization/folder/project IAM.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `service_accounts` | `map(string)` | — | Map of fully-qualified service account resource names (`projects/<project_id>/serviceAccounts/<email>`) keyed by an arbitrary identifier. |
| `mode` | `string` | `"member"` | One of `"member"`, `"binding"`, `"policy"`. Selects which resource family is created. |
| `members` | `map(object)` | `{}` | IAM grants, one resource per entry role. Only used when `mode = "member"`. |
| `bindings` | `map(object)` | `{}` | IAM bindings, one resource each. Only used when `mode = "binding"`. |
| `policies` | `map(object)` | `{}` | Whole-policy grants, one resource per service account, keyed by service account key. Only used when `mode = "policy"`. |

Plan-time validation: only the input matching `mode` may be set (the others
must be empty), every `service_account` reference must be a key of
`service_accounts`, each members entry needs at least one role and must not
repeat a role within the entry, members are checked against the
`user|serviceAccount|group|domain:<id>` (plus
`deleted:user|serviceAccount|group:<id>`) / `allUsers` /
`allAuthenticatedUsers` / federated `principal(Set|Group)://` formats, roles
must be `roles/...` or custom `projects/<project id>/roles/...` /
`organizations/<org id>/roles/...`, bindings must not repeat a role on the
same service account, and `policy_data` must be a JSON object string.

### `service_accounts`

Keys are arbitrary identifiers; values are the fully-qualified service
account resource names — the `service_accounts` output of the
[`gcp/service-account`](../service-account) module.

### `members` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service_account` | `string` | — | Key into `service_accounts`. |
| `member` | `string` | — | Identity to grant the roles to. |
| `roles` | `list(string)` | — | Roles to grant; at least one, no repeats within the entry. |
| `condition` | `object` | `null` | Optional IAM condition, applied to all of the entry's roles. |

### `bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service_account` | `string` | — | Key into `service_accounts`. |
| `role` | `string` | — | Role to grant. Only one binding per role per service account. |
| `members` | `list(string)` | — | Identities to grant the role to. |
| `condition` | `object` | `null` | Optional IAM condition. |

### `condition` object (members and bindings)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `title` | `string` | — | Condition title, e.g. `expires_after_2026_12_31`. |
| `description` | `string` | `null` | Optional longer description. |
| `expression` | `string` | — | CEL expression. |

### `policies` object

Keyed by service account key (one policy per service account).

| Attribute | Type | Default | Description |
|---|---|---|---|
| `policy_data` | `string` | — | JSON-encoded IAM policy (build it with a `google_iam_policy` data source or `jsonencode`). |

## Outputs

| Name | Description |
|---|---|
| `members` | Map of `"<entry key>/<role>"` (conditional grants append `"/<condition title>"`) => `{ service_account, role, member, etag }`, one entry per granted role. Empty unless `mode = "member"`. |
| `bindings` | Map of binding key => `{ service_account, role, members, etag }`. Empty unless `mode = "binding"`. |
| `policies` | Map of service account key => `{ service_account, etag }`. Empty unless `mode = "policy"`. |

The `service_account` field carries the fully-qualified resource name.

## Example

Member mode (default) — let a CI service account act as the app account, and
let a workload identity pool federate into it:

```hcl
service_accounts = {
  "app" = dependency.service_account.outputs.service_accounts["app"].name
}

members = {
  "ci-impersonation" = {
    service_account = "app"
    member          = "serviceAccount:ci-runner@my-project.iam.gserviceaccount.com"
    roles           = ["roles/iam.serviceAccountUser"]
  }
  "gha-federation" = {
    service_account = "app"
    member          = "principalSet://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/github/attribute.repository/my-org/my-repo"
    roles           = ["roles/iam.workloadIdentityUser"]
  }
  "ops-expiring-token-creator" = {
    service_account = "app"
    member          = "user:ops@example.com"
    roles           = ["roles/iam.serviceAccountTokenCreator"]
    condition = {
      title       = "expires_after_2026_12_31"
      description = "Expiring at midnight of 2026-12-31"
      expression  = "request.time < timestamp(\"2027-01-01T00:00:00Z\")"
    }
  }
}
```

Binding mode, authoritative per role:

```hcl
mode    = "binding"
members = {}
bindings = {
  "app-users" = {
    service_account = "app"
    role            = "roles/iam.serviceAccountUser"
    members         = ["group:app-users@example.com"]
  }
}
```

Policy mode, fully authoritative for one service account:

```hcl
mode = "policy"

policies = {
  "app" = {
    policy_data = jsonencode({
      bindings = [
        {
          role    = "roles/iam.serviceAccountUser"
          members = ["group:app-users@example.com"]
        },
      ]
    })
  }
}
```

## Notes

- IAM on a service account resource controls who can use **that account** —
  impersonate it (`roles/iam.serviceAccountUser`), mint OIDC/OAuth tokens for
  it (`roles/iam.serviceAccountTokenCreator`,
  `roles/iam.serviceAccountOpenIdTokenCreator`) or federate into it
  (`roles/iam.workloadIdentityUser`). It does not give the service account
  access to other resources; grant those roles on the target resources
  (project-iam etc.) using the account's `member` identity.
- Unlike the organization/folder/project IAM modules, `member` values here
  additionally accept federated principals (`principal://...`,
  `principalSet://...`, `principalGroup://...`) — workload identity
  federation grants use `principalSet://` members, which those modules'
  validation rejects.
- The policy resource is authoritative and replaces the entire service
  account policy; deleting it removes access for everyone unless something
  else re-grants it. Prefer member/binding mode, and import the existing
  policy before the first apply to see exactly what would be replaced. It
  cannot be combined with member or binding resources — the module rejects
  that combination at plan time.
- Binding resources are authoritative per role per service account: a role
  in `bindings` must not be granted on the same account by any other module.
  Bindings and members can coexist only if they do not grant the same role
  on the same account. Removing all members from a binding revokes the role
  for everyone.
- IAM conditions cannot be used with basic roles such as Owner, Editor or
  Viewer — the API rejects the binding with a 400.
- Terraform treats role plus condition content (`title` + `description` +
  `expression`) as the identity of a binding/member. Changing any part of a
  condition out-of-band makes Terraform see a different resource and
  replace it.
- Keys are arbitrary unique identifiers — several entries can grant the same
  role or member. One members entry's condition applies to all of its roles;
  a member needing different conditions per role gets one entry per
  condition.
- Each members entry expands to one resource per role, so the `members`
  output is keyed `"<entry key>/<role>"` (with the condition title appended
  when conditional) rather than by the input map keys — a deliberate
  deviation from the repo-wide "outputs keyed identically to inputs"
  convention.
- Two entries granting the same member the same role with the same condition
  on the same account create two resources for one grant — keep grants
  distinct.
- Custom roles may be project-scoped (any project) or org-scoped — both are
  grantable here.
- The runner needs `iam.serviceAccounts.getIamPolicy` and
  `iam.serviceAccounts.setIamPolicy` on each target account's project (e.g.
  via `roles/iam.serviceAccountAdmin`).
- Service accounts have no audit config IAM resource, so unlike the
  organization/folder/project IAM modules there is no audit config input.

## Import

- Member: `terraform import google_service_account_iam_member.member["<entry key>/<role>"] "projects/<project_id>/serviceAccounts/<email> <role> <member>"`
- Conditional member: append the condition title as a final space-delimited
  component, e.g. `"... <role> <member> <condition-title>"`, and carry the
  title in the address key too: `member["<entry key>/<role>/<condition title>"]`.
- Binding: `terraform import google_service_account_iam_binding.binding["<key>"] "projects/<project_id>/serviceAccounts/<email> <role>"`
- Conditional binding: append the condition title as a final space-delimited component.
- Policy: `terraform import google_service_account_iam_policy.policy["<service account key>"] "projects/<project_id>/serviceAccounts/<email>"`

Custom roles must be imported with their full name
(`projects/<project_id>/roles/<role_id>` or
`organizations/<org_id>/roles/<role_id>`).
