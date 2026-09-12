# stackit/postgresflex_instance

Map-keyed module for STACKIT PostgreSQL Flex instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). Changing it replaces the instance. |
| `name` | `string` | — | Instance name: starts with a lowercase letter, lowercase letters/digits/hyphens only, no trailing hyphen (validated). Updates in place. |
| `version` | `string` | — | PostgreSQL major version (e.g. `17`). Updates in place per the schema — see the version note below before relying on major-version changes. |
| `backup_schedule` | `string` | — | Backup schedule as a cron expression with numeric minute and hour values (e.g. `0 2 * * *`); five fields (validated). Updates in place. |
| `storage` | `object` | — | `{class, size}`; see the `storage` object table. |
| `flavor_id` | `string` | — | Flavor ID (e.g. `4.8-replica`); list available flavors consumer-side via the `stackit_postgresflex_flavors` data source. Required in this module — the provider requires exactly one of `flavor_id` or the deprecated `flavor`, and this module only supports `flavor_id`. Updates in place. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the instance. |
| `retention_days` | `number` | API fallback (`32`) | Backup retention in days, 32–90 (validated). Updates in place. Becomes required after February 2027. |
| `network` | `object` | — | Network configuration; see the `network` object table. Required in this module — see the ACL note below. Becomes required upstream after February 2027. |
| `encryption` | `object` | `null` | Encryption with a STACKIT KMS key; see the `encryption` object table. Immutable after create. |

### `storage` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `class` | `string` | — | Storage class (e.g. `premium-perf2-stackit`); list available classes via `stackit postgresflex flavor describe FLAVOR_ID` (STACKIT CLI). Changing it replaces the instance. |
| `size` | `number` | — | Storage size in gigabytes (per STACKIT docs — confirm against the current STACKIT documentation), at least 1 (validated). Updates in place. |

### `network` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `acl` | `list(string)` | — | Access control list for the instance: non-empty list of valid IPv4 CIDRs (validated). Required in this module — the provider requires exactly one ACL form (the deprecated top-level `acl` or `network.acl`) and this module only supports `network.acl`. Updates in place. |
| `access_scope` | `string` | `null` | Network access scope: `PUBLIC` or `SNA` (validated). Private preview — supplying it on a non-enabled account fails at apply. Changing it replaces the instance. |

### `encryption` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `kek_key_id` | `string` | — | UUID of the key within the STACKIT KMS used for the encryption (validated). |
| `kek_keyring_id` | `string` | — | UUID of the keyring where the key is located (validated). |
| `kek_key_version` | `string` | — | Version of the key within the STACKIT KMS. |
| `service_account` | `string` | — | Service account linked to the key within the STACKIT KMS. |

## Outputs

`instances` — map of instance key => object:

| Attribute | Description |
|---|---|
| `instance_id` | Instance UUID. |
| `host` | Write connection host (DNS name from the instance overview). |
| `port` | Write connection port. |
| `id` | `"{project_id},{region},{instance_id}"` — the import ID. |

## Example

```hcl
module "postgresflex_instance" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/postgresflex_instance?ref=v1.3.0"

  instances = {
    "app-db" = {
      project_id      = "12345678-1234-1234-1234-123456789012"
      name            = "example-app-db"
      version         = "17"
      backup_schedule = "0 2 * * *"
      flavor_id       = "4.8-replica"
      retention_days  = 32
      storage = {
        class = "premium-perf2-stackit"
        size  = 10
      }
      network = {
        acl = ["10.0.0.0/8"]
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **ACL is required**: the provider enforces exactly one of the
  deprecated top-level `acl` or `network.acl` — with neither set, plan
  fails provider-side. This module exposes only the non-deprecated
  `network.acl`, so it is required here and must be a non-empty list of
  IPv4 CIDRs (validated). `network` itself becomes required upstream
  after February 2027 anyway.
- **Renaming a map key destroys and recreates the instance — data loss
  risk on a database instance.** The same applies to changing
  `project_id`, `region`, `storage.class`, `network.access_scope` or
  removing/re-adding the `encryption` block.
- **`flavor_id` is required**: the provider enforces exactly one of
  `flavor_id` or the deprecated `flavor` — with neither set, plan fails
  provider-side. This module exposes only `flavor_id`, so it is
  required here.
- `name`, `version`, `backup_schedule`, `storage.size`, `retention_days`
  and `network.acl` update in place.
- `version` is an in-place update per the schema; whether the API
  actually supports in-place major-version upgrades is not documented
  upstream — verify against the STACKIT docs before relying on
  major-version changes.
- `backup_schedule` should be a simplified cron string (e.g. `0 2 * * *`
  rather than `00 02 * * *`); the provider only warns today, but
  non-simplified strings will error after February 2027.
- `retention_days` falls back to 32 when unset and becomes required
  after February 2027 — set it now to avoid a breaking change.
- The deprecated `flavor`/`replicas` pair and the top-level `acl` are
  intentionally not exposed; they are scheduled for removal after
  February 2027 and `flavor_id`/`network.acl` are the supported paths.
- Database users and their passwords are managed via
  stackit/postgresflex_user; this module exposes no credentials.
- Plan-time validations follow the provider's plan-time validators
  (UUIDs, name rule, retention bound, access scope, ACL form and CIDR
  notation) where those exist. The five-field cron shape for
  `backup_schedule` and the storage-size bound are documented STACKIT
  rules checked consumer-side as forward-checking — the provider
  itself only warns on non-simplified cron strings at apply time.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_postgresflex_instance` ← `{project_id},{region},{instance_id}`
