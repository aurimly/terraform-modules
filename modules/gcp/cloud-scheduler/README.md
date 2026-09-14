# gcp/cloud-scheduler

Map-keyed module for Google Cloud Scheduler jobs
(`google_cloud_scheduler_job`).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `jobs` | `map(object)` | — | Map of jobs keyed by an arbitrary unique ID. |

### `jobs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cloud Scheduler job name; validated. Immutable; changing forces replacement. |
| `description` | `string` | — | Human-readable description (≤ 500 chars). |
| `schedule` | `string` | — | Cron or App Engine cron string, in `time_zone`. |
| `time_zone` | `string` | — | tz database name, e.g. `Europe/Berlin`. |
| `paused` | `bool` | — | Set `true` to create/disable the job in paused state. |
| `attempt_deadline` | `string` | — | e.g. `320s`; HTTP targets 15s–30min, App Engine 15s–24h. Ignored — and rejected here (validated) — for `pubsub_target` jobs. |
| `region` | `string` | — | Job region; defaults to the provider-level region. |
| `project_id` | `string` | — | Project the job lives in; defaults to the provider-level project. |
| `deletion_policy` | `string` | `DELETE` | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `retry_config` | `object` | — | `{retry_count, max_retry_duration, min_backoff_duration, max_backoff_duration, max_doublings}`; `retry_count` ≤ 5 (validated). |
| `pubsub_target` | `object` | — | `{topic_name, data, attributes}`; `topic_name` is the full resource name (`projects/{x}/topics/{t}`); exactly one target per job (validated). |
| `http_target` | `object` | — | `{uri, http_method, body, headers, oauth_token, oidc_token}`; see the `http_target` object table. |
| `app_engine_http_target` | `object` | — | `{http_method, relative_uri, body, headers, app_engine_routing = {service, version, instance}}`. |

### `http_target` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `uri` | `string` | — | Required full URI. |
| `http_method` | `string` | — | One of `POST`, `GET`, `HEAD`, `PUT`, `DELETE`, `PATCH`, `OPTIONS` (validated). |
| `body` | `string` | — | Base64-encoded body; `base64encode(...)` from the consumer. |
| `headers` | `map(string)` | — | Map of request headers. |
| `oauth_token` | `object` | — | `{service_account_email, scope}`; GCP endpoints only. |
| `oidc_token` | `object` | — | `{service_account_email, audience}`; third-party endpoints/Cloud Run. Mutually exclusive with `oauth_token` (validated). |

## Outputs

`job_ids` — map of job key => job id
(`projects/{project}/locations/{region}/jobs/{name}`).
`job_names` — map of job key => job name.
`job_states` — map of job key => job state.

## Example

```hcl
jobs = {
  "nightly-sync" = {
    name             = "example-nightly-sync"
    schedule         = "0 3 * * *"
    time_zone        = "Europe/Berlin"
    attempt_deadline = "320s"
    http_target = {
      uri         = "https://api.example.com/jobs/sync"
      http_method = "POST"
      body        = base64encode("{\"kind\":\"sync\"}")
      headers     = { "Content-Type" = "application/json" }
      oidc_token = {
        service_account_email = "jobs-rt@example-prj.iam.gserviceaccount.com"
        audience              = "https://api.example.com"
      }
    }
    retry_config = {
      retry_count          = 3
      min_backoff_duration = "1s"
      max_retry_duration   = "300s"
    }
  }
  "weekly-snapshot" = {
    schedule = "0 5 * * 1"
    pubsub_target = {
      topic_name = "projects/example-prj/topics/example-snapshot-requests"
      data       = base64encode("{\"scope\":\"full\"}")
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not job names.
- Pair with `gcp/project-services` (`cloudscheduler.googleapis.com`) and
  `gcp/pubsub` for Pub/Sub targets; this module does not enable APIs or
  create topics/service accounts itself.
- Setting `attempt_deadline` on a `pubsub_target` job causes an
  unresolvable plan diff (field is ignored by the API); the module rejects
  that combination up front.
- `deletion_policy = "PREVENT"` makes destroy fail until the field is set
  back to `"DELETE"` in state first.

## Import

`google_cloud_scheduler_job` ← `projects/{project}/locations/{region}/jobs/{name}`
(or the denominator-free `{region}/{name}` form).
