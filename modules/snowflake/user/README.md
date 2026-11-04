# snowflake/user

Map-keyed module for Snowflake users. Each entry creates one `snowflake_user`
in the account configured on the provider.

This module exposes a curated attribute set for human users — identity fields,
login/auth, session defaults and the common knobs. The resource additionally
takes dozens of type-format and driver parameters that are intentionally not
mapped here; pass them consumer-side or in a follow-up if the repo needs them.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `users` | `map(object)` | `{}` | Map of users keyed by an arbitrary unique ID. |

Plan-time validation: `name` contains none of the characters the provider
excludes on user identifiers (`"`, `|`, `.` — `login_name` is not restricted;
Snowflake accepts any string there, including email-style logins), `email`
looks like an
email address, `default_secondary_roles_option` and `log_level` match their
provider enums (case-insensitive), RSA keys are single-line base64 payloads,
and login names (defaulting to `name`) are unique across entries
case-insensitively.

### `users` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | User identifier; also used as login name when `login_name` is unset. |
| `login_name` | `string` | `null` | Login identifier; always case-insensitive and unique across the account. |
| `first_name` / `middle_name` / `last_name` | `string` | `null` | Person names. |
| `display_name` | `string` | `null` | Name shown in the Snowflake web interface. |
| `email` | `string` | `null` | Email address. |
| `password` | `string` | `null` | **Lands in Terraform state.** Prefer key-pair auth (`rsa_public_key`/rsa_public_key_2`) or don't use this attribute. |
| `disabled` | `bool` | `null` | Disable logins and abort running queries. Not set ⇒ Snowflake default. |
| `must_change_password` | `bool` | `null` | Force password change on next login. Not set ⇒ Snowflake default. |
| `days_to_expiry` | `number` | `null` | Days until the user expires (temporary users only — never set on ACCOUNTADMIN users, Snowflake locks them out). External changes are not detected. |
| `default_role` | `string` | `null` | Role active at login. **Does not grant the role** — pair with `snowflake/role-grant`. |
| `default_warehouse` | `string` | `null` | Warehouse active at login (e.g. `warehouse_fully_qualified_names[...]` from `snowflake/warehouse`). |
| `default_namespace` | `string` | `null` | Database or database.schema active at login. |
| `default_secondary_roles_option` | `string` | `null` | `DEFAULT`, `NONE` or `ALL`; provider default `DEFAULT`. |
| `rsa_public_key` / `rsa_public_key_2` | `string` | `null` | Key-pair authentication keys (and rotation slot). One line, no `-----BEGIN-----` header or trailer. |
| `network_policy` | `string` | `null` | Network policy enforced for the user (preferred over the attachment resource the provider plans to rework). |
| `log_level` | `string` | `null` | Log ingest level: `TRACE`–`OFF`. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW USERS`. |

## Outputs

| Name | Description |
|---|---|
| `user_fully_qualified_names` | Map of key => fully qualified name. Feed into `snowflake/role-grant` (`user_name`) and consumer-side GRANT statements. |
| `user_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
users = {
  "analyst" = {
    name                   = "USER_ANALYST"
    login_name             = "ANALYST_LOGIN"
    first_name             = "Addie"
    last_name              = "Example"
    email                  = "analyst@example.com"
    default_role           = "ROLE_ANALYST"
    default_warehouse      = "\"WH_ANALYTICS\""
    rsa_public_key         = "MIIBIjANBgkq..."
    must_change_password   = true
  }
}
```

## Notes

- Sensitive-value caution from the provider docs: `email`,
  `first_name`/`middle_name`/`last_name`, `login_name` and `password` are
  marked Sensitive; `display_name` is not, and the `show_output` mirrors for
  `display_name`/`email`/names present those values unredacted — keep
  personal or regulated data out of these metadata fields.
- Automation identity: `TYPE=SERVICE` users come from the separate
  `snowflake_service_user` resource (and legacy ones from
  `snowflake_legacy_service_user`); this module only manages human users.
- The role running Terraform needs CREATE USER on the account; password
  changes for existing users need additional privileges.
- `days_to_expiry`, `mins_to_unlock` and `mins_to_bypass_mfa` change
  continuously on the Snowflake side, so external changes to them are invisible
  to plan/apply drift.

## Import

`terraform import 'snowflake_user.user["<key>"]' '"<user_name>"'`

After import, `terraform plan` + `apply` may be needed to fill out the missing
fields in state (e.g. `password`).
