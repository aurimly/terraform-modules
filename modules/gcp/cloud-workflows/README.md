# gcp/cloud-workflows

Map-keyed module for Google Workflows (`google_workflows_workflow`).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `workflows` | `map(object)` | — | Map of workflows keyed by an arbitrary unique ID. |

### `workflows` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Verified: starts with a letter, letters/digits/underscore/dash/dot, ≤ 64 chars (validated). Immutable; changing forces replacement. |
| `region` | `string` | — | Region, e.g. `europe-west4`. |
| `project_id` | `string` | — | Project the workflow lives in; defaults to the provider-level project. |
| `description` | `string` | — | User description (≤ 1000 chars). |
| `service_account` | `string` | — | Identity of the workflow, e.g. `projects/{project}/serviceAccounts/{account}` or email; separate revisions per service account change. |
| `crypto_key_name` | `string` | — | CMEK key, full resource name form (validated). |
| `call_log_level` | `string` | — | One of `CALL_LOG_LEVEL_UNSPECIFIED`, `LOG_ALL_CALLS`, `LOG_ERRORS_ONLY`, `LOG_NONE` (validated). |
| `execution_history_level` | `string` | — | One of `EXECUTION_HISTORY_LEVEL_UNSPECIFIED`, `EXECUTION_HISTORY_BASIC`, `EXECUTION_HISTORY_DETAILED` (validated). |
| `labels` | `map(string)` | `{}` | User labels. |
| `user_env_vars` | `map(string)` | `{}` | ≤ 20 entries; keys cannot be empty or start with `GOOGLE`/`WORKFLOWS` (validated), referenced via `sys.get_env("key")`. |
| `tags` | `map(string)` | — | Resource manager tags, keys `tagKeys/{id}` and values `tagValues/{id}` (validated). |
| `source_contents` | `string` | — | Required workflow source (YAML/JSON syntax), ≤ 128KB. |
| `deletion_protection` | `bool` | `true` | Destroy requires setting it `false` first. |

## Outputs

`workflow_ids` — map of workflow key => workflow id
(`projects/{project}/locations/{region}/workflows/{name}`).
`workflow_names` — map of workflow key => workflow name.
`workflow_states` — map of workflow key => workflow state.
`workflow_revision_ids` — map of workflow key => current revision id.

## Example

```hcl
workflows = {
  "status-check" = {
    name            = "example-status-check"
    region          = "europe-west4"
    service_account = "projects/example-prj/serviceAccounts/workflows-rt@example-prj.iam.gserviceaccount.com"
    call_log_level  = "LOG_ERRORS_ONLY"
    user_env_vars   = { base_url = "https://api.example.com" }
    source_contents = <<-EOF
      - check:
          call: http.get
          args:
            url: $${sys.get_env("base_url") + "/healthz"}
          result: health
      - return:
          return: $${health.status}
    EOF
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not workflow names.
- Pair with `gcp/project-services` (`workflows.googleapis.com`) and
  `gcp/service-account` for the runtime identity; this module does not
  enable APIs or create service accounts itself.
- The service invoking Workflows needs `roles/workflows.invoker`
  (service-based triggers) or `roles/iam.serviceAccountTokenCreator` for
  impersonation; the module does not grant these itself.
- Escape `$` as `$$` inside `source_contents` heredocs to keep workflow
  syntax variables intact.
- Modifying `service_account` or `source_contents` creates a
  new revision.
- **This resource does not support import** (provider limitation); drift
  on imported workflows cannot be reconciled.
- `deletion_protection` defaults to `true`; set it `false` to allow
  `destroy` to remove a workflow.
- The `user_env_vars`, `execution_history_level` and `tags` attributes
  require a reasonably recent `google` provider (they appeared in the 6.x
  / 7.x cycles); the module ships no version pin by design, so consumers
  should pin a provider version that supports them.
