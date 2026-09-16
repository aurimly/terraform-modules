# gcp/eventarc

Map-keyed module for standalone Eventarc triggers (`google_eventarc_trigger`)
delivering events to Cloud Run services, GKE services, Workflows, or HTTP
endpoints.

Function-owned event triggers (2nd gen Cloud Functions) stay in
`gcp/cloud-functions` — this module covers the destinations the inline
trigger cannot express.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `triggers` | `map(object)` | — | Map of triggers keyed by an arbitrary unique ID. |

### `triggers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1–63 chars, lowercase RFC1035-ish (shape-validated). Unique within the location; immutable. |
| `location` | `string` | — | Region, e.g. `us-central1`, or a multi region (`us`, `eu`) (shape-validated). Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `service_account` | `string` | — | Service account identity the trigger delivers with, e.g. `projects/{p}/serviceAccounts/{sa}`. Needs `roles/eventarc.eventReceiver` and `iam.serviceAccounts.actAs`. |
| `pubsub_topic` | `string` | — | Existing Pub/Sub topic to use as transport; only valid for `messagePublished` triggers (validated); setting it makes the trigger use the topic instead of a transient one. |
| `channel` | `string` | — | Channel resource for custom/3P event sources, e.g. of a SaaS partner event source. |
| `event_data_content_type` | `string` | — | `application/json` or `application/protobuf` (validated). |
| `deletion_policy` | `string` | DELETE | `DELETE` or `ABANDON` (validated); `ABANDON` keeps the transport-created Pub/Sub subscription. |
| `labels` | `map(string)` | `{}` | Labels. |
| `cloud_run_service` | `object` | — | Destination: `{service, region, path?}`. Exactly one destination is required (validated). |
| `gke` | `object` | — | Destination: `{cluster, location, namespace, service, path?}`. |
| `workflow` | `string` | — | Destination: fully qualified `workflows/{name}` resource path. |
| `http_endpoint` | `object` | — | Destination: `{uri}`. |
| `network_attachment` | `string` | — | Network attachment resource for an HTTP endpoint destination in a VPC-attached setup. |
| `matching_criteria` | `list(object)` | — | Event filters, list of `{attribute, value, operator?}`; must include one `attribute = "type"` entry (validated). `operator` for prefix/regexp filtering on string attributes. |
| `retry_policy` | `object` | — | `{max_attempts}`; Cloud Run destinations only, `max_attempts` must be 1 (validated). |

`destination.cloud_function` is an output-only field the API rejects when set,
so it is intentionally not exposed.

## Outputs

| Name | Description |
|---|---|
| `trigger_names` | Map of trigger key => trigger name. |
| `trigger_ids` | Map of trigger key => `projects/{project}/locations/{location}/triggers/{name}`. |
| `trigger_uids` | Map of trigger key => API-assigned unique UUID. |
| `transport_subscriptions` | Map of trigger key => Pub/Sub subscription the transport created (null otherwise). |

## Example

Pub/Sub topic events delivered to a Cloud Run service:

```hcl
module "triggers" {
  source = "git::ssh://git@github.com/<org>/terraform-modules.git//modules/gcp/eventarc?ref=v1.25.0"

  triggers = {
    "pubsub-to-runner" = {
      name             = "example-pubsub-to-runner"
      location         = "us-central1"
      service_account  = "projects/example-prj/serviceAccounts/example-trigger@example-prj.iam.gserviceaccount.com"
      pubsub_topic     = "projects/example-prj/topics/example-inbound"
      event_data_content_type = "application/json"
      matching_criteria = [
        { attribute = "type", value = "google.cloud.pubsub.topic.v1.messagePublished" }
      ]
      cloud_run_service = {
        service = "example-runner"
        region  = "us-central1"
        path    = "/events"
      }
      retry_policy = {
        max_attempts = 1
      }
    }
  }
}
```

The event type filter values mirror Cloud Audit Logs / Pub/Sub event bag tags,
e.g. `{attribute = "type", value = "google.cloud.audit.storage.buckets.v1.updated"}`.

## Import

`google_eventarc_trigger` ← `projects/{project}/locations/{location}/triggers/{name}`.

## Notes

- Enable `eventarc.googleapis.com` (and the source-service API, e.g.
  `compute.googleapis.com` for audit-log sources) consumer-side via
  `project-services`.
- The trigger's `service_account` needs `roles/run.invoker` on the destination
  and `roles/pubsub.subscriber` (or `roles/eventarc.eventReceiver`) depending
  on the source; `http_endpoint` destinations deliver unauthenticated.
