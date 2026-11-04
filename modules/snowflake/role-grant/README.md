# snowflake/role-grant

Map-keyed module for Snowflake account-role grants. Each entry grants one
account role to one user or to one parent role, creating the role hierarchy
edge (`GRANT ROLE ... TO USER|ROLE`).

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `role_grants` | `map(object)` | `{}` | Map of role grants keyed by an arbitrary unique ID. |

Plan-time validation: exactly one grantee per entry, role/grantee identifiers
non-empty and free of the `"|"` import separator, and no duplicate role+grantee
pairs across entries.

### `role_grants` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role_name` | `string` | — | Fully qualified name of the role being granted (e.g. `account_role_fully_qualified_names[...]` from `snowflake/account-role`). |
| `user_name` | `string` | `null` | Fully qualified name of the user receiving the role. Mutually exclusive with `parent_role_name`. |
| `parent_role_name` | `string` | `null` | Fully qualified name of the parent role receiving the role (role-hierarchy edge). Mutually exclusive with `user_name`. |

## Outputs

| Name | Description |
|---|---|
| `role_grant_ids` | Map of key => Terraform provider ID (constructed identifier — used for imports; this resource exposes no fully-qualified-name read-only attribute). |

## Example

Grant a role to a user, wire a two-level hierarchy:

```hcl
role_grants = {
  "analyst-to-user" = {
    role_name = "\"ROLE_ANALYST\""
    user_name = "\"USER_ANALYST\""
  }
  "analyst-in-team-role" = {
    role_name        = "\"ROLE_ANALYST\""
    parent_role_name = "\"ROLE_TEAM\""
  }
}
```

## Notes

- Object references must be quoted fully qualified names; a bare name shows
  up quoted or errors at apply depending on the identifier in question.
- Setting `default_role` on a user (`snowflake/user`) does **not** grant the
  role — that needs an entry here with the user as grantee.
- The role running Terraform needs to own the granted role (or hold
  MANAGE GRANTS on the account) for the grant to succeed; role-hierarchy
  grants additionally need the parent role to be grantable by it.
- The resource has no comment/documentation attribute beyond the grant itself;
  the identity lives on the role and user modules.

## Import

`terraform import 'snowflake_grant_account_role.grant["<key>"]' '"<role>"|USER|"<user>"'`

or for a parent-role edge:

`terraform import 'snowflake_grant_account_role.grant["<key>"]' '"<role>"|ROLE|"<parent_role>"'`

The grantee object type is `USER` or `ROLE` accordingly.
