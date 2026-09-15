# gcp/network-endpoint-group

Map-keyed module for Google Cloud network endpoint groups and their
endpoints. Two NEG resource kinds:

- `negs` — zonal NEGs (`google_compute_network_endpoint_group`): GCE VM
  endpoints (`GCE_VM_IP`, `GCE_VM_IP_PORT`) and hybrid non-GCP endpoints
  (`NON_GCP_PRIVATE_IP_PORT`), plus `GCE_VM_IP_DEDICATED_BACKEND`.
- `regional_negs` — regional NEGs (`google_compute_region_network_endpoint_group`):
  serverless (Cloud Run, App Engine, Cloud Functions), Private Service
  Connect and internet NEG types.

`endpoints` (`google_compute_network_endpoint`) references a zonal NEG by
key — hybrid and `GCE_VM_IP_PORT` NEGs are unusable without endpoints, and
the provider has no regional endpoint resource. There is no composite-key
surface in this module: all maps are flat and cross-referenced by key
(endpoints → negs), like `gcp/load-balancer` proxies → URL maps.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `negs` | `map(object)` | — | Zonal NEGs. |
| `regional_negs` | `map(object)` | — | Regional NEGs. |
| `endpoints` | `map(object)` | — | Endpoints inside the zonal `negs` created by this module. |

### `negs` (zonal)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name (validated). |
| `zone` | `string` | — | GCP zone; defaults to the provider-level zone. Referencing endpoints inherit this: if `zone` is unset, endpoints stay unset too and both resources fall back to the same provider zone. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `network` | `string` | — | VPC network (name or self link). Required by the provider resource; to use the project's default network pass `"default"`. |
| `subnetwork` | `string` | — | Subnetwork (needed for `GCE_VM_IP_DEDICATED_BACKEND`). |
| `default_port` | `number` | — | Port for endpoints that omit `port`; 0–65535 (validated). |
| `network_endpoint_type` | `string` | `GCE_VM_IP_PORT` | One of `GCE_VM_IP`, `GCE_VM_IP_PORT`, `NON_GCP_PRIVATE_IP_PORT`, `INTERNET_IP_PORT`, `INTERNET_FQDN_PORT`, `SERVERLESS`, `PRIVATE_SERVICE_CONNECT`, `GCE_VM_IP_DEDICATED_BACKEND` (validated). In practice serverless/internet types are regional (see the `regional_negs` table). |
| `description` | `string` | — | Human-readable description. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). Use `ABANDON`/`PREVENT` for NEGs referenced by backend services. |

