# stackit/object_storage

Map-keyed module for STACKIT Object Storage buckets, credentials groups,
and credentials.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `buckets` | `map(object)` | — | Map of buckets keyed by an arbitrary unique ID. |
| `credentials_groups` | `map(object)` | — | Map of credentials groups keyed by an arbitrary unique ID. |
| `credentials` | `map(object)` | — | Map of S3 credentials keyed by an arbitrary unique ID; see the rotation note. |

### `buckets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Bucket name, DNS conform: 3–63 characters of lowercase letters, digits, dots and hyphens, starting and ending with a letter or digit, no consecutive dots (S3 rule, validated); no comma (the import ID is comma-joined, validated). |
| `project_id` | `string` | — | STACKIT project UUID the bucket is created in (validated). |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the bucket. |
| `object_lock` | `bool` | API default (`false`) | Object lock for the bucket; create-time only. Requires a project-level compliance lock (a separate resource, out of scope here) — without one, the create fails at apply. |

### `credentials_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Credentials group name. |
| `project_id` | `string` | — | STACKIT project UUID the credentials group is created in (validated). |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. |

### `credentials` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the credential is created in (validated). |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. |
| `credentials_group_id` | `string` | `null` | Credentials group UUID to create the credential in (bring your own group). Exactly one of `credentials_group_id`/`credentials_group_key` must be set (validated). |
| `credentials_group_key` | `string` | `null` | Key into this module's `credentials_groups` map instead of a raw UUID (validated to exist); lets the credential follow a group created by the same module instance. |
| `expiration_timestamp` | `string` | `null` | Expiry as RFC3339 with seconds precision and no fractional seconds (e.g. `2027-01-02T03:04:05Z`, numeric offsets accepted — validated). |
| `rotate_when_changed` | `map(string)` | `null` | Write-only rotation trigger: changing any value replaces the credential (destroy + create, new keys). Keys and values are never sent to the API — see the rotation recipe in the notes. |

## Outputs

`buckets` — map of bucket key => object:

| Attribute | Description |
|---|---|
| `url_path_style` | Bucket URL in path style. |
| `url_virtual_hosted_style` | Bucket URL in virtual-hosted style. |
| `id` | `"{project_id},{region},{name}"` — the import ID. |

`credentials_groups` — map of credentials group key => object:

| Attribute | Description |
|---|---|
| `credentials_group_id` | Credentials group UUID. |
| `urn` | Credentials group URN. |
| `id` | `"{project_id},{region},{credentials_group_id}"` — the import ID. |

`credentials` (**sensitive**) — map of credential key => object:

| Attribute | Description |
|---|---|
| `access_key` | S3 access key (API-generated). |
| `secret_access_key` | S3 secret access key (API-generated, provider-sensitive). |
| `credential_id` | Credential UUID. |
| `name` | Credential name (API-generated). |
| `id` | `"{project_id},{region},{credentials_group_id},{credential_id}"` — the import ID. |

## Example

```hcl
module "object_storage" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/object_storage?ref=v1.3.0"

  buckets = {
    "app-data" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-app-data"
      region     = "eu01"
    }
  }

  credentials_groups = {
    "app" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-app"
      region     = "eu01"
    }
  }

  credentials = {
    "app-current" = {
      project_id            = "12345678-1234-1234-1234-123456789012"
      region                = "eu01"
      credentials_group_key = "app"
      rotate_when_changed = {
        rotation = "2026-09-08"
      }
    }
    "app-expiring" = {
      project_id            = "12345678-1234-1234-1234-123456789012"
      region                = "eu01"
      credentials_group_key = "app"
      expiration_timestamp  = "2027-01-02T03:04:05Z"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- Object Storage is enabled for the project automatically: the provider
  enables it when creating the first bucket, credentials group or
  credential.
- Bucket names must be unique per project and region upstream — the API
  rejects duplicates at apply, so avoid duplicate `name`s across entries
  targeting the same project/region.
- A bucket cannot be destroyed while it contains objects — empty it
  first; this also applies to the replacement caused by renaming a key
  or changing `name`/`region`/`project_id`.
- `object_lock` is create-time only and requires a project-level
  compliance lock (`stackit_objectstorage_compliance_lock`, a separate
  resource intentionally out of scope — a consumer-side option);
  without one, the create fails at apply.
- Credentials: the API generates `name`, `access_key` and
  `secret_access_key`; only `expiration_timestamp` and
  `rotate_when_changed` are manageable. The `credentials` output is
  sensitive — distribute the values from the pipeline, not logs.
- Rotation recipe: set `rotate_when_changed = { "rotation" = "<version
  or date>" }` and bump the value to force a replacement (a new
  access/secret pair). Replacement is destroy-then-create: the old pair
  stops working at the swap, and the new secret is only readable from
  the module output afterwards. For zero-downtime rotation, create a
  new credential entry first, switch consumers over, then drop the old
  entry. Adding an `expiration_timestamp` is a common backstop so a
  lost pair — or a forgotten rotation — expires on its own; setting or
  changing it replaces the credential with a new access/secret pair, so
  add it together with the planned rotation, not between rotations.
- The `credentials_group_key` cross-reference in the variable validation
  requires Terraform/OpenTofu >= 1.9 (cross-variable validation
  support).
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, no-comma bucket names) and the documented API rules (DNS
  conform bucket names, seconds-precision expiry).
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; the
  newest behavior in this module (`rotate_when_changed`, 0.97.0)
  predates it, so no behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_objectstorage_bucket` ← `{project_id},{region},{name}`

`stackit_objectstorage_credentials_group` ←
`{project_id},{region},{credentials_group_id}`

`stackit_objectstorage_credential` ←
`{project_id},{region},{credentials_group_id},{credential_id}`
