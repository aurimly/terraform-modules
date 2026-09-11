# gcp/dns-record-sets

Map-keyed module for Google Cloud DNS resource record sets in a single
managed zone, with weighted, geo, and primary-backup routing policies
(including health-checked internal load balancer targets).

Pair with `gcp/dns-zone`, which creates the zone this module populates.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `managed_zone_name` | `string` | — | Managed zone **name** the records belong to (the zone identifier, not the DNS name) — feed it `zone_names` from `gcp/dns-zone`. |
| `project_id` | `string` | — | Project the managed zone lives in; defaults to the provider-level project. |
| `record_sets` | `map(object)` | — | Map of record sets keyed by an arbitrary unique ID. |

### `record_sets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Fully qualified record name with trailing dot (`www.example.com.`, apex as `example.com.`); validated. The provider does not qualify relative names. |
| `type` | `string` | — | Record type (e.g. `A`, `MX`, `TXT`, `CAA`). Uppercase shape-validated, not enum-validated — new types appear over time. |
| `ttl` | `number` | `300` | TTL in seconds, ≥ 1 (validated). |
| `rrdatas` | `list(string)` | — | Record data strings; exactly one of `rrdatas` or `routing_policy` per record (validated). MX/SRV priority is encoded in the string (`1 mail.example.com.`). |
| `routing_policy` | `object` | — | Advanced routing; see the `routing_policy` object table. |

### `routing_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enable_geo_fencing` | `bool` | — | For `geo` policies: restrict to region boundaries (geo fencing) instead of geo-based crossing. |
| `wrr` | `list(object)` | — | Weighted round robin entries: `{weight, rrdatas, health_checked_targets}`. `weight` required. |
| `geo` | `list(object)` | — | Geo entries: `{location, rrdatas, health_checked_targets}`. |
| `primary_backup` | `object` | — | Primary/backup policy: see below. |
| (policy shape) | — | — | Exactly one of `wrr`, `geo`, or `primary_backup` per routing policy (validated). Each `wrr`/`geo`/`backup_geo` entry needs at least one of `rrdatas` or `health_checked_targets` (validated). |

`health_checked_targets` uses `{external_endpoints = [...]}` (internet IPs)
or `{internal_load_balancers = [{ip_address, port, ip_protocol, network_url, project, region}]}` tying into the `gcp/load-balancer` module — health-checked routing needs LB targets. `ip_protocol` (`tcp`/`udp`) and the LB's `project` are required by the API; `load_balancer_type` is one of `regionalL4ilb`, `regionalL7ilb`, `globalL7ilb`; `port` is a string.

### `primary_backup` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `primary` | `object` | — | Required: `{external_endpoints}` or `{internal_load_balancers}` — health-checked targets (validated non-empty). |
| `backup_geo` | `list(object)` | — | Required backup geo entries, same shape as `geo` (`location`, plus `rrdatas` or `health_checked_targets`). |
| `enable_geo_fencing_for_backups` | `bool` | — | Fence backup geo queries to region boundaries. |
| `trickle_ratio` | `number` | — | Fraction of traffic sent to the backup targets even when primaries are healthy. |

## Outputs

`record_set_names` — map of record key => fully qualified record name.
`record_set_types` — map of record key => record type.
`record_set_ttl` — map of record key => TTL in seconds.
`record_set_rrdatas` — map of record key => rrdatas; only meaningful for
records configured via `rrdatas`.

## Example

```hcl
managed_zone_name = "example-org-public"

record_sets = {
  "apex" = {
    name = "example.com."
    type = "A"
    rrdatas = [
      "203.0.113.10",
      "203.0.113.11",
    ]
  }
  "www" = {
    name    = "www.example.com."
    type    = "CNAME"
    ttl     = 3600
    rrdatas = ["example.com."]
  }
  "mx" = {
    name = "example.com."
    type = "MX"
    rrdatas = [
      "10 mail.example.com.",
    ]
  }
  "spf" = {
    name    = "example.com."
    type    = "TXT"
    rrdatas = ["\"v=spf1 include:_spf.example.net ~all\""]
  }
  "internal-app" = {
    name = "app.example.internal."
    type = "A"
    routing_policy = {
      primary_backup = {
        primary = {
          internal_load_balancers = [
            {
              ip_address         = "10.0.0.20"
              port               = "80"
              ip_protocol        = "tcp"
              network_url        = "https://www.googleapis.com/compute/v1/projects/example-prj/global/networks/vpc-example-prd"
              project            = "example-prj"
              region             = "europe-west4"
            },
          ]
        }
        backup_geo = [{ location = "europe-west1" }]
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not record names — multiple records
  can share a name (e.g. several CAA records all named `@` in the apex;
  write the apex out fully as `example.com.`).
- `managed_zone_name` is the zone identifier (from `gcp/dns-zone`'s
  `zone_names`), not the DNS name.
- rrdatas must match the API representation byte-for-byte — quoted TXT
  string contents, DKIM public keys spanning a single string, and trailing
  dots on CNAME/MX targets are the usual zero-diff traps.
- Routing policies and plain `rrdatas` are mutually exclusive (validated);
  health-checked routing requires internal load balancer targets registered
  in the same network.
- The zone in `managed_zone_name` must be managed by some other configuration
  (typically `gcp/dns-zone`) — this module only creates record sets.

## Import

`google_dns_record_set` ← `{project_id}/{managed_zone_name}/{record_name}/{record_type}`;
older provider pins use the space-delimited
`{project_id} {managed_zone_name} {record_name} {record_type}` form instead.
