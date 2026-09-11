# gcp/dns-zone

Map-keyed module for Google Cloud DNS managed zones (public, private,
forwarding, and peering zones) with DNSSEC, private visibility wiring,
and cloud-logging controls.

Pair with `gcp/dns-record-sets` to populate the zones.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | — | Map of zones keyed by an arbitrary unique ID. |

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Zone identifier used by the API and by `dns-record-sets` (`managed_zone_name`). Lowercase letters, digits, hyphens; starts with a letter (validated). Immutable; changing forces replacement. Not the DNS name. |
| `dns_name` | `string` | — | Fully qualified DNS name of the zone, with trailing dot (`example.com.`). Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the zone lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Free-form description. |
| `visibility` | `string` | `public` | One of `public` or `private` (validated). |
| `force_destroy` | `bool` | `false` | Remove zone-level resource records (e.g. A/AAAA/CNAME) before deleting the zone. Non-empty zones fail deletion without it. |
| `labels` | `map(string)` | `{}` | User labels. |
| `dnssec_config` | `object` | — | Public zones only (validated); see the `dnssec_config` object table. |
| `private_visibility_config` | `object` | — | Private zones only (validated): `{networks, gke_clusters}`; see below. |
| `forwarding_config` | `object` | — | Private zones only (validated): `{target_name_servers}`; see below. Mutually exclusive with `peering_config` (validated). |
| `peering_config` | `object` | — | Private zones only (validated): `{target_network = {network_url}}`. Mutually exclusive with `forwarding_config` (validated). |
| `cloud_logging_config` | `object` | — | `{enable_logging}` (default `true`); presence toggles the block; omitting the block leaves the zone at the API default (query logging off). |

### `dnssec_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `state` | `string` | — | One of `on`, `off`, `transfer` (validated). |
| `non_existence` | `string` | — | One of `nsec` or `nsec3` (validated). |
| `default_key_specs` | `list(object)` | `[]` | Key specs: `{algorithm, key_length, key_type}`. `key_type` one of `keySigning`, `zoneSigning` (validated); `algorithm` one of `rsasha1`, `rsasha256`, `rsasha512`, `ecdsap256sha256`, `ecdsap384sha384` (validated; the exact set supported may vary by provider version). When `default_key_specs` is set, exactly one `keySigning` and one `zoneSigning` spec are required (validated). Omit to use provider defaults. |

### `private_visibility_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `networks` | `list(object)` | `[]` | Entries with `{network_url}`; at least one `network_url` or `gke_clusters` entry required (validated). |
| `gke_clusters` | `list(object)` | `[]` | Optional GKE cluster visibility entries: `{gke_cluster_name}`. |

### `forwarding_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `target_name_servers` | `list(object)` | — | Forwarding targets: `{ipv4_address, ipv6_address, forwarding_path}`. Exactly one of the two addresses per target (validated). `forwarding_path` one of `default` or `private` (validated). |

## Outputs

`zone_names` — map of zone key => zone name (the value `dns-record-sets`
expects as `managed_zone_name`).
`zone_dns_names` — map of zone key => zone DNS name (trailing dot).
`zone_name_servers` — map of zone key => set of assigned name servers.
`zone_ids` — map of zone key => zone id.

## Example

```hcl
zones = {
  "example-public" = {
    name     = "example-org-public"
    dns_name = "example.org."
    dnssec_config = {
      state = "on"
    }
  }
  "example-forwarding" = {
    name        = "example-onprem-forward"
    dns_name    = "corp.example.internal."
    visibility  = "private"
    private_visibility_config = {
      networks = [
        { network_url = "https://www.googleapis.com/compute/v1/projects/example-prj/global/networks/vpc-example-prd" },
      ]
    }
    forwarding_config = {
      target_name_servers = [
        { ipv4_address = "10.0.0.10" },
        { ipv4_address = "10.0.0.11" },
      ]
    }
  }
  "example-peering" = {
    name        = "example-peer-net"
    dns_name    = "other.example.internal."
    visibility  = "private"
    peering_config = {
      target_network = { network_url = "projects/example-producer-prj/global/networks/vpc-producer" }
    }
  }
}
```

## Notes

- `name` is the zone identifier used by the API; `dns_name` is the DNS name.
  `dns-record-sets` references the zone by `name`, not by `dns_name`.
- Keys are arbitrary unique identifiers, not zone names.
- Immutable: `name` and `dns_name` changes replace the zone.
- Pair with `gcp/project-services` (`dns.googleapis.com`) when the target
  project does not have the DNS API enabled yet; this module does not enable
  APIs itself.
- DNSSEC is public-zone only; private visibility, forwarding and peering are
  private-zone only (all plan-time validated, mirroring API rules).
- Forwarding and peering are mutually exclusive (validated).
- `force_destroy` is needed to delete a zone that still has resource records.
- Advanced zone types (`reverse_lookup`, Service Directory zones) are
  Beta-only in the google provider and are not modeled here; some provider
  versions need a `google-beta` pin for them. `gke_clusters` visibility is
  GA and supported.
- Peering requires the DNS producer/consumer VPC arrangement to already exist;
  this module wires the zone only.

## Import

`google_dns_managed_zone` ← `{zone_name}` or `{project_id}/{zone_name}`.
