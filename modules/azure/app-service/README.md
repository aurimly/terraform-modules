# azure/app-service

> **Provider floor** — developed against the `azurerm` provider v5.x
> (v5.9.0 at build time), using the modern
> `azurerm_service_plan`/`azurerm_linux_web_app`/`azurerm_windows_web_app`
> resources exclusively; nothing is pinned in-module — pin the provider
> version at the consumer's root Terragrunt level.

Map-keyed module for Azure App Service: `azurerm_service_plan` plans,
`azurerm_linux_web_app` and `azurerm_windows_web_app` web apps, and the
`azurerm_linux_web_app_slot` / `azurerm_windows_web_app_slot` slots under them.
Apps bind to plans by `service_plan_key` (in-module) or by full ARM resource
ID for a plan managed elsewhere; slots bind via `app_key` and output keys
compose `<app_key>.<slot_key>`.

The deprecated `azurerm_app_service` / `azurerm_app_service_plan` resources
(removed in azurerm 4.0) are not used — only the modern
`service_plan`/`web_app`/`slot` resources.

## Destroy semantics (read before using)

- Removing a plan key with apps still referencing it fails — plans cannot be
  deleted while web apps exist on them. Remove the apps (and slots) first.
- Removing an app key with slots replaces nothing: slots are separate
  resources; remove the slot entries in the same run — the slot resources
  reference the app by ID and lose their parent otherwise.
- Renaming an app (`name`) recreates the Azure site — a global rename, since
  app names are globally unique; slot `<app_key>.<slot_key>` addresses
  survive, the `_ismaster`/slot names underneath carry over to the new site.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `service_plans` | `map(object)` | — | Map of App Service plans keyed by an arbitrary unique ID. |
| `linux_web_apps` | `map(object)` | `{}` | Map of Linux web apps keyed by an arbitrary unique ID. |
| `windows_web_apps` | `map(object)` | `{}` | Map of Windows web apps keyed by an arbitrary unique ID. |
| `linux_web_app_slots` | `map(object)` | `{}` | Map of Linux slots keyed by an arbitrary ID; entries carry `app_key` into `linux_web_apps`. |
| `windows_web_app_slots` | `map(object)` | `{}` | Map of Windows slots keyed by an arbitrary ID; entries carry `app_key` into `windows_web_apps`. |

Map keys must not contain `.` at any level — keys compose into output
identifiers (`<app_key>.<slot_key>`).

Plan-time validation: names, resource groups and locations non-empty;
app names in the provider's 1–60 alphanumeric/hyphen format and unique
across all apps case-insensitively; exactly one plan wiring per app
(`service_plan_key` or `service_plan_id`); `os_type` values; plan SKU rules
(auto-scale needs a Premium `P*` SKU, elastic worker counts an `EP*` SKU,
zone balancing needs >1 worker, ASE IDs an Isolated `I*` SKU); Linux/Windows
apps strictly on matching-OS plans with the plan's region and no
`always_on` on F1/D1/SHARED tiers; identity types; connection-string
types; TLS floor versions; `ftps_state`; IP-restriction entries with
exactly one source and Allow/Deny actions; slot `app_key` references and
per-app slot-name uniqueness; the Linux / Windows `application_stack`
shapes each with their consistency rules; and tags within Azure's limits.

### `service_plans` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Plan name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the plan lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `os_type` | `string` | — | `Windows`, `Linux` or `WindowsContainer` — the OS is immutable and tied to the SKU pricing family (validated). WindowsContainer plans do not accept `azurerm_windows_web_app` apps (see Notes). |
| `sku_name` | `string` | — | Plan SKU in the documented form: `F1`, `D1`, `SHARED` (free/shared), `B1`–`B3` (basic), `S1`–`S3` (standard), `P0v3`–`P5mv4` (premium), `EP1`–`EP3` (elastic premium), `I1`–`I3`, `I1v2`–`I3v2` (isolated), `FC1` (flex consumption) and friends. Case differences are suppressed provider-side; not enum-validated here — the SKU list grows. |
| `worker_count` | `number` | `null` | Fixed worker count; leave set only for non-auto-scaled plans (validated against `premium_plan_auto_scale_enabled`). |
| `maximum_elastic_worker_count` | `number` | `null` | Elastic worker ceiling — Elastic Premium (`EP*`) SKUs or Premium with auto-scale enabled (validated). |
| `premium_plan_auto_scale_enabled` | `bool` | `null` | Premium v2/v3/mv3/v4 automatic scaling; mutually exclusive with a fixed `worker_count` (validated). |
| `per_site_scaling_enabled` | `bool` | `false` | Per-app rather than per-plan scaling (in-place change). |
| `zone_balancing_enabled` | `bool` | `false` | Spread the plan across availability zones (in-place change); needs more than one worker (validated). |
| `app_service_environment_id` | `string` | `null` | Full ARM resource ID of an ASE — only with Isolated `I*` SKUs (validated). |
| `tags` | `map(string)` | `{}` | Tags. |

