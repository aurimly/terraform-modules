# github/membership

Map-keyed module for GitHub organization membership. Manage who belongs
to the organization before wiring team membership or repository access.

## Auth

The provider reads `GITHUB_TOKEN` (classic PAT with `admin:org` scope,
or fine-grained PAT with the organization Members permission at write
level) and `GITHUB_OWNER` from the environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `members` | `map(object)` | — | Map of members keyed by arbitrary key. Keys are not usernames and are not sent to GitHub. The same username must not appear under two keys. |

### `members` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `username` | `string` | — | GitHub username to invite. |
| `role` | `string` | `"member"` | `member` or `admin`. `admin` is the org owner role in the GitHub UI. |
| `downgrade_on_destroy` | `bool` | `false` | On destroy, downgrade an `admin` to `member` instead of removing them. No-op if the account is already a member or no longer in the org. |

### Behavior

- Apply sends an organization invitation to each username; destroy
  cancels a pending invitation or removes the member outright.
- GitHub requires at least one org owner: removing or demoting the last
  `admin` fails at apply with the API error.
- Usernames are case-insensitive at GitHub — the same username under
  two keys is rejected at plan time.
- `github_team_membership` (modules/github/team) requires the user to
  already be an org member; chain this module before the team module
  via a Terragrunt dependency.

## Outputs

`membership_ids` — map of member key to resource ID
(`<organization>:<username>`, the import form).

## Import

- `github_membership` ← `<organization>:<username>` (e.g. `example-org:someuser`)

## Example

```hcl
members = {
  "dev-1" = {
    username = "dev-one"
  }
  "owner-1" = {
    username = "owner-one"
    role     = "admin"
  }
}
```
