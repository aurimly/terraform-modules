# gcp/subnet

Map-keyed module for Google Cloud subnetworks in a VPC network.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subnets` | `map(object)` | — | Map of subnetworks keyed by an arbitrary unique ID. |

### `subnets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Subnetwork name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `network` | `string` | — | VPC network name or self link — see Notes. Immutable; changing forces replacement. |
| `region` | `string` | — | GCP region the subnetwork lives in. Shape-validated, not a region list. Immutable; changing forces replacement. |
| `ip_cidr_range` | `string` | — | Primary IPv4 CIDR of the subnetwork. Widening updates in place; any other change (including shrinking) forces replacement. Validated client-side. |
| `project_id` | `string` | — | Project the subnetwork lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `purpose` | `string` | — | One of `PRIVATE`, `REGIONAL_MANAGED_PROXY`, `GLOBAL_MANAGED_PROXY`, `PRIVATE_SERVICE_CONNECT`, `PEER_MIGRATION`, `PRIVATE_NAT` (case-sensitive). Defaults to `PRIVATE` server-side. |
| `role` | `string` | — | One of `ACTIVE`, `BACKUP` (case-sensitive). Only used with managed-proxy purposes (validated). |
| `private_ip_google_access` | `bool` | — | Enables Private Google Access for VMs without external IPs. |
| `secondary_ranges` | `list(object)` | `[]` | Alias-IP ranges as `{range_name, ip_cidr_range}` objects; names unique per subnet (validated). |
| `flow_log` | `object` | — | Presence enables VPC Flow Logs; see the `flow_log` object table. Omit to keep logging off. |

### `flow_log` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `aggregation_interval` | `string` | `INTERVAL_5_SEC` | One of `INTERVAL_5_SEC`, `INTERVAL_30_SEC`, `INTERVAL_1_MIN`, `INTERVAL_5_MIN`, `INTERVAL_10_MIN`, `INTERVAL_15_MIN` (validated). |
| `flow_sampling` | `number` | `0.5` | Fraction of observed packets to sample, 0.0–1.0 (validated). |
| `metadata` | `string` | `INCLUDE_ALL_METADATA` | One of `EXCLUDE_ALL_METADATA`, `INCLUDE_ALL_METADATA`, `CUSTOM_METADATA` (validated). |
| `metadata_fields` | `list(string)` | — | Field names to include; only valid with `metadata = CUSTOM_METADATA` (validated). |
| `filter_expr` | `string` | — | CEL expression selecting which packets to log; provider default `'true'` (log everything). |

## Outputs

`subnet_names` — map of subnet key => subnetwork name.
`subnet_self_links` — map of subnet key => subnetwork self link.
`subnet_gateway_addresses` — map of subnet key => gateway address chosen by
GCP for default routes out of the subnetwork. May be null for special-purpose
subnets (proxy-only, PSC); don't assume a value for every key.

## Example

```hcl
subnets = {
  "app" = {
    name          = "example-app"
    network       = "example-vpc"
    region        = "us-central1"
    ip_cidr_range = "10.0.0.0/24"
  }
  "gke" = {
    name                     = "example-gke"
    network                  = "projects/example-project-1234/global/networks/example-vpc"
    region                   = "us-central1"
    ip_cidr_range            = "10.1.0.0/20"
    private_ip_google_access = true
    secondary_ranges = [
      { range_name = "pods",     ip_cidr_range = "10.8.0.0/14" },
      { range_name = "services", ip_cidr_range = "10.12.0.0/20" },
    ]
  }
  "mon" = {
    name          = "example-mon"
    network       = "example-vpc"
    region        = "europe-west4"
    ip_cidr_range = "10.2.0.0/24"
    flow_log = {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not subnet names — multiple entries
  may share a name across regions; the key disambiguates them.
- `network` accepts the VPC network name (same project) or a full self link;
  the provider treats the two forms as equivalent on plan, so switching
  between them causes no churn. For Shared VPC, where the subnetwork lives in
  the host project, pass the `gcp/vpc` module's `network_self_links` value.
  Changing `network` or `region` forces replacement.
- `ip_cidr_range` is IPv4 only (primary and secondary ranges). Widening to a
  containing prefix updates in place; any other change, including shrinking,
  forces replacement — size generously from the start. The `cidrnetmask`
  validation also rejects ranges with host bits set (e.g. `10.0.0.1/24`),
  which the API would reject anyway.
- `region` validation is a shape check (`<area><direction><index>`), not a
  fixed list of regions, so new Google Cloud regions pass without a module
  change.
- `purpose` defaults to `PRIVATE` server-side. `role` is only meaningful with
  the managed-proxy purposes (`REGIONAL_MANAGED_PROXY`, `GLOBAL_MANAGED_PROXY`
  — enforced here); the API reserves proxy-only subnets for Envoy-based load
  balancers. `purpose` and `role` changes are sent as in-place PATCHes, but
  the API rejects most purpose transitions on existing subnets.
- `PRIVATE_SERVICE_CONNECT` subnets host published services.
- `flow_log`: setting the object enables VPC Flow Logs; omitting it leaves
  logging off. The inner defaults mirror the provider's (`INTERVAL_5_SEC`,
  `0.5`, `INCLUDE_ALL_METADATA`). `metadata_fields` requires
  `metadata = CUSTOM_METADATA` (validated) and is expected to be non-empty
  under it. Flow logging is not supported on managed-proxy-purpose subnets
  (validated).
- `secondary_ranges` back alias IPs (e.g. GKE pods and services); consumers
  reference the range names. Names must be unique within a subnet
  (validated).
- Pair with `gcp/vpc`.

## Import

`google_compute_subnetwork` ←
`projects/{project}/regions/{region}/subnetworks/{name}` (also
`{project}/{region}/{name}`, `{region}/{name}`, and the bare `{name}`).
