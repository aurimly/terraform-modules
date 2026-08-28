# gcp/service-account

Map-keyed module for Google Cloud service accounts. IAM on the created
service accounts — who can impersonate them or act as them — is managed by
the separate [`gcp/service-account-iam`](../service-account-iam) module,
mirroring the repo's `project` / `project-iam` split.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | Project the service accounts are created in by default. Each entry can override it with its own `project`. |
| `service_accounts` | `map(object)` | — | Map of service accounts keyed by an arbitrary unique ID. |

### `service_accounts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Account id used to generate the email and stable unique id; unique within a project, 6–30 chars, `[a-z]([-a-z0-9]*[a-z0-9])` (RFC1035). Immutable — changing it forces a new service account. |
| `display_name` | `string` | `null` | Display name; defaults to the `account_id` when unset. |
| `description` | `string` | `null` | Free-text description; at most 256 characters (the API allows 256 UTF-8 bytes). |
| `disabled` | `bool` | `false` | Whether the service account is disabled. The API ignores this during creation — an account created with `disabled = true` starts enabled and is disabled by a subsequent apply. |
| `create_ignore_already_exists` | `bool` | `false` | Skip creation (adopt into state) when a service account with the same email already exists. |
| `deletion_policy` | `string` | `DELETE` | One of `DELETE`, `ABANDON`, `PREVENT`. |
| `project` | `string` | `null` | Project override for this entry; defaults to `project_id`. |

Plan-time validation: `account_id` format and length, `project` format,
description length, `deletion_policy` value, and that no two entries resolve
to the same project/account_id pair (the API rejects duplicates within a
project at creation).

## Outputs

`service_accounts` — map of service account key => object:

| Attribute | Description |
|---|---|
| `email` | Service account email (`account_id@<project>.iam.gserviceaccount.com`). |
| `member` | Identity form `serviceAccount:<email>`, for granting this account roles on other resources. |
| `name` | Fully-qualified resource name `projects/<project>/serviceAccounts/<email>` — usable as the values of the `gcp/service-account-iam` module's `service_accounts` input. |
| `unique_id` | Stable numeric unique id of the service account. |
| `project` | Project the service account lives in. |

## Example

```hcl
project_id = "my-project"

service_accounts = {
  "app" = {
    account_id   = "app-prod"
    display_name = "App runtime"
    description  = "Runtime identity for the app's Cloud Run services"
  }
  "ci" = {
    account_id                   = "ci-deployer"
    create_ignore_already_exists = true
  }
  "offboarded" = {
    account_id      = "offboarded-sa"
    disabled        = true
    deletion_policy = "PREVENT"
  }
  "other-project" = {
    account_id = "app-prod"
    project    = "my-other-project"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — `account_id`
  only needs to be unique within its project, and two entries may share an
  `account_id` when they target different projects.
- The API ignores `disabled` during creation (provider note): a service
  account created with `disabled = true` starts enabled and gets disabled on
  a later apply.
- Deleting and recreating a service account is disruptive: any IAM roles
  granted to it (as an identity) must be re-applied, and Google restricts
  reusing the deleted account's email for a period afterwards.
- Service account creation is eventually consistent — applying IAM to a
  freshly created account in the same run can fail. The provider suggests a
  delay (e.g. a `local-exec` sleep) when both happen in one config; with
  separate units, the natural Terragrunt dependency ordering plus a second
  run resolves it.
- `create_ignore_already_exists = true` is for adoption: the first apply
  skips creating an account whose email already exists and adopts the
  existing account into state — no separate import is needed.
- The runner needs `roles/iam.serviceAccountAdmin` (or equivalent
  `iam.serviceAccounts.create`) on each target project.

## Import

`google_service_account` ← `projects/<project_id>/serviceAccounts/<email>`
