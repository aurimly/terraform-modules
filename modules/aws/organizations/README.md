# aws/organizations

Map-keyed module for AWS Organizations management-plane governance: the
organization itself, nested organizational units, policies (usually SCPs)
with attachments, and delegated administrators.

Account creation is out of scope — existing accounts are adopted by
reference (account IDs are literal attachment targets and delegated-admin
inputs). Bootstrapping accounts (`aws_organizations_account`) does not fit
declarative module management (immutable root email, invitation/handshake
flows); manage accounts consumer-side.

## Destroy semantics (read before using)

- Destroying the managed organization requires all member accounts removed
  or closed and every OU emptied — the API rejects the destroy otherwise.
- Migrating `feature_set` from `CONSOLIDATED_BILLING` to `ALL` shows a
  perpetual diff until all member invitations are accepted and the change
  is finalized in the console (provider warning; the invitations must be
  accepted out-of-band).
- Policies are kept in the org on destroy when `skip_destroy = true`;
  attachments likewise (`skip_destroy`, see below). AWS requires at least
  one attached SCP on the root — keep the last attachment with
  `skip_destroy` or the apply fails.
- Delegated administrators are unregistered on destroy.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `organization` | `object` | `null` | Organization settings; `null` runs the module attach-only against an org managed elsewhere. |
| `ous` | `map(object)` | `{}` | Organizational units; map keys must not contain `.` (validated). |
| `policies` | `map(object)` | `{}` | Organization policies from JSON content documents. |
| `policy_attachments` | `map(object)` | `{}` | Policy-to-target attachments; map keys must not contain `.` (validated). |
| `delegated_administrators` | `map(object)` | `{}` | Delegated administrators (existing accounts). |

Plan-time validation: OU names (1–200 chars), parents (`"root"`, a sibling
key, or a literal `r-`/`ou-` ID), policy names (1–128 chars), JSON content,
policy types, one-of `policy_key`/`policy_id`, non-empty target sets,
12-digit account IDs, unique (policy, target) pairs, and the
management-requires-org rules (`"root"` parents and `target_root` need
`organization` set).

### `organization` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `aws_service_access_principals` | `list(string)` | `[]` | Trusted service principals, e.g. `cloudtrail.amazonaws.com`. Note: enabling `GUARDDUTY_POLICY` requires `guardduty.amazonaws.com`, `INSPECTOR_POLICY` requires `inspector2.amazonaws.com`, and `SECURITYHUB_POLICY` requires `securityhub.amazonaws.com` here. Some services additionally need enabling via their own console/API. |
| `enabled_policy_types` | `list(string)` | `[]` | Policy types enabled on the root (validated set; enabling `GUARDDUTY_POLICY`/`INSPECTOR_POLICY`/`SECURITYHUB_POLICY` requires the matching service principal above). |
| `feature_set` | `string` | `ALL` | `ALL` or `CONSOLIDATED_BILLING`. Policy types require `ALL` (validated). Migrating `CONSOLIDATED_BILLING` → `ALL` needs out-of-band invitation acceptance (see destroy semantics). |

Valid `enabled_policy_types`/`type` values: `AISERVICES_OPT_OUT_POLICY`,
`BACKUP_POLICY`, `BEDROCK_POLICY`, `CHATBOT_POLICY`, `DECLARATIVE_POLICY_EC2`,
`GUARDDUTY_POLICY`, `INSPECTOR_POLICY`, `NETWORK_SECURITY_DIRECTOR_POLICY`,
`RESOURCE_CONTROL_POLICY`, `S3_POLICY`, `SECURITYHUB_POLICY`,
`SERVICE_CONTROL_POLICY`, `TAG_POLICY`, `UPGRADE_ROLLOUT_POLICY`.

### `ous` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | OU name, 1–200 characters (validated). |
| `parent` | `string` | `root` | `"root"` (managed root), a key of the `ous` map (nesting), or a literal `r-<id>`/`ou-<id>-<id>` ID (validated). Managed nesting is two levels deep (validated) — deeper trees go consumer-side, or into a separate module instance whose parent IDs are literal; parent cycles are rejected by the same validation. |
| `tags` | `map(string)` | `{}` | Tags. |

### `policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name, 1–128 characters (validated). |
| `content` | `string` | — | JSON policy document (validated); build with `jsonencode`. |
| `description` | `string` | `null` | Description. |
| `type` | `string` | `SERVICE_CONTROL_POLICY` | Any valid policy type (see list above). When the org is managed by this module, the type must be enabled on it (validated). |
| `skip_destroy` | `bool` | `false` | Detach instead of delete on destroy (AWS requires ≥1 attached SCP — see destroy semantics). |
| `tags` | `map(string)` | `{}` | Tags. |

