# stackit/sqlserverflex_instance

Map-keyed module for STACKIT SQLServer Flex instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). Changing it replaces the instance. |
| `name` | `string` | — | Instance name: starts with a lowercase letter, lowercase letters/digits/hyphens only, no trailing hyphen (validated). Updates in place. |
| `version` | `string` | — | SQLServer version; only `2022` is currently supported upstream (validated). Updates in place. |
| `backup_schedule` | `string` | — | Backup schedule as a five-field cron expression (e.g. `0 2 * * *`; shape-validated, not semantic minute/hour ranges). Updates in place. |
| `flavor_id` | `string` | — | Flavor ID; list available flavors consumer-side via the `stackit_sqlserverflex_flavors` data source. Required in this module — the provider requires exactly one of `flavor_id` or the deprecated `flavor`, and this module only supports `flavor_id`. Updates in place. |
| `storage` | `object` | — | `{class, size}`; see the `storage` object table. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the instance. |
| `retention_days` | `number` | API fallback | Backup retention in days, 30–90 (validated; note the different lower bound vs postgresflex's 32–90). Updates in place. Becomes required in the future upstream. |
| `network` | `object` | — | Network configuration; see the `network` object table. Required in this module — see the ACL note below. Becomes required upstream in the future. |
| `encryption` | `object` | `null` | Encryption with a STACKIT KMS key; see the `encryption` object table. Immutable after create. |

### `storage` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `class` | `string` | — | Storage class; list available classes for the chosen flavors via the `stackit_sqlserverflex_flavors` data source. Updates in place. |
| `size` | `number` | — | Storage size in gigabytes, at least 1 (validated). Updates in place. |

### `network` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `acl` | `list(string)` | — | Access control list for the instance: non-empty list of valid IPv4 CIDRs (validated). Required in this module — the provider requires exactly one ACL form (the deprecated top-level `acl` or `network.acl`) and this module only supports `network.acl`. Updates in place. |
| `access_scope` | `string` | `null` | Network access scope: `PUBLIC` or `SNA` (validated). Private preview — supplying it on a non-enabled account fails at apply. Updates in place. |

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
| `id` | `"{project_id},{region},{instance_id}"` — the import ID. |

No host/port/credentials are exposed here — this instance resource offers
no connection info; database users (with host and port) come from
stackit/sqlserverflex_user.

## Example

```hcl
module "sqlserverflex_instance" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/sqlserverflex_instance?ref=v2.1.0"

  instances = {
    "app-db" = {
      project_id      = "12345678-1234-1234-1234-123456789012"
      name            = "example-app-db"
      version         = "2022"
      backup_schedule = "0 2 * * *"
      flavor_id       = "4.8-standard"
      retention_days  = 30
      storage = {
        class = "cheap-storage"
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
  IPv4 CIDRs (validated).
- **Renaming a map key destroys and recreates the instance — data-loss
  risk on a database instance.** The same applies to changing
  `project_id`, `region` or removing/re-adding the `encryption` block.
- **`flavor_id` is required**: the provider enforces exactly one of
  `flavor_id` or the deprecated `flavor` — with neither set, plan fails
  provider-side. This module exposes only `flavor_id`, so it is
  required here.
- `name`, `version`, `backup_schedule`, `storage.*`, `retention_days`
  and `network.*` update in place.
- `version` currently only accepts `2022` upstream (validated here);
  the deprecated `flavor`/`options`/`replicas` inputs and the top-level
  `acl` are intentionally not exposed — `flavor_id` and `network.acl`
  are the supported paths.
- storage/network fields, `version`, `backup_schedule` and
  `retention_days` all become required in the future upstream — set
  them now (this module already requires them) to avoid breaking
  changes.
- `network.access_scope` is in private preview — applying it on a
  non-enabled account is rejected.
- Users, passwords and connection info are managed via
  stackit/sqlserverflex_user; this module exposes no credentials.
- Plan-time validations follow the provider's plan-time validators
  (UUIDs, name rule, retention bounds, access scope, ACL form and CIDR
  notation) where those exist. The five-field cron shape for
  `backup_schedule` and storage-size bound are documented STACKIT rules
  checked consumer-side as forward-checking.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_sqlserverflex_instance` ← `{project_id},{region},{instance_id}`
