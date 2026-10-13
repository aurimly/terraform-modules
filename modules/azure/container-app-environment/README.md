# azure/container-app-environment

> **Provider floor** — developed against the `azurerm` provider v5.x
> (v5.9.0 at build time), on the `Microsoft.App` `managedEnvironments`
> resource; nothing is pinned in-module — pin the provider version at the
> consumer's root Terragrunt level.

Map-keyed module for Azure Container Apps managed environments
(`azurerm_container_app_environment`): one environment per entry, with
Log Analytics/Azure Monitor logging, workload profiles, VNet injection
(external-connectivity or ILB mode) and zone redundancy. Apps attach by
the environment's ARM ID — see the sibling `azure/container-app` module,
which takes `container_app_environment_id` (wire it through
`environment_ids` here). This module never creates apps.

## Destroy semantics (read before using)

- Removing an environment key destroys the environment and every app,
  job and certificate hosted in it — apps reference the environment by ID
  and lose their parent otherwise. Delete the app entries (the
  `azure/container-app` module) and everything else attached to it first.
- Renaming an environment (or moving it to another resource group/region)
  forces replacement — and with it, every app held on the ARM ID. The
  service-generated default domain changes, so any marketing/hosting
  reference breaks with it.
- `infrastructure_subnet_id`, `internal_load_balancer_enabled`,
  `zone_redundancy_enabled`, `infrastructure_resource_group_name` and
  `dapr_application_insights_connection_string` are set at creation only —
  changing any of them forces replacement (Azure's managed-environment
  rule, not a module choice).
