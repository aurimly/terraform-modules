# gcp/vertex-ai

Map-keyed module for Google Cloud Vertex AI prediction endpoints
(`google_vertex_ai_endpoint`) and Model Garden / Hugging Face model
deployments (`google_vertex_ai_endpoint_with_model_garden_deployment`).

## Scope

There is no `google_vertex_ai_model` resource in the Google provider yet
([hashicorp/terraform-provider-google#23217](https://github.com/hashicorp/terraform-provider-google/issues/23217)).
Custom model registration and deploy/undeploy to an endpoint happen
outside Terraform (Vertex AI SDK, console, or MLOps pipelines). This
module manages endpoints and their networking, encryption, and
request-response logging, `traffic_split` routing by deployed-model id,
and Model Garden deployments (which create their own endpoint).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `endpoints` | `map(object)` | — | Map of endpoints keyed by an arbitrary unique ID. |
| `model_garden_deployments` | `map(object)` | — | Map of Model Garden deployments keyed by an arbitrary unique ID. |

### `endpoints` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Numeric with no leading zeros, at most 10 digits (validated). This is the Vertex AI endpoint id, not a free-form name; changing forces replacement. |
| `display_name` | `string` | — | Up to 128 UTF-8 characters. |
| `location` | `string` | — | Region, e.g. `europe-west4`. |
| `region` | `string` | — | Region for the resource; defaults to `location` behavior at the provider. |
| `project_id` | `string` | — | Project the endpoint lives in; defaults to the provider-level project. |
| `description` | `string` | — | Free-form description. |
| `labels` | `map(string)` | `{}` | Keys/values up to 64 characters, no uppercase ASCII letters or spaces (validated); international characters allowed, matching the provider. Non-authoritative: labels set outside the config are left alone. |
| `dedicated_endpoint_enabled` | `bool` | — | Expose the endpoint through a dedicated DNS. Conflicts with `private_service_connect_config`. Once enabled, requests to the shared DNS are rejected. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated). Provider default is `DELETE` — omitting it permits destroy; use `PREVENT` as the destroy guard. |
| `traffic_split` | `map(number)` | — | Deployed-model id => traffic percent; each 0–100 and summing to 100, or an empty map for an endpoint accepting no traffic (validated). Passed to the provider as JSON. |
| `network` | `string` | — | Full network name (`projects/{project-number}/global/networks/{name}`) to peer with; requires private services access already configured. Mutually exclusive with `private_service_connect_config` (validated). |
| `encryption_spec` | `object` | — | CMEK: `{kms_key_name}`; the key must be in the same region as the endpoint. |
| `private_service_connect_config` | `object` | — | See the `private_service_connect_config` object table. |
| `predict_request_response_logging_config` | `object` | — | `{enabled, sampling_rate, bigquery_destination}`; `sampling_rate` is a fraction in (0,1] (validated). See the `bigquery_destination` object table. |

### `private_service_connect_config` object (`endpoints`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enable_private_service_connect` | `bool` | — | Required when the block is present. |
| `project_allowlist` | `list(string)` | — | Projects from which the forwarding rule targets the service attachment. |
| `psc_automation_configs` | `list(object)` | `[]` | `{project_id, network}` — projects and networks where PSC endpoints (forwarding rules) are created automatically. |

`enable_secure_private_service_connect` is not exposed: it was marked
beta-only upstream and dropped from the GA provider (no longer valid
configuration as of provider 7.0.0).

### `bigquery_destination` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `output_uri` | `string` | — | Required in this module (the provider makes it optional and auto-creates dataset/table naming when only a project is given). Forms: `bq://projectId`, `bq://projectId.bqDatasetId`, `bq://projectId.bqDatasetId.bqTableId`. |

### `model_garden_deployments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `publisher_model_name` | `string` | — | Model Garden model, `publishers/{publisher}/models/{model}@{version}`. Exactly one of this or `hugging_face_model_id` (validated). |
| `hugging_face_model_id` | `string` | — | Hugging Face model ID, e.g. `google/gemma-2-2b-it`. |
| `location` | `string` | — | Region, e.g. `europe-west4`. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated). Provider default is `DELETE`. |
| `model_config` | `object` | — | `{accept_eula, model_display_name, hugging_face_cache_enabled, hugging_face_access_token, container_spec}`. |
| `endpoint_config` | `object` | — | `{endpoint_display_name, dedicated_endpoint_enabled, private_service_connect_config}`. |
| `deploy_config` | `object` | — | `{fast_tryout_enabled, system_labels, dedicated_resources}`. |

The `private_service_connect_config` inside `endpoint_config` is a
narrower shape than the `endpoints` one: it supports
`enable_private_service_connect`, `project_allowlist`, and
`psc_automation_configs` only — the provider does not accept
`enable_secure_private_service_connect` on this resource.

### `container_spec` object (`model_config`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `image_uri` | `string` | — | Required container image in Artifact Registry or Container Registry. |
| `predict_route` / `health_route` | `string` | — | HTTP paths for prediction and health-check requests. |
| `command` / `args` | `list(string)` | — | Entry point override / arguments. |
| `env` | `list(object)` | `[]` | `{name, value}`. |
| `ports` | `list(object)` | `[]` | `{container_port}`; required here (the provider defaults to 8080 when omitted). Vertex AI uses the first port only. |
| `grpc_ports` | `list(object)` | `[]` | `{container_port}`. |
| `shared_memory_size_mb` | `number` | — | VM memory reserved as shared memory. |
| `deployment_timeout` | `string` | — | Deployment timeout; the provider limits it to 2 hours. |
| `startup_probe` / `health_probe` / `liveness_probe` | `object` | — | Exactly one of `exec` (`{command}`), `http_get` (`{path, port, host, scheme, http_headers}`), `grpc` (`{port, service}`) or `tcp_socket` (`{port, host}`) (validated); plus `timeout_seconds`, `success_threshold`, `initial_delay_seconds`, `period_seconds`, `failure_threshold`. |

