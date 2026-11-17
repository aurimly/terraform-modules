# akamai/property

Map-keyed module for Akamai Property Manager properties: rule trees passed in as JSON, traditional hostnames with certificate provisioning type, and optional staging/production activations.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `properties` | `map(object)` | — | Map of properties keyed by an arbitrary unique ID. |

### `properties` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Property Manager property name. |
| `contract_id` | `string` | — | Contract ID (`ctr_` prefix accepted). |
| `group_id` | `string` | — | Group ID (`grp_` prefix accepted). |
| `product_id` | `string` | — | Product ID (`prd_` prefix), e.g. `prd_SPM` for Standard TLS or `prd_Fresa` for Enhanced TLS. |
| `rule_format` | `string` | null | Dated rule format, e.g. `v2025-07-07`. |
| `rules` | `string` | null | Full rule-tree JSON — a JSON string, typically rendered with `data.akamai_property_rules_template` or `akamai_property_rules_builder` in the consumer unit (or written inline with `jsonencode`). Omitted ⇒ the provider's default rule tree. |
| `version_notes` | `string` | null | Notes stamped on the created/edited version. |
| `hostnames` | `list(object)` | `[]` | Traditional hostnames: `{ cname_from, cname_to, cert_provisioning_type }`. `cert_provisioning_type` must be `DEFAULT` or `CPS_MANAGED` (validated; `CCM` is a limited-availability feature and is rejected). Each change creates a new property version. |
| `activation` | `object` | null | `{ network, contact, note, auto_acknowledge_rule_warnings }`. `network` must be `STAGING` or `PRODUCTION` (validated), `contact` needs at least one email. Absent ⇒ no activation resource for the entry. |

## Outputs

All keyed by the input map key:

| Output | Description |
|---|---|
| `property_ids` | key => property ID (`prp_...`), the import ID base of the resource. |
| `property_latest_versions` | key => latest version number. |
| `property_staging_versions` | key => version active on staging (0 when never activated). |
| `property_production_versions` | key => version active on production (0 when never activated). |
| `hostnames` | key => resolved hostname set, including `edge_hostname_id`, `cname_type` and `cert_status`. |
| `activation_statuses` | key => activation status, only for entries with an activation. |
| `activation_ids` | key => activation ID, only for entries with an activation. |

## Example

```hcl
module "property" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/akamai/property?ref=v2.68.0"

  properties = {
    "www" = {
      name        = "www"
      contract_id = "ctr_C-0N7RAC7"
      group_id    = "grp_12345"
      product_id  = "prd_SPM"
      rule_format = "v2025-07-07"
      rules = jsonencode({
        name    = "default"
        options = {}
        behaviors = [{
          name    = "origin"
          options = { originType = "CUSTOMER", hostname = "origin.example.net" }
        }]
        rules = []
      })
      hostnames = [{
        cname_from             = "www.example.com"
        cname_to               = "www.example.com.edgesuite.net"
        cert_provisioning_type = "DEFAULT"
      }]
      activation = {
        network = "STAGING"
        contact = ["webops@example.com"]
      }
    }
  }
}
```

### Wiring records

Downstream units consume `property_ids` / `activation_statuses` with a Terragrunt `dependency` block (Terraform-style `depends_on = [module.property]` does not exist in Terragrunt):

```hcl
dependency "property" {
  config_path = "../property"

  mock_outputs = {
    property_ids = { "www" = "prp_12345" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  property_id = dependency.property.outputs.property_ids["www"]
}
```

The mocks exist so `validate`/`plan` work on a fresh clone before the property unit has state; the first downstream apply must follow the property unit's apply.

### Provider authentication

The Akamai provider authenticates with EdgeGrid credentials — an `~/.edgerc` file (optionally selecting a section with `config_section` in the provider block at the consumer's unit level) or the `AKAMAI_*` environment variables. The consumer unit also needs PAPI authorization for the contract and group the properties live in. Modules never configure the provider themselves.

## Notes

- Rules come in as a JSON string; the module does not manage rule files. Rules, hostnames and `rule_format` changes create a new property version and bump `latest_version`, which re-runs the activation resource — that is expected Akamai behavior, not churn to fight. Every apply with a rules diff creates a version even when the tree is semantically unchanged at the behavior level (the provider compares parsed JSON equality).
- `DEFAULT` (DV) certificates: PAPI auto-creates the edge hostname when the property version activates; serving traffic still needs the DNS CNAME (end-user hostname to edge hostname) and possibly domain validation.
- `CPS_MANAGED` hostnames need a pre-existing edge hostname — create it in a separate unit (`akamai_edge_hostname`, import ID `EdgehostNameID,contractID,groupID[,[productID][,certificate]]`) and pass its name as `cname_to`. CP codes are referenced inside the rules JSON (`cpCode` behavior) and are created consumer-side (`akamai_cp_code`).
- `CCM` is out of scope and rejected by validation (limited-availability feature needing `ccm_certificates`/`mtls`/`tls_configuration` inputs the module does not offer).
- Production activations that trigger non-compliance need the `compliance_record` acknowledgment block, which the module does not expose in v1 — consumers with that requirement manage that activation resource directly. `auto_acknowledge_rule_warnings` acknowledges rule warnings only; it is a separate request field and not a production-compliance bypass.
- Transitions to zero hostnames are rejected by the provider ("hostnames exist on server and cannot be updated to empty"). Removing all hostnames from a managed property, or importing a property that has hostnames while keeping the module default `[]`, can fail at plan/apply — brownfield adoption must carry the existing hostname set into config on the first apply. Creating a property with no hostnames is valid.
- Import does not auto-reconcile rules/hostnames into config: the first apply after import shows updates for them. Reconcile on that apply.
- Changing `activation.network` activates the new network without deactivating the old one; destroying the activation resource deactivates only the network stored in its state. Residual networks stay live but unmanaged — verify in Control Center.
- A `contact`-only edit is silently ignored: the provider diff-suppresses it while `version`/`network`/`property_id` are unchanged, so nothing errors and nothing changes. To actually update the contact list, re-trigger the activation (bump the version or change the network). `auto_acknowledge_rule_warnings` updates on an already-ACTIVE version are rejected loudly by the provider; deactivate (or destroy/recreate the activation) and reactivate to change it.
- Hostname exclusivity across separate properties (the same hostname on two properties) is an account-level rule Akamai enforces at apply; the module only checks uniqueness within one property entry. Property names themselves are not required to be unique — the map keys are what disambiguate entries.
- The property resource carries `lifecycle { prevent_destroy = true }`: removing an entry from the input map (or destroying the module) refuses at plan time instead of deleting a live traffic configuration. Lift it deliberately at the consumer's resource block only when the teardown is intended.
- The provider floor `>= 12.0.0` is a loose floor; exact pinning is done at the consumer's unit level.

## Import

The property resource imports as `propertyID,groupID,contractID` (the provider also accepts a 4th version part and a `property-bootstrap` variant; the module's examples use the 3-part form). Rules and hostnames reconcile on the first apply after import. The activation resource imports as `propertyID:network`.

```hcl
import {
  to = module.property.akamai_property.property["www"]
  id = "prp_12345,grp_67890,ctr_C-0N7RAC7"
}

import {
  to = module.property.akamai_property_activation.activation["www"]
  id = "prp_12345:STAGING"
}
```
