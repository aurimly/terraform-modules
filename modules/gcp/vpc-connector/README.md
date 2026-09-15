# gcp/vpc-connector

Map-keyed module for Serverless VPC Access connectors
(`google_vpc_access_connector`), regional resources that let Cloud Run,
Cloud Functions and App Engine reach private VPC resources.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `connectors` | `map(object)` | — | Map of connectors keyed by an arbitrary unique ID. |

### `connectors` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | **At most 25 characters** (connector API limit, unlike the usual 63) and lowercase RFC1035 (validated). Immutable; changing it replaces the connector. |
| `region` | `string` | — | GCP region; defaults to the provider-level region. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `network` | `string` | — | VPC network name or self link. Required when `ip_cidr_range` is set (validated). |
| `ip_cidr_range` | `string` | — | Unused IPv4 CIDR in the network, `/28` or larger; must not overlap the network's existing ranges (CIDR shape validated; overlaps rejected by the API). Mutually exclusive with `subnet` (validated). |
| `subnet` | `object` | — | Shared-VPC mode `{name, project_id}`; `name` is the relative subnet name in the host project, `project_id` the host project. Mutually exclusive with `ip_cidr_range` (validated). |
| `machine_type` | `string` | — | e.g. `e2-micro` (API default), `e2-standard-4`. |
| `min_instances` | `number` | — | 2–9 (validated); instance-based autoscaling. Exclusive with `min_throughput` (validated), requires `max_instances` (validated). |
| `max_instances` | `number` | — | 3–10 (validated). Exclusive with `max_throughput` (validated), requires `min_instances` (validated). |
| `min_throughput` | `number` | — | 200–900, multiple of 100 (validated); API default 200. Exclusive with `min_instances` (validated), requires `max_throughput` (validated). Discouraged by Google in favor of instance scaling. |
| `max_throughput` | `number` | — | 300–1000, multiple of 100 (validated); API default 300. Exclusive with `max_instances` (validated), requires `min_throughput` (validated). |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). `PREVENT`/`ABANDON` protect connectors that other services already use. |

## Outputs

`connector_names` — map of connector key => name.
`connector_ids` — map of connector key => fully-qualified ID
(`projects/{project}/locations/{region}/connectors/{name}`).
`connector_self_links` — map of connector key => self link.
`connector_states` — map of connector key => state (`READY`, `CREATING`, ...).

## Example

```hcl
connectors = {
  "shared" = {
    name                = "example-shared-conn"
    region              = "us-central1"
    project_id          = "example-prj"
    deletion_policy     = "ABANDON"
    subnet = {
      name       = "example-subnet"
      project_id = "example-host-prj"
    }
  }
  "dedicated" = {
    name           = "example-dedicated-conn"
    region         = "us-central1"
    network        = "projects/example-prj/global/networks/example-vpc"
    ip_cidr_range  = "10.1.0.0/28"
    min_instances  = 2
    max_instances  = 5
  }
}
```

## Notes

- **Shared VPC**: with `subnet`, the connector lives in the service project
  (`project_id`) while the subnet belongs to the host project — pass the host
  project's subnet `name` (relative, not self link) and `project_id`. The
  subnet must not be shared across projects already.
- Instance scaling (`min_instances`/`max_instances`) is preferred; throughput
  pairs stay supported for configs predating instance scaling.
- Pair with `gcp/project-services` (`vpcaccess.googleapis.com`); this module
  does not enable APIs.
- Deleting a connector that a Cloud Run service or function still references
  fails at apply. For long-lived or shared connectors use
  `deletion_policy = "ABANDON"` (keeps the connector on destroy) or
  `"PREVENT"`.
- `region` and the free-string `network` are not graph-visible; clear them (or
  destroy both sides in one apply) before removing a referenced network — the
  API rejects connector creation on a network that was just deleted.

## Import

`google_vpc_access_connector` ←
`projects/{project}/locations/{region}/connectors/{name}` (shorter accepted
forms: `{project}/{region}/{name}`, `{region}/{name}`, `{name}`).
