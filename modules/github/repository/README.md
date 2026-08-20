# github/repository

Map-keyed module for GitHub repository settings and branch protection.

## Auth

The provider reads `GITHUB_TOKEN` (classic PAT with `repo` scope) and
`GITHUB_OWNER` from the environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repositories` | `map(object)` | — | Map of repos keyed by repo name. |

### `repositories` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `description` | `string` | `""` | Repo description. |
| `visibility` | `string` | `"private"` | `"public"` or `"private"`. |
| `topics` | `list(string)` | `[]` | Repo topics. |
| `has_issues` | `bool` | `false` | Issues enabled. |
| `has_wiki` | `bool` | `false` | Wiki enabled. |
| `has_projects` | `bool` | `false` | Projects enabled. |
| `delete_branch_on_merge` | `bool` | `true` | Delete head branches on merge. |
| `archived` | `bool` | `false` | Archive the repo. |
| `branch_protection` | `object` | — | Optional branch protection. |

### `branch_protection` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `branch` | `string` | `"main"` | Protected branch pattern. |
| `enforce_admins` | `bool` | `true` | Apply rule to admins. |
| `required_pull_request_reviews` | `object` | `{}` | PR review requirements. |
| `required_status_checks` | `object` | `{}` | Status check requirements. |
| `allows_force_pushes` | `bool` | `false` | Allow force pushes. |

`default_branch` is **not** settable (deprecated in v6); new repos inherit
GitHub's `main` default. It is exported as an output.

## Safe destroy

`archive_on_destroy = true` is hardcoded: removing a repo from the map
**archives** it, never deletes. Recovery: re-add the entry (plans a
create that fails "name already exists"), then re-import
`github_repository.repo["<name>"]` (and its branch protection) into fresh
state.

## Outputs

`repo_full_names`, `repo_ids` (node ID), `repo_names`, `default_branch`,
`ssh_clone_urls`, `html_urls` — all keyed by repo key.

## Import

- `github_repository` ← `<name>`
- `github_branch_protection` ← `<repository>:<branch>`
  (e.g. `example-repo:main`)

## Example

```hcl
repositories = {
  "example-repo" = {
    description = "Example repository"
    visibility  = "private"
    has_issues  = true
    branch_protection = {
      enforce_admins = true
      required_pull_request_reviews = {
        required_approving_review_count = 0
      }
    }
  }
}
```
