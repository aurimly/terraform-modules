# aws/iam-group

Map-keyed module for AWS IAM groups. Managed policy attachments and inline
policies are optional. Group membership is intentionally not part of this
module — it is managed on the user side (non-exclusively) by the
`aws/iam-user` module via `aws_iam_user_group_membership`, which avoids the
self-conflict of the exhaustively-membership-managed
`aws_iam_group_membership`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `groups` | `map(object)` | `{}` | Map of groups keyed by an arbitrary unique identifier. |

### `groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Group name; at most 128 characters, letters/digits/`+=,.@_-`. Validated client-side. Unique account-wide regardless of `path`; not distinguished by case, so `ADMINS` and `admins` cannot both exist. Renames in place (no replacement). |
| `path` | `string` | `/` | IAM path, e.g. `/users/`. Moving to a new path happens in place (no replacement). |
| `managed_policy_arns` | `list(string)` | `[]` | ARNs of managed policies to attach as separate `aws_iam_group_policy_attachment` resources. |
| `inline_policies` | `map(object)` | `{}` | Inline policies keyed by an arbitrary identifier: `name` (1-128 characters) and `policy_json` (a valid JSON policy document; both validated client-side). Created as separate `aws_iam_group_policy` resources. |

Map keys (`groups` and `inline_policies`) must not contain `.` — resource
addresses are composed as `<group>.<policy>` — validated client-side.

IAM groups do not support tags; no tagging input exists.

## Outputs

`group_names` — map of group key => group name.
`group_arns` — map of group key => group ARN.
`group_unique_ids` — map of group key => group unique ID (`AGPA...`).

## Example

```hcl
groups = {
  "deployers" = {
    name                = "example-deployers"
    path                = "/ci/"
    managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  }
  "log-watchers" = {
    name = "example-log-watchers"
    inline_policies = {
      "read-logs" = {
        name        = "example-read-logs"
        policy_json = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Effect   = "Allow"
            Action   = ["logs:GetLogEvents"]
            Resource = "arn:aws:logs:eu-central-1:123456789012:log-group:/example/app:*"
          }]
        })
      }
    }
  }
}
```

The `group_names` output feeds the `groups` attribute of the `aws/iam-user`
module, where each user declares the groups it belongs to.

## Notes

- Map keys are arbitrary unique identifiers that decouple the key set from
  the names — but group names themselves must be unique account-wide
  regardless of `path` (AWS friendly names are unique within the account).
- Users added to a group here via `aws/iam-user` (or out of band via the
  console) do not conflict with this module; membership is never declared on
  the group side.
- Managed policy attachments and inline policies are separate resources
  addressed as `<group>.<arn>` / `<group>.<policy key>`; removing an entry
  from the input destroys exactly that attachment/policy, not the group.

## Import

`aws_iam_group` — group name.
`aws_iam_group_policy_attachment` — `group_name/policy_arn` (slash-separated).
`aws_iam_group_policy` — `group_name:policy_name` (colon-separated).