### `linux_web_apps` / `windows_web_apps` object

The frames are identical; parent attributes first.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | App name — 1–60 letters/digits/hyphens (validated), **globally unique across Azure** (it owns `<name>.azurewebsites.net`). Immutable — renaming recreates the site. |
| `resource_group_name` | `string` | — | Resource group the app lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region — must match the plan's (validated for in-module plans). Immutable — changing it forces replacement. |
| `service_plan_key` | `string` | `null` | Key into `service_plans` (validated to exist) — set exactly one of this or `service_plan_id`. |
| `service_plan_id` | `string` | `null` | Full ARM resource ID of an external plan. |
| `app_settings` | `map(string)` | `{}` | App settings (`WEBSITE_*`, custom). |
| `connection_strings` | `map(object)` | `{}` | Keyed by the connection string **name**: `{ type = APIHub/Custom/DocDb/EventHub/MySql/NotificationHub/PostgreSQL/RedisCache/ServiceBus/SQLAzure/SQLServer }` and `value` — use a `@Microsoft.KeyVault` secret reference for key-vault-backed values. |
| `identity` | `object` | `null` | Managed identity: `type` (`SystemAssigned`, `UserAssigned`, `"SystemAssigned, UserAssigned"`) and `identity_ids` (required when UserAssigned, validated). |
| `key_vault_reference_identity_id` | `string` | `null` | Identity used for `@Microsoft.KeyVault` app-setting references. |
| `virtual_network_subnet_id` | `string` | `null` | ARM ID of the VNET-integration subnet (validated). Conflicts with the standalone `azurerm_app_service_virtual_network_swift_connection` resource — pick one per app. |
| `https_only` | `bool` | `false` | Redirect HTTP → HTTPS. |
| `public_network_access_enabled` | `bool` | `true` | Site-level public switch — `false` for private-endpoint-only apps. |
| `client_affinity_enabled` | `bool` | `false` | ARR affinity cookie. |
| `client_certificate_enabled` / `client_certificate_mode` / `client_certificate_exclusion_paths` | `bool` / `string` / `string` | `false` / `null` / `null` | Client-cert config — mode is `Required`/`Optional`/`OptionalInteractiveUser` (validated; only when enabled). |
| `enabled` | `bool` | `true` | Site enabled switch. |
| `end_to_end_tls_encryption_enabled` | `bool` | `false` | Front-end-to-worker TLS inside App Service. |
| `ftp_publish_basic_authentication_enabled` | `bool` | provider default | FTP basic auth; setting it `false` is the usual posture. |
| `webdeploy_publish_basic_authentication_enabled` | `bool` | provider default | WebDeploy basic auth; same posture note. |
| `site_config` | `object` | — | Typically one always-rendered block (see below or per app). |
| `tags` | `map(string)` | `{}` | Tags. |

### `site_config` object (Linux and Windows)

