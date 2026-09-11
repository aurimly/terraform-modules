# gcp/cloud-run

Map-keyed module for Google Cloud Run services (`google_cloud_run_v2_service`)
with optional IAM bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `services` | `map(object)` | — | Map of services keyed by an arbitrary unique ID. |

### `services` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 4–63 lowercase letters/digits/hyphens, starts with a letter (validated). Immutable; changing forces replacement. |
| `location` | `string` | — | Region, e.g. `europe-west4`. |
| `project_id` | `string` | — | Project the service lives in; defaults to the provider-level project. |
| `description` | `string` | — | Free-form description. |
| `ingress` | `string` | — | One of `INGRESS_TRAFFIC_ALL`, `INGRESS_TRAFFIC_INTERNAL_ONLY`, `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` (validated). |
| `launch_stage` | `string` | — | e.g. `GA`, `BETA`; pass-through, not enum-validated. |
| `labels` / `annotations` | `map(string)` | `{}` | User labels / annotations. |
| `deletion_protection` | `bool` | `true` | Destroy requires setting it `false` first. |
| `default_uri_disabled` | `bool` | — | Disable the default `*.run.app` URL. |
| `custom_audiences` | `list(string)` | — | Custom audience URLs for ID tokens. |
| `binary_authorization` | `object` | — | `{breakglass_justification, use_default, policy}`; `use_default` (not `use_default_policy`) mirrors the provider. |
| `template` | `object` | — | Required; see the `template` object table. |
| `traffic` | `list(object)` | `[]` | Traffic splits: `{percent, type, revision, tag}`; `type` one of `TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST`, `TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION` (`REVISION` requires `revision`, validated); percent 0–100 and per-service sum 100 (validated). Omit for 100% latest revision. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings; see the `role_bindings` object table. |

### `template` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `encryption_key` | `string` | — | CMEK key for encryption at rest (revision scope, hence on the template). |
| `service_account` | `string` | — | Runtime service account email. |
| `timeout` | `string` | — | e.g. `60s`. |
| `max_instance_request_concurrency` | `number` | — | Concurrency per instance. |
| `scaling` | `object` | — | `{min_instance_count, max_instance_count}`. |
| `vpc_access` | `object` | — | `{connector, egress, network_interfaces}`. `connector` (serverless connector) and `network_interfaces` (Direct VPC egress) are mutually exclusive (validated); `egress` one of `ALL_TRAFFIC`, `PRIVATE_RANGES_ONLY` (validated). |
| `containers` | `list(object)` | — | Required, ≥ 1 (validated); see the `containers` object table. |
| `volumes` | `list(object)` | `[]` | Named volumes mounted by containers; exactly one type per entry — `secret`, `cloud_sql_instance` (`{instances}`), `nfs` (`{server, path, read_only}`), `gcs` (`{bucket, mount_options, read_only}`), `empty_dir` (`{medium, size_limit}`) — validated. |

### `containers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Container name; omit for a single container. |
| `image` | `string` | — | Required image reference. |
| `command` / `args` | `list(string)` | — | Entry point override / arguments. |
| `env` | `list(object)` | `[]` | `{name, value, value_source = {secret_key_ref = {secret, version}}}`; exactly one of `value` or `value_source` (validated). |
| `resources` | `object` | — | `{limits, startup_cpu_boost, cpu_idle}`; `limits` is a map like `{"cpu" = "1", "memory" = "512Mi"}`. |
| `ports` | `list(object)` | `[]` | `{name, container_port}` (default 8080). |
| `volume_mounts` | `list(object)` | `[]` | `{name, mount_path}` referencing `template.volumes`. |
| `startup_probe` / `liveness_probe` | `object` | — | Exactly one of `http_get` (`{path, http_headers}`), `grpc` (`{port, service}`) or `tcp_socket` (`{port}`) (validated); plus `timeout_seconds`, `period_seconds`, `failure_threshold` and `initial_delay_seconds` (liveness only). |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/run.invoker`. Must be unique within the service (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on this service. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

Making a service publicly reachable is the `roles/run.invoker` →
`allUsers` binding:

```hcl
role_bindings = {
  "public" = {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}
```

## Outputs

`service_uris` — map of service key => service URI.
`service_names` — map of service key => service name.
`service_latest_ready_revisions` — map of service key => latest ready
revision name.
`service_ids` — map of service key => service id.
`iam_binding_roles` — map of composite IAM binding key
(`service key/binding key`) => role.

## Example

```hcl
services = {
  "api" = {
    name     = "example-api"
    location = "europe-west4"
    ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    deletion_protection = true
    template = {
      service_account = "api-rt@example-prj.iam.gserviceaccount.com"
      scaling = {
        min_instance_count = 1
        max_instance_count = 10
      }
      vpc_access = {
        network_interfaces = [
          {
            network    = "vpc-example"
            subnetwork = "sn-example-west4"
          },
        ]
      }
      containers = [
        {
          image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3"
          env = [
            {
              name = "DB_PASSWORD"
              value_source = {
                secret_key_ref = {
                  secret  = "db-password"
                  version = "latest"
                }
              }
            },
          ]
          resources = {
            limits = {
              "cpu"    = "1"
              "memory" = "512Mi"
            }
          }
        },
      ]
    }
  }
  "web" = {
    name     = "example-web"
    location = "europe-west4"
    ingress  = "INGRESS_TRAFFIC_ALL"
    template = {
      containers = [{ image = "europe-docker.pkg.dev/example-prj/example/example-web:0.9.0" }]
    }
    role_bindings = {
      "public" = {
        role    = "roles/run.invoker"
        members = ["allUsers"]
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not service names.
- This module uses only `google_cloud_run_v2_service` and its v2 IAM
  resources; the v1 `google_cloud_run_service` family is legacy and manages
  the same policy — never mix the two.
- Pair with `gcp/project-services` (`run.googleapis.com`) and
  `gcp/service-account` for the runtime identity; this module does not
  enable APIs or create service accounts itself.
- Secrets referenced in `env` and secret volumes must exist but are not
  managed here; secret env `version` is the full resource name form
  (`projects/{project}/secrets/{secret}/versions/{version}` or `latest`).
- `deletion_protection` defaults to `true`: set it `false` to allow
  `destroy` to remove a service.
- Omitting `traffic` leaves the default 100% latest revision behavior.
- IAM bindings are authoritative per role (`google_cloud_run_v2_service_iam_binding`):
  members you omit are removed from that role on the service. Keys are
  `service key/binding key`; roles must be unique per service (validated).
- `startup_probe`/`liveness_probe` and `scaling` cover health checks and
  autoscaling bounds; set `max_instance_count = 0` for unbounded scale-out.

## Import

`google_cloud_run_v2_service` ← `{location}/{name}` or
`{project_id}/{location}/{name}` (older provider pins use the
space-delimited `{location} {name}` form instead).
`google_cloud_run_v2_service_iam_binding` ← space-delimited
`{location}/{name} roles/{role}` (also `projects/{project}/locations/{location}/services/{name} roles/{role}`).
