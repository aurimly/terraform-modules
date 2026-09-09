# gcp/artifact-registry

Map-keyed module for Google Cloud Artifact Registry repositories with optional IAM
bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repositories` | `map(object)` | — | Map of repositories keyed by an arbitrary unique ID. |

### `repositories` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `repository_id` | `string` | — | Repository ID, 1–100 chars; lowercase letters, digits, `.`, `_`, `-`; start alnum (validated). Immutable; changing forces replacement. |
| `location` | `string` | — | Repository location: region (`us-central1`), multi-region (`us`, `europe`, `asia`). Immutable; changing forces replacement. |
| `format` | `string` | — | Repository format: `DOCKER`, `MAVEN`, `NPM`, `PYTHON`, `APT`, `YUM`, `KFP`, `GO`, `GENERIC` and newer values as the API grows them. Shape-validated (uppercase identifier) only — the API rejects unknown values. Immutable. |
| `project_id` | `string` | — | Project the repository lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `kms_key_name` | `string` | — | CMEK crypto key (fully-qualified `projects/.../keyRings/.../cryptoKeys/...`) for repository data encryption — pair with the `gcp/kms` module. |
| `cleanup_policy_dry_run` | `bool` | — | Run cleanup policies in dry-run (log-only) mode. |
| `cleanup_policies` | `map(object)` | `{}` | Cleanup policies keyed by policy ID; see the `cleanup_policies` object table. |
| `docker_config` | `object` | — | `{immutable_tags}` — reject overwriting existing image tags. |
| `vulnerability_scanning_config` | `object` | — | `{enablement_config}` — one of `INHERITED` (follow the project setting), `DISABLED`, or `""` (empty = disabled; validated by the provider). |
| `role_bindings` | `map(object)` | `{}` | IAM bindings; see the `role_bindings` object table. |

### `cleanup_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `id` | `string` | — | Policy ID (map key must also be unique; the key is used for state, `id` is sent to the API). |
| `action` | `string` | — | One of `DELETE`, `KEEP` (validated). |
| `condition.tag_state` | `string` | — | One of `TAGGED`, `UNTAGGED`, `ANY` (validated). |
| `condition.tag_prefixes` | `list(string)` | — | Apply only to versions with these tag prefixes. |
| `condition.version_name_prefixes` / `package_name_prefixes` | `list(string)` | — | Version/package name prefix matches. |
| `condition.older_than` / `newer_than` | `string` | — | Duration cutoffs, day-suffixed (e.g. `30d`). |
| `most_recent_versions.keep_count` | `number` | — | Keep N most recent versions. |
| `most_recent_versions.package_name_prefixes` | `list(string)` | — | Apply only to these packages. |
| `most_recent_versions` | — | — | Only valid with `action = KEEP` (validated). |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/artifactregistry.writer`. Must be unique within the repository (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on this repository. |

## Outputs

`repository_ids` — map of repository key => repository_id.
`repository_uris` — map of repository key => registry URI
(host/project/repository_id, e.g. `us-docker.pkg.dev/...` — the value
`docker push` targets).
`repository_names` — map of repository key => fully-qualified repository name
(`projects/.../locations/.../repositories/...`).
`iam_binding_roles` — map of composite IAM binding key
(`repository key/binding key`) => role.

## Example

```hcl
repositories = {
  "app-images" = {
    repository_id = "app-images"
    location      = "us-central1"
    format        = "DOCKER"
    description   = "Application container images"

    docker_config = {
      immutable_tags = true
    }

    cleanup_policies = {
      "keep-recent" = {
        action = "KEEP"
        most_recent_versions = {
          keep_count = 10
        }
      }
      "delete-old-untagged" = {
        action    = "DELETE"
        condition = {
          tag_state  = "UNTAGGED"
          older_than = "30d"
        }
      }
    }

    role_bindings = {
      "writers" = {
        role    = "roles/artifactregistry.writer"
        members = ["serviceAccount:ci@example-project-1234.iam.gserviceaccount.com"]
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not repository IDs — the key only decouples
  your config from the repository.
- Pair with `gcp/project-services` (`artifactregistry.googleapis.com`) when the target
  project does not have the Artifact Registry API enabled yet; this module does not
  enable APIs itself.
- IAM bindings are authoritative per role
  (`google_artifact_registry_repository_iam_binding`): members you omit are removed
  from that role on the repository. Each binding always targets the same
  project/location as its repository — when you set `project_id` on the repository
  object, both resources resolve to it; when you omit it, both fall back to the
  provider-level project.
- Only `STANDARD` repositories are supported; `VIRTUAL`/`REMOTE` repositories (which
  need `remote_repository_config` with upstream repos/credentials) are not implemented
  yet.
- `repository_id`, `location` and `format` are immutable — changing any of them
  replaces the repository.
- `docker_config.immutable_tags = true` is recommended for release registries: once a
  tag exists, pushes overwriting it are rejected (accidental-replay protection).

## Import

`google_artifact_registry_repository` ←
`projects/{project}/locations/{location}/repositories/{repository_id}` (also
`{project}/{location}/{repository_id}` or `{location}/{repository_id}`).
`google_artifact_registry_repository_iam_binding` ← space-delimited
`{project}/{location}/{repository_id} roles/{role}`.
