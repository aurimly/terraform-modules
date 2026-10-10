# azure/container-registry

Map-keyed module for Azure Container Registries with nested georeplications,
webhooks, scope maps and tokens. Each entry creates one
`azurerm_container_registry` in the named resource group; registry names are
5–50 alphanumeric characters and globally unique across all of Azure — the
name doubles as the login-server host (`<name>.azurecr.io`). Child resources
wire into the registry resources this module creates itself — no registry-ID
plumbing on the consumer side.

## Destroy semantics (read before using)

- Removing a registry key destroys the registry and everything on it —
  webhooks, scope maps, tokens and passwords included. Images are gone with
  it.
- Removing a child entry deletes that webhook, token or scope map. Removing
  a token entry destroys its password resource with it (retention note: the
  token must be disabled before delete, or the API proceeds anyway and
  revokes access immediately).
- Georeplication entries follow the registry — removing one tears down the
  replicated location.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `container_registries` | `map(object)` | — | Map of container registries keyed by an arbitrary unique ID. |

Plan-time validation: `name` 5–50 alphanumeric; `sku` Basic/Standard/Premium;
Premium-only features (georeplications, network_rule_set, data endpoints,
quarantine, retention, zone redundancy) gated; `anonymous_pull_enabled`
Standard/Premium; ip_rule actions `Allow`; export lock requires public
access off; `network_rule_bypass_option` and `role_assignment_mode` enums;
georeplication locations unique and not the registry's own; webhook
names/actions/status shapes; scope-map action grammar; token
`scope_map_key` resolution; RFC 3339 password expiries; identity/encryption
pairing; tags respecting the 50/512/256 limits; map keys on every level
without `.`; child names unique per registry.

### `container_registries` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Registry name: 5–50 alphanumeric (validated), globally unique — it is the login-server host (see Notes). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the registry lives in. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku` | `string` | `Premium` | `Basic`, `Standard` or `Premium` (validated). |
| `admin_enabled` | `bool` | `false` | Admin user on the registry — its credentials surface through `registry_admin_usernames`/`registry_admin_passwords` (sensitive). |
| `public_network_access_enabled` | `bool` | `true` | Public endpoint reachability — off together with an export lock (validated) or a private-endpoint posture. |
| `anonymous_pull_enabled` | `bool` | `null` | Allow unauthenticated pulls — Standard/Premium only (not Basic, validated). |
| `data_endpoint_enabled` | `bool` | `null` | Dedicated data endpoints — Premium only (validated). |
| `quarantine_policy_enabled` | `bool` | `null` | Quarantine imported images — Premium only (validated). |
| `retention_policy_in_days` | `number` | `null` | Days untagged manifests survive before purge — Premium only (validated). |
| `zone_redundancy_enabled` | `bool` | `null` | Zone redundancy — Premium only (validated). Changing it forces replacement. |
| `export_policy_enabled` | `bool` | `null` | Data export to other registries; `false` requires the public endpoint closed (validated). |
| `azuread_authentication_as_arm_policy_enabled` | `bool` | `null` | Use ARM-audience tokens for docker login (Entra-only posture building block). |
| `network_rule_bypass_option` | `string` | `AzureServices` | `None` or `AzureServices` (validated) — trusted Azure services through network-restricted registries. |
| `network_rule_bypass_for_tasks_enabled` | `bool` | `null` | Registry tasks bypass network restrictions. |
| `role_assignment_mode` | `string` | `LegacyRegistryPermissions` | `LegacyRegistryPermissions` or `AbacRepositoryPermissions` (validated) — ABAC scopes repository RBAC granularly; new registries generally prefer ABAC (see Notes). |
| `network_rule_set` | `object` | `null` | Optional single network-rule block — Premium only (validated), `{ default_action, ip_rule }` where `ip_rule` is a map of `{ action (Allow, validated), ip_range (CIDR) }`. Azure pre-configures rules — a set with `default_action = "Deny"` is what removes them. |
| `identity` | `object` | `null` | Optional identity block — `{ type, identity_ids }`; required for `encryption` (validated), needed by consumers of `registry_identity_principal_ids`. |
| `encryption` | `object` | `null` | Customer-managed key — `{ key_vault_key_id, identity_client_id }`; requires `identity` (validated), and the identity must have Key Vault get access (operational — see Notes). |
| `georeplications` | `map(object)` | `{}` | Premium only (validated) — `{ location, global_endpoint_routing_enabled, zone_redundancy_enabled, tags }` per replication; the module emits them in alphabetic location order (see Notes). |
| `webhooks` | `map(object)` | `{}` | Webhooks — see the object table. |
| `scope_maps` | `map(object)` | `{}` | Scope maps — see the object table. |
| `tokens` | `map(object)` | `{}` | Tokens — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the registry. Authoritative — a change replaces the whole set. |

### `webhooks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Webhook name, alphanumeric only (validated), unique per registry (validated). |
| `service_uri` | `string` | — | Endpoint the notification POSTs to. |
| `actions` | `list(string)` | — | At least one of `push`, `delete`, `quarantine`, `chart_push`, `chart_delete` (validated). |
| `status` | `string` | `enabled` | `enabled` or `disabled` (validated). |
| `scope` | `string` | `null` | Repository scope filter (`"foo:*"` for all tags of `foo`; empty = all events). |
| `custom_headers` | `map(string)` | `{}` | Headers added to the notification request. |
| `tags` | `map(string)` | `{}` | Tags on the webhook. |

