# github/actions-variables

Map-keyed module for GitHub Actions repository variables in one repo.

The module instance is per-repo: `repository` is a plain string. The
`variables` map is keyed by the actual variable name — there is no
separate name attribute, the key is the variable name.

## Auth

The provider reads `GITHUB_TOKEN` (fine-grained PAT with
`variables` repository permission) and `GITHUB_OWNER` from the
environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | Repository name. |
| `variables` | `map(object)` | — | Map of variables keyed by variable name. |

### `variables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — | Variable value. |

## Outputs

`variable_names` — map of key => variable name (identity map, for
consumer `dependency` wiring).

## Import

- `github_actions_variable` ← `<repository>:<variable_name>`
  (e.g. `example-repo:REGISTRY_URL`)

## Example

```hcl
repository = "example-repo"

variables = {
  "REGISTRY_URL" = { value = "registry.example.com" }
  "DEPLOY_ENV"   = { value = "prod" }
}
```
