# github/actions-organization-secrets

Map-keyed module for GitHub Actions organization secrets
(`github_actions_organization_secret`).

Each secret is keyed by its name — GitHub secret names allow uppercase
letters, digits and underscores only, and the map key is the name.

Repository scoping: `selected_repository_ids` on an entry creates the
standalone `github_actions_organization_secret_repositories` allow-list
resource for that secret — the inline attribute on the secret resource
itself is deprecated by the provider. The allow-list also requires
`visibility = "selected"` for the secret: entries are validated to carry a
non-null `selected_repository_ids` and the visibility always matches
(validated), including the unreachable-selected corner (a `selected`
secret with no allow-list) which is rejected.

Note the model consequence of the dependency data flow: an
`terraform  import`-ed secret carries no `value` — the first plan after
import shows the value change (that is the provider's behavior; treat the
first apply as a value reset). Values are not readable back from GitHub —
any drift in a changed secret shows up as a value diff you cannot
resolve from the live state.

## Auth

The provider reads `GITHUB_TOKEN` (PAT with `repo` scope; for org secrets,
`admin:org` or the fine-grained `organization_secrets` equivalent) and
`GITHUB_OWNER` from the environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `secrets` | `map(object)` | — | Map of org secrets keyed by secret name. |

Plan-time validation: `visibility` in `all`/`private`/`selected`;
`selected_repository_ids` ⇔ `visibility = "selected"` on every entry; map
keys without `.`.

### `secrets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — | Plaintext secret value (encrypted server-side; sensitive in state). |
| `visibility` | `string` | — | `all`, `private` or `selected` (validated). |
| `selected_repository_ids` | `list(number)` | `null` | GitHub numeric repository IDs for the allow-list (validated against `visibility`). |

## Outputs

`secret_names` — map of secret => secret name; `secret_updated_ats` —
map of secret => provider-applied timestamp. Values are write-only and
never echoed back.

## Import

- `github_actions_organization_secret` ← `<secret-name>`.
- `github_actions_organization_secret_repositories` ← `<secret-name>`.
  Imported secrets carry no `value` — see the note above.

## Example

```hcl
secrets = {
  "DEPLOY_TOKEN" = {
    value      = var.deploy_token
    visibility = "selected"
    selected_repository_ids = [
      458636207, # example-repo
      458636208, # infra-runner
    ]
  }
  "PUBLIC_FLAG" = {
    value      = "1"
    visibility = "all"
  }
}
```