Mostly shared; per-OS differences marked.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `always_on` | `bool` | `true` | Always-on. Not available on F1/D1/SHARED plans (validated for in-module plans). |
| `api_definition_url` / `api_management_api_id` | `string` | `null` | OpenAPI definition URL / linked APIM API. |
| `app_command_line` | `string` | `null` | Startup command override. |
| `application_stack` | `object` | `null` | See per-OS shapes below. |
| `container_registry_use_managed_identity` / `container_registry_managed_identity_client_id` | `bool` / `string` | `null` / `null` | Linux only — pull private images without registry credentials in config. |
| `cors` | `object` | `null` | `allowed_origins` (list) plus `support_credentials`. |
| `default_documents` | `list(string)` | `[]` | Default document priority list. |
| `ftps_state` | `string` | `Disabled` | `AllAllowed`, `FtpsOnly` or `Disabled` (validated). Note: the provider default is `Disabled` where Azure's own is `AllAllowed` — set it explicitly. |
| `health_check_path` | `string` | `null` | Health endpoint; enables warm-up-aware pinging. |
| `health_check_eviction_time_in_min` | `number` | `null` | 2–10 (validated) and requires `health_check_path` (validated). |
| `http2_enabled` | `bool` | `null` | H2 at the front end. |
| `ip_restriction` / `scm_ip_restriction` | `map(object)` | `{}` | Access rules (see below). |
| `ip_restriction_default_action` / `scm_ip_restriction_default_action` | `string` | `null` | `Allow`/`Deny` fallback for the respective rule sets (validated). |
| `load_balancing_mode` | `string` | `null` | e.g. `LeastRequests`, `MostRequests`, `ResponseTime`, `PerfTraffic`, `TimeToFirstRequest`. |
| `local_mysql_enabled` | `bool` | `null` | Bundled MySQL. |
| `minimum_tls_version` / `scm_minimum_tls_version` | `string` | `1.2` / `1.2` | TLS floor, `1.0`–`1.3` (validated). |
| `remote_debugging_enabled` / `remote_debugging_version` | `bool` / `string` | `null` / `null` | VS attach debugging — version `VS2017`/`VS2019`/`VS2022`. |
| `scm_use_main_ip_restriction` | `bool` | `null` | Reuse ip_restriction set for SCM. |
| `use_32_bit_worker` | `bool` | `null` | 32-bit worker mode (Windows sites use the classic 32-bit switch; Linux sites the worker-size toggle). |
| `vnet_route_all_enabled` | `bool` | `null` | Route all egress through the VNET-integration subnet. |
| `websockets_enabled` | `bool` | `null` | WebSockets. |
| `worker_count` | `number` | `null` | Site-level worker override (per-site scaling plans). |
| `auto_swap_slot_name` | `string` | `null` | Slots only — auto-swap this slot into production. |

`ip_restriction` / `scm_ip_restriction` entries, keyed by an arbitrary ID:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Restriction name. |
| `action` | `string` | `Allow` | `Allow` or `Deny` (validated). |
| `priority` | `number` | `null` | Rule priority; only one rule may sit below the default 65000 restriction. |
| `ip_address` | `string` | `null` | IPv4 or CIDR. Exactly one of `ip_address`, `service_tag`, `virtual_network_subnet_id` (validated). |
| `service_tag` | `string` | `null` | Azure service tag, e.g. `AzureCloud`. |
| `virtual_network_subnet_id` | `string` | `null` | ARM ID, typically `dependency.subnet.outputs.subnet_ids["workload"]` with `azure/subnet`. |
| `description` | `string` | `null` | Free-text note. |

### `application_stack` object

Linux (one stack only, validated; docker image requires `docker_registry_url`, the Java trio `java_server` + `java_server_version` + `java_version` is all-or-none):

| Attribute | Note |
|---|---|
| `docker_image_name`, `docker_registry_url`, `docker_registry_username`, `docker_registry_password` | Custom images — don't duplicate the registry credentials in `app_settings`, the provider manages the DOCKER_REGISTRY_SERVER_* keys. |
| `dotnet_version`, `go_version`, `node_version`, `php_version`, `python_version` | One language per app (the resource itself allows only a single stack). |
| `java_server`, `java_server_version`, `java_version` | Java trio — all or none. |

Windows: `current_stack` (`dotnet`, `dotnetcore`, `node`, `python`, `php`,
`java` — required when any version field is set, validated) plus at most the
matching version attribute: `dotnet_version`, `dotnet_core_version`,
`tomcat_version`, `java_version`, `node_version`, `php_version`, `python`
(boolean for python3).

### `linux_web_app_slots` / `windows_web_app_slots` object

The parent-app frame minus `resource_group_name`/`location` (slots inherit),
plus:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `app_key` | `string` | — | Key into the matching app map (validated). |
| `service_plan_id` | `string` | `null` | Optional plan override — otherwise the slot rides the parent app's plan. |
| `name` | `string` | — | Slot name, unique per app (validated), same 1–60 charset. |

Everything else (`app_settings`, `connection_strings`, `identity`,
top-level access flags, `site_config` with `auto_swap_slot_name`, `tags`)
mirrors the parent app frame.

## Outputs