### `dedicated_resources` object (`deploy_config`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `machine_spec` | `object` | — | Required; see the `machine_spec` object table. |
| `min_replica_count` | `number` | — | Required, at least 1 (validated). |
| `max_replica_count` | `number` | — | Defaults to `min_replica_count` at the provider; must be ≥ `min_replica_count` (validated). Quota is charged against this value. |
| `required_replica_count` | `number` | — | Replicas required for the deploy to succeed (partial deployment). |
| `spot` | `bool` | — | Schedule on spot VMs. |
| `autoscaling_metric_specs` | `list(object)` | `[]` | `{metric_name, target}`; `metric_name` must start with `aiplatform.googleapis.com/prediction/online/` (validated, prefix match), `target` 1–100 (validated), default 60. |

### `machine_spec` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `machine_type` | `string` | — | Defaults to `n1-standard-2` at the provider. |
| `accelerator_type` | `string` | — | e.g. `NVIDIA_L4`; required when `accelerator_count` > 0 (validated). |
| `accelerator_count` | `number` | — | At least 0 (validated). |
| `tpu_topology` | `string` | — | e.g. `2x2x1`. |
| `multihost_gpu_node_count` | `number` | — | Nodes per replica for multihost GPU deployments. |
| `reservation_affinity` | `object` | — | `{reservation_affinity_type, key, values}`; type one of `TYPE_UNSPECIFIED`, `NO_RESERVATION`, `ANY_RESERVATION`, `SPECIFIC_RESERVATION` (validated) — `SPECIFIC_RESERVATION` requires `key` and `values` (validated). Target a named reservation with key `compute.googleapis.com/reservation-name`. |

## Outputs

`endpoint_ids` — map of endpoint key => endpoint id
(`projects/{project}/locations/{location}/endpoints/{name}`).
`endpoint_names` — map of endpoint key => endpoint name (the numeric
endpoint id).
`endpoint_dedicated_endpoint_dns` — map of endpoint key => dedicated
endpoint DNS; populated only when `dedicated_endpoint_enabled` is true.
`endpoint_deployed_models` — map of endpoint key => `deployed_models`
list (output-only; read deployed-model ids here when wiring
`traffic_split`).
`model_garden_deployed_model_ids` — map of model garden deployment key
=> `deployed_model_id` assigned by Vertex AI at deploy time.
`model_garden_endpoint_ids` — map of model garden deployment key =>
endpoint id segment of the created endpoint.

## Example

```hcl
endpoints = {
  "serving" = {
    name         = "1234567890"
    display_name = "example-endpoint"
    location     = "europe-west4"
    network      = "projects/123456789012/global/networks/vpc-example"
    traffic_split = {
      "12345" = 100
    }
    predict_request_response_logging_config = {
      enabled       = true
      sampling_rate = 0.5
      bigquery_destination = {
        output_uri = "bq://example-prj.example-ds.example-table"
      }
    }
  }
}

model_garden_deployments = {
  "gemma" = {
    publisher_model_name = "publishers/google/models/gemma@gemma-1.1-2b-it"
    location             = "europe-west4"
    model_config = {
      accept_eula = true
    }
    endpoint_config = {
      private_service_connect_config = {
        enable_private_service_connect = true
        project_allowlist              = ["example-prj"]
      }
    }
    deploy_config = {
      dedicated_resources = {
        machine_spec = {
          machine_type      = "g2-standard-12"
          accelerator_type  = "NVIDIA_L4"
          accelerator_count = 1
        }
        min_replica_count = 1
        max_replica_count = 3
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- Pair with `gcp/project-services` (`aiplatform.googleapis.com`) and,
  when using `network`, with `gcp/private-service-connect` — private
  services access must already be configured on the network; this module
  does not set up the peering itself.
- `traffic_split` keys are the numeric deployed-model ids Vertex assigns
  at deploy time; read them from `endpoint_deployed_models`. Out-of-band
  deploys (console, pipelines) change the ids — update `traffic_split`
  to match, since this module is authoritative for the field.
- To give an endpoint no traffic, the provider requires setting
  `traffic_split` to `"{}"`, applying, and then removing the field.
  Through this module: set `traffic_split = {}`, apply, then remove the
  attribute.
- The plain endpoint resource has 20-minute create/update/delete
  timeouts at the provider. The Model Garden deployment resource has a
  180-minute create timeout (model download and deployment are slow),
  does not support import, and mostly replaces on change — wrap it with
  `deletion_policy` thoughtfully.
- `deletion_policy` defaults to `DELETE` at the provider on both
  resources: omitting it permits `destroy`. Set `PREVENT` where destroy
  should fail.
- `model_config.hugging_face_access_token` is a plain attribute: it is
  stored in state and appears in plan output. Only gated Hugging Face
  models need it. `hugging_face_cache_enabled` with pre-cached artifacts
  is the VPC-SC-friendly alternative.
- PSC automation (`psc_automation_configs`) creates forwarding rules in
  the allowlisted projects; ensure the projects/networks referenced
  exist consumer-side.

## Import

`google_vertex_ai_endpoint` ←
`projects/{project}/locations/{location}/endpoints/{name}`,
`{project}/{location}/{name}`, or `{location}/{name}`.

`google_vertex_ai_endpoint_with_model_garden_deployment` does not
support import.
