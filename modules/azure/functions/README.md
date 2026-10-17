# azure/functions

> **Provider floor** — developed against the `azurerm` provider v5.x using
> the modern `azurerm_service_plan` / `azurerm_linux_function_app` /
> `azurerm_windows_function_app` resources and the
> `azurerm_function_app_host_keys` data source; nothing is pinned in-module —
> pin the provider version at the consumer's root Terragrunt level.

Map-keyed module for Azure Function Apps: `azurerm_service_plan` plans and
the `azurerm_linux_function_app` / `azurerm_windows_function_app` siblings.
Apps bind to plans by `service_plan_key` (in-module) or by full ARM resource
ID for a plan managed elsewhere.

## Destroy semantics (read before using)

- Removing a plan key with apps still referencing it fails — plans cannot be
  deleted while function apps exist on them. Remove the apps first.
- Renaming an app (`name`) recreates the Azure site and with it the function
  code package — the published code is not carried over; re-run your deploy
  step (CI or `zip_deploy_file`).

## Storage

Each app needs exactly one storage auth path: `storage_account_access_key`
or `storage_uses_managed_identity = true` (validated; the latter requires an
`identity` block on the app). The provider wires the
`AzureWebJobsStorage` / `WEBSITE_CONTENTAZUREFILECONNECTIONSTRING` settings
from these — do not set them by hand in `app_settings`.

`storage_key_vault_secret_id` (the vault-backed connection string path) is
not exposed — ask for it if you need vault-buffered storage credentials.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `service_plans` | `map(object)` | `{}` | Map of App Service plans keyed by an arbitrary unique ID. |
| `linux_function_apps` | `map(object)` | `{}` | Map of Linux function apps keyed by an arbitrary unique ID. |
| `windows_function_apps` | `map(object)` | `{}` | Map of Windows function apps keyed by an arbitrary unique ID. |

Map keys must not contain `.` at any level.

Plan-time validation: names, resource groups and locations non-empty; app
names 1–60 in the provider's alphanumeric/hyphen format (keep them ≤ 32 —
the name doubles as the functions host ID and longer names are prone to
host-ID collisions) and unique across all apps case-insensitively; exactly
one plan wiring per app (`service_plan_key` or `service_plan_id`);
`os_type` values; plan SKU rules (auto-scale needs a Premium `P*` SKU,
elastic worker counts an `EP*` SKU, zone balancing needs >1 worker, ASE IDs
an Isolated `I*` SKU); Linux/Windows apps strictly on matching-OS plans with
the plan's region and no `always_on` on Consumption (Y1/Dynamic) tiers;
exactly one storage auth path per app; `zip_deploy_file` with publishing
profile intact; no manual `FUNCTIONS_WORKER_RUNTIME` next to an
`application_stack`; identity types; connection-string types; TLS floor
versions; `ftps_state`; health-check pairing and 2–10 minute eviction
window; IP-restriction entries with exactly one source and Allow/Deny
actions; `runtime_scale_monitoring_enabled` with pre-warmed instances
>= 1; the per-OS `application_stack` shapes with their consistency rules;
and tags within Azure's limits.

### `service_plans` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Plan name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the plan lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `os_type` | `string` | — | `Windows`, `Linux` or `WindowsContainer` — the OS is immutable and tied to the SKU pricing family (validated). |
| `sku_name` | `string` | — | Plan SKU in the documented form: `Y1` (dynamic consumption), `B1`–`B3`, `S1`–`S3`, `P0v3`–`P5mv4`, `EP1`–`EP3`, `I1`–`I3`, `I1v2`–`I3v2` and friends. Consumption plans only fit HTTP/timer workloads sensibly — `always_on` is rejected for them (validated). Case differences are suppressed provider-side; not enum-validated here — the SKU list grows. |
| `worker_count` | `number` | `null` | Fixed worker count; leave set only for non-auto-scaled plans (validated against `premium_plan_auto_scale_enabled`). |
| `maximum_elastic_worker_count` | `number` | `null` | Elastic worker ceiling — Elastic Premium (`EP*`) SKUs or Premium with auto-scale enabled (validated). |
| `premium_plan_auto_scale_enabled` | `bool` | `null` | Premium v2/v3/mv3/v4 automatic scaling; mutually exclusive with a fixed `worker_count` (validated). |
| `per_site_scaling_enabled` | `bool` | `false` | Per-app rather than per-plan scaling (in-place change). |
| `zone_balancing_enabled` | `bool` | `false` | Spread the plan across availability zones (in-place change); needs more than one worker (validated). |
| `app_service_environment_id` | `string` | `null` | Full ARM resource ID of an ASE — only with Isolated `I*` SKUs (validated). |
| `tags` | `map(string)` | `{}` | Tags. |

### `linux_function_apps` / `windows_function_apps` object

