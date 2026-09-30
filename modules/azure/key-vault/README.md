# azure/key-vault

Map-keyed module for Azure key vaults with nested keys, secrets and
certificates. Each entry creates one `azurerm_key_vault` in the named resource
group; vault names are unique across all of Azure — they are the vault URI's
host (`<name>.vault.azure.net`). Child objects wire into the vault resource
this module creates itself — no vault ID plumbing on the consumer side.

## Destroy semantics (read before using)

- Removing a vault key destroys the vault — with soft delete (default) the
  vault (and its keys, secrets and certificates) lands in Azure's soft-delete
  limbo until the retention window passes; the provider's `features` block
  (purge / recover behaviour; consumer-side provider config) decides whether a
  same-named vault can be re-created in its shadow.
- `purge_protection_enabled = true` is irreversible once set — a vault with
  purge protection cannot be destroyed by this module or any other tool until
  (~) the retention window passes with purge in place.
- Removing a key, secret or certificate entry deletes the object; soft-deleted
  children recoverable per the vault's retention window.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `key_vaults` | `map(object)` | — | Map of key vaults keyed by an arbitrary unique ID. |

Plan-time validation: `name` is 3–24 characters, starts with a letter,
alphanumerics and single hyphens only (no `--`), unique across entries
case-insensitively; `name`/`resource_group_name`/`location`/`tenant_id` are
non-empty; `sku_name` is `standard`/`premium`; `soft_delete_retention_days`
is 7–90; `network_acls` (when set) takes `default_action` `Allow`/`Deny`,
`bypass` `AzureServices`/`None`, IPv4 CIDR/bare `ip_rules` and full ARM
`virtual_network_subnet_ids`; access-policy permission lists are subsets of
the documented permission sets; tags on every level respect the
50-entry / 512-char key / 256-char value limits; map keys on every level
contain no `.`; child names are 1–127 alphanumerics/hyphens and unique per
vault per type; keys pick a valid `key_type` with the matching parameters
and fit their `key_opts` to the key's type; secrets set exactly one of
`value`/`value_wo` (with `value_wo_version` requirements); certificates set
at least one of `certificate`/`certificate_policy` and their policy objects
carry the documented shapes (issuer, key properties, lifetime actions,
x509 properties).

