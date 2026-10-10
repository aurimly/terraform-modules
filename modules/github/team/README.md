# github/team

Map-keyed module for GitHub teams, with nested membership and
parent-team wiring inside one map.

## Auth

The provider reads `GITHUB_TOKEN` (classic PAT with `repo` scope, or
fine-grained PAT with `members:write` organization permission) and
`GITHUB_OWNER` from the environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `teams` | `map(object)` | — | Map of teams keyed by arbitrary key. Keys are not team names; they must not contain `:` and are not sent to GitHub. |

### `teams` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Team name. |
| `description` | `string` | `""` | Team description. |
| `privacy` | `string` | `"closed"` | `"closed"` or `"secret"`. Secret teams are visible only to their members and org owners; nested teams inside a secret parent inherit visibility constraints. |
| `notification_setting` | `string` | `null` | `notifications_enabled`, `notifications_disabled`; unset, the provider default `notifications_enabled` applies. |
| `parent_team_key` | `string` | `null` | Parent team by map key (resolved to numeric ID in a second pass — not by raw ID). Must be another key of the same map, never itself. |
| `members` | `map(object)` | `{}` | Team members keyed by arbitrary key — the same username may sit in several teams. Keys must not contain `:`. |

### `members` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `username` | `string` | — | GitHub username to add. |
| `role` | `string` | `"member"` | `member` or `maintainer`. Org owners may only sit as `maintainer`. |

Nested maps fan out to `github_team_membership` keyed `"<team_key>:<member_key>"`.
`github_team_membership` is incompatible with `github_team_members` — if
you manage the same team with that resource elsewhere, migrate to one of
the two, never both.

### Cycles and parent removal

`parent_team_key` resolves to a reference on the resolved numeric ID of
another team in the same map, so a parent must always appear as a key in
that map. Cycles (a -> b -> a) fail plan with a dependency cycle error.
Removing a team that is another team's parent: drop the child first,
then the parent (a destroyed parent leaves the child's reference
dangling — the child would then need its `parent_team_key` set to
`null` in the same change).

## Outputs

`team_ids` (numeric team IDs), `team_slugs` (slug computed by GitHub, may
differ from name), `team_node_ids` (node IDs) — all keyed by team key.
`membership_ids` is keyed `"<team_key>:<member_key>"` and carries the
membership resource ID (numeric team ID:username, the import form).

Numeric `team_id`s satisfy the ID form other team resources accept.
Re-creating a team after deletion produces a new numeric ID —
re-import membership references.

## Import

- `github_team` ← team ID or name
- `github_team_membership` ← `<team_id>:<username>` (e.g. `1234567:someuser`)

## Example

```hcl
teams = {
  "platform" = {
    name        = "Platform"
    description = "Platform engineering"
    privacy     = "closed"
    members = {
      "dev-1" = {
        username = "dev-one"
        role     = "maintainer"
      }
      "dev-2" = {
        username = "dev-two"
      }
    }
  }
  "platform-sre" = {
    name            = "Platform SRE"
    parent_team_key = "platform"
    privacy         = "closed"
    members = {
      "sre-1" = {
        username = "sre-one"
      }
    }
  }
}
```
