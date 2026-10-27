# github/repo-access

Map-keyed module for repository access: grant teams and users
permissions on repositories, one authoritative collaborators resource
per repo.

## Auth

The provider reads `GITHUB_TOKEN` (classic PAT with `repo` scope, or
fine-grained PAT with the Administration repository permission at write
level) and `GITHUB_OWNER` from the environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repositories` | `map(object)` | — | Map of access grants keyed by arbitrary key. Keys are not repository names and are not sent to GitHub. The same repository must not appear under two keys. |

### `repositories` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | Repository name (not a URL, not `owner/name`). |
| `teams` | `map(object)` | `{}` | Team grants keyed by arbitrary key. |
| `users` | `map(object)` | `{}` | Direct collaborator grants keyed by arbitrary key. |

### `teams` and `users` objects

| Attribute | Applies to | Type | Default | Description |
|---|---|---|---|---|
| `team_id` | `teams` | `string` | — | Numeric team ID or slug — feed it from modules/github/team outputs `team_ids` (ID form) or `team_slugs`. |
| `username` | `users` | `string` | — | GitHub username; org members and outside collaborators both work. |
| `permission` | both | `string` | `"push"` | `pull`, `triage`, `push`, `maintain` or `admin`. Custom repository role names are not accepted by this module. |

### Declarative access set

The module manages the complete set of direct collaborators per repo —
teams **and** users granted outside the configuration (manually or by
other tooling) are removed on the next apply. Importing an existing
repository first adopts its current collaborators into state, so the
first apply after an import removes nothing.

Do not combine with `github_team_repository` or
`github_repository_collaborator` on the same repository — the provider
documents the conflict and the resources fight on every apply. This
module's team grants go through the same authoritative resource.

If the same team is referenced twice under one repo (e.g. once by slug,
once by numeric ID) the plan-time duplicate checks cannot catch it and
which grant wins is nondeterministic — avoid it.

### Other behavior

- User grants email a repository invitation; pending invitations appear
  in `invitation_ids` (empty once accepted). Org members gaining direct
  access get no invitation ID. Changing a pending invitation's
  permission updates it. Destroy cancels pending invitations or removes
  collaborators.
- Teams that inherit access through a nested parent are left alone —
  only direct team access is reconciled.
- The module targets organization repositories. Personal repos have no
  team grants, and non-owner users must hold `push`.
- Repositories archived at destroy time are dropped from state without
  API calls.

## Outputs

`collaborator_ids` (numeric repository ID as a string) and
`invitation_ids` (map of username to pending invitation ID) — both
keyed by repo key.

## Import

- `github_repository_collaborators` ← repository name (e.g. `example-repo`)

## Example

```hcl
repositories = {
  "example-repo" = {
    repository = "example-repo"
    teams = {
      "platform" = {
        team_id    = "1234567"
        permission = "push"
      }
      "readers" = {
        team_id    = "example-team"
        permission = "pull"
      }
    }
    users = {
      "contractor-1" = {
        username = "some-user"
      }
    }
  }
}
```