### `scope_maps` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Scope-map name (unique per registry, validated). Immutable — changing it forces replacement. |
| `actions` | `list(string)` | — | Action list in the `repositories/<repo>/(content|metadata)/<perm>` grammar (validated loosely — the full permission matrix is Azure-documented). |
| `description` | `string` | `null` | Description text. |

### `tokens` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Token name (unique per registry, validated). Immutable — changing it forces replacement. |
| `scope_map_key` | `string` | — | Key into the same registry entry's `scope_maps` (validated) — tokens bind to in-module scope maps only. |
| `enabled` | `bool` | `true` | Token alive. |
| `password1_expiry` | `string` | `null` | RFC 3339 expiry of password 1; omitted means never expires (validated). Changing it forces a new password resource — that is the rotation mechanism (see Notes). |
| `password2_expiry` | `string` | `null` | RFC 3339 expiry of password 2 — creates the second password block (validated). |

## Outputs

| Name | Description |
|---|---|
| `registry_ids` | Map of registry key => full ARM resource ID. |
| `registry_names` | Map of registry key => registry name. |
| `registry_login_servers` | Map of registry key => login server (`<name>.azurecr.io`). |
| `registry_admin_usernames` | Map of registry key => admin username (admin_enabled only). |
| `registry_admin_passwords` | Map of registry key => admin password (sensitive). |
| `registry_identity_principal_ids` | Map of registry key => system-assigned identity principal ID. |
| `data_endpoint_host_names` | Map of registry key => set of data-endpoint host names. |
| `webhook_ids` | Map of `<registry_key>.<webhook_key>` => webhook ARM resource ID. |
| `scope_map_ids` | Map of `<registry_key>.<scope_map_key>` => scope-map ARM resource ID. |
| `token_ids` | Map of `<registry_key>.<token_key>` => token ARM resource ID. |
| `token_password_values` | Map of `<registry_key>.<token_key>` => `{ password1, password2 }` values (sensitive). |

## Example

```hcl
container_registries = {
  "primary-eu" = {
    name                = "ordersprodregistry01"
    resource_group_name = "rg-store-prod"
    location            = "westeurope"
    sku                 = "Premium"

    zone_redundancy_enabled    = true
    retention_policy_in_days   = 30
    quarantine_policy_enabled  = true
    role_assignment_mode       = "AbacRepositoryPermissions"

    georeplications = {
      "us" = {
        location                = "eastus"
        zone_redundancy_enabled = true
      }
      "eu2" = {
        location = "northeurope"
      }
    }

    network_rule_set = {
      default_action = "Deny"
      ip_rule = {
        "office" = {
          ip_range = "203.0.113.0/24"
        }
      }
    }

    webhooks = {
      "deploy" = {
        name        = "deployhook"
        service_uri = "https://webhook.example.com/deploy"
        actions     = ["push", "chart_push"]
      }
    }

    scope_maps = {
      "ci-pull" = {
        name    = "cipull"
        actions = ["repositories/app/content/read"]
      }
    }

    tokens = {
      "ci" = {
        name             = "ci"
        scope_map_key    = "ci-pull"
        password1_expiry = "2027-01-02T03:04:05Z"
      }
    }

    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- **Premium gating**: georeplications, network rules, data endpoints,
  quarantine, retention and zone redundancy all validate against
  `sku = "Premium"` at plan — those features fail at the API on lower SKUs,
  so the plan rejects them earlier.
- **Georeplication ordering**: the API expects several replication blocks in
  alphabetic location order. The module emits them sorted by location no
  matter how the input map is written, so any ordering is accepted at plan.
  Locations must not repeat the registry's own region or another entry.
- **State exposure**: admin credentials and token password values are
  sensitive outputs that still land in state — the Azure API has no
  write-only variants here. Rotate tokens via `password1_expiry`/`password2_
  expiry` changes (each expiry change forces a new password resource).
- **CMK**: the `encryption.identity_client_id` identity must also appear in
  `identity.identity_ids`, and the identity needs Key Vault get access on
  the key — module validates the pairing, the Key Vault policy is
  consumer-side.
- **ABAC mode**: `AbacRepositoryPermissions` changes the RBAC story —
  per-repository ABAC conditions instead of the legacy registry-wide
  permissions. Pick at creation; switching modes on an existing registry is
  disruptive and not covered by this module.
- **SQL RBAC / tasks / cache rules**: Container Registry Tasks, agent pools,
  connected registries and cache (pull-through) rules are out of scope for
  this module; `azuread_authentication_as_arm_policy_enabled` is the
  pass-through for their ARM-token prerequisites.
- Tags are authoritative — a change replaces the whole tag set; RBAC needed
  is `Microsoft.ContainerRegistry/registries/write` plus children on scope.

## Import

Registries import by ARM ID; children reference the registry by ARM ID:

```
tofu import 'azurerm_container_registry.registry["primary-eu"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<name>"
tofu import 'azurerm_container_registry_webhook.webhook["primary-eu.deploy"]' "<registry_id>/webHooks/<webhook-name>"
tofu import 'azurerm_container_registry_scope_map.scope_map["primary-eu.ci-pull"]' "<registry_id>/scopeMaps/<scope-map-name>"
tofu import 'azurerm_container_registry_token.token["primary-eu.ci"]' "<registry_id>/tokens/<token-name>"
tofu import 'azurerm_container_registry_token_password.password["primary-eu.ci"]' "<registry_id>/tokens/<token-name>/passwords/password"
```
