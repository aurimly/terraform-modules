# github/webhook

Map-keyed module for GitHub webhooks: repository webhooks
(`github_repository_webhook`) and organization webhooks
(`github_organization_webhook`).

The two maps are independent; use either or both. Keys are arbitrary stable
identifiers — not the payload URL and not the target repository.

Archived repositories: GitHub makes archived repos read-only — the provider
drops archived-repo webhooks from state (with a log line) instead of
erroring on destroy.

## Auth

The provider reads `GITHUB_TOKEN` and `GITHUB_OWNER` from the environment.
Repository webhooks need `repo`-scope write access on the target
repositories. Organization webhooks need `admin:org_hook` — a
repository-scoped token cannot manage them and the resource fails on
404/403. No token is committed.

`configuration.secret` is write-only on the GitHub side: reads return
`********`, so changing the secret outside Terraform does not drift (the
import family shows the same masking). The `insecure_ssl` toggle is a
boolean the API bit-packs — keep it `false` for HTTPS targets.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repository_webhooks` | `map(object)` | `{}` | Repository webhooks, keyed arbitrarily. |
| `organization_webhooks` | `map(object)` | `{}` | Organization webhooks, keyed arbitrarily. **Requires `admin:org_hook` token scope** — repository-scoped tokens cannot manage them. |

Plan-time validation: `content_type` is `form` or `json`; `events`
non-empty for both maps.

### `repository_webhooks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | Repository name to pin the webhook to. |
| `events` | `list(string)` | — | Event names that trigger the webhook (`push`, `issues`, `workflow_run`, ...). |
| `configuration` | `object` | — | `url` (payload URL), `content_type` (`form`/`json`), optional `secret`, optional `insecure_ssl`. |
| `active` | `bool` | `true` | Whether GitHub delivers events. |

### `organization_webhooks` object

Same `events` / `configuration` / `active` attributes — there is no
`name` argument (the webhook type is fixed to `web` server-side).

## Outputs

| Name | Description |
|---|---|
| `repository_webhook_urls` | Webhook key => payload URL. Sensitive. |
| `repository_webhook_ids` | Webhook key => hook resource ID (`<repository>/<id>`), usable for import. |
| `repository_webhook_repositories` | Webhook key => repository name (for import bookkeeping). |
| `organization_webhook_urls` | Webhook key => payload URL. Sensitive. |
| `organization_webhook_ids` | Webhook key => numeric hook ID, usable for import. |

## Import

- `github_repository_webhook` ← `<repository>/<webhook-id>` — the numeric
  ID is the tail of the hook's settings URL.
- `github_organization_webhook` ← `<webhook-id>`.

## Example

```hcl
repository_webhooks = {
  "ci-injector" = {
    repository = "example-repo"
    events     = ["workflow_run"]

    configuration = {
      url          = "https://ci.example.com/hooks/inject"
      content_type = "json"
      secret       = var.hook_secret
    }
  }
}

organization_webhooks = {
  "audit-feed" = {
    events = ["issues", "pull_request"]

    configuration = {
      url          = "https://audit.example.com/org-hooks/feed"
      content_type = "json"
    }
  }
}
```
