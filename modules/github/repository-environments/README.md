# github/repository-environments

Map-keyed module for GitHub deployment environments in one repo,
including reviewers, deployment branch policies, and environment-scoped
Actions secrets and variables.

The module instance is per-repo: `repository` is a plain string, and the
repo must already exist. The `environments` map is keyed by an arbitrary
stable identifier — the key is not the environment name; the
`environment` attribute is the name.

## Auth

The provider reads `GITHUB_TOKEN` (fine-grained PAT with
`administration:read` + `environments` repository permissions) and
`GITHUB_OWNER` from the environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | Repository name. |
| `environments` | `map(object)` | — | Map of environments keyed by arbitrary key. Keys are not environment names, must not contain `:`, and are not sent to GitHub. |

### `environments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `environment` | `string` | — | Environment name as GitHub sees it. Renaming is force-new (no API rename). |
| `wait_timer` | `number` | `null` | Seconds a job waits after triggering. Validated to 0–43200 (24h cap). |
| `can_admins_bypass` | `bool` | `true` | Repo admins may bypass the protections. |
| `prevent_self_review` | `bool` | `false` | The job's creator may not approve their own run. |
| `reviewers` | `object` | `null` | Required reviewers. Users and teams combined are capped at 6 by the API. |
| `deployment_branch_policy` | `object` | `null` | Branch policy mode for deployments. Exactly one of the two modes must be true. |
| `secrets` | `map(object)` | `{}` | Env-scoped Actions secrets keyed by secret name (sensitive). |
| `variables` | `map(object)` | `{}` | Env-scoped Actions variables keyed by variable name. |

### `reviewers` object

Reviewers take **numeric user or team IDs**, not usernames or slugs.
Resolve IDs through `data "github_user"` / `data "github_team"`, or the
`team_ids` output of `modules/github/team`.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `users` | `list(number)` | `[]` | IDs of users who may review. |
| `teams` | `list(number)` | `[]` | IDs of teams who may review. |

### `deployment_branch_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `protected_branches` | `bool` | `null` | Only branches with branch protection rules can deploy. Exactly one of the two mode attributes must be true, the other false. |
| `custom_branch_policies` | `bool` | `null` | Only branches matching the configured patterns can deploy. Exactly one of the two mode attributes must be true, the other false. |
| `branch_patterns` | `list(string)` | `[]` | Branch patterns, custom mode only. |
| `tag_patterns` | `list(string)` | `[]` | Tag patterns, custom mode only. |

Exactly one of `protected_branches` / `custom_branch_policies` must be
true and the other false — both true, both absent, or both false is
rejected. Patterns are only accepted in custom mode. Each pattern
becomes its own
`github_repository_environment_deployment_policy` keyed
`"<env_key>:<pattern>"`.

`secrets`/`variables` objects carry one `value` attribute (string); the
secrets `value` is sensitive and lands plaintext in state — same
provider limitation as `modules/github/actions-secrets`. Nested entries
fan out to `github_actions_environment_secret` /
`github_actions_environment_variable` keyed `"<env_key>:<secret/variable name>"`.

## Outputs

`environment_names` (key => environment name), `environment_import_ids`
(key => resource ID, usable directly for import), `secret_names`,
`variable_names` — the latter two keyed `"<env_key>:<name>"`.

## Import

- `github_repository_environment` ← `<repository>:<environment name>`
  (e.g. `example-repo:prod`). Any `:` in the **environment name** must
  be written as `??` in the import ID (the map keys never appear here).
- `github_repository_environment_deployment_policy` ←
  `<repository>:<environment name>:<policy id>` (numeric policy ID, from
  the API or the deployment-policies data provider).
- `github_actions_environment_secret` ←
  `<repository>:<environment name>:<secret_name>`
- `github_actions_environment_variable` ←
  `<repository>:<environment name>:<variable_name>`

## Example

```hcl
repository = "example-repo"

environments = {
  "dev" = {
    environment = "dev"
    deployment_branch_policy = {
      protected_branches     = true
      custom_branch_policies = false
    }
    variables = {
      "DEPLOY_ENV" = { value = "dev" }
    }
  }
  "prod" = {
    environment = "prod"
    wait_timer          = 300
    prevent_self_review = true
    reviewers = {
      users = [1234567]
      teams = [7654321]
    }
    deployment_branch_policy = {
      custom_branch_policies = true
      branch_patterns        = ["main", "release/*"]
    }
    secrets = {
      "DEPLOY_TOKEN" = { value = "example-value" }
    }
  }
}
```
