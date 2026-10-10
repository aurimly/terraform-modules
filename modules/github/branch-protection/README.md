# github/branch-protection

Map-keyed standalone module for branch protection on existing
repositories. Use `modules/github/repository` when the repo is created
by Terraform — that module embeds the same shape inline; this module is
for repos created elsewhere or managed in separate units.

## Auth

The provider reads `GITHUB_TOKEN` (PAT with `repo` scope, or
fine-grained PAT with `administration:read` + `administration:write`
repository permissions) and `GITHUB_OWNER` from the environment. No
token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `branch_protections` | `map(object)` | — | Map of protections keyed by arbitrary stable identifier. Keys are not branch names; the `branch` attribute supplies the pattern. |

### `branch_protections` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `repository_id` | `string` | — | The repository node ID — the provider also accepts the repo name; node ID is the recommended form (use `repo_ids` from `modules/github/repository`). |
| `branch` | `string` | `"main"` | Protected branch pattern. |
| `enforce_admins` | `bool` | `true` | Apply rule to admins. |
| `required_pull_request_reviews` | `object` | `{}` | PR review requirements. |
| `required_status_checks` | `object` | `{}` | Status check requirements. |
| `allows_force_pushes` | `bool` | `false` | Allow force pushes. |

The nested objects match the inline `branch_protection` in
`modules/github/repository` exactly. `required_approving_review_count`
is validated to 0-6 (the GitHub API rejects values above 6).

## Outputs

`protection_ids` — map of key => resource ID (`<repository_id>:<pattern>`),
`branch_patterns` — map of key => branch pattern actually set. Both keyed
by the input map key.

## Import

- `github_branch_protection` ← `<repository_id>:<pattern>`
  (e.g. `example-repo-id:release/*`)

## Example

With `modules/github/repository` managing the repos in a sibling unit:

```hcl
branch_protections = {
  "example-repo-main" = {
    repository_id  = dependency.repository.outputs.repo_ids["example-repo"]
    branch         = "main"
    enforce_admins = true
    required_pull_request_reviews = {
      required_approving_review_count = 2
      dismiss_stale_reviews           = true
    }
    required_status_checks = {
      strict   = true
      contexts = ["ci/example"]
    }
  }
}
```
