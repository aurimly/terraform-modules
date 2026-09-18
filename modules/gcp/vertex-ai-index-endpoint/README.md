# gcp/vertex-ai-index-endpoint

Map-keyed module for Google Cloud Vertex AI Vector Search index
endpoints (`google_vertex_ai_index_endpoint`) and their deployed indexes
(`google_vertex_ai_index_endpoint_deployed_index`).

## Scope

The module creates index endpoints (PSA-peered, PSC, or public) and
deploys indexes onto them. The indexes themselves come from the
`gcp/vertex-ai-index` module; wire their `index_ids` output into
`deployed_indexes[*].index` via a Terragrunt dependency.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `index_endpoints` | `map(object)` | — | Map of index endpoints keyed by an arbitrary unique ID. |
| `deployed_indexes` | `map(object)` | — | Map of deployed indexes keyed by an arbitrary unique ID. |

### `index_endpoints` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `display_name` | `string` | — | Up to 128 UTF-8 characters. |
| `region` | `string` | — | Region of the endpoint, e.g. `europe-west4`; defaults to the provider-level region. Immutable — changing it forces replacement. |
| `project_id` | `string` | — | Project the endpoint lives in; defaults to the provider-level project. |
| `description` | `string` | — | Free-form description. |
| `labels` | `map(string)` | `{}` | Keys/values up to 64 characters, no uppercase ASCII letters or spaces (validated); international characters allowed, matching the provider. Non-authoritative: labels set outside the config are left alone. |
| `network` | `string` | — | Full network name (`projects/{project-number}/global/networks/{name}`) to peer with; requires private services access already configured. Mutually exclusive with `private_service_connect_config` (validated). Immutable — changing it forces replacement. |
| `public_endpoint_enabled` | `bool` | — | Make deployed indexes accessible through a public endpoint. Immutable — changing it forces replacement. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated). Provider default is `DELETE` — omitting it permits destroy; use `PREVENT` as the destroy guard. |
| `encryption_spec` | `object` | — | CMEK: `{kms_key_name}` (`projects/{project}/locations/{region}/keyRings/{key-ring}/cryptoKeys/{key}`, format validated); the key must be in the same region as the endpoint. Immutable — changing it forces replacement. |
| `private_service_connect_config` | `object` | — | See the `private_service_connect_config` object table. Immutable — changing it forces replacement. |

### `private_service_connect_config` object (`index_endpoints`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enable_private_service_connect` | `bool` | — | Required when the block is present; creates the endpoint without private service access. |
| `project_allowlist` | `list(string)` | — | Projects from which the forwarding rule targets the service attachment. |
| `psc_automation_configs` | `list(object)` | `[]` | `{project_id, network}` — projects and networks where PSC endpoints (forwarding rules) are created automatically. Requires provider ≥ 7.15.0. |

### `deployed_indexes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `deployed_index_id` | `string` | — | Up to 128 characters, starts with a letter, letters/digits/underscores only (validated). Must be unique within the project it is created in, per the provider. Immutable — changing it forces replacement. |
| `index` | `string` | — | Full index resource name (`projects/{project}/locations/{region}/indexes/{name}`) — wire from the `gcp/vertex-ai-index` module's `index_ids` output. Immutable — changing it forces replacement. |
| `index_endpoint` | `string` | — | Full endpoint resource name (`projects/{project}/locations/{region}/indexEndpoints/{name}`) — wire from this module's `index_endpoint_ids` output. Immutable — changing it forces replacement. |
| `region` | `string` | — | Region of the deployment; defaults to the provider-level region. Immutable — changing it forces replacement. |
| `display_name` | `string` | — | Up to 128 UTF-8 characters. Immutable — changing it forces replacement. |
| `enable_access_logging` | `bool` | `false` | Send private endpoint access logs to Cloud Logging. Immutable — changing it forces replacement. |
| `reserved_ip_ranges` | `list(string)` | — | Names of reserved addresses under the peered network to deploy into. Immutable — changing it forces replacement. |
| `deployment_group` | `string` | — | Up to 64 characters (validated); provider default `default`. Immutable — changing it forces replacement. See the note on groups and IP ranges below. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated). Provider default is `DELETE`. |
| `automatic_resources` | `object` | — | Exactly one of this or `dedicated_resources` (validated). `{min_replica_count, max_replica_count}`; min defaults to 2 at the API (no SLA at 1), max defaults to min. Replica counts update in place. |
| `dedicated_resources` | `object` | — | Exactly one of this or `automatic_resources` (validated). See the `dedicated_resources` object table. |
| `deployed_index_auth_config` | `object` | — | `{auth_provider}` with `{audiences, allowed_issuers}`; `allowed_issuers` are Google service account emails. Immutable — changing it forces replacement. |

### `dedicated_resources` object (`deployed_indexes`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `machine_spec` | `object` | — | Required; `{machine_type}`. Immutable — changing it forces replacement. |
| `min_replica_count` | `number` | — | Required, at least 1 (validated). No SLA at 1. |
| `max_replica_count` | `number` | — | Defaults to `min_replica_count` at the provider; must be ≥ `min_replica_count` (validated). Updates in place. |

