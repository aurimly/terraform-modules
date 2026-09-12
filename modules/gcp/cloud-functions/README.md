# gcp/cloud-functions

Map-keyed module for Google Cloud Functions (2nd gen) with optional IAM
bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `functions` | `map(object)` | — | Map of functions keyed by an arbitrary unique ID. |

### `functions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Function name; lowercase letters/digits/hyphens, 4–63 chars, starting and ending with a letter or digit (module-level convention; kebab-case keeps the generated Cloud Run service name aligned). Validated client-side. |
| `location` | `string` | — | GCP region (shape validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `labels` | `map(string)` | `{}` | User labels. |
| `kms_key_name` | `string` | — | CMEK key for the function (`projects/<project>/locations/<location>/keyRings/<ring>/cryptoKeys/<key>`). |
| `deletion_policy` | `string` | `PREVENT` | One of `DELETE`, `ABANDON`, `PREVENT` (case-sensitive). The provider defaults to `DELETE`; this module is stricter by default — set `DELETE` explicitly to allow destroy. |
| `build_config` | `object` | — | Required here (optional in the provider). See below. |
| `build_config.runtime` | `string` | — | Runtime (e.g. `nodejs20`, `python312`, `go122`); required. |
| `build_config.entrypoint` | `string` | — | Entry point in the source code; defaults to the resource name suffix. |
| `build_config.source` | `object` | — | Required. Exactly one of `storage_source` (`{bucket, object, generation?}`) or `repo_source` (`{project_id?, repo_name?, branch_name?, tag_name?, commit_sha?, dir?, invert_regex?}`) — validated. |
| `build_config.worker_pool` | `string` | — | Cloud Build custom worker pool. |
| `build_config.service_account` | `string` | — | Service account used for building the container. |
| `build_config.docker_repository` | `string` | — | Artifact Registry repository for the built image. |
| `build_config.environment_variables` | `map(string)` | `{}` | Build-time environment variables. |
| `build_config.automatic_update_policy` | `bool` | — | Set `true` for automatic runtime security patches. Mutually exclusive with `on_deploy_update_policy` (validated). |
| `build_config.on_deploy_update_policy` | `bool` | — | Set `true` to apply security patches only on redeploy. Mutually exclusive with `automatic_update_policy` (validated). |
| `service_config` | `object` | — | Optional; omitted means API defaults. See below. |
| `service_config.min_instance_count` | `number` | — | Minimum number of instances. |
| `service_config.max_instance_count` | `number` | — | Maximum number of instances. |
| `service_config.available_memory` | `string` | — | Memory (e.g. `256M`, `4Gi`); API default `256M`. |
| `service_config.available_cpu` | `string` | — | CPUs per instance; derived from memory when unset. |
| `service_config.timeout_seconds` | `number` | — | Execution timeout; API default 60. |
| `service_config.environment_variables` | `map(string)` | `{}` | Runtime environment variables. |
| `service_config.ingress_settings` | `string` | — | One of `ALLOW_ALL`, `ALLOW_INTERNAL_ONLY`, `ALLOW_INTERNAL_AND_GCLB` (case-sensitive); API default `ALLOW_ALL`. |
| `service_config.vpc_connector` | `string` | — | Serverless VPC Access connector; mutually exclusive with direct VPC egress (validated). |
| `service_config.vpc_connector_egress_settings` | `string` | — | One of `VPC_CONNECTOR_EGRESS_SETTINGS_UNSPECIFIED`, `PRIVATE_RANGES_ONLY`, `ALL_TRAFFIC` (case-sensitive). |
| `service_config.direct_vpc_egress` | `string` | — | One of `VPC_EGRESS_ALL_TRAFFIC`, `VPC_EGRESS_PRIVATE_RANGES_ONLY` (case-sensitive); API default `VPC_EGRESS_PRIVATE_RANGES_ONLY`. |
| `service_config.direct_vpc_network_interface` | `object` | — | `{network?, subnetwork?, tags?}` for direct VPC egress. |
| `service_config.service_account_email` | `string` | — | Runtime service account. |
| `service_config.max_instance_request_concurrency` | `number` | — | Max concurrent requests per instance; API default 1. |
| `service_config.all_traffic_on_latest_revision` | `bool` | — | Route 100% of traffic to the latest revision; API default `true`. |
| `service_config.binary_authorization_policy` | `string` | — | Binary Authorization policy to check on deploy. |
| `service_config.secret_environment_variables` | `list(object)` | `[]` | `{key, project_id, secret, version}` — all four required (provider requirement). |
| `service_config.secret_volumes` | `list(object)` | `[]` | `{mount_path, project_id, secret, versions?}` — first three required (provider requirement); `versions` = `{version, path}`. |
| `event_trigger` | `object` | — | Optional; omitted means HTTP-triggered. `{trigger_region?, event_type, pubsub_topic?, service_account_email?, retry_policy?, event_filters?}`: `retry_policy` one of `RETRY_POLICY_UNSPECIFIED`, `RETRY_POLICY_DO_NOT_RETRY`, `RETRY_POLICY_RETRY` (validated); `event_filters` = `{attribute, value, operator?}` with `operator` limited to `match-path-pattern` (validated). |
| `role_bindings` | `map(object)` | `{}` | IAM bindings on the function: `{role, members, condition?}`. |

## Outputs

`function_ids` — map of function key => full resource path
(`projects/<project>/locations/<location>/functions/<name>`).
`function_urls` — map of function key => deployed HTTPS URL
(HTTP-triggered functions).
`function_states` — map of function key => state (`ACTIVE`, `FAILED`,
`DEPLOYING`, `DELETING`, `UNKNOWN`).
`function_runtime_services` — map of function key => the backing Cloud
Run service name (null when `service_config` is omitted).

## Example

```hcl
functions = {
  "http" = {
    name     = "example-http-fn"
    location = "europe-west4"
    build_config = {
      runtime    = "nodejs20"
      entrypoint = "helloHttp"
      source = {
        storage_source = {
          bucket = "example-gcf-source"
          object = "function-source.zip"
        }
      }
    }
    service_config = {
      available_memory = "256M"
      timeout_seconds  = 60
    }
    role_bindings = {
      "invoker" = {
        role    = "roles/cloudfunctions.invoker"
        members = ["serviceAccount:svc@example-prj.iam.gserviceaccount.com"]
      }
    }
  }
  "pubsub" = {
    name     = "example-pubsub-fn"
    location = "europe-west4"
    build_config = {
      runtime = "python312"
      source = {
        repo_source = {
          repo_name   = "example-repo"
          branch_name = "^main$"
        }
      }
    }
    event_trigger = {
      event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
      pubsub_topic = "projects/example-prj/topics/example-topic"
      retry_policy = "RETRY_POLICY_RETRY"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not function names.
- Pair with `gcp/project-services` (`cloudfunctions.googleapis.com`,
  `run.googleapis.com`, `eventarc.googleapis.com` for event triggers)
  when the project does not have the APIs enabled yet; this module does
  not enable APIs itself.
- `role_bindings` only covers the function resource. Public or
  service-account HTTPS invocation through the URL may additionally
  require `roles/run.invoker` on the backing Cloud Run service (see
  `function_runtime_services` and the `gcp/cloud-run` module).
- Source must be uploaded to GCS (or a Source Repository) beforehand;
  this module does not package code.
- Event triggers create an Eventarc trigger managed by Cloud Functions;
  the trigger's service account needs `roles/run.invoker` and
  `roles/eventarc.eventReceiver`.

## Import

`google_cloudfunctions2_function` ←
`projects/{project}/locations/{location}/functions/{name}` (also
`{project}/{location}/{name}` and `{location}/{name}`).
`google_cloudfunctions2_function_iam_binding` ←
`{project}/{location}/{name} {role}`.
