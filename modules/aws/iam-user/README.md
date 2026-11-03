# aws/iam-user

Map-keyed module for AWS IAM users. Group memberships, managed policy
attachments, inline policies, and a single access key are optional.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `users` | `map(object)` | `{}` | Map of users keyed by an arbitrary unique identifier. |

### `users` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | User name; at most 64 characters, letters/digits/`+=,.@_-`. Validated client-side. Unique account-wide regardless of `path`; not distinguished by case, so `TESTUSER` and `testuser` cannot both exist. Renames in place (no replacement). |
| `path` | `string` | `/` | IAM path, e.g. `/users/`. Moving to a new path happens in place (no replacement). |
| `permissions_boundary` | `string` | — | ARN of a managed policy used as the permissions boundary. |
| `force_destroy` | `bool` | `false` | Destroy the user even if it has non-module IAM access keys, login profile, or MFA devices. Without it those objects cause a `DeleteConflict` on destroy. Must have been applied beforehand to take effect on a later destroy. |
| `managed_policy_arns` | `list(string)` | `[]` | ARNs of managed policies to attach as separate `aws_iam_user_policy_attachment` resources. |
| `inline_policies` | `map(object)` | `{}` | Inline policies keyed by an arbitrary identifier: `name` (1-128 characters) and `policy_json` (a valid JSON policy document; both validated client-side). Created as separate `aws_iam_user_policy` resources. |
| `groups` | `list(string)` | `[]` | Group names to add the user to, managed non-exclusively via `aws_iam_user_group_membership` — see the `aws/iam-group` module for the group side. |
| `access_key` | `object` | — | Creates exactly one `aws_iam_access_key` when set — see table below (AWS allows at most two keys per user; additional ones are out of scope). |
| `tags` | `map(string)` | `{}` | Tags; the module injects `Name = name` on top (overriding a consumer-supplied `Name`), consumer tags win on any other key. |

### `access_key` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `pgp_key` | `string` | `null` | Base-64-encoded PGP public key (or `keybase:username`) for the `encrypted_secret` output. With `pgp_key` set, the raw secret is not returned by the module. Without it, the secret access key is stored in plaintext in the Terraform state file. |
| `status` | `string` | `Active` | `Active` or `Inactive`. |

Map keys (`users` and `inline_policies`) must not contain `.` — resource
addresses are composed as `<user>.<policy>` — validated client-side.

## Outputs

`user_names` — map of user key => user name.
`user_arns` — map of user key => user ARN.
`user_unique_ids` — map of user key => user unique ID (`AIDA...`).
`access_key_ids` — map of user key => access key ID, `null` for users without `access_key`. Covers all user keys.
`access_key_secrets` — sensitive; map of user key => secret access key, `null` for users without `access_key` or with a `pgp_key`. Covers all user keys. Stored in the Terraform state file; protect the backend accordingly.
`access_key_encrypted_secrets` — map of user key => PGP-encrypted secret (base64), `null` for users without `access_key` or without `pgp_key`. Covers all user keys.

## Example

```hcl
users = {
  "ci-deployer" = {
    name      = "example-ci-deployer"
    path      = "/ci/"
    groups    = ["example-deployers"]
    access_key = {
      pgp_key = "keybase:example_owner"
    }
  }
  "ci-reporter" = {
    name                = "example-ci-reporter"
    groups              = ["example-earthwatch"]
    managed_policy_arns = ["arn:aws:iam::aws:policy/IAMReadOnlyAccess"]
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

Pair with the `aws/iam-group` module: its `group_names[key]` outputs feed the
`groups` attribute here.

## Notes

- Map keys are arbitrary unique identifiers that decouple the key set from
  the names — but user names themselves must be unique account-wide
  regardless of `path` (AWS friendly names are unique within the account).
- Group membership is declared on the user side with
  `aws_iam_user_group_membership`, which is safe against self-conflict for
  the same user. The exclusive per-group `aws_iam_group_membership` is
  deliberately not used here.
- Managed policy attachments and inline policies are separate resources
  addressed as `<user>.<arn>` / `<user>.<policy key>`; removing an entry
  from the input destroys exactly that attachment/policy, not the user.
- Mixing `groups` entries managed here with manually managed membership
  (console or other tooling) for the same groups can drift or conflict;
  manage membership with this module or entirely out of band, not both.
- `force_destroy` must be applied in a separate, successful run before the
  destroy that needs it — setting it in the same run that destroys the user
  has no effect.
- IAM user tag keys are case-insensitive; avoid supplying a case-variant
  of `Name` (e.g. lowercase `name`) since the module injects `Name = name`.

## Import

`aws_iam_user` — user name.
`aws_iam_access_key` — access key ID; secret-related attributes are unavailable after import.
`aws_iam_user_policy_attachment` — `user_name/policy_arn` (slash-separated).
`aws_iam_user_policy` — `user_name:policy_name` (colon-separated).
`aws_iam_user_group_membership` — `user_name/group1_name/group2_name` (slash-separated).
