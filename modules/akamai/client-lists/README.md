# akamai/client-lists

Map-keyed module for Akamai client lists (IP, GEO, ASN, TLS fingerprint, file hash, user ID, domain, request header name/value) with item management and optional staging/production activations.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `client_lists` | `map(object)` | — | Map of client lists keyed by an arbitrary unique ID. |

### `client_lists` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | List name, unique ignoring case across the map (Akamai list IDs embed the name; validated). |
| `type` | `string` | — | One of `IP`, `GEO`, `ASN`, `TLS_FINGERPRINT`, `FILE_HASH`, `USER_ID`, `DOMAIN`, `REQUEST_HEADER_NAME_VALUE` (validated). Force-new: changing it replaces the list, which `prevent_destroy` blocks — see Notes. |
| `contract_id` | `string` | — | Contract ID (`ctr_` prefix). |
| `group_id` | `number` | — | Numeric group ID (the provider attribute is a number, no `grp_` prefix). |
| `notes` | `string` | null | Free text. |
| `tags` | `list(string)` | `[]` | List tags. |
| `items` | `list(object)` | — | At least one item; shape is per-type — see below. |
| `activation` | `object` | null | `{ network, comments, notification_recipients }`. `network` must be `STAGING` or `PRODUCTION` (validated). Absent ⇒ no activation resource for the entry. |

### Item shape (per type)

| Type | Item shape |
|---|---|
| `REQUEST_HEADER_NAME_VALUE` | `key` (required, non-empty) + `values` (required, at least one entry); `value` must be empty (validated both ways). |
| every other type | `value` (required, non-empty); `key` and `values` must be empty (validated both ways). |

All items also accept optional `description`, `tags`, `expiration_date` (RFC3339-shaped when set; light check — the API is the final arbiter).

## Outputs

All keyed by the input map key:

| Output | Description |
|---|---|
| `client_list_ids` | key => unique list ID (`<contractId>_<NAME>`), the import ID of the resource. |
| `client_list_versions` | key => list version (starts at 1, increments on every modification; wired into the activation resource). |
| `activation_statuses` | key => activation status, only for entries with an activation. |

## Example

```hcl
module "client_lists" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/akamai/client-lists?ref=v2.68.0"

  client_lists = {
    "bad-asns" = {
      name        = "bad-asns"
      type        = "ASN"
      contract_id = "ctr_C-0N7RAC7"
      group_id    = 12345
      items = [
        { value = "64496" },
        { value = "64497", description = "bulletproof hoster" }
      ]
      activation = {
        network                 = "STAGING"
        notification_recipients = ["secops@example.com"]
      }
    }
    "blocked-headers" = {
      name        = "blocked-headers"
      type        = "REQUEST_HEADER_NAME_VALUE"
      contract_id = "ctr_C-0N7RAC7"
      group_id    = 12345
      items = [{
        key    = "X-Gateway"
        values = ["untrusted.example.net"]
      }]
    }
  }
}
```

### Wiring records

Downstream units consume `client_list_ids` with a Terragrunt `dependency` block (Terraform-style `depends_on = [module.client_lists]` does not exist in Terragrunt):

```hcl
dependency "client_lists" {
  config_path = "../client-lists"

  mock_outputs = {
    client_list_ids = { "bad-asns" = "123456_BAD-ASNS" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  client_list_id = dependency.client_lists.outputs.client_list_ids["bad-asns"]
}
```

The mocks exist so `validate`/`plan` work on a fresh clone before the list unit has state; the first downstream apply must follow the list unit's apply.

### Provider authentication

The Akamai provider authenticates with EdgeGrid credentials — an `~/.edgerc` file (optionally selecting a section with `config_section` in the provider block at the consumer's unit level) or the `AKAMAI_*` environment variables. The consumer unit also needs Client Lists authorization. Modules never configure the provider themselves.

## Notes

- Items are whole-set managed: the resource replaces the item list on every change (deterministic). Every item change increments `version`, which re-triggers the activation resource (expected).
- `type` is force-new — changing it forces list replacement, which `prevent_destroy` blocks outright. Recreate under a new map key instead of lifting `prevent_destroy`.
- Deletion ordering: the activation resource must be destroyed (deactivating the list) before the list resource can be deleted; Terraform's reverse dependency order handles the stored-network case. A destroyed activation leaves the remote list active on the last-applied network.
- Changing `activation.network` activates the new network without deactivating the old one; destroying the activation deactivates only the network stored in state — a list active on another network (or through another state) stays live but unrepresented. Verify in Control Center.
- `comments`/`notification_recipients`-only changes do not re-activate (documented provider behavior).
- `siebel_ticket_id` on activations is omitted by the module (same documented limitation as the property module's `compliance_record`).
- `USER_ID`-type lists trigger a username-translation API call in the provider (a plan/apply-time remote read).
- The provider floor `>= 12.0.0` is a loose floor; exact pinning is done at the consumer's unit level.

## Import

The list resource imports by its unique list ID; the activation resource imports as `listID:network`.

```hcl
import {
  to = module.client_lists.akamai_clientlist_list.list["bad-asns"]
  id = "123456_BAD-ASNS"
}

import {
  to = module.client_lists.akamai_clientlist_activation.activation["bad-asns"]
  id = "123456_BAD-ASNS:STAGING"
}
```