- `logs_destination` and `log_analytics_workspace_id` are the exception:
  changing them updates the environment in place (verified against the
  provider's update path) — most other environment attributes replace.
- An environment created without workload profiles can never add them
  later (that would force replacement); an environment created with
  profiles must always keep at least one — removing all profile entries
  forces replacement.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `container_app_environments` | `map(object)` | — | Map of managed environments keyed by an arbitrary unique ID. |

Map keys must not contain `.` and must be non-blank — keys are the
identifiers referenced in the module's outputs.

Plan-time validation: `name` in the provider's 2–60 alphanumeric/hyphen
format (no leading/trailing hyphen); `name`/`resource_group_name`/
`location` non-empty; `logs_destination` pairing with
`log_analytics_workspace_id` (exactly mirrored to the provider's rule —
see the `logs_destination` row); `log_analytics_workspace_id` a full ARM
workspace ID; `dapr_application_insights_connection_string` non-blank when
set; `infrastructure_subnet_id` a full ARM subnet ID;
`internal_load_balancer_enabled` and `zone_redundancy_enabled` only with a
subnet; `infrastructure_resource_group_name` only with workload profiles;
profile names unique per environment case-insensitively; profile type in
the 14-value provider list, the Consumption profile named `Consumption`
with no counts; `maximum_count` ≥ 1 with `minimum_count` not exceeding it;
at most one Consumption profile; `public_network_access` in the
`Enabled`/`Disabled` set and never `Enabled` with ILB; identity types; and
tags within Azure's limits.

### `container_app_environments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Environment name: 2–60 characters, alphanumeric/hyphen (validated). Scoped to the resource group; the globally-unique part is the service-generated default domain (outputs). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the environment lives in (typically `dependency.rg.outputs.resource_group_names["platform"]`). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `logs_destination` | `string` | `null` | `log-analytics` or `azure-monitor` (validated) — omit it for streamed-only logs (the service keeps no table). Pairs exactly with `log_analytics_workspace_id` (validated): a workspace ID requires `log-analytics` and vice versa; `azure-monitor` forbids the workspace. Changing it is an in-place update. |
| `log_analytics_workspace_id` | `string` | `null` | Full ARM ID of the Log Analytics workspace (typically `dependency.log.outputs.workspace_ids["platform"]`). Pairs with `logs_destination` (validated). Changing it is an in-place update that re-wires where app logs land. |
| `dapr_application_insights_connection_string` | `string` | `null` | Application Insights connection string the Dapr sidecars use to export service-to-service telemetry. Sensitive on the provider side. Set at creation only — changing it forces replacement; if you will use it, wire it in from day one. |
| `identity` | `object` | `null` | Optional managed-identity block — see the object table. Needed when Key Vault-referenced certificates/dapr secrets read with an identity. |
| `infrastructure_subnet_id` | `string` | `null` | Full ARM subnet ID for VNet injection, dedicated to the environment: at least /23 for consumption-only, at least /27 for workload-profile environments (Azure reserves addresses within the subnet for its own platform services). Set at creation only — changing it forces replacement. Carry it from `azure/subnet` outputs. |
| `infrastructure_resource_group_name` | `string` | `null` | Name of the platform-managed resource group hosting the environment's infrastructure when workload profiles are used (validated — requires a `workload_profile` entry); if a subnet is used, the resource group is created in the subnet's subscription. Set at creation only — changing it forces replacement. |
| `internal_load_balancer_enabled` | `bool` | `null` | ILB mode: apps in the environment get internal-only FQDNs resolved to the subnet IP. Requires `infrastructure_subnet_id` (validated). Set at creation only — changing it forces replacement. Omit (or leave null) for the false default. |
| `zone_redundancy_enabled` | `bool` | `null` | Zone spreading of the environment across the region's availability zones. Requires `infrastructure_subnet_id` (validated). Set at creation only — changing it forces replacement. Omit (or leave null) for the false default. |
| `public_network_access` | `string` | `null` | `Enabled` or `Disabled` (validated) — must not be `Enabled` in ILB mode (validated; the provider rejects it). Leave unset to let Azure decide based on VNet provisioning: the attribute is computed by the service and a hard default invites perpetual diffs. Updated in place. |
| `mutual_tls_enabled` | `bool` | `false` | mTLS between the platform's ingress and app sidecars. Public preview — enabling it may increase response latency and reduce maximum throughput under load. Updated in place (but see Notes). |
| `workload_profile` | `map(object)` | `{}` | Workload profiles on the environment keyed by an arbitrary unique ID (name values live in the objects) — see the object table. The environment owns its lifecycle: an environment created without profiles can never add one, and one created with them must always keep at least one. |
| `tags` | `map(string)` | `{}` | Tags on the environment. The tag set is authoritative — see Notes. |

### `identity` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `SystemAssigned`, `UserAssigned` or `SystemAssigned, UserAssigned` (case-sensitive; validated). |
| `identity_ids` | `list(string)` | `[]` | Full ARM resource IDs of the user-assigned identities (at least one when the type contains `UserAssigned` — validated). |

### `workload_profile` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Profile name apps reference via `workload_profile_name` in `azure/container-app`. Unique within the environment, case-insensitively (validated). The single Consumption profile is named `Consumption` exactly. |
| `workload_profile_type` | `string` | — | `Consumption`, `Consumption-GPU-NC24-A100`, `Consumption-GPU-NC8as-T4`, `D4`, `D8`, `D16`, `D32`, `E4`, `E8`, `E16`, `E32`, `NC24-A100`, `NC48-A100` or `NC96-A100` (validated — the provider's own list). `Consumption` names are fixed to the profile (validated); dedicated types carry the counts below. |
| `maximum_count` | `number` | `null` | Top of the dedicated profiles' instance range (≥ 1, not below `minimum_count` — validated). Rejected on the Consumption profile (validated — that profile autoscales on its own). |
| `minimum_count` | `number` | `null` | Bottom of the dedicated profiles' instance range. Rejected on the Consumption profile (validated). |

## Outputs

| Name | Description |
|---|---|
| `environment_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.App/managedEnvironments/<name>`) — the value `azure/container-app`'s `container_app_environment_id` takes. |
| `environment_names` | Map of key => environment name. |
| `environment_default_domains` | Map of key => the service-generated default domain (`<name>-<hash>.<region>.azurecontainerapps.io`) — apps get FQDNs under it. |
| `environment_static_ip_addresses` | Map of key => the environment's static IP — its public inbound IP, or the ILB subnet IP in ILB mode. |
| `environment_custom_domain_verification_ids` | Map of key => the environment's custom-domain verification ID — the `asuid.<domain>` TXT value for domains bound to the environment's own DNS suffix. Marked sensitive in this module as a precaution (it is domain-bounding data that should not scatter beyond state) — see Notes. |
| `environment_identity_principal_ids` | Map of key => the system-assigned principal ID (null when there is no identity or a user-assigned-only one) — the value RBAC grants on the environment carry. |
| `environment_docker_bridge_cidrs` | Map of key => the environment's docker-bridge CIDR — populated only for VNet-injected environments. |
| `environment_platform_reserved_cidrs` | Map of key => the environment's platform-reserved CIDR — populated only for VNet-injected environments. |
| `environment_platform_reserved_dns_ip_addresses` | Map of key => the environment's platform-reserved internal DNS IP — populated only for VNet-injected environments; apps talking to platform services must route through this stub. |

## Example

```hcl
container_app_environments = {
  "platform" = {
    name                = "cae-eu-prod-01"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"

    logs_destination           = "log-analytics"
    log_analytics_workspace_id = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-terraform-state/providers/Microsoft.OperationalInsights/workspaces/log-platform-prod"

    infrastructure_subnet_id           = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/snet-cae"
    infrastructure_resource_group_name = "rg-managed-cae"
    zone_redundancy_enabled            = true

    workload_profile = {
      "d4" = {
        name                  = "D4"
        workload_profile_type = "D4"
        maximum_count         = 10
        minimum_count         = 2
      }
      "gpu" = {
        name                  = "GPU-24"
        workload_profile_type = "Consumption-GPU-NC24-A100"
      }
    }

    tags = {
      env = "prod"
    }
  }
}
```

An app unit wires downstream like:

```hcl
dependency "cae" {
  config_path = "../cae"

  mock_outputs = {
    environment_ids = {
      "platform" = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "output"]
}
```

and passes `dependency.cae.outputs.environment_ids["platform"]` into the
`azure/container-app` module's `container_app_environment_id`.

## Notes

- The environment is the platform piece: region-pinned, replacement-heavy
  and shared by many apps. Keep it in its own unit and let app units
  reference `environment_ids` — an app change never re-plans the
  environment this way, and an environment replacement story stays
  opt-in and reviewable.
- Subnet sizing (per provider/Azure docs): the environment's subnet must
  be dedicated to it and must be at least /23 (consumption-only) or /27
  (workload-profile environments; the platform also reserves addresses
  inside it for infrastructure services). Plan the subnet in
  `azure/subnet` and delegate it fully to one environment.
- Workload profiles: an environment is created either all-consumption
  (no profile entries) or with dedicated profiles. Turning an
  all-consumption environment into a profile environment later forces
  replacement, and an environment with profiles must always keep at least
  one — keep one profile entry permanent and change counts instead. The
  API may inject an extra `Consumption` profile into dedicated-profile
  environments; the provider diff-suppresses that injection, so a plan
  stays clean, and the module's map passes through without
  normalization on top.
- `public_network_access` is computed by the service: leaving it unset is
  the normal case. Force `Disabled` only for environments you want to be
  publicly unreachable on purpose (fully internal ones must use ILB
  instead — `Enabled` + ILB is rejected, validated).
- mTLS is public preview: sensible in sidecar-heavy topologies where
  service-to-service calls inside the environment must authenticate, at
  the cost of latency — re-reading it off can drop connections until the
  sidecars catch up, so treat the flip as maintenance work.
- Env-level DNS suffixes (`azurerm_container_app_environment_custom_domain`)
  and environment certificates/managed certificates
  (`azurerm_container_app_environment_certificate`,
  `..._managed_certificate`) are deliberate pass-through candidates (see
  below).
- Not exposed, deliberately (pass-through candidates for a later minor):
  environment certificates, managed certificates, the environment-level
  custom DNS suffix, and Dapr components
  (`azurerm_container_app_environment_dapr_component`) — apps bind to
  those separately or consumer-side.
- RBAC the caller needs: `Microsoft.App/managedEnvironments/write` (and
  delete) on the resource group; Key Vault certificate/dapr-secret flows
  additionally need the environment identity granted
  Key Vault Secrets User on the vault(s) — the identity wiring is this
  module's `identity` block, the vault grant is the consumer's IAM code.
- The `environment_custom_domain_verification_ids` output is marked
  sensitive by this module as a precaution; it lands in state and anyone
  with state access can read it.

## Import

```text
tofu import 'azurerm_container_app_environment.environment["<environment_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.App/managedEnvironments/<name>"
```
