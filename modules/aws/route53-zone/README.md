# aws/route53-zone

Map-keyed module for Route 53 hosted zones: public and private zones with
VPC associations, comments, delegation sets, and optional delegation set
creation.

## Destroy semantics (read before using)

- Removing a zone key deletes the hosted zone along with **all DNS records
  in it** (Route 53 deletes the full record set with the zone). Domains
  relying on the zone will stop resolving.
- `force_destroy = true` is required by AWS to delete a zone with
  non-default records; the module passes it through so the delete can
  succeed. Do not set it on production zones.
- Removing a VPC ID from `vpc_ids` only disassociates that VPC; the zone
  itself remains until the zone resource is destroyed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | `{}` | Map of hosted zones keyed by an arbitrary unique ID. |

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Domain name of the zone, e.g. `example.com` (validated shape). A trailing dot is normalized by the API. |
| `private` | `bool` | `false` | Private hosted zone. Requires at least one `vpc_ids` entry (precondition/validated). |
| `comment` | `string` | — | Free-form comment stored with the zone. |
| `delegation_set_id` | `string` | — | ID of an existing reusable delegation set to use for a public zone. |
| `create_delegation_set` | `bool` | `false` | Create a new reusable delegation set for this zone (mutually exclusive with `delegation_set_id`, validated). |
| `force_destroy` | `bool` | `false` | Allow deleting the zone even when it still contains records. Dangerous — see Destroy semantics. |
| `vpc_ids` | `list(string)` | `[]` | VPC IDs to associate; private zones only (validated both ways). |
| `tags` | `map(string)` | `{}` | Tags. |

## Outputs

`zone_ids` — map of zone key => hosted zone ID (use as `zone_id` in record
modules and for NS delegations).
`zone_arns` — map of zone key => zone ARN.
`zone_name_servers` — map of zone key => list of assigned name servers.
`delegation_set_ids` — map of zone key => created delegation set ID (only
for zones with `create_delegation_set = true`).

## Example

```hcl
zones = {
  "main" = {
    name    = "example.com"
    comment = "primary public zone"
  }
  "internal" = {
    name    = "example.internal"
    private = true
    vpc_ids = ["vpc-0123456789abcdef0"]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not domain names; the key only
  decouples your config from the zone.
- For a private zone spanning multiple VPCs, list all VPC IDs at creation
  time where possible; associations can be updated later but the zone
  must have at least one at all times.
- Pair with `aws/route53-records`, passing the zone key's `zone_id` output.
- Creating a zone does not register a domain; domain registration is out
  of scope for this module.

## Import

`aws_route53_zone` ← hosted zone ID (`Z...`).
`aws_route53_delegation_set` ← delegation set ID.