The frames are identical apart from the `application_stack` stack set (see
below); parent attributes first.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | App name — 1–60 letters/digits/hyphens (validated), **globally unique across Azure** (it owns `<name>.azurewebsites.net`). Keep it ≤ 32: the name doubles as the functions host ID and the Azure Functions docs recommend 32 to avoid host-ID collisions. Immutable — renaming recreates the site. |
| `resource_group_name` | `string` | — | Resource group the app lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region — must match the plan's (validated for in-module plans). Immutable — changing it forces replacement. |
| `service_plan_key` | `string` | `null` | Key into `service_plans` (validated to exist) — set exactly one of this or `service_plan_id`. |
| `service_plan_id` | `string` | `null` | Full ARM resource ID of an external plan. |
| `storage_account_name` | `string` | — | Backend storage account for function content and host state. |
| `storage_account_access_key` | `string` | `null` | Storage access key — exactly one of this or `storage_uses_managed_identity` (validated). |
| `storage_uses_managed_identity` | `bool` | `null` | Reach the storage account with the app's managed identity; requires an `identity` block (validated). |
| `app_settings` | `map(string)` | `{}` | App settings (custom `WEBSITE_*`; runtime markers belong to `application_stack`, not here — `FUNCTIONS_WORKER_RUNTIME` is rejected next to it, validated). |
| `connection_strings` | `map(object)` | `{}` | Keyed by the connection string **name**: `type` (`APIHub`/`Custom`/`DocDb`/`EventHub`/`MySQL`/`NotificationHub`/`PostgreSQL`/`RedisCache`/`ServiceBus`/`SQLAzure`/`SQLServer`, validated) and `value` — use a `@Microsoft.KeyVault` secret reference for key-vault-backed values. |
| `functions_extension_version` | `string` | `null` | Functions runtime version (the provider default is `~4`). |
| `zip_deploy_file` | `string` | `null` | Local path of a zip package to deploy with the app. Requires `WEBSITE_RUN_FROM_PACKAGE = 1` (Linux alternatively `SCM_DO_BUILD_DURING_DEPLOYMENT = true`) in `app_settings`; conflicts with `webdeploy_publish_basic_authentication_enabled = false` (validated). |
| `identity` | `object` | `null` | Managed identity: `type` (`SystemAssigned`, `UserAssigned`, `"SystemAssigned, UserAssigned"`) and `identity_ids` (required when UserAssigned, validated). |
| `key_vault_reference_identity_id` | `string` | `null` | Identity used for `@Microsoft.KeyVault` app-setting references (requires the `identity` block, validated). |
| `virtual_network_subnet_id` | `string` | `null` | ARM ID of the VNET-integration subnet (validated). |
| `https_only` | `bool` | `false` | Redirect HTTP → HTTPS. |
| `public_network_access_enabled` | `bool` | `true` | Site-level public switch — `false` for private-endpoint-only apps. |
| `enabled` | `bool` | `true` | Site enabled switch. |
| `end_to_end_tls_encryption_enabled` | `bool` | `false` | Front-end-to-worker TLS inside App Service. |
| `daily_memory_time_quota` | `number` | `null` | Memory-time quota in GB-seconds — Consumption-plan scoped. |
| `builtin_logging_enabled` | `bool` | `null` | Built-in logging (maps to `AzureWebJobsDashboard`; runtime 1.x feature). |
| `content_share_force_disabled` | `bool` | `null` | Suppress the function content-share wiring — for `WEBSITE_RUN_FROM_PACKAGE`-style apps. |
| `ftp_publish_basic_authentication_enabled` / `webdeploy_publish_basic_authentication_enabled` | `bool` | provider default | Basic-auth publishing toggles; setting both `false` is the usual posture — but that breaks `zip_deploy_file` (validated). |
| `site_config` | `object` | — | Always-rendered block (see below). |
| `tags` | `map(string)` | `{}` | Tags. |

### `site_config` object (Linux / Windows)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `always_on` | `bool` | `false` | Keep instances warm; rejected on Consumption plans (validated). |
| `app_command_line` | `string` | `null` | Startup command override. |
| `app_scale_limit` | `number` | `null` | Maximum worker instances (Consumption/Premium plans). |
| `worker_count` | `number` | `null` | Fixed worker count (Premium/Dedicated plans). |
| `use_32_bit_worker` | `bool` | `null` | 32-bit worker (provider defaults: `false` on Linux, `true` on Windows). |
| `websockets_enabled` | `bool` | `null` | Web socket support. |
| `application_insights_connection_string` / `application_insights_key` | `string` | `null` | App Insights wiring (the provider maps these to `APPLICATIONINSIGHTS_CONNECTION_STRING` / inherited settings). |
| `application_stack` | `object` | `null` | Runtime — shapes differ per OS, below. Setting it requires no `FUNCTIONS_WORKER_RUNTIME` in `app_settings` (validated). |
| `cors` | `object` | `null` | `allowed_origins` (list) plus `support_credentials`. |
| `ftps_state` | `string` | `Disabled` | `AllAllowed`, `FtpsOnly` or `Disabled` (validated); provider default is `Disabled` where Azure's is `AllAllowed`. |
| `http2_enabled` | `bool` | `null` | H2 at the front end. |
| `minimum_tls_version` / `scm_minimum_tls_version` | `string` | `1.2` / `1.2` | TLS floor (validated: 1.0–1.3). |
| `health_check_path` | `string` | `null` | Health endpoint. |
| `health_check_eviction_time_in_min` | `number` | `null` | 2–10 (validated) and requires `health_check_path` (validated). |
| `pre_warmed_instance_count` | `number` | `null` | Pre-warmed instances (Elastic Premium). |
| `elastic_instance_minimum` | `number` | `null` | Minimum instances (Elastic Premium). |
| `runtime_scale_monitoring_enabled` | `bool` | `null` | Runtime scale monitoring — Elastic Premium apps with pre-warmed instances >= 1 (validated). |
| `vnet_route_all_enabled` | `bool` | `null` | Route all outbound traffic through the VNET (pairs with `virtual_network_subnet_id` or an `azurerm_linux_app_service_virtual_network_swift_connection`-style wiring). |
| `ip_restriction` / `scm_ip_restriction` | `map(object)` | `{}` | Access rules: `name`, `action` (`Allow`/`Deny`), `priority`, and exactly one of `ip_address` (CIDR), `service_tag` or `virtual_network_subnet_id` (validated), `description`. |
| `ip_restriction_default_action` / `scm_ip_restriction_default_action` | `string` | `null` | `Allow`/`Deny` fallback for the respective rule sets (validated). |

