# snowflake/grant-privileges

Map-keyed module for Snowflake privilege grants to account roles. Each entry
creates one `snowflake_grant_privileges_to_account_role`: a privilege set
granted to one account role on one target — the account itself, an account
object, a schema-level choice, or a schema object (all/future/inherited
variants included).

This module is the modern replacement for the legacy `snowflake_*_grant`
resources the provider removed. Grants are only half the story: pair with
`snowflake/account-role` (create the role), `snowflake/role-grant` (attach it
to users or a role hierarchy).

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `grants` | `map(object)` | `{}` | Map of grants keyed by an arbitrary unique ID. |

Plan-time validation (module policy unless noted): exactly one target per
entry (`on_account`, `on_account_object`, `on_schema` or `on_schema_object`),
exactly one of `privileges`/`all_privileges`, `privileges` is a non-empty
UPPER-CASE list (this field is case-sensitive per the provider docs), the
on_account_object pair-vs-inherited shape mirrors the provider's conflicts,
exactly one choice inside `on_schema` and `on_schema_object`, exactly one
scope inside `inherited` blocks (at most one inside `all`/`future`),
`strict_privilege_management` cannot accompany `all_privileges` or
all-objects targets, and `with_grant_option`/`always_apply` cannot
accompany `inherited` grants (the last three mirror plan-time conflicts the
provider enforces).

