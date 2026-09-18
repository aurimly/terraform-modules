# gcp/dataflow

Map-keyed module for Google Cloud Dataflow: jobs launched from classic
templates.

**Flex Template jobs are deliberately not modeled** —
`google_dataflow_flex_template_job` is beta-only in the provider (it does not
resolve against the stable `google` provider) and this module keeps everything
GA; manage Flex Template jobs consumer-side with the `google-beta` provider if
you need them.

## Job lifecycle (read before using)

- A job in a terminal state (`FAILED`, `COMPLETE`, `CANCELLED`) is
  **recreated on the next apply** — expected for streaming jobs, surprising
  for batch jobs.
- On destroy the job is drained or cancelled per `on_delete`
  (**default `drain`**). `drain` can make `terraform destroy` wait a long
  time.
- `skip_wait_on_job_termination = true` short-circuits that wait, but unless
  the job `name` changes between instances, relaunching fails with a name
  conflict (e.g. pair with a `random_id` name suffix).
- Do **not** configure Dataflow service options in `parameters` — it only
  forwards template parameters.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `jobs` | `map(object)` | `{}` | Classic-template jobs keyed by an arbitrary unique ID; see `jobs` object table. |

### `jobs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Job name; 1–40 chars, lowercase letters/digits/hyphens, no underscores (validated). Immutable; changing forces replacement. |
| `template_gcs_path` | `string` | — | GCS path to the job template, `gs://...` (validated). |
| `temp_gcs_location` | `string` | — | Writeable GCS location for temporary data, `gs://...` (validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `parameters` | `map(string)` | `{}` | Template parameters forwarded to the pipeline options (keys are case-sensitive per pipeline language). |
| `labels` | `map(string)` | `{}` | User labels; non-authoritative (see `effective_labels` on the resource). |
| `transform_name_mapping` | `map(string)` | — | Transform-name prefixes for pipeline updates; only used during update. |
| `max_workers` | `number` | — | Maximum workers for the job. |
| `on_delete` | `string` | — | `drain` or `cancel` (lowercase, validated); defaults to `drain` server-side. |
| `skip_wait_on_job_termination` | `bool` | — | Treat `DRAINING`/`CANCELLING` as terminal on delete; see lifecycle note. |
| `zone` | `string` | — | Zone for the job; falls back to the provider zone. |
| `region` | `string` | — | Region for the job. |
| `service_account_email` | `string` | — | Service account email (no `serviceAccount:` prefix) used to create the job. |
| `network` | `string` | — | Network for worker VMs; defaults to `default`. |
| `subnetwork` | `string` | — | Subnetwork for worker VMs (`regions/REGION/subnetworks/SUBNET`; full URL required for Shared VPC). |
| `machine_type` | `string` | — | Machine type for worker VMs. |
| `kms_key_name` | `string` | — | CMEK key for the job (`projects/.../locations/.../keyRings/.../cryptoKeys/...`). |
| `ip_configuration` | `string` | — | `WORKER_IP_PUBLIC` or `WORKER_IP_PRIVATE` (case-sensitive, validated). |
| `additional_experiments` | `list(string)` | — | Experiments for the job. |
| `enable_streaming_engine` | `bool` | — | Use Streaming Engine for the job. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated); defaults to `DELETE` server-side. |

## Outputs

`job_ids` — map of job key => job id.
`job_states` — map of job key => current job state (JobState enum).

## Example

```hcl
jobs = {
  "wordcount" = {
    name              = "example-df-wordcount"
    template_gcs_path = "gs://example-bucket/templates/wordcount"
    temp_gcs_location = "gs://example-bucket/tmp"
    parameters = {
      inputFile = "gs://example-bucket/input.txt"
      output    = "gs://example-bucket/output"
    }
    max_workers      = 4
    on_delete        = "cancel"
    machine_type     = "n1-standard-2"
    ip_configuration = "WORKER_IP_PRIVATE"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- Batch jobs that reach a terminal state are recreated on the next apply;
  pin streaming jobs (which should never end) and treat batch jobs as
  ephemeral outputs of a pipeline run rather than long-lived resources.
- Dataflow options (e.g. `--maxNumWorkers`) must not be set in `parameters`;
  use the module attributes instead.
- Pair with `gcp/project-services` (`dataflow.googleapis.com`) and grant the
  worker service account access to its input/output sources.

## Import

`google_dataflow_job` ← the job `id`.
