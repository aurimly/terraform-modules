# gcp/cloud-run-jobs

Map-keyed module for Google Cloud Run jobs (`google_cloud_run_v2_job`)
with optional IAM bindings. Jobs differ from services: no `liveness_probe`
(only `startup_probe`), `resources` supports `limits` only, and secret env
references require an explicit `version`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `jobs` | `map(object)` | — | Map of jobs keyed by an arbitrary unique ID. |

### `jobs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 4–63 lowercase letters/digits/hyphens, starts with a letter (validated). Immutable; changing forces replacement. |
| `location` | `string` | — | Region, e.g. `europe-west4`. |
| `project_id` | `string` | — | Project the job lives in; defaults to the provider-level project. |
| `launch_stage` | `string` | — | e.g. `GA`, `BETA`; pass-through, not enum-validated. |
| `labels` / `annotations` | `map(string)` | `{}` | User labels / annotations. |
| `tags` | `map(string)` | — | Resource-manager tags, `tagKeys/{id}` → `tagValues/{id}`. |
| `deletion_protection` | `bool` | `true` | Destroy requires setting it `false` first. |
| `deletion_policy` | `string` | `DELETE` (provider default) | One of `DELETE`, `PREVENT`, `ABANDON` (validated). `ABANDON` removes the job from state without deleting it in the API. |
| `binary_authorization` | `object` | — | `{breakglass_justification, use_default, policy}`. |
| `template` | `object` | — | Required; see the `template` object table. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings; see the `role_bindings` object table. |

### `template` object

The outer task template carries `task_count` and `parallelism`; everything
else lives on the inner revision-like template. Both are flattened into one
object here.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `task_count` | `number` | `1` | Number of tasks in the job. |
| `parallelism` | `number` | `task_count` | Concurrently running tasks; must not exceed `task_count` (validated). |
| `max_retries` | `number` | `3` | Retries per task attempt. |
| `timeout` | `string` | — | Per-task, per-attempt timeout, e.g. `600s`. |
| `service_account` | `string` | — | Runtime service account email. |
| `encryption_key` | `string` | — | CMEK key for encryption at rest. |
| `execution_environment` | `string` | — | `EXECUTION_ENVIRONMENT_GEN1` or `EXECUTION_ENVIRONMENT_GEN2` (validated). |
| `node_selector` | `object` | — | `{accelerator}` for GPU jobs, e.g. `nvidia-l4`. |
| `vpc_access` | `object` | — | `{connector, egress, network_interfaces}`. `connector` (serverless connector) and `network_interfaces` (Direct VPC egress) are mutually exclusive (validated); `egress` one of `ALL_TRAFFIC`, `PRIVATE_RANGES_ONLY` (validated). |
| `containers` | `list(object)` | — | Required, ≥ 1 (validated); see the `containers` object table. |
| `volumes` | `list(object)` | `[]` | Named volumes mounted by containers; exactly one type per entry — `secret`, `cloud_sql_instance` (`{instances}`), `nfs` (`{server, path, read_only}`), `gcs` (`{bucket, mount_options, read_only}`), `empty_dir` (`{medium, size_limit}`) — validated. |

### `containers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Container name; omit for a single container. |
| `image` | `string` | — | Required image reference. |
| `command` / `args` | `list(string)` | — | Entry point override / arguments. |
| `env` | `list(object)` | `[]` | `{name, value, value_source = {secret_key_ref = {secret, version}}}`; exactly one of `value` or `value_source` (validated). `secret_key_ref.version` is required for jobs — `latest` is not assumed. |
| `resources` | `object` | — | `{limits}`; jobs do not support `startup_cpu_boost` or `cpu_idle`. `limits` is a map like `{"cpu" = "1", "memory" = "512Mi"}`. |
| `ports` | `list(object)` | `[]` | `{name, container_port}` (default 8080); `name` one of `http1`, `h2c`; only meaningful to probes. |
| `volume_mounts` | `list(object)` | `[]` | `{name, mount_path, sub_path}` referencing `template.volumes`; `sub_path` mounts a file within a secret volume. |
| `startup_probe` | `object` | — | Exactly one of `http_get` (`{path, http_headers}`), `grpc` (`{port, service}`) or `tcp_socket` (`{port}`) (validated); plus `initial_delay_seconds`, `timeout_seconds`, `period_seconds`, `failure_threshold`. Jobs have no `liveness_probe`. |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/run.invoker`. Must be unique within the job (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on this job. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

## Outputs

`job_names` — map of job key => job name.
`job_ids` — map of job key => job id.
`iam_binding_roles` — map of composite IAM binding key
(`job key/binding key`) => role.

## Example

```hcl
jobs = {
  "nightly-import" = {
    name     = "example-nightly-import"
    location = "europe-west4"
    template = {
      task_count  = 10
      parallelism = 5
      max_retries = 2
      timeout     = "600s"
      service_account = "import-rt@example-prj.iam.gserviceaccount.com"
      vpc_access = {
        connector = "projects/example-prj/locations/europe-west4/connectors/example-vpc"
      }
      containers = [
        {
          image = "europe-docker.pkg.dev/example-prj/example/example-import:1.2.3"
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
}
```

## Notes

- Keys are arbitrary unique identifiers, not job names.
- Job shape differs from the service sibling (`gcp/cloud-run`): no
  `liveness_probe`, no `description`/`ingress`/`traffic`/`scaling`,
  `resources` has `limits` only, and secret env `version` is required.
  Not exposed at all: `client`/`client_version` (API-client bookkeeping),
  `start_execution_token`/`run_execution_token`
  (run jobs with the runtime API instead), beta-only `functional_type`,
  `workload_identity_config` and `gpu_zonal_redundancy_disabled`,
  container `working_dir`/`depends_on`, `sandbox_launcher`,
  `delay_execution`, and the outer template's `labels`/`annotations`
  (job labels belong at the job level).
- Pair with `gcp/project-services` (`run.googleapis.com`) and
  `gcp/service-account` for the runtime identity; this module does not
  enable APIs or create service accounts itself.
- Secrets referenced in `env` and secret volumes must exist but are not
  managed here.
- `deletion_protection` defaults to `true`: set it `false` to allow
  `destroy` to remove a job. With the default `deletion_policy = DELETE`
  the job is then deleted; `PREVENT` makes destroy fail outright and
  `ABANDON` drops the job from state without deleting it.
- IAM bindings are authoritative per role (`google_cloud_run_v2_job_iam_binding`):
  members you omit are removed from that role on the job. Keys are
  `job key/binding key`; roles must be unique per job (validated).

## Import

`google_cloud_run_v2_job` ← `{location}/{name}` or
`projects/{project}/locations/{location}/jobs/{name}`.
`google_cloud_run_v2_job_iam_binding` ← space-delimited
`{location}/{name} roles/{role}` (also
`projects/{project}/locations/{location}/jobs/{name} roles/{role}`).
