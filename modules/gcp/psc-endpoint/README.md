# gcp/psc-endpoint

Map-keyed module for Private Service Connect **consumer** endpoints — an
internal reserved IP plus a regional forwarding rule targeting a producer's
service attachment (e.g. MongoDB Atlas, Cloud SQL, a partner SaaS).

This is not the same thing as `gcp/private-service-connect`, which implements
Private Services Access (VPC peering via allocated ranges + service
networking). Reach a Private Services Access-connected producer (e.g. Cloud
SQL via PSA) with that module; reach anything exposing a service attachment
with this one.

Why a dedicated module: `gcp/load-balancer` `forwarding_rules` cannot express
PSC consumer rules (its `load_balancing_scheme` validation does not allow the
empty-string scheme PSC requires), and this module always creates its own
internal reserved IP — there is no bring-your-own-address path today.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `psc_endpoints` | `map(object)` | — | Map of endpoints keyed by an arbitrary unique ID. |

### `psc_endpoints` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Endpoint (forwarding rule) name, RFC1035 and ≤ 60 chars if `address_name` is unset (validated) — the reserved IP is named `<name>-ip`. Immutable. |
| `project_id` | `string` | — | Project the endpoint lives in; defaults to the provider-level project. Format validated. |
| `region` | `string` | — | Region of the endpoint and the reserved IP (shape validated). Immutable once created. |
| `network` | `string` | — | VPC network name or self link. |
| `subnetwork` | `string` | — | Subnet (or subnet self link) to allocate the IP in; use a `purpose = PRIVATE_SERVICE_CONNECT` subnet from `gcp/subnet`. |
| `target_service_attachment` | `string` | — | Producer service attachment self link (validated non-empty). Changing it re-creates the endpoint. |
| `address` | `string` | — | Explicit IP to reserve; auto-allocated when unset. Changing it replaces the address. |
| `address_name` | `string` | — | Override for the reserved IP's name; defaults to `<name>-ip`. |
| `description` | `string` | — | Free-text description, applied to the reserved IP. |
| `allow_psc_global_access` | `bool` | `false` | Reach the endpoint from any region. |
| `recreate_closed_psc` | `bool` | — | Re-create the forwarding rule if the PSC connection reaches a terminal CLOSED state (otherwise it silently stays dead). |
| `no_automate_dns_zone` | `bool` | — | Do not create the private DNS zone that maps the producer's `service_name` to the endpoint IP. |
| `labels` | `map(string)` | `{}` | User labels, applied to both the reserved IP and the forwarding rule. |

## Outputs

`endpoint_ips` — map of endpoint key => reserved internal IP (the IP that
consumers connect to).
`address_names` / `address_self_links` — map of endpoint key => reserved IP
name / self link.
`endpoint_self_links` — map of endpoint key => forwarding rule self link.
`psc_connection_ids` — map of endpoint key => PSC connection id.
`psc_connection_statuses` — map of endpoint key => PSC connection status
(`STATUS_UNSPECIFIED`, `PENDING`, `ACCEPTED`, `REJECTED`, `CLOSED`).
`service_names` — map of endpoint key => the internal service DNS name
resolving to the endpoint IP.

## Example

```hcl
psc_endpoints = {
  "mongodb" = {
    name                      = "example-mongodb-psc"
    region                    = "europe-west4"
    network                   = "vpc-example-prd"
    subnetwork                = "psc-europe-west4"
    target_service_attachment = "projects/example-producer-project/regions/europe-west4/serviceAttachments/example-mongodb-attachment"
    allow_psc_global_access   = true
    labels = {
      "env" = "prd"
    }
  },
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- The subnet must be a `purpose = PRIVATE_SERVICE_CONNECT` subnet in the same
  region — allocate it with `gcp/subnet` (`purpose = "PRIVATE_SERVICE_CONNECT"`).
- Connections start `PENDING` and become `ACCEPTED` after the producer
  accepts; `REJECTED` and `CLOSED` are terminal — with `recreate_closed_psc`
  Terraform re-creates the forwarding rule instead of leaving a dead endpoint.
- Pair with `gcp/project-services` (`compute.googleapis.com`) when the target
  project does not have the Compute Engine API enabled yet; this module does
  not enable APIs itself.

## Import

`google_compute_address` ←
`projects/{project}/regions/{region}/addresses/{name}`.
`google_compute_forwarding_rule` ←
`projects/{project}/regions/{region}/forwardingRules/{name}`.
