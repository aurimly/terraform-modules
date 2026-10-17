# github/actions-organization-variables

Map-keyed module for GitHub Actions organization variables
(`github_actions_organization_variable`).

Each variable is keyed by its name — GitHub variable names allow uppercase
letters, digits and underscores only, and the map key is the name.

Unlike organization secrets, org variables are readable back from GitHub —
the `variable_values` output reflects live state. Repository scoping uses
the resource's inline `selected_repository_ids` attribute (supported here;
only the secret variant is deprecated by the provider).

## Auth

The provider reads `GITHUB_TOKEN` (PAT with `repo` scope; for org
variables, `admin:org` or the fine-grained Actions organization equivalent)
and `GITHUB_OWNER` from the environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `variables` | `map(object)` | — | Map of org variables keyed by variable name. |

Plan-time validation: `visibility` in `all`/`private`/`selected`;
`selected_repository_ids` ⇔ `visibility = "selected"` on every entry; map
keys without `.`.

### `variables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — | Variable value (plain text, readable back on GitHub). |
| `visibility` | `string` | — | `all`, `private` or `selected` (validated). |
| `selected_repository_ids` | `list(number)` | `null` | GitHub numeric repository IDs when `visibility = "selected"` (validated). |

## Outputs

`variable_names` — map of variable => variable name; `variable_values` —
map of variable => live value.

## Import

- `github_actions_organization_variable` ← `<variable-name>`.

## Example

```hcl
variables = {
  "DEPLOY_ENV" = {
    value      = "prd"
    visibility = "all"
  }
  "RUNNER_LABEL" = {
    value      = "self-hosted-eu"
    visibility = "selected"
    selected_repository_ids = [
      458636207, # example-repo
    ]
  }
}
```
