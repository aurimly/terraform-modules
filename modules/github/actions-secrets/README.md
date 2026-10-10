# github/actions-secrets

Map-keyed module for GitHub Actions repository secrets in one repo.

The module instance is per-repo: `repository` is a plain string. The
`secrets` map is keyed by the actual secret name — there is no
separate name attribute, the key is the secret name.

## Auth

The provider reads `GITHUB_TOKEN` (fine-grained PAT with
`secrets` repository permission) and `GITHUB_OWNER` from the
environment. No token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | Repository name. |
| `secrets` | `map(object)` | — | Map of secrets keyed by secret name. |

### `secrets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — | Secret value (sensitive). |

The module uses the v6 `value` attribute (plaintext). The deprecated
`plaintext_value`/`encrypted_value` pair is not exposed; consumer-managed
client-side encryption works with the `value_encrypted` + `key_id` path
outside this module.

The provider marks `value` `sensitive`, so values render as
`(sensitive value)` in plans — but **values still land plaintext in
state**, and values seen by Terraform from nonsensitive literals are
visible in the change list at write time. Populate from a
`secret-value` style source or replace with client-side encryption if
state exposure is a concern.

## Outputs

`secret_names` — map of key => secret name (identity map, for consumer
`dependency` wiring).

## Import

- `github_actions_secret` ← `<repository>:<secret_name>`
  (e.g. `example-repo:DEPLOY_TOKEN`)

After import, `value` is empty in state (provider limitation): run a
change (re-apply with the real value) or add

```hcl
lifecycle {
  ignore_changes = [value]
}
```

per entry if the value was rotated outside Terraform. The module does
not bake `ignore_changes` in — it would disable updates made by
removing a key from the map's intent.

## Example

```hcl
repository = "example-repo"

secrets = {
  "DEPLOY_TOKEN" = { value = "example-value" }
  "API_KEY"      = { value = "example-key" }
}
```
