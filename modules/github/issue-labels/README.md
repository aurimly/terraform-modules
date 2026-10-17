# github/issue-labels

Map-keyed module for GitHub repository issue labels in one repo
(`github_issue_label`).

Each entry creates one label. The map key doubles as the label's display
name on GitHub — with one map key per name, several entries in a module
instance spread across colors and descriptions only. The provider upserts:
a pre-existing label with the same name is updated rather than erroring
(the default labels ship with every new repository are the usual case).

Archived repositories: GitHub makes archived repos read-only — the provider
drops archived-repo labels from state (with a log line) instead of erroring
on destroy.

## Auth

The provider reads `GITHUB_TOKEN` (PAT with `repo` scope, or fine-grained
PAT with `issues:write` repository permission) and `GITHUB_OWNER` from the
environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | Repository name. |
| `labels` | `map(object)` | — | Map of labels keyed by label display name. |

Plan-time validation: `color` is 6 hex characters without the leading `#`.

### `labels` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `color` | `string` | — | 6-character hex code without `#` (validated). |
| `description` | `string` | `null` | Short label description. |

## Outputs

`label_names` — map of label => display name (equals the map key);
`label_urls` — map of label => label URL on GitHub. Both keyed by the
input map key.

## Import

- `github_issue_label` ← `<repository>:` + label name (e.g.
  `example-repo:urgent`).

## Example

```hcl
repository = "example-repo"

labels = {
  "urgent" = {
    color       = "FF0000"
    description = "Drop everything."
  }
  "triage" = {
    color       = "FBCA04"
    description = "Needs a first pass."
  }
}
```