### `grants` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `account_role_name` | `string` | — | Fully qualified name of the account role receiving the grant (e.g. `account_role_fully_qualified_names[...]` from `snowflake/account-role`). |
| `privileges` | `set(string)` | `null` | Privileges to grant, UPPER-CASE. Mutually exclusive with `all_privileges`. |
| `all_privileges` | `bool` | `null` | Grant all privileges on the target instead of a list. |
| `with_grant_option` | `bool` | `false` | Grantee can re-grant. Not supported with `IMPORTED PRIVILEGES`. |
| `always_apply` | `bool` | `false` | **Escape hatch**: re-apply the grant every run — plan is never empty. Only sensible with all-objects/all-privileges grants so new objects get covered. Cannot accompany `inherited` grants (provider rejects the combination). |
| `strict_privilege_management` | `bool` | `null` | When true, the module revokes externally granted privileges not in this config (becomes the source of truth) — actual revocations land on the apply after the flag change. Cannot combine with `all_privileges` or all-objects targets (`on_schema.all_schemas_in_database`, `on_schema_object.all`). Gated by the `GRANTS_STRICT_PRIVILEGE_MANAGEMENT` experiment (on by default; [guide](https://registry.terraform.io/providers/snowflakedb/snowflake/latest/docs/guides/strict_privilege_management)). |
| `on_account` | `bool` | `null` | Grant on the account — exactly one target of four. |
| `on_account_object.object_type` | `string` | `null` | Account object type (required together with `object_name`): `DATABASE`, `WAREHOUSE`, `COMPUTE POOL`, `INTEGRATION`, `CONNECTION`, `FAILOVER GROUP`, `REPLICATION GROUP`, `EXTERNAL VOLUME`, `USER`, `RESOURCE MONITOR`, ... Snowflake validates the type at apply. Conflicts with `inherited`. |
| `on_account_object.object_name` | `string` | `null` | Quoted fully qualified object name. Mutually exclusive with `inherited`. |
| `on_account_object.inherited.object_type_plural` | `string` | `null` | Set `inherited` alone (no object identity) for an inherited grant on all current+future account objects of the given type; gated by the `INHERITED_GRANTS` experiment (on by default). |
| `on_schema.schema_name` | `string` | — | Exactly one of the four schema-level choices. |
| `on_schema.all_schemas_in_database` | `string` | — | Quoted database name; grant on all its schemas. |
| `on_schema.future_schemas_in_database` | `string` | — | Quoted database name; grant on its future schemas. |
| `on_schema.inherited.in_account` / `.in_database` | `bool`/`string` | — | Inherited grant on all schemas; exactly one scope required. |
| `on_schema_object.object_type` + `.object_name` | `string` | — | Single schema object grant (`TABLE`, `VIEW`, `TASK`, ...). Exactly one choice in the group; both fields required together. |
| `on_schema_object.all/future.{object_type_plural, in_database\|in_schema}` | `string` | — | All/future objects grant; at most one scope. |
| `on_schema_object.inherited.{object_type_plural, in_account\|in_database\|in_schema}` | — | All current+future objects of a type; exactly one scope required. |

## Outputs

| Name | Description |
|---|---|
| `grant_ids` | Map of key => Terraform provider ID (constructed identifier — used for imports; this resource exposes no fully-qualified-name read-only attribute). |

## Example

Role creation + grants + role attachment, the full composability chain:

```hcl
# snowflake/account-role
account_roles = {
  "analyst" = {
    name = "ROLE_ANALYST"
  }
}

# snowflake/grant-privileges
grants = {
  "analyst-select-all-tables" = {
    account_role_name = account_role_fully_qualified_names["analyst"]
    privileges        = ["SELECT"]
    on_schema_object = {
      all = {
        object_type_plural = "TABLES"
        in_schema          = "\"TEST_DB\".\"TEST_SCHEMA\""
      }
    }
  }
  "analyst-usage-database" = {
    account_role_name = account_role_fully_qualified_names["analyst"]
    privileges        = ["USAGE"]
    on_account_object = {
      object_type = "DATABASE"
      object_name = "\"TEST_DB\""
    }
  }
}

# snowflake/role-grant
role_grants = {
  "analyst-to-user" = {
    role_name = account_role_fully_qualified_names["analyst"]
    user_name = user_fully_qualified_names["analyst"]
  }
}
```

## Notes

- Object, database and schema references must be quoted fully qualified names
  (`"<db>"."<schema>"`); bare names error at apply.
- Special cases from the provider docs: manage `HYBRID TABLE` by specifying
  `TABLE`/`TABLES` as the object type; to grant on an application (e.g. the
  default `SNOWFLAKE` app) use `on_account_object.object_type = "DATABASE"`.
- `IMPORTED PRIVILEGES` (shared databases): grant it alone — no regular
  privilege lists on imported databases, and not combined with
  `with_grant_option`. External grants of it are not detected (Snowflake
  limitation).
- `always_apply` breaks Terraform's convergent-config convention (perpetual
  non-empty plan) — use it only for the all-objects scenarios it was built
  for.
- Granting future / all / inherited grants takes dedicated entries — regular
  and future grants are separate resources even for the same role and object.
  `with_grant_option` and `always_apply` cannot accompany any `inherited`
  grant (provider-rejected combination). Inherited grants depend on the
  `INHERITED_GRANTS` experiment — enabled by default, opt out now via the
  provider's `experimental_features_disabled`, removal expected in
  v2.23.0/v2.24.0. The same removal window applies to
  `GRANTS_STRICT_PRIVILEGE_MANAGEMENT`.
- The grant-owning role needs the privileges it grants (directly or via
  ownership/MANAGE GRANTS), and ownership of the target role or MANAGE GRANTS
  on account.

## Import

Import uses a constructed pipe-separated identifier with every name part
quoted (schema objects `"<db>"."<schema>"."<object>"`). The `<privileges>`
field is a comma-separated list — write `ALL` (or `ALL PRIVILEGES`) for
`all_privileges = true` grants:

```
<account_role_name>|<with_grant_option>|<always_apply>|<privileges>|<grant_type>[|<grant_data>]
```

All documented `grant_type` forms for the per-key adaptation:

- `OnAccount` — account-level privileges.
- `OnAccountObject|<object_type>|<object_name>`.
- `OnSchema|OnSchema|<schema_name>`.
- `OnSchema|OnAllSchemasInDatabase|<database_name>`.
- `OnSchema|OnFutureSchemasInDatabase|<database_name>`.
- `OnSchemaObject|OnObject|<object_type>|<object_name>`.
- `OnSchemaObject|OnAll|<object_type_plural>|InDatabase|<identifier>`.
- `OnSchemaObject|OnAll|<object_type_plural>|InSchema|<identifier>`.
- `OnSchemaObject|OnFuture|<object_type_plural>|InDatabase|<identifier>`.
- `OnSchemaObject|OnFuture|<object_type_plural>|InSchema|<identifier>`.

The provider additionally documents the three inherited forms through its
example identifiers (not in the import template set):
`OnAccountObjectInherited|<object_type_plural>`,
`OnSchemaInherited|InDatabase|<database>` and
`OnSchemaObjectInherited|<object_type_plural>|InDatabase|<database>`.

Worked examples, adapted per key:

`terraform import 'snowflake_grant_privileges_to_account_role.grant["<key>"]' '"test_db_role"|false|false|ALL|OnAccountObject|DATABASE|"test_db"'`

`terraform import 'snowflake_grant_privileges_to_account_role.grant["<key>"]' '"test_db_role"|false|false|CREATE TAG,CREATE TABLE|OnSchema|OnAllSchemasInDatabase|"test_db"'`

`terraform import 'snowflake_grant_privileges_to_account_role.grant["<key>"]' '"test_db_role"|false|false|SELECT,DELETE,INSERT|OnSchemaObject|OnObject|TABLE|"test_db"."test_schema"."test_table"'`

`terraform import 'snowflake_grant_privileges_to_account_role.grant["<key>"]' '"test_db_role"|false|false|SELECT,DELETE,INSERT|OnSchemaObject|OnAll|TABLES|InSchema|"test_db"."test_schema"'`