### `policy_attachments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `policy_key` | `string` | `null` | Key of the `policies` map (in-module policy). Exactly one of `policy_key`/`policy_id` (validated). |
| `policy_id` | `string` | `null` | Literal policy ID (`p-...`) — AWS-managed policies (e.g. `FullAWSAccess`) or policies created consumer-side. Exactly one of the two (validated). |
| `skip_destroy` | `bool` | `false` | Keep the attachment (detached) on destroy. |
| `target_root` | `bool` | `false` | Attach to the managed root (requires `organization`, validated). |
| `target_ous` | `list(string)` | `[]` | Keys of the `ous` map to attach to (validated). |
| `target_account_ids` | `list(string)` | `[]` | Existing account IDs to attach to (12 digits, validated). |

Each (policy, target) pair becomes one attachment resource; pairs must be
unique across entries (validated).

### `delegated_administrators` object

| Attribute | Type | Description |
|---|---|---|
| `account_id` | `string` | Existing account ID (12 digits, validated). |
| `service_principal` | `string` | Service principal, e.g. `guardduty.amazonaws.com` (validated). The service must have trusted access enabled in the org first (enabling it via `organization.aws_service_access_principals` is not always sufficient — some services require their own console/API enablement). |

## Outputs

| Name | Description |
|---|---|
| `organization_id` / `organization_arn` / `organization_master_account_id` | Organization identity; `null` in attach-only mode. |
| `root_id` | Root ID (`r-...`); `null` in attach-only mode. |
| `organization_account_names` | Map of account ID => name for all org accounts (read-only adoption view); `null` in attach-only mode. |
| `ou_ids` / `ou_arns` | OU key => ID (`ou-...`, also the import ID) / ARN. |
| `policy_ids` / `policy_arns` | Policy key => ID (`p-...`, also the import ID) / ARN. |
| `attachment_policy_ids` / `attachment_target_ids` | `"attachment-key.target-key"` => policy ID / target ID. |
| `delegated_administrator_arns` | Delegated-administrator key => delegation ARN. |

## Example

```hcl
organization = {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
  ]
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
  feature_set          = "ALL"
}

ous = {
  "workloads" = { name = "workloads" }
  "sandbox"   = { parent = "workloads", name = "sandbox" }
}

policies = {
  "deny-region" = {
    name = "deny-region"
    content = jsonencode({
      Version   = "2012-10-17"
      Statement = [{ Sid = "DenyOtherRegion", Effect = "Deny", Action = "*", Resource = "*", Condition = { StringNotEquals = { "aws:RequestedRegion" = ["eu-central-1"] } } }]
    })
  }
}

policy_attachments = {
  "deny-region-root"    = { policy_key = "deny-region", target_root = true }
  "deny-region-sandbox" = { policy_key = "deny-region", target_ous = ["sandbox"] }
}

delegated_administrators = {
  "security" = { account_id = "123456789012", service_principal = "guardduty.amazonaws.com" }
}
```

Attach-only variant (org managed elsewhere, literal IDs):

```hcl
ous = {
  "shared" = { parent = "ou-8nkmt7tq1-example001", name = "shared" }
}

policy_attachments = {
  "fullawsaccess-sandbox" = {
    policy_id          = "p-FullAWSAccess"
    target_account_ids = ["123456789012"]
  }
}
```

Adopting an existing org: the provider stores `aws_service_access_principals`
and `enabled_policy_types` — pass the org's current values explicitly in
`organization`, otherwise the empty defaults plan to disable them.

## Notes

- Attach-only mode (`organization = null`): only OUs (with literal parents),
  policies (consumer must enable the policy type on the org), attachments to
  literal OU/account IDs, and delegated administrators work — root wiring
  requires the managed org (validated).
- Policy types must be enabled before attachment; when the org is managed
  here this is validated, otherwise the consumer enables them (and the
  GuardDuty/Inspector/Security Hub service principals — see
  `organization` above).
- Attachment resources take a single `target_id`, so each (policy, target)
  pair is one resource keyed `"attachment-key.target-key"`; the import ID is
  `"<target_id>:<policy_id>"` — note the reversed order vs the output key.
- Very large organizations hitting `aws_organizations_organization` read
  throttling should manage the org resource consumer-side and run this
  module attach-only.
- Pairing: feed `ou_ids`/`root_id` into consumer-side account-vending or IAM
  modules, and register audit trails with `aws/cloudtrail`
  (`is_organization_trail` from the management account).

## Import

`aws_organizations_organization` ← organization ID (`o-...`).
`aws_organizations_organizational_unit` ← OU ID (`ou-...`).
`aws_organizations_policy` ← policy ID (`p-...`).
`aws_organizations_policy_attachment` ← `"<target_id>:<policy_id>"`.
`aws_organizations_delegated_administrator` ← `"<account_id>/<service_principal>"`.