`machine_spec.machine_type` defaults to `n1-standard-2` at the provider
when unset — set it explicitly to avoid accidental legacy N1
deployments. Available machine types depend on shard size: `SHARD_SIZE_SMALL`
supports `e2-standard-2` and everything available for MEDIUM/LARGE;
`SHARD_SIZE_MEDIUM` supports `e2-standard-16` and everything available
for LARGE; `SHARD_SIZE_LARGE` supports `e2-highmem-16` and
`n2d-standard-32`. `n1-standard-16`/`n1-standard-32` still work, but
Google recommends `e2-standard-16`/`e2-highmem-16` for cost efficiency.

## Outputs

`index_endpoint_ids` — map of index endpoint key => index endpoint id
(`projects/{project}/locations/{region}/indexEndpoints/{name}`). Wire
this into `deployed_indexes[*].index_endpoint`.
`index_endpoint_names` — map of index endpoint key => resource name of
the index endpoint (Google-assigned).
`index_endpoint_public_endpoint_domain_names` — map of index endpoint
key => public endpoint domain name; populated only when
`public_endpoint_enabled` is true.
`deployed_index_ids` — map of deployed index key => `deployed_index_id`.
`deployed_index_names` — map of deployed index key => resource name of
the deployed index (Google-assigned).
`deployed_index_private_endpoints` — map of deployed index key =>
private endpoints list (`{match_grpc_address, service_attachment,
psc_automated_endpoints}`); populated when the endpoint uses network
peering or PSC.
`deployed_index_sync_times` — map of deployed index key =>
`index_sync_time` (RFC3339 UTC "Zulu" format). Compare against the
`gcp/vertex-ai-index` module's `index_update_times` for the source
index to check whether a deployed index has caught up with a batch
update.

## Example

```hcl
index_endpoints = {
  "serving" = {
    display_name = "example-psa-endpoint"
    region       = "europe-west4"
    network      = "projects/123456789012/global/networks/vpc-example"
  }
}

deployed_indexes = {
  "treeah" = {
    deployed_index_id = "example_deployed"
    index             = "projects/example-prj/locations/europe-west4/indexes/12345"
    index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
    dedicated_resources = {
      machine_spec = {
        machine_type = "e2-standard-2"
      }
      min_replica_count = 1
      max_replica_count = 3
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- `index` and `index_endpoint` take full resource names — wire them from
  the `gcp/vertex-ai-index` module's `index_ids` output and this
  module's `index_endpoint_ids` output via Terragrunt dependencies.
- Pair with `gcp/project-services` (`aiplatform.googleapis.com`) and,
  when using `network`, with `gcp/private-service-connect` — private
  services access must already be configured on the network; this module
  does not set up the peering itself. PSC automation
  (`psc_automation_configs`) creates forwarding rules in the
  allowlisted projects; ensure the projects/networks referenced exist
  consumer-side. When using CMEK, pair with `gcp/kms` — the key must be
  in the same region, and the Vertex AI service agent needs
  `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the key
  (consumer-side).
- Deployment groups: up to 5 groups besides `default`. A group (except
  `default`) can only be used with the same `reserved_ip_ranges` — once
  a group has been used with ranges `[a, b, c]`, reusing it with
  `[a, b]` or `[d, e]` is disallowed. Creating groups with reserved IP
  ranges is the recommended practice on networks with multiple peering
  ranges.
- Replica counts (`automatic_resources`,
  `dedicated_resources.min/max_replica_count`) update in place;
  everything else on a deployed index is ForceNew — a replacement
  undeploys and redeploys (45-minute create/update timeout, 20-minute
  delete at the provider).
- Destroy ordering: deployed indexes are destroyed before their index
  endpoint and index (Terraform dependency order); the API refuses to
  delete an endpoint or index whose deployed indexes are still live, so
  out-of-band deployments block deletion entirely.
- `deletion_policy` defaults to `DELETE` at the provider on both
  resources: omitting it permits `destroy`. Set `PREVENT` where destroy
  should fail.
- Provider floor: `psc_automation_configs` needs ≥ 7.15.0 and the
  deployed-index import handling ≥ 7.36.0 — use provider ≥ 7.36.0 with
  this module.

## Import

`google_vertex_ai_index_endpoint` ←
`projects/{project}/locations/{region}/indexEndpoints/{name}`,
`{project}/{region}/{name}`, `{region}/{name}`, or `{name}`.

`google_vertex_ai_index_endpoint_deployed_index` ←
`projects/{project}/locations/{region}/indexEndpoints/{endpoint}/deployedIndex/{deployed-index-id}`,
`{project}/{region}/{endpoint}/{deployed-index-id}`,
`{region}/{endpoint}/{deployed-index-id}`, or
`{endpoint}/{deployed-index-id}`.

The short forms rely on the provider-level region/project; the full
`projects/...` form always works.