| Name | Description |
|---|---|
| `service_plan_ids` / `service_plan_names` | Map of plan key => ARM ID (provider type `serverFarms`) / name. |
| `linux_web_app_ids` / `windows_web_app_ids` | Map of app key => ARM ID (`/.../Microsoft.Web/sites/<name>`). |
| `linux_web_app_names` / `windows_web_app_names` | Map of app key => app name. |
| `linux_web_app_default_hostnames` / `windows_web_app_default_hostnames` | Map of app key => `<name>.azurewebsites.net`. Wire via `azure/dns-records`. |
| `linux_web_app_outbound_ip_addresses` / `windows_web_app_outbound_ip_addresses` | Map of app key => egress IP list (allow-list targets for downstream systems). |
| `linux_web_app_identity_principal_ids` / `windows_web_app_identity_principal_ids` | Map of app key => system-assigned principal ID, null when none. |
| `linux_web_app_custom_domain_verification_ids` / `windows_web_app_custom_domain_verification_ids` | Map of app key => verification ID for `asuid.<domain>` TXT records. |
| `linux_web_app_slot_ids` / `windows_web_app_slot_ids` | Map of `<app_key>.<slot_key>` => ARM ID (`/.../sites/<app>/slots/<slot>`). |
| `linux_web_app_slot_default_hostnames` / `windows_web_app_slot_default_hostnames` | Map of `<app_key>.<slot_key>` => slot hostname. |

## Example

```hcl
service_plans = {
  "platform" = {
    name                = "asp-platform-prod"
    resource_group_name = "rg-apps-prod"
    location            = "westeurope"
    os_type             = "Linux"
    sku_name            = "P1v3"
    worker_count        = 2
    zone_balancing_enabled = true
  }
}

linux_web_apps = {
  "api" = {
    name                = "web-api-prod-euw"
    resource_group_name = "rg-apps-prod"
    location            = "westeurope"
    service_plan_key    = "platform"

    app_settings = {
      WEBSITE_RUN_FROM_PACKAGE = "https://example.com/api.zip"
    }

    identity = {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-id-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-api"]
    }

    ftp_publish_basic_authentication_enabled      = false
    webdeploy_publish_basic_authentication_enabled = false

    site_config = {
      health_check_path = "/healthz"
      health_check_eviction_time_in_min = 5

      application_stack = {
        node_version = "22-lts"
      }

      cors = {
        allowed_origins = ["https://portal.example.com"]
      }
    }

    tags = { env = "prod" }
  }
}

linux_web_app_slots = {
  "api-staging" = {
    app_key = "api"
    name    = "staging"

    site_config = {
      auto_swap_slot_name = "production"

      application_stack = {
        node_version = "22-lts"
      }
    }
  }
}
```

## Notes

- **App names are globally unique** — they prefix the default hostname. A
  claimed name surfaces at apply; this module validates format only. The
  module's own entries are double-checked case-insensitively.
- **WindowsContainer plans don't host `azurerm_windows_web_app`** — those
  plans run containerized sites (docker compose images). This module
  validates `windows_web_apps` against plain `Windows` plans; create
  WindowsContainer apps with a dedicated container-app toolchain instead.
- **`ftps_state` and the basic-auth flags** default differently between the
  provider and the Azure portal (`Disabled` vs `AllAllowed`; auth flags
  default to enabled provider-side). Set them explicitly — the example
  posture turns FTP/WebDeploy basic auth off.
- **VNET integration** takes a dedicated subnet (delegated to
  `Microsoft.Web/serverFarms`); `virtual_network_subnet_id` conflicts with
  the standalone swift-connection resource. Subnet join needs
  `Microsoft.Network/virtualNetworks/subnets/joinViaServiceTag`.
- **Custom domains are out of scope** (pass-through candidate for a later
  minor): add the `asuid.<domain>` TXT record with this module's
  `custom_domain_verification_ids` output via `azure/dns-records`, then
  bind the hostname (`azurerm_app_service_custom_hostname_binding`
  resource) consumer-side.
- **Deliberately not exposed** (pass-through candidates): `auth_settings`/
  `auth_settings_v2` (possibly with auth V2 providers), `backups`,
  `logs` (site diagnostics), `storage_account` mounts, `sticky_settings`,
  `zip_deploy_file`, `azurerm_app_service_virtual_network_swift_connection`,
  auto-heal rules, `managed_pipeline_mode`, `minimum_tls_cipher_suite`,
  slot `virtual_network_backup_restore_enabled`,
  `virtual_application` (Windows) and `handler_mapping`.
- The caller needs `Microsoft.Web/serverFarms/write` and
  `Microsoft.Web/sites/write`.

## Import

```shell
tofu import 'azurerm_service_plan.service_plan["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/serverFarms/<name>"
tofu import 'azurerm_linux_web_app.linux_web_app["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<name>"
tofu import 'azurerm_windows_web_app.windows_web_app["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<name>"
tofu import 'azurerm_linux_web_app_slot.linux_slot["<app_key>.<slot_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<app-name>/slots/<slot-name>"
tofu import 'azurerm_windows_web_app_slot.windows_slot["<app_key>.<slot_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<app-name>/slots/<slot-name>"
```
