# gcp/secret-manager

Map-keyed module for Secret Manager secrets with optional in-Terraform secret
versions, IAM bindings, rotation and replication controls.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `secrets` | `map(object)` | — | Map of secrets keyed by an arbitrary unique ID. |

### `secrets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `secret_id` | `string` | — | Secret ID within the project, 1–255 chars; letters, digits, `-`, `_` (validated). Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the secret lives in; defaults to the provider-level project. Format validated. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `annotations` | `map(string)` | `{}` | User annotations (key–value metadata), passed through unchanged. |
| `replication` | `object` | auto replication | `{auto, user_managed}` — see the `replication` object table. Required by the API; the module sends `replication { auto {} }` when you omit it (automatic replication). |
| `rotation` | `object` | — | `{next_rotation_time, rotation_period}` — see the `rotation` object table. |
| `topics` | `list(object)` | — | Rotation-notification topics, each `{name}`; `name` must be a fully-qualified `projects/{project}/topics/{topic}` reference (validated). Requires at least one entry when `rotation` is set (validated) — the API rejects rotation without a topic. |
| `version_aliases` | `map(string)` | — | Alias keys mapped to version numbers (`latest` needs no alias — the API aliases it). Keys must be non-empty (validated). |
| `version_destroy_ttl` | `string` | — | Duration destructive version destroy is delayed (e.g. `86400s`). |
| `ttl` | `string` | — | Duration until the secret is deleted automatically (`1200s`). Mutually exclusive with the underlying `expire_time` RFC3339 field, which the module does not expose. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). `PREVENT` blocks destroy on locked secrets; `ABANDON` leaves the secret in the API. |
| `versions` | `map(object)` | — | Opt-in payloads; see the `versions` object table. Omit to manage payloads out of band. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings; see the `role_bindings` object table. |

### `replication` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `auto` | `object` | — | Automatic replication: empty object for plain auto; `customer_managed_encryption` nested `{kms_key_name}` for automatic-mode CMEK. Mutually exclusive with `user_managed` (validated; exactly one required). |
| `user_managed` | `object` | — | `{replicas}` — at least one replica (validated). |

### `replication.user_managed.replicas` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `location` | `string` | — | Replication location (e.g. `us-central1`). Required, shape-validated. |
| `customer_managed_encryption` | `object` | — | `{kms_key_name}` — CMEK for this replica. |

### `rotation` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `next_rotation_time` | `string` | — | RFC3339 timestamp of the next rotation (validated). Required by the API when `rotation_period` is set (validated); a rotation block with only `next_rotation_time` is also valid. |
| `rotation_period` | `string` | — | Seconds-suffixed duration between rotations, 3600s–3153600000s (validated). |

### `versions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `secret_data` | `string` | — | Version payload, passed by value (validated — it is the only payload field). Lands in state; see Notes. |
| `is_secret_data_base64` | `bool` | `false` | Set `true` when `secret_data` is base64-encoded. |
| `enabled` | `bool` | `true` | Version state. |
| `deletion_policy` | `string` | `DELETE` | One of `DELETE`, `DISABLE`, `ABANDON`, `PREVENT` (validated). |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/secretmanager.secretAccessor`. Must be unique within the secret (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on this secret. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

## Outputs

`secret_names` — map of secret key => secret ID.
`secret_ids` — map of secret key => secret resource name
(`projects/{project}/secrets/{secret_id}`).
`secret_version_names` — map of version composite key (secret key/version key)
=> version resource name
(`projects/{project}/secrets/{secret_id}/versions/{version}`).
`iam_binding_roles` — map of composite IAM binding key (secret key/binding key)
=> role.

## Example

```hcl
secrets = {
  "db-password" = {
    secret_id = "example-db-password"
    replication = {
      user_managed = {
        replicas = [
          { location = "europe-west4" },
          { location = "europe-west1" },
        ]
      }
    }
    versions = {
      "1" = { secret_data = "example-value" }
    }
  }
  "app-config" = {
    secret_id = "example-app-config"
    replication = {
      auto = {
        customer_managed_encryption = { kms_key_name = "projects/example-prj/locations/us-central1/keyRings/example-kr/cryptoKeys/example-key" }
      }
    }
    rotation = {
      next_rotation_time = "2026-01-15T08:00:00Z"
      rotation_period    = "2592000s"
    }
    topics = [
      { name = "projects/example-prj/topics/example-secret-notifications" },
    ]
    version_destroy_ttl = "86400s"
    versions = {
      "1" = { secret_data = base64encode("example-payload"), is_secret_data_base64 = true }
    }
    role_bindings = {
      "accessors" = {
        role    = "roles/secretmanager.secretAccessor"
        members = ["serviceAccount:api-rt@example-prj.iam.gserviceaccount.com"]
      }
    }
  }
  "dns-api-key" = {
    secret_id = "example-dns-api-key"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not secret IDs — the key only
  decouples your config from the name.
- Omitting `replication` sends the API-required block as `replication { auto {} }`
  (automatic replication). Pass it explicitly once you know the mode you want;
  moving from the implicit default to an explicit `auto` config changes the
  resource and the plan output shows it. Pair automatic replication with
  `customer_managed_encryption` for automatic-mode CMEK.
- `versions.secret_data` is stored by value and therefore lands in the
  Terraform state (it is wrapped as sensitive in the config, which only
  redacts CLI output — it does not remove it from state). The provider offers
  a `secret_data_wo` / `secret_data_wo_version` write-only alternative that
  never touches state; the module stays with `secret_data` for readability,
  and payloads can be handled wholly out of band by omitting `versions`.
- Secret versions are append-only: changing `secret_data` creates a new
  version (the provider handles that). Removing a `versions` entry destroys
  it, subject to `deletion_policy` (`DELETE` default; `DISABLE` disables
  instead, `ABANDON` removes from Terraform, `PREVENT` blocks the destroy).
- `ttl` and `expire_time` are mutually-exclusive alternatives for secret expiry
  (durations vs an RFC3339 timestamp); the module ships `ttl` only.
- `deletion_protection` also exists on the secret alongside `deletion_policy`;
  out of scope here — set it in a perimeter module if you need it.
- Pair with `gcp/project-services` (`secretmanager.googleapis.com`) and
  `gcp/pubsub` (rotation `topics`) when needed; this module does not enable
  APIs or topics itself.
- The identities Terraform runs as need Secret Manager admin on the target
  project to create secrets, versions and take over IAM bindings; an accessor
  role alone is not enough.

## Import

`google_secret_manager_secret` ← `projects/{project}/secrets/{secret_id}`.
`google_secret_manager_secret_version` ←
`projects/{project}/secrets/{secret_id}/versions/{version}`.
`google_secret_manager_secret_iam_binding` ← space-delimited
`{secret} roles/{role}`, e.g.
`projects/example-prj/secrets/example-db-password
roles/secretmanager.secretAccessor`.