### `application_stack` object

Linux apps accept: `docker_registry_url` + `image_name` (both required
together, validated) + `image_tag` (± `registry_username` /
`registry_password` as a pair — or set
`site_config.container_registry_use_managed_identity` and skip
credentials) as a custom image, or a language stack — `dotnet_version`
(bare versions: `8.0`, `9.0`), `use_dotnet_isolated_runtime`,
`java_version`, `node_version`, `python_version`,
`powershell_core_version`, `use_custom_runtime`. Windows apps accept the
same language set plus the `v`-prefixed `dotnet_version` form (`v4.0`,
`v8.0`, validated) and no docker block. At most one runtime marker per
app, `use_custom_runtime` excludes every explicit stack (validated).

## Always-on tiers

`always_on = true` is required on Dedicated Basic/Standard tiers (B1/B2/B3,
S1–S3) for HTTP functions — without it the app idles to disk-stopped and
deploys get stuck. It is rejected on Consumption plans (validated for
in-module plans), where scale is controlled by `app_scale_limit` instead.

## Outputs

All keyed by the input map key. Family-prefixed (`linux_*`, `windows_*`) —
the input keys may repeat across families by design, so there are no merged
outputs.

| Name | Description |
|---|---|
| `service_plan_ids` / `service_plan_names` | Created plan ARM IDs / names. |
| `linux_function_app_ids` / `windows_function_app_ids` | Full ARM resource IDs (`/.../Microsoft.Web/sites/<name>`). |
| `..._names` | App names. |
| `..._default_hostnames` | `<name>.azurewebsites.net` — the HTTPS entry point. |
| `..._outbound_ip_addresses` | Egress IP list for downstream allow-listing. |
| `..._identity_principal_ids` | System-assigned principal IDs, `null` where unset. |
| `..._host_keys` | `{ default_function_key, primary_key }` per app from the `azurerm_function_app_host_keys` data source. **Sensitive**: keys land in state — treat any state access as key access. Rotating a platform key outside Terraform shows up as drift on the next read. |
| `..._custom_domain_verification_ids` | TXT-record verification value (`asuid.<domain>`) for custom domain stewardship. Sensitive. |

## Not (yet) in the module

Slots, `auth_settings` / `auth_settings_v2`, `backup`, `sticky_settings`,
the Flex Consumption resource family (`azurerm_linux_function_app_flex_consumption`
— a separate resource, Linux-only) and the `azurerm_function_app_function`
child resource (zip-deployed individual functions). Immutable options are
left to provider defaults; ask if you need one surfaced.

## Import

- `azurerm_linux_function_app` /
  `azurerm_windows_function_app` ← the app's full ARM resource ID (e.g.
  `/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<name>`).
- `azurerm_service_plan` ← the plan's full ARM resource ID (same shape,
  `Microsoft.Web/serverFarms`). Host keys are data-sourced and need no
  import.

## Example

```hcl
service_plans = {
  "func-plan" = {
    name                = "asp-func-prod"
    resource_group_name = "rg-example-prod"
    location            = "westeurope"
    os_type             = "Linux"
    sku_name            = "EP1"
  }
}

linux_function_apps = {
  "notify" = {
    name                          = "func-notify-prod"
    resource_group_name           = "rg-example-prod"
    location                      = "westeurope"
    service_plan_key              = "func-plan"
    storage_account_name          = "stfuncrexample"
    storage_uses_managed_identity = true

    identity = {
      type = "SystemAssigned"
    }

    app_settings = {
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
    }

    site_config = {
      application_stack = {
        dotnet_version = "8.0"
      }
    }
  }
}
```

A second function app on the same plan adds another key to
`linux_function_apps` — no extra assertion, the plan is shared by key.