### `key_vaults` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Vault name: 3–24 characters, start letter, alphanumerics/single hyphens, no `--` (validated). Globally unique — it is the URI host (`.vault.azure.net`). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the vault lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `tenant_id` | `string` | — | Entra ID tenant UUID data-plane authorisation runs against (typically `data.azurerm_client_config.current.tenant_id`). |
| `sku_name` | `string` | `standard` | `standard` or `premium` (lowercase) — premium is required for HSM-backed keys (`RSA-HSM`, `EC-HSM`). Immutable (SKU changes are, provider-side). |
| `soft_delete_retention_days` | `number` | `90` | Soft-delete retention in days, 7–90 (validated). Immutable after vault creation — see Notes. |
| `purge_protection_enabled` | `bool` | `false` | Guard against immediate hard deletes of vaults and children. **Irreversible** once enabled — see Notes. |
| `rbac_authorization_enabled` | `bool` | `true` | Use Entra RBAC for data-plane authorisation (project/role assignments out of this module's scope; pair with `azure/subscription-iam` / role-assignment wiring). When `false`, legacy `access_policies` govern — see Notes. |
| `public_network_access_enabled` | `bool` | `true` | Public endpoint reachability of the vault. `false` pairs with private endpoints (out of this module's scope). Updated in place. |
| `enabled_for_deployment` | `bool` | `false` | Let Azure VMs fetch certificates from the vault. Updated in place. |
| `enabled_for_disk_encryption` | `bool` | `false` | Let Azure Disk Encryption fetch/unwrap secrets/keys. Updated in place. |
| `enabled_for_template_deployment` | `bool` | `false` | Let ARM templates fetch values from the vault during deployments. Updated in place. |
| `network_acls` | `object` | `null` | Optional single network-ACL block, one per vault (provider shape; `ip_rules`/`virtual_network_subnet_ids` are sets like the provider stores them). `null` means the default Allow-all-without-rules posture. Updated in place. See the object table. |
| `access_policies` | `list(object)` | `[]` | Legacy access-policy entries — separate tenant/object pairs and permission lists. Only effective with `rbac_authorization_enabled = false` — see Notes. Empty with the RBAC default. |
| `keys` | `map(object)` | `{}` | Vault keys keyed by an arbitrary unique ID. See the object table. |
| `secrets` | `map(object)` | `{}` | Vault secrets keyed by an arbitrary unique ID. See the object table. |
| `certificates` | `map(object)` | `{}` | Vault certificates keyed by an arbitrary unique ID — import or generate. See the object table. |
| `tags` | `map(string)` | `{}` | Tags on the vault. The tag set is authoritative — see Notes. |

### `network_acls` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `default_action` | `string` | — | `Allow` or `Deny` (case-sensitive) — the posture when nothing else matches. |
| `bypass` | `string` | `AzureServices` | `AzureServices` or `None` (case-sensitive) — trusted Azure services (backup, disk encryption) walk through regardless of the rules. |
| `ip_rules` | `set(string)` | `[]` | IPv4 CIDRs or bare IPv4 addresses the rules allow. |
| `virtual_network_subnet_ids` | `set(string)` | `[]` | Full ARM subnet resource IDs allowed through (typically from `azure/subnet` outputs). Azure requires the vault-owning identity to have network operator rights on the referenced VNets for cross-resource wiring. |

### `keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Key name: 1–127 alphanumerics/hyphens (validated); unique per vault per type. Immutable. |
| `key_type` | `string` | — | `EC`, `EC-HSM`, `RSA`, `RSA-HSM` (validated). `*-HSM` requires the `premium` SKU. Immutable — changing it forces replacement. |
| `key_size` | `number` | `null` | Key size in bits — required for `RSA`/`RSA-HSM` (2048, 3072, 4096 — validated); must stay unset for EC types (validated). |
| `curve` | `string` | `null` | Elliptic curve for EC types: `P-256`, `P-256K`, `P-384`, `P-521` (validated); must stay unset for RSA types (validated). |
| `key_opts` | `list(string)` | `null` | Key operation set — RSA: `decrypt`, `encrypt`, `sign`, `unwrapKey`, `verify`, `wrapKey`; EC: `sign`, `verify` (validated per type). Pass the call-site use case's needs — receipts narrow, wider grants wider powers. |
| `not_before_date` | `string` | `null` | `Z`-form UTC activation timestamp (`2026-01-02T03:04:05Z`). |
| `expiration_date` | `string` | `null` | `Z`-form UTC expiry timestamp. Removing it (once set) forces key replacement — see Notes. |
| `rotation_policy` | `object` | `null` | Optional rotation-policy block (expire_after/notify_before_expiry pair, automatic settings) — see below. |
| `tags` | `map(string)` | `{}` | Tags on the key. |

`rotation_policy` object: `expire_after` (`P28D`…`P100Y` ISO 8601 duration
form — provider-enforced bounds, not validated here), `notify_before_expiry`
(`P7D`…`P36493D`, required together with `expire_after` in both directions —
validated), `automatic` (`time_after_creation` / `time_before_expiry`, at
least one — validated). Upstream quirk: when `expire_after` stays unset, only
the notify action is persisted in state — expect a persistent plan diff from
the dropped field.

### `secrets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Secret name: 1–127 alphanumerics/hyphens (validated); unique per vault per type. Immutable. |
| `value` | `string` | `null` | Secret value. Exactly one of `value`/`value_wo` (validated). Lands in state — see Notes. |
| `value_wo` | `string` | `null` | Write-only secret value — kept out of state (requires a core with write-only support: Terraform ≥ 1.11, matching OpenTofu). Bump `value_wo_version` to rotate. |
| `value_wo_version` | `number` | `null` | Version marker for `value_wo`, ≥ 1 (validated, required with `value_wo`). |
| `content_type` | `string` | `null` | MIME type hint of the secret's payload, e.g. `application/x-pem-file`. |
| `not_before_date` | `string` | `null` | `Z`-form UTC activation timestamp. |
| `expiration_date` | `string` | `null` | `Z`-form UTC expiry timestamp. |
| `tags` | `map(string)` | `{}` | Tags on the secret. |

### `certificates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Certificate name: 1–127 alphanumerics/hyphens (validated); unique per vault per type. Immutable. |
| `certificate` | `object` | `null` | Import path: `{ contents, password }` — a base64-encoded PFX or a PEM/PKCS8 bundle, with its password. At least one of `certificate`/`certificate_policy` is required (the provider accepts both together: import with a policy applied). |
| `certificate_policy` | `object` | `null` | Generate path (or policy for an import) — see below. |
| `tags` | `map(string)` | `{}` | Tags on the certificate. |

`certificate_policy` object: `issuer_parameters` (`{ name }` — `Self` for
self-signed, `Unknown` for a CA CSR, or a custom issuer), `key_properties` —
`{ exportable, key_type, key_size, curve, reuse_key }`, `lifetime_action`
list (`{ action = { action_type }, trigger = { days_before_expiry,
lifetime_percentage } }` — exactly one trigger field, validated; action types
`AutoRenew`/`EmailContacts`), `secret_properties` (`{ content_type }` —
`application/x-pkcs12` or `application/x-pem-file`, validated) and optional
`x509_certificate_properties` (`subject`, `validity_in_months`, `key_usage`
subset of the documented set, `extended_key_usage`,
`subject_alternative_names` with `dns_names`/`emails`/`upns`).

## Outputs

| Name | Description |
|---|---|
| `key_vault_ids` | Map of vault key => full ARM resource ID. |
| `key_vault_uris` | Map of vault key => vault URI (`https://<name>.vault.azure.net/`). |
| `key_ids` | Map of `<vault_key>.<key_key>` => versioned data-plane key URI (provider `id`). |
| `key_versionless_ids` | Map of `<vault_key>.<key_key>` => versionless data-plane key URI (provider `versionless_id`). |
| `key_resource_versionless_ids` | Map of `<vault_key>.<key_key>` => versionless ARM resource ID (provider `resource_versionless_id`) — for ARM consumers that must follow rotation. |
| `secret_ids` | Map of `<vault_key>.<secret_key>` => versioned data-plane secret URI (provider `id`). |
| `secret_versionless_ids` | Map of `<vault_key>.<secret_key>` => versionless data-plane secret URI (provider `versionless_id`). |
| `certificate_ids` | Map of `<vault_key>.<certificate_key>` => versioned data-plane certificate URI (provider `id`). |
| `certificate_secret_ids` | Map of `<vault_key>.<certificate_key>` => versioned data-plane URI of the certificate's PKCS#12 backing secret (provider `secret_id`). |
| `certificate_secret_versionless_ids` | Map of `<vault_key>.<certificate_key>` => versionless data-plane URI of the backing secret (provider `versionless_secret_id`). |

No key or secret values are exposed — only IDs/URIs. Consumers after key/
secret material pull it from `value_wo` inputs, a data source, or their own
secret-config pipeline; see Notes for the state-exposure stance.

## Example

```hcl
data "azurerm_client_config" "current" {}

key_vaults = {
  "platform" = {
    name                = "kv-platform-prod-01"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    tenant_id           = data.azurerm_client_config.current.tenant_id
    sku_name            = "standard"
    network_acls = {
      default_action           = "Deny"
      bypass                   = "AzureServices"
      ip_rules                 = ["203.0.113.0/24"]
      virtual_network_subnet_ids = []
    }
    keys = {
      "cmk" = {
        name     = "storage-cmk"
        key_type = "RSA-HSM"
        key_size = 3072
        key_opts = ["unwrapKey", "wrapKey"]
        rotation_policy = {
          expire_after         = "P90D"
          notify_before_expiry = "P30D"
        }
      }
    }
    secrets = {
      "sql-password" = {
        name         = "sql-admin-password"
        value_wo     = var.sql_password
        value_wo_version = 1
        content_type = "text/plain"
      }
    }
    certificates = {
      "web-tls" = {
        name = "web-tls"
        certificate_policy = {
          issuer_parameters = {
            name = "Self"
          }
          key_properties = {
            exportable = true
            key_type   = "RSA"
            key_size   = 2048
            reuse_key  = true
          }
          lifetime_action = [
            {
              action  = { action_type = "AutoRenew" }
              trigger = { days_before_expiry = 30 }
            },
          ]
          secret_properties = {
            content_type = "application/x-pkcs12"
          }
          x509_certificate_properties = {
            subject            = "CN=app.example.internal"
            validity_in_months = 12
            key_usage          = ["digitalSignature", "keyEncipherment"]
          }
        }
      }
    }
    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- **RBAC vs access policies**: with the default `rbac_authorization_enabled =
  true`, data-plane authorisation is Entra RBAC — any `access_policies` set
  here are silently ineffective (they only matter with RBAC off). Grant
  data-plane roles through IAM instead (e.g. Key Vault Secrets User on the
  scope pair).
- The separate `azurerm_key_vault_access_policy` resource fights this
  module's inline `access_policy` blocks over the vault's policy list — pick
  one owner. With RBAC on (the default), access policies are irrelevant
  entirely.
- `soft_delete_retention_days` and `purge_protection_enabled` are
  provider-permanent: soft-delete days cannot decrease, purge protection
  cannot turn off. The provider's `features {}` block (`key_vault` purging/
  recovering toggles, consumer side) governs whether destroy purges or
  leaves a recoverable vault — configure it explicitly rather than relying
  on defaults.
- Vault-name changes force replacement (a new vault) — with soft delete the
  old vault stays in Azure's purgatory until purged/expired; reclaiming an
  old name requires purge (see the provider features note).
- **State exposure**: key material, secret values (`value`) and certificate
  bundles land in the module's state; this module outputs IDs and URIs
  only. Consumers that must keep values out of state use the `value_wo`
  write-only path (write-only-capable core required) or pull values via
  data sources at use time.
- Removing `expiration_date` (or `not_before_date`) from an existing key
  forces key replacement (provider-side) — keep such fields intentional,
  not exploratory.
- Certificate imports vs generation are consumed in one module resource —
  `certificate` (import) and `certificate_policy` (generate) both set is
  the provider's supported combined form (policy applied onto the
  import).
- The caller needs `Microsoft.KeyVault/vaults/write` plus the RBAC role
  assignments (Key Vault Administrator / Secrets Officer) on the vault for
  data-plane management — RBAC-only vaults have no legacy access-policy
  path.
- Children (keys, secrets, certificates) apply after the vault resource —
  no module-level ordering required; the provider handles vault readiness.
- Not exposed, deliberately (pass-through candidates for a later minor
  release): `release_policy` on keys, certificate merge/append-tag
  operations, `contact` (certificate contacts) blocks, and the
  storage-account-backed `storage_permissions` nuances on a legacy vault.

## Import

Vaults import by ARM ID; keys, secrets and certificates import by their
versioned data-plane URIs (the importer requires a version segment):

```
tofu import 'azurerm_key_vault.key_vault["platform"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<name>"
tofu import 'azurerm_key_vault_key.key["<vault_key>.<key_key>"]' "https://<vault>.vault.azure.net/keys/<name>/<version>"
tofu import 'azurerm_key_vault_secret.secret["<vault_key>.<secret_key>"]' "https://<vault>.vault.azure.net/secrets/<name>/<version>"
tofu import 'azurerm_key_vault_certificate.certificate["<vault_key>.<certificate_key>"]' "https://<vault>.vault.azure.net/certificates/<name>/<version>"
```
