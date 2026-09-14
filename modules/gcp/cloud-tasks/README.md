# gcp/cloud-tasks

Map-keyed module for Google Cloud Tasks queues (`google_cloud_tasks_queue`)
with optional IAM bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `queues` | `map(object)` | — | Map of queues keyed by an arbitrary unique ID. |

### `queues` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 4–63 chars, starts with a letter, letters/digits/hyphens (validated). Immutable; changing forces replacement. |
| `location` | `string` | — | Region, e.g. `europe-west4`. |
| `project_id` | `string` | — | Project the queue lives in; defaults to the provider-level project. |
| `desired_state` | `string` | — | `RUNNING` or `PAUSED` (validated); paused queues accept tasks but do not dispatch them. |
| `deletion_policy` | `string` | `DELETE` | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `rate_limits` | `object` | — | `{max_dispatches_per_second, max_concurrent_dispatches}`; both optional, validated positive. |
| `retry_config` | `object` | — | `{max_attempts, max_retry_duration, min_backoff, max_backoff, max_doublings}`; `-1` attempts means unlimited (validated). |
| `stackdriver_logging_config` | `object` | — | `{sampling_ratio}` required, 0.0–1.0 (validated). |
| `http_target` | `object` | — | Queue-level HTTP target override; see the `http_target` object table. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings; see the `role_bindings` object table. |

### `http_target` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `http_method` | `string` | — | Required; one of `POST`, `GET`, `HEAD`, `PUT`, `DELETE`, `PATCH`, `OPTIONS` (validated). |
| `uri_override` | `object` | — | `{scheme, host, port, path_override = {path}, query_override = {query_params}, uri_override_enforce_mode}`; `host` required (validated); enforce mode one of `ALWAYS` or `IF_NOT_EXISTS`. |
| `header_overrides` | `map(string)` | `{}` | Header name => value, applied to every task in the queue. |
| `oauth_token` | `object` | — | `{service_account_email, scope}`; Google-API calls only. |
| `oidc_token` | `object` | — | `{service_account_email, audience}`; Cloud Run and custom endpoints. Mutually exclusive with `oauth_token` (validated). |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/cloudtasks.enqueuer`. Must be unique within the queue (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on this queue. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

## Outputs

`queue_ids` — map of queue key => queue id
(`projects/{project}/locations/{location}/queues/{name}`).
`queue_names` — map of queue key => queue name.
`queue_states` — map of queue key => queue state.
`iam_binding_roles` — map of composite IAM binding key
(`queue key/binding key`) => role.

## Example

```hcl
queues = {
  "email-notifications" = {
    name     = "example-email-notifications"
    location = "europe-west4"
    rate_limits = {
      max_dispatches_per_second = 5
      max_concurrent_dispatches = 10
    }
    retry_config = {
      max_attempts  = 5
      min_backoff   = "2s"
      max_backoff   = "300s"
      max_doublings = 3
    }
    http_target = {
      http_method = "POST"
      uri_override = {
        host          = "worker.example.com"
        path_override = { path = "/tasks/email" }
      }
      oidc_token = {
        service_account_email = "tasks-rt@example-prj.iam.gserviceaccount.com"
      }
    }
  }
  "billing-sync" = {
    name     = "example-billing-sync"
    location = "europe-west4"
    stackdriver_logging_config = {
      sampling_ratio = 0.5
    }
    role_bindings = {
      "enqueue" = {
        role    = "roles/cloudtasks.enqueuer"
        members = ["serviceAccount:enqueuer@example-prj.iam.gserviceaccount.com"]
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not queue names.
- Pair with `gcp/project-services` (`cloudtasks.googleapis.com`) and
  `gcp/service-account` for the OIDC/OAuth grant identity; this module does
  not enable APIs or create service accounts itself.
- The deprecated `app_engine_routing_override` block is intentionally not
  exposed; use `http_target` with `uri_override` instead.
- IAM bindings are authoritative per role
  (`google_cloud_tasks_queue_iam_binding`): members you omit are removed
  from that role on the queue. Keys are `queue key/binding key`; roles must
  be unique per queue (validated).
- `deletion_policy = "PREVENT"` makes destroy fail until the field is set
  back to `"DELETE"` in state first.

## Import

`google_cloud_tasks_queue` ← `projects/{project}/locations/{location}/queues/{name}`
(or the denominator-free `{location}/{name}` form).
`google_cloud_tasks_queue_iam_binding` ← space-delimited
`projects/{project}/locations/{location}/queues/{name} roles/{role}`.
