# snowflake/account-role

Map-keyed module for Snowflake account roles. Each entry creates one
`snowflake_account_role` in the account configured on the provider.

Account roles are the access-control building blocks: grant privileges to
them with `snowflake/grant-privileges`, and grant them to users or other
roles with `snowflake/role-grant`. This module creates the roles only.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_roles` | `map(object)` | `{}` | Map of account roles keyed by an arbitrary unique ID. |

Plan-time validation: `name` contains none of the characters the provider
excludes on role identifiers (`"`, `|`, `.`), and names are unique across
entries case-insensitively (Snowflake-enforced account-wide uniqueness).

### `account_roles` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Role identifier; unique across the account. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW ROLES`. |

## Outputs

| Name | Description |
|---|---|
| `account_role_fully_qualified_names` | Map of key => fully qualified name. Feed directly into the `account_role_name` input of `snowflake/grant-privileges` and the `role_name` input of `snowflake/role-grant`. |
| `account_role_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
account_roles = {
  "analyst" = {
    name    = "ROLE_ANALYST"
    comment = "read analytics shapes"
  }
}
```

## Notes

- A role grants nothing by itself; wire it up with the grant modules —
  see the composability example in `snowflake/grant-privileges`.
- Dropping a role that is the current primary role of a user errors
  ("Cannot drop role '<role_name>' because it is the current role for
  user '<username>'"); reassign default roles first.
- The role running Terraform needs CREATE ROLE on the account.

## Import

`terraform import 'snowflake_account_role.role["<key>"]' '"<account_role_name>"'`
