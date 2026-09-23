# aws/iam-role

Map-keyed module for AWS IAM roles. The trust (assume-role) policy is built
inline from a principal type, identifiers, and optional conditions, or passed
in as a raw JSON policy document — exactly one of the two per role. Managed
policy attachments, inline policies, and an instance profile are optional.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `roles` | `map(object)` | `{}` | Map of roles keyed by an arbitrary unique identifier; each entry also carries its `inline_policies` map. |

### `roles` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Role name; at most 64 characters, letters/digits/`+=,.@_-`. Validated client-side. Immutable; changing forces replacement. The instance profile (if enabled) reuses this name. |
| `path` | `string` | — | IAM path, e.g. `/service/`. Immutable; changing forces replacement. Also applied to the instance profile. |
| `description` | `string` | — | Role description. |
| `max_session_duration` | `number` | `3600` | Maximum session duration (seconds) for assumed-role sessions, 3600-43200. Validated client-side. |
| `permissions_boundary` | `string` | — | ARN of a managed policy used as the permissions boundary. |
| `force_detach_policies` | `bool` | `false` | Detach attached policies on destroy instead of failing with `DeleteConflict` when a policy is still attached (typically an out-of-band attachment). |
| `trust_policy_json` | `string` | — | Raw assume-role policy document as JSON. Exactly one of `trust_policy_json` or `trust` per role (validated client-side). |
| `trust` | `object` | — | Inline trust policy builder — see table below. Exactly one of `trust_policy_json` or `trust` per role (validated client-side). |
| `managed_policy_arns` | `list(string)` | `[]` | ARNs of managed policies to attach as separate `aws_iam_role_policy_attachment` resources. |
| `inline_policies` | `map(object)` | `{}` | Inline policies keyed by an arbitrary identifier: `name` (1-128 characters) and `policy_json` (a valid JSON policy document; both validated client-side). Created as separate `aws_iam_role_policy` resources. |
| `create_instance_profile` | `bool` | `false` | Also create an `aws_iam_instance_profile` named after the role, for EC2 instance profiles. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `trust` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `principal_type` | `string` | — | Principal block type: `AWS`, `Service`, `Federated`, `CanonicalUser` or `*`. Validated client-side. |
| `identifiers` | `list(string)` | — | Principal identifiers, e.g. `["ec2.amazonaws.com"]` for `Service` or account IDs / role ARNs for `AWS`. Must be non-empty. |
| `conditions` | `map(object)` | `{}` | Assume-role conditions keyed by an arbitrary identifier: `test` (condition operator, e.g. `StringEquals`), `variable` (condition key, e.g. `aws:SourceArn`), `values` (list of strings). |

Values inside `conditions` are evaluated by Terraform's templating first —
use `&{aws:username}`-style escaping (double-ampersand) for AWS policy
variables so `${...}` is not interpreted as Terraform interpolation.

Map keys (`roles` and `inline_policies`) must not contain `.` — resource
addresses are composed as `<role>.<policy>` — validated client-side.

## Outputs

`role_names` — map of role key => role name.
`role_arns` — map of role key => role ARN.
`role_unique_ids` — map of role key => role unique ID (`AROA...`), usable as a principal in other policies.
`instance_profile_names` — map of role key => instance profile name, `null` for roles without one. Covers all role keys.
`instance_profile_arns` — map of role key => instance profile ARN, `null` for roles without one. Covers all role keys.

## Example

```hcl
roles = {
  "ec2-app" = {
    name                    = "example-ec2-app"
    description             = "Example application server role"
    create_instance_profile = true
    trust = {
      principal_type = "Service"
      identifiers    = ["ec2.amazonaws.com"]
      conditions = {
        "source-arn" = {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = ["123456789012"]
        }
      }
    }
    managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
    inline_policies = {
      "s3-logs" = {
        name        = "example-s3-logs"
        policy_json = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Effect   = "Allow"
            Action   = ["s3:PutObject"]
            Resource = "arn:aws:s3:::example-bucket/*"
          }]
        })
      }
    }
  }
  "ci-deployer" = {
    name              = "example-ci-deployer"
    trust_policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::123456789012:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "sts:ExternalId" = "example-external-id" }
        }
      }]
    })
    managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  }
}
```

The `instance_profile_arns["ec2-app"]` output feeds the `iam_instance_profile`
attribute of the `aws/ec2-instance` module.

## Notes

- Map keys are arbitrary unique identifiers, not resource names — multiple
  roles can share a `name` (e.g. identical role names under different
  `path`s), so the key disambiguates them.
- The trust policy is a single statement with `Action = "sts:AssumeRole"`.
  Policies needing multiple statements or not-allow effects should use
  `trust_policy_json` instead.
- Managed policy attachments and inline policies are separate resources
  addressed as `<role>.<arn>` / `<role>.<policy key>`; removing an entry
  from the input destroys exactly that attachment/policy, not the role.
- The instance profile name is the role name, so the role `name` character
  set and 64-character limit also apply to it — enforced client-side.
- `name` and `path` force role replacement if changed; everything else,
  including the trust policy, updates in place.

## Import

`aws_iam_role` — role name; roles created under a non-default `path` may
need the path-qualified form (`path/name`) depending on the provider
version.
`aws_iam_role_policy_attachment` — `role_name/policy_arn` (slash-separated).
`aws_iam_role_policy` — `role_name:policy_name` (colon-separated).
`aws_iam_instance_profile` — instance profile name.