### `regional_negs` (regional)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | RFC1035 name (validated). |
| `region` | `string` | — | GCP region (validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `network_endpoint_type` | `string` | `SERVERLESS` | One of `SERVERLESS`, `PRIVATE_SERVICE_CONNECT`, `INTERNET_IP_PORT`, `INTERNET_FQDN_PORT` (validated). |
| `network` | `string` | — | VPC network; used only with PSC and `INTERNET_*` types. Required for `INTERNET_*` (validated — stricter than the API, which falls back to the default network). |
| `subnetwork` | `string` | — | PSC-only (validated). |
| `psc_target_service` | `string` | — | Target service URI; required for PSC (validated). |
| `psc_data` | `object` | — | `{producer_port}`; PSC-only (validated). |
| `cloud_run` | `object` | — | `{service, tag, url_mask}`; SERVERLESS-only (validated). |
| `app_engine` | `object` | — | `{service, version, url_mask}`; SERVERLESS-only (validated). |
| `cloud_function` | `object` | — | `{function, url_mask}`; SERVERLESS-only (validated). |
| `description` | `string` | — | Human-readable description. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |

A regional `SERVERLESS` NEG must set exactly one of `cloud_run`,
`app_engine` or `cloud_function` (validated, matching the API rule).

### `endpoints`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `neg` | `string` | — | Key into `negs` (validated at plan time); resolved to the referenced NEG. |
| `ip_address` | `string` | — | IPv4 address of the endpoint (required). |
| `port` | `number` | — | Endpoint port; required unless the NEG type is `GCE_VM_IP` (validated); 0–65535. |
| `instance` | `string` | — | VM instance owning the IP; required for `GCE_VM_IP_PORT` endpoints (validated), must be in the NEG's zone. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |

The endpoint zone is derived from the referenced NEG's `zone` — set it on
the NEG, never on the endpoint. If the NEG has no explicit zone, both
resources fall back to the provider zone consistently.

## Outputs

`neg_names`, `neg_self_links`, `neg_ids` — zonal NEGs, keyed by the input
key (IDs `projects/{project}/zones/{zone}/networkEndpointGroups/{name}`).
`regional_neg_names`, `regional_neg_self_links`, `regional_neg_ids` —
regional NEGs (IDs `.../regions/{region}/networkEndpointGroups/{name}`).
`endpoint_ids` — endpoint key => fully-qualified endpoint ID
(`projects/{project}/zones/{zone}/networkEndpointGroups/{neg}/{instance}/{ip_address}/{port}`).

## Example

```hcl
negs = {
  "gce" = {
    name       = "example-gce-neg"
    zone       = "us-central1-a"
    network    = "projects/example-prj/global/networks/example-vpc"
    subnetwork = "projects/example-prj/regions/us-central1/subnetworks/example-subnet"
  }
  "hybrid" = {
    name                  = "example-hybrid-neg"
    zone                  = "example-zone-b"
    network               = "example-vpc"
    network_endpoint_type = "NON_GCP_PRIVATE_IP_PORT"
  }
}

endpoints = {
  "vm-1" = {
    neg        = "gce"
    ip_address = "10.10.0.10"
    port       = 8080
    instance   = "example-instance-1"
  }
  "onprem" = {
    neg        = "hybrid"
    ip_address = "192.0.2.10"
    port       = 443
  }
}

regional_negs = {
  "run" = {
    name   = "example-run-regneg"
    region = "us-central1"
    cloud_run = {
      service  = "example-run-service"
      url_mask = "https://example-run-service-xyz-uc.a.run.app/<path>"
    }
  }
}
```

## Notes

- **Backend wiring**: `backends[].group` in `gcp/load-balancer` takes the NEG
  self link (`neg_self_links` / `regional_neg_self_links`); zonal hybrid/GCE
  NEGs are internet-stable endpoints, serverless/internet NEGs are regional
  resources (that's why there are two maps).
- **Recreating an in-use NEG fails at apply** (`resourceInUseByAnotherResource`):
  pair the NEG (or its consumers) with `lifecycle { create_before_destroy =
  true }` when you expect to rename or recreate, or protect it with
  `deletion_policy = "ABANDON"`/`"PREVENT"`.
- **Endpoint instance recreation**: when a `GCE_VM_IP_PORT` endpoint's
  Instance is recreated, two `apply`s are needed unless the endpoint is used
  with `lifecycle { replace_triggered_by }` on the instance ID — use
  `gcp/compute-instance` output IDs for that.
- Keys are arbitrary unique identifiers; they contain no `/` handling
  requirements (flat maps, no composite flattening in this module).
- Pair with `gcp/project-services` (`compute.googleapis.com`); this module
  does not enable APIs.
- Not yet in scope: the regional `GCE_VM_IP_PORTMAP` type and

  `serverless_deployment` (API Gateway, Cloud Router) — both carry beta
  provenance and are deferred until proven against the GA API (add-back is a
  minor release).
- The zonal `negs` enum accepts regional types (`SERVERLESS`, `INTERNET_*`)
  because the provider resource does, and the module does not reject them
  beyond the enum check — use the `regional_negs` map for those types;
  configuring them here is left to the consumer.

## Import

- Zonal NEG: `projects/{project}/zones/{zone}/networkEndpointGroups/{name}`
- Regional NEG: `projects/{project}/regions/{region}/networkEndpointGroups/{name}`
- Endpoint: `projects/{project}/zones/{zone}/networkEndpointGroups/{neg}/{instance}/{ip_address}/{port}`
