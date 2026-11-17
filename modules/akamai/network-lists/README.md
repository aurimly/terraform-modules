# akamai/network-lists

Map-keyed module for Akamai network lists (IP/GEO) with entry management and optional staging/production activations.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `network_lists` | `map(object)` | — | Map of network lists keyed by an arbitrary unique ID. |

### `network_lists` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | List name, unique ignoring case across the map (Akamai list IDs embed the name; validated). Treat it as immutable: renaming embeds the new name in the unique ID and replaces the activation (`network_list_id` is force-new). |
| `type` | `string` | — | `IP` (≤ 50,000 IPv4/IPv6/CIDR entries) or `GEO` (≤ 275 EdgeScape country codes); validated. |
| `description` | `string` | — | Required by the provider. |
| `list` | `list(string)` | `[]` | Entries. `mode` is a per-apply delta operation: `APPEND` adds these to the remote list, `REMOVE` removes exactly these and retains the rest, `REPLACE` replaces the whole list. |
| `mode` | `string` | — | `APPEND`, `REPLACE` or `REMOVE` (validated). |
| `contract_id` | `string` | null | Optional contract for the list. |
| `group_id` | `number` | null | Numeric group ID (the provider attribute is a number, no `grp_` prefix). |
| `activation` | `object` | null | `{ network, notes, notification_emails }`. `network` must be `STAGING` or `PRODUCTION` (module policy — the provider passes the value through and defaults to `STAGING`), `notification_emails` needs at least one email. Absent ⇒ no activation resource for the entry. |

## Outputs

All keyed by the input map key:

| Output | Description |
|---|---|
| `network_list_ids` | key => unique list ID (`<contractId>_<NAME>`), the import ID of the resource. |
| `network_list_sync_points` | key => sync point (increments on every list modification; wired into the activation resource). |
| `network_list_types` | key => list type (`IP`/`GEO`). |
| `activation_statuses` | key => activation status, only for entries with an activation. |

## Example

```hcl
module "network_lists" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/akamai/network-lists?ref=v2.68.0"

  network_lists = {
    "blocked-cidrs" = {
      name        = "blocked-cidrs"
      type        = "IP"
      description = "CIDRs blocked at the edge"
      mode        = "REPLACE"
      list        = ["203.0.113.0/24", "2001:db8::/32"]
      contract_id = "ctr_C-0N7RAC7"
      group_id    = 12345
      activation = {
        network             = "STAGING"
        notification_emails = ["secops@example.com"]
      }
    }
    "allowed-countries" = {
      name        = "allowed-countries"
      type        = "GEO"
      description = "Countries allowed through"
      mode        = "REPLACE"
      list        = ["US", "GB"]
    }
  }
}
```

### Wiring records

Downstream units (typically AppSec or CDN behaviors referencing the list) consume `network_list_ids` with a Terragrunt `dependency` block (Terraform-style `depends_on = [module.network_lists]` does not exist in Terragrunt):

```hcl
dependency "network_lists" {
  config_path = "../network-lists"

  mock_outputs = {
    network_list_ids = { "blocked-cidrs" = "123456_BLOCKED-CIDRS" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  network_list_id = dependency.network_lists.outputs.network_list_ids["blocked-cidrs"]
}
```

The mocks exist so `validate`/`plan` work on a fresh clone before the list unit has state; the first downstream apply must follow the list unit's apply.

### Provider authentication

The Akamai provider authenticates with EdgeGrid credentials — an `~/.edgerc` file (optionally selecting a section with `config_section` in the provider block at the consumer's unit level) or the `AKAMAI_*` environment variables. The consumer unit also needs Network Lists authorization. Modules never configure the provider themselves.

## Notes

- `mode` semantics, source-verified: `APPEND`/`REMOVE` are delta operations against the remote list — `REMOVE` with an empty `list` removes nothing remotely (it is not a deactivation or emptying path); `REPLACE` replaces the whole list. Emptying a list = `REPLACE` with `[]`.
- **The module does not provide deactivation**: destroying the activation resource removes local state only, and no wrapped resource calls a deactivation endpoint. Withdrawing a list is done by removing the references that use it and managing the list itself via Control Center or the API.
- Every list modification increments `sync_point`, which re-triggers the activation resource (expected).
- Renaming a list embeds the new name in the unique ID and replaces the activation (force-new `network_list_id`); the case-insensitive name-uniqueness validation exists because of that identity.
- Changing `activation.network` activates the new network without deactivating the old one — residual networks stay live but unmanaged; verify in Control Center.
- IP/GEO entry shape checks are kept permissive (module policy); the API is the final arbiter.
- The list resource carries `lifecycle { prevent_destroy = true }`: network lists are commonly referenced by AppSec policies and CDN behaviors, so removing an entry from the input map (or destroying the module) refuses at plan time instead of deleting the list out from under referencing configurations. Lift it deliberately at the consumer's resource block only when the teardown is intended.
- Subscriptions (`akamai_networklist_subscription`) and the redundant description resource are out of scope.
- The provider floor `>= 12.0.0` is a loose floor; exact pinning is done at the consumer's unit level.

## Import

The list resource imports by its unique ID. `akamai_networklist_activations` is **not importable** (the provider has no importer for it).

```hcl
import {
  to = module.network_lists.akamai_networklist_network_list.list["blocked-cidrs"]
  id = "123456_BLOCKED-CIDRS"
}
```
