# gcp/static_ip

Map-keyed module for Google Cloud regional and global static IP addresses.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `addresses` | `map(object)` | — | Map of addresses keyed by an arbitrary unique ID; each entry creates one `google_compute_address` (regional) or `google_compute_global_address` (global). |

### `addresses` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Address name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `region` | `string` | — | GCP region for regional entries; must be unset for global entries (validated). Shape-validated, not a region list. |
| `project_id` | `string` | — | Project the address lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `global_ip` | `bool` | `false` | Forces the global resource for entries whose purpose alone wouldn't (e.g. a global external address for a global LB). Only valid with purpose unset, `VPC_PEERING`, or `PRIVATE_SERVICE_CONNECT` (validated). Immutable. |
| `address` | `string` | — | Specific IP (or range start with `prefix_length`) to reserve; omit to let GCP allocate. |
| `address_type` | `string` | — | One of `EXTERNAL`, `INTERNAL` (case-sensitive, validated; provider default `EXTERNAL`). |
| `purpose` | `string` | — | Regional: `GCE_ENDPOINT` (default), `SHARED_LOADBALANCER_VIP`, `IPSEC_INTERCONNECT`. Global: `VPC_PEERING`, `PRIVATE_SERVICE_CONNECT`. See the routing table below. Purpose changes force replacement. |
| `network_tier` | `string` | — | One of `PREMIUM`, `STANDARD` (validated); regional `EXTERNAL` only (validated). |
| `subnetwork` | `string` | — | Subnetwork self link or name; regional `INTERNAL` with purpose unset/`GCE_ENDPOINT`/`SHARED_LOADBALANCER_VIP` only (validated). Immutable; changing forces replacement. |
| `network` | `string` | — | VPC network self link; global `VPC_PEERING`/`PRIVATE_SERVICE_CONNECT` and regional `IPSEC_INTERCONNECT` only (validated). Immutable; changing forces replacement. |
| `prefix_length` | `number` | — | Prefix length for range reservations; not valid on global `INTERNAL` `PRIVATE_SERVICE_CONNECT` (validated). |
| `ip_version` | `string` | — | One of `IPV4`, `IPV6` (validated). |

### Routing: global vs regional

An entry is created via `google_compute_global_address` when
`global_ip = true` **or** `purpose` is one of `VPC_PEERING`,
`PRIVATE_SERVICE_CONNECT`; otherwise it is regional. Useful consequences:

- `purpose = "VPC_PEERING"` (reserved ranges for peering) needs no
  `global_ip` flag — it is global by construction.
- `SHARED_LOADBALANCER_VIP` is a regional-only purpose (validated).
- `IPSEC_INTERCONNECT`, despite being an interconnect purpose, is a regional
  address form (validated).

## Outputs

`address_names` — map of address key => address name.
`address_ips` — map of address key => reserved IP (or range start).
`address_self_links` — map of address key => self link
(`projects/{project}/regions/{region}/addresses/{name}` regional,
`projects/{project}/global/addresses/{name}` global).

## Example

```hcl
addresses = {
  "lb" = {
    name         = "example-lb-ip"
    project_id   = "example-project-1234"
    region       = "us-central1"
    network_tier = "PREMIUM"
  }
  "static-nat" = {
    name         = "example-nat-ip"
    region       = "us-central1"
    address_type = "EXTERNAL"
  }
  "vm" = {
    name         = "example-vm-ip"
    region       = "us-central1"
    address_type = "INTERNAL"
    subnetwork   = "projects/example-project-1234/regions/us-central1/subnetworks/example-app"
  }
  "peering-range" = {
    name          = "example-peering-range"
    purpose       = "VPC_PEERING"
    network       = "https://www.googleapis.com/compute/v1/projects/example-project-1234/global/networks/example-vpc"
    prefix_length = 16
    address       = "10.64.0.0"
  }
  "global-lb" = {
    name      = "example-global-ip"
    global_ip = true
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not address names — the key
  disambiguates entries; names must still be unique per project/region
  (regional) or per project (global).
- `region` is required for regional entries and must be unset for global
  ones (validated) — there is no implicit provider-region fallback, as the
  split has to be unambiguous per key.
- `subnetwork`s for `INTERNAL` addresses: pass the subnetwork self link (or
  the name within the same project/region); pair with `gcp/subnet`.
- `network` for `VPC_PEERING`/`PRIVATE_SERVICE_CONNECT` global entries: pass
  the VPC network self link; pair with `gcp/vpc`.
- Addresses in use cannot be deleted (`resourceInUseByAnotherResource`) —
  free a NAT gateway (see `gcp/nat`), forwarding rule, or instance first;
  plan order matters.
- A reserved `address` change is a replace op (same as un-setting it); plan
  drift shows as a replacement, not an update.
- Regional `EXTERNAL` entries default to `network_tier = PREMIUM`
  server-side.

- Not yet in scope (future additions): `labels`, BYOIP via `ip_collection`, `ipv6_endpoint_type`, and `deletion_policy`.

## Import

`google_compute_address` ←
`projects/{project}/regions/{region}/addresses/{name}` (also
`{project}/{region}/{name}`, `{region}/{name}`, and the bare `{name}`).

`google_compute_global_address` ←
`projects/{project}/global/addresses/{name}` (also `{project}/{name}`, and
the bare `{name}`).
