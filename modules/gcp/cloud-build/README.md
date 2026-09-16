# gcp/cloud-build

Map-keyed module for Cloud Build triggers (`google_cloudbuild_trigger`):
GitHub / Cloud Source Repositories / v2-repository push & PR triggers, Pub/Sub
and webhook triggers, and manual triggers, with inline build templates or
repo-defined build files.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `triggers` | `map(object)` | — | Map of triggers keyed by an arbitrary unique ID. |

### `triggers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1–100 chars, alphanumeric start (shape-validated). Unique within the project. |
| `location` | `string` | `global` | Cloud Build location, e.g. `us-central1` (shape-validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `description` | `string` | — | Free-text description. |
| `disabled` | `bool` | `false` | Create the trigger disabled. |
| `service_account` | `string` | — | Full SA resource name `projects/{p}/serviceAccounts/{account}`; needs `roles/cloudbuild.builds.builder`, `roles/iam.serviceAccountUser` (act-as) and `roles/logging.logWriter`. |
| `filename` | `string` | — | Path to a repo-defined build file; only valid with `trigger_template`/`github` (validated). `build` xor `filename` (validated). |
| `filter` | `string` | — | CEL filter; only valid with `pubsub_config`/`webhook_config` (validated). |
| `include_build_logs` | `string` | — | `INCLUDE_BUILD_LOGS_UNSPECIFIED` or `INCLUDE_BUILD_LOGS_WITH_STATUS` (validated); GitHub pull-request triggers only. |
| `deletion_policy` | `string` | DELETE | `DELETE` or `ABANDON` (validated). |
| `included_files` / `ignored_files` | `list(string)` | — | File globs (repo-matches) gates for SCM triggers. |
| `substitutions` | `map(string)` | — | Trigger-level substitutions, `_FOO = "bar"`. |
| `tags` | `list(string)` | — | Tags annotating the trigger's builds. |
| `build` | `object` | — | Inline build template; see the `build` object table. |
| `trigger_template` | `object` | — | Cloud Source Repositories SCM config; exactly one of `branch_name`, `tag_name`, `commit_sha` (validated); optional `repo_name`, `project_id`, `dir`, `invert_regex`. |
| `github` | `object` | — | GitHub trigger: `{owner, name, push | pull_request, enterprise_config_resource_name?}`. Exactly one of push/pull_request (validated); `push` has exactly one of `branch`/`tag` (validated); `pull_request` requires `branch`, optional `comment_control` (`COMMENTS_DISABLED`, `COMMENTS_ENABLED`, `COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY`) and `invert_regex`. At most one event source per trigger (validated together with the other source kinds). |
| `repository_event_config` | `object` | — | Cloud Build v2 repository trigger: `{repository (resource name), push | pull_request}` (at most one, validated). |
| `pubsub_config` | `object` | — | `{topic, service_account_email?}`; pair with `git_file_source`/`source_to_build` and `filter`. |
| `webhook_config` | `object` | — | `{secret}` — Secret Manager secret version used as the URL parameter. |
| `approval_config` | `object` | — | `{approval_required}`; builds produced by the trigger wait for a Cloud Build Approver. |
| `source_to_build` | `object` | — | `{uri?|repository?, ref (must start with `refs/`, validated), repo_type, github_enterprise_config?}`; repo_type in `UNKNOWN`, `CLOUD_SOURCE_REPOSITORIES`, `GITHUB`, `BITBUCKET_SERVER` (validated). |
| `git_file_source` | `object` | — | `{path, uri?|repository?, revision?, repo_type, github_enterprise_config?}`. |

### `build` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `steps` | `list(object)` | — | Required; see the `steps` table. |
| `source` | `object` | — | `{repo_source = {project_id?, repo_name, branch_name?, tag_name?, commit_sha?, dir?, invert_regex?, substitutions?}}` or `{storage_source = {bucket, object, generation?}}`. |
| `images` | `list(string)` | — | Images pushed on successful completion. |
| `substitutions` | `map(string)` | — | Build-level substitutions. |
| `tags` | `list(string)` | — | Tags annotating the build (not docker tags). |
| `logs_bucket` | `string` | — | GCS bucket for build logs. |
| `timeout` | `string` | `600s` | Build wall clock, e.g. `"600s"`. |
| `queue_ttl` | `string` | — | Queue expiry, e.g. `"20s"`. |
| `options` | `object` | — | `{machine_type, disk_size_gb, env, secret_env, substitution_option (ALLOW_LOOSE|ALLOW_UNSUBSTITUTED, validated), dynamic_substitutions, logging (validated), log_streaming_option (validated), requested_verify_option (validated), source_provenance_hash (NONE|MD5|SHA256, validated), worker_pool, volumes = [{name,path}]}`. |
| `available_secrets` | `object` | — | `{secret_manager = {ENV = "projects/.../versions/latest"}}`; steps reference them via `secret_env`. |
| `artifacts` | `object` | — | `{images, objects = {location, paths}, maven_artifacts = map({repository, path?, artifact_id?, group_id?, version?}), python_packages = map({repository, paths?}), npm_packages = map({repository, package_path?})}`. |

### `steps` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Container image to run. |
| `args` | `list(string)` | — | Command arguments. |
| `script` | `string` | — | Shell script payload (alternative to args). |
| `id` / `dir` / `entrypoint` | `string` | — | Step id, working dir, entrypoint. |
| `env` / `secret_env` | `list(string)` | — | Env vars; secret_env references `available_secrets` keys. |
| `timeout` | `string` | — | Step timeout, e.g. `120s`. |
| `timing` | `string` | — | `BUILD` (default), `WAITER` or `POSTBUILD`. |
| `allow_failure` | `bool` | — | Continue the build when the step fails. |
| `allow_exit_codes` | `list(number)` | — | Non-zero exit codes that do not fail the build. |
| `wait_for` | `list(string)` | — | Step ids to wait for (`["-"]` = start immediately). |
| `volumes` | `list(object)` | `[]` | `{name, path}`. |

Bitbucket Server and Developer Connect event sources and the legacy `build.secret`
KMS block are intentionally not exposed.

## Outputs

| Name | Description |
|---|---|
| `trigger_names` | Map of trigger key => trigger name. |
| `trigger_ids` | Map of trigger key => `projects/{project}/locations/{location}/triggers/{trigger_id}`. |
| `trigger_numeric_ids` | Map of trigger key => API-generated unique trigger ID. |
| `trigger_self_links` | Map of trigger key => `projects/.../locations/.../triggers/{name}`. |
| `pubsub_subscriptions` | Map of trigger key => Pub/Sub subscription created for `pubsub_config` triggers (null otherwise); grant the trigger SA `roles/run.invoker` if it pushes to Cloud Run, + actAs. |

## Example

GitHub push trigger running a repo-defined build file:

```hcl
module "build_triggers" {
  source = "git::ssh://git@github.com/<org>/terraform-modules.git//modules/gcp/cloud-build?ref=v1.25.0"

  triggers = {
    "push-main" = {
      name            = "example-push-main"
      location        = "us-central1"
      service_account = "projects/example-prj/serviceAccounts/example-builder@example-prj.iam.gserviceaccount.com"
      included_files  = ["src/**"]
      filename        = "cloudbuild.yaml"
      substitutions   = { _IMAGE = "example-registry.test.local/example-app" }
      github = {
        owner = "example-org"
        name  = "example-repo"
        push = {
          branch = "^main$"
        }
      }
    }
  }
}
```

Inline build template (manual, approval-gated):

```hcl
  triggers = {
    "deploy" = {
      name = "example-deploy"
      approval_config = {
        approval_required = true
      }
      build = {
        steps = [
          { name = "ubuntu", script = "./deploy.sh" }
        ]
      }
    }
  }
```

## Import

`google_cloudbuild_trigger` ← `projects/{project}/locations/{location}/triggers/{trigger_id}`
(also accepted: `projects/{project}/triggers/{trigger_id}`,
`{project}/{trigger_id}`, `{trigger_id}`).

## Notes

- Enable `cloudbuild.googleapis.com` via `project-services`; this module does
  not enable APIs itself.
- The trigger's `service_account` needs `roles/cloudbuild.builds.builder`,
  `roles/iam.serviceAccountUser` (granted to the Cloud Build SA), and
  `roles/logging.logWriter`.
