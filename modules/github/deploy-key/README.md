# github/deploy-key

Map-keyed module for GitHub repository deploy keys in one repo.

The module instance is per-repo: `repository` is a plain string. The
`deploy_keys` map is keyed by an arbitrary stable identifier — the key
is not the title; when `title` is not set, the map key becomes the
title on GitHub.

## Auth

The provider reads `GITHUB_TOKEN` (PAT with `repo` scope, or
fine-grained PAT with `administration:read` + `deployment:write`
repository permissions) and `GITHUB_OWNER` from the environment. No
token is committed.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | Repository name. |
| `deploy_keys` | `map(object)` | — | Map of deploy keys keyed by arbitrary key. Keys must not contain `:` — the key is not the title; the title defaults to the map key. |

### `deploy_keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `key` | `string` | — | SSH public key (OpenSSH single-line format). |
| `title` | `string` | `null` | Key title. Defaults to the map key. |
| `read_only` | `bool` | `true` | Restrict to read access. |

`key` must be a public key — never set a private key here.

## Outputs

`key_import_ids` — map of key => resource ID (`<repository>:<key_id>`,
usable directly for import), `key_titles` — map of key => title actually
set (map key when `title` was null). Both keyed by the input map key.

Keys are immutable on GitHub: changing any attribute (`key`, `title`,
`read_only`) plans a full replacement of the deploy key resource.

## Import

- `github_repository_deploy_key` ← `<repository>:<key_id>`
  (e.g. `example-repo:123456789`) — the key ID is the numeric key
  GitHub assigns; the `key_import_ids` output carries it pre-joined.

## Example

```hcl
repository = "example-repo"

deploy_keys = {
  "ci-runner" = {
    key       = "ssh-ed25519 AAAAC3Nz..."
    read_only = true
  }
  "server-pull" = {
    key   = "ssh-ed25519 AAAAB3Nz..."
    title = "app server pull key"
  }
}
```
