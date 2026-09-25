# aws/ecr

Map-keyed module for private ECR repositories with tag mutability and
exclusion filters, scan-on-push, KMS/AES256 encryption, lifecycle
policies, and repository policies.

## Destroy semantics (read before using)

- Removing a key deletes the repository. ECR refuses to delete a
  non-empty repository: without `force_delete`, the destroy of a repo
  that still holds images **fails** (the policy/lifecycle sub-resources
  are already gone at that point). `force_delete = true` flips this —
  ECR deletes the repo **and every image in it, irreversibly**. Do not
  flip it on repos you cannot afford to lose.
- `aws_ecr_lifecycle_policy` and `aws_ecr_repository_policy` die with
  the repo; removing their entries just clears the corresponding
  configuration.
- ECR has no server-side removal-protection flag. For state-critical
  repos, gate the module inputs outside this module instead.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `repositories` | `map(object)` | `{}` | Map of repositories keyed by an arbitrary unique ID. |

### `repositories` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Repository name, lowercase, 2–256 chars; path-like namespaces allowed (`team/app`), segments separated by single `. _ -` (validated). Immutable; changing replaces the repo. |
| `image_tag_mutability` | `string` | `MUTABLE` | One of `MUTABLE`, `IMMUTABLE`, `MUTABLE_WITH_EXCLUSION`, `IMMUTABLE_WITH_EXCLUSION` (validated). Immutable modes reject overwriting existing tags pushes (a repeated push of an existing tag is rejected, not silently updated). |
| `image_tag_mutability_exclusion_filters` | `list(object)` | `[]` | Only with the `_WITH_EXCLUSION` mutability modes (validated): `{filter, filter_type}` with `filter_type = WILDCARD`; each filter supports up to two `*` wildcards. |
| `scan_on_push` | `bool` | `false` | Basic scanning at push. Enhanced scanning is set at registry level (out of scope here). |
| `encryption` | `object` | `{type = AES256}` | `{type, kms_key}`. `type` one of `AES256`, `KMS` (validated). `kms_key` accepts a KMS key ARN; **optional even under KMS** — omitted means the AWS-managed ECR key. **Changing encryption type/key forces replacement of the repository** (destroy + recreate); a repo with images must be emptied or `force_delete` set first — destructive. |
| `force_delete` | `bool` | `false` | Allow destroying a non-empty repo (see Destroy semantics). Dangerous. |
| `timeouts` | `object` | — | `{delete}`; useful for huge repos where the default delete timeout can be exceeded. |
| `lifecycle_policy` | `object` | — | `{rules}` — see the lifecycle table. Presence manages exactly one policy per repo. |
| `repository_policy` | `object` | — | `{policy}` — JSON policy document (e.g. `jsonencode(data.aws_iam_policy_document.x.json)`); non-empty JSON validated at plan time. Authoritative per repo. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `lifecycle_policy.rules` object

Rules are listed in **ascending `rule_priority`** (validated); ECR
evaluates in order and applies the first matching rule. The JSON the
module emits maps snake_case attrs to camelCase keys:

| Attribute | JSON key | Type | Description |
|---|---|---|---|
| `rules[].rule_priority` | `rulePriority` | `number` | Required. Positive (validated), unique (validated). `tagStatus = any` must be listed last and thus carry the highest priority (validated). |
| `rules[].description` | `description` | `string` | — |
| `rules[].selection.tag_status` | `selection.tagStatus` | `string` | `tagged`, `untagged`, `any` (validated). |
| `rules[].selection.tag_pattern_list` | `selection.tagPatternList` | `list(string)` | Only one of pattern/prefix lists (validated) and only with `tag_status = tagged` (validated, also requires one of the two). |
| `rules[].selection.tag_prefix_list` | `selection.tagPrefixList` | `list(string)` | Same constraints. |
| `rules[].selection.storage_class` | `selection.storageClass` | `string` | `archive` (required) with `count_type = sinceImageTransitioned`; `standard` accepted for the count-based types (validated). |
| `rules[].selection.count_type` | `selection.countType` | `string` | `imageCountMoreThan`, `sinceImagePushed`, `sinceImagePulled`, `sinceImageTransitioned` (validated). |
| `rules[].selection.count_unit` | `selection.countUnit` | `string` | `days`, required for the `since*` count types, forbidden otherwise (validated). |
| `rules[].selection.count_number` | `selection.countNumber` | `number` | Required positive (validated). |
| `rules[].action.type` | `action.type` | `string` | Default `{type = "expire"}`. `expire`, `transition` (validated). |
| `rules[].action.target_storage_class` | `action.targetStorageClass` | `string` | `archive`, required with `transition` (validated). |

## Outputs

`repository_arns` — map of repo key => ARN.
`repository_urls` — map of repo key => registry URL.
`repository_names` — map of repo key => name.
`registry_ids` — map of repo key => registry ID (account).

## Example

```hcl
repositories = {
  "app" = {
    name                 = "example/team/app"
    image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"
    image_tag_mutability_exclusion_filters = [
      { filter = "sha256-*" }
    ]
    scan_on_push = true
    encryption = {
      type    = "KMS"
      kms_key = "arn:aws:kms:eu-central-1:111111111111:key/example"
    }
    lifecycle_policy = {
      rules = [
        {
          rule_priority = 1
          description   = "expire untagged weeklies"
          selection = {
            tag_status   = "untagged"
            count_type   = "sinceImagePushed"
            count_unit   = "days"
            count_number = 30
          }
        },
        {
          rule_priority = 2
          description   = "keep last 30 tagged"
          selection = {
            tag_status       = "tagged"
            tag_prefix_list  = ["v"]
            count_type       = "imageCountMoreThan"
            count_number     = 30
          }
        },
        {
          rule_priority = 3
          description   = "expire everything else after a year"
          selection = {
            tag_status   = "any"
            count_type   = "sinceImagePushed"
            count_unit   = "days"
            count_number = 365
          }
        }
      ]
    }
    repository_policy = {
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "Pull"
            Effect    = "Allow"
            Principal = { AWS = "arn:aws:iam::111111111111:root" }
            Action = [
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "ecr:BatchCheckLayerAvailability"
            ]
          }
        ]
      })
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not repo names; the key only
  decouples your config from the name.
- The lifecycle is a single JSON document per repo: this module builds
  it from the `rules` list above (see the key mapping). Rule semantics
  are ECR's own: a rule matches at most once per image; `tagStatus =
  any` must have the highest `rulePriority` (listed last).
- Requires `hashicorp/aws >= 6.8.0` (image tag mutability exclusion
  filters); pin at the consumer root per repo convention.
- `repository_policy` is authoritative: entry changes replace the
  whole policy doc.
- Registry-level settings (replication, registry scanning config,
  registry permissions, pull-through cache rules) are out of scope —
  they are registry-level singletons, not per-repo.
- Cross-account pulls also need the target account to authenticate
  (ECR token) and, for cross-account KMS keys, read access to the key.
- Pair with `aws/kms` for CMEK (`encryption.kms_key`) and image
  scanning findings land in Inspector (registry-level enhanced
  scanning enables continuous scans).

## Import

`aws_ecr_repository` ← repository name.
`aws_ecr_lifecycle_policy` ← repository name.
`aws_ecr_repository_policy` ← repository name.
(Imported repos carry no lifecycle/repo policy in state until their
resources are imported separately.)
