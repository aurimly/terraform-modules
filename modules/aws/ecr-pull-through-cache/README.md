# aws/ecr-pull-through-cache

Map-keyed module for ECR pull-through cache rules: cache images from an
upstream registry (Docker Hub, ECR Public, ECR private, Quay, Kubernetes,
GitHub/GitLab/Azure/Chainguard container registries) in your private ECR
registry under a repository name prefix.

## Destroy semantics (read before using)

- Deleting a rule leaves every repository and image it created **in
  place** — nothing cached is removed with the rule.
- `ecr_repository_prefix`, `upstream_registry_url` and
  `upstream_repository_prefix` are immutable: changing any of them
  replaces the rule (old rule deleted, new one created; caches again
  stay).
- `credential_arn` and `custom_role_arn` update in place. The provider
  omits empty values on update, so clearing a previously set ARN may
  not stick — if you need a rule without credentials/role, replace it
  (rename the map key or change the prefix).
- The auto-created service-linked role
  `AWSServiceRoleForECRPullThroughCache` must be deleted explicitly and
  only after all rules are gone.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `rules` | `map(object)` | `{}` | Map of pull-through cache rules keyed by an arbitrary unique ID. |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ecr_repository_prefix` | `string` | — | Repository namespace prefix in your registry, e.g. `docker-hub` → `docker-hub/<upstream-repo>`. `ROOT` is the catch-all for repositories with no other matching rule (one per registry). 2–30 chars, lowercase, `.` `_` `-` separators, optional `/` path segments (validated). The rule's unique key and its import ID. |
| `upstream_registry_url` | `string` | — | Upstream registry host, no scheme/path: `public.ecr.aws`, `registry-1.docker.io`, `ghcr.io`, `registry.gitlab.com`, `registry.k8s.io`, `quay.io`, `cgr.dev`, `<account>.dkr.ecr.<region>.amazonaws.com`, `<custom>.azurecr.io`. |
| `credential_arn` | `string` | — | Secrets Manager secret ARN with the upstream credentials (shape-validated). Secret name must start with `ecr-pullthroughcache/` and live in the same account and Region as the rule — see Notes. |
| `custom_role_arn` | `string` | — | IAM role ARN (shape-validated) for ECR-to-ECR upstreams — required cross-account; optional for same-account (e.g. cross-Region) upstreams. Not used by non-ECR upstreams. |
| `upstream_repository_prefix` | `string` | — | Upstream-side namespace prefix for ECR-to-ECR rules; unset behaves as `ROOT` (match any upstream repo). Only settable when `ecr_repository_prefix` is not `ROOT` (validated). |

## Outputs

`registry_ids` — map of rule key => registry ID (the account owning the rule).

## Example

```hcl
rules = {
  "docker-hub" = {
    ecr_repository_prefix = "docker-hub"
    upstream_registry_url = "registry-1.docker.io"
    credential_arn        = "arn:aws:secretsmanager:eu-central-1:111111111111:secret:ecr-pullthroughcache/docker-hub-abc123"
  }
  "root" = {
    ecr_repository_prefix = "ROOT"
    upstream_registry_url = "public.ecr.aws"
  }
  "cross-account-ecr" = {
    ecr_repository_prefix      = "other-account"
    upstream_registry_url      = "222222222222.dkr.ecr.us-east-1.amazonaws.com"
    custom_role_arn            = "arn:aws:iam::111111111111:role/example-ecr-ptc"
    upstream_repository_prefix = "ROOT"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not prefixes; the
  `ecr_repository_prefix` is the rule's real key (unique per registry,
  validated distinct across entries here).
- Requires `hashicorp/aws >= 5.94.0` (`custom_role_arn`,
  `upstream_repository_prefix`; `credential_arn` needs 5.40.0). Pin at
  the consumer root per repo convention.
- Credentials secret: name must begin with `ecr-pullthroughcache/`
  (the auto-created service-linked role policy scopes
  `secretsmanager:GetSecretValue` to that prefix) in the same account
  and Region as the rule. The ECR API docs document the prefix as part
  of the ARN pattern but their own Docker Hub example omits it — use
  the prefix. Pair with `aws/secrets-manager` for the secret itself.
- Every account is reported to ship **default pull-through cache rules**
  with the `ecr-public` (→ `public.ecr.aws`) and `docker-library`
  (→ `registry-1.docker.io`) prefixes. Creating a rule with either
  prefix fails with `PullThroughCacheRuleAlreadyExistsException` until
  you delete the default rule of the same prefix (defaults are
  deletable and re-creatable).
- The first pull of an image happens anonymously or with the rule's
  credentials and **requires an internet route** — with PrivateLink
  `com.amazonaws.<region>.ecr.dkr` endpoints, the very first pull still
  needs a path to the internet (AWS' own caveat). Subsequent pulls are
  served from cache.
- ECR checks the upstream for newer versions of a pulled tag at most
  once every 24 hours; the cached image is served if the check fails.
  Pushing images directly to a pull-through cache repository is not
  supported (pushes can be shadowed by the cache on later pulls).
- Tag immutability on cache repositories blocks the 24h cache refresh
  (a new upstream version cannot overwrite an existing tag).
- AWS Lambda cannot pull images through a pull-through cache rule.
- Docker Hub **official images** (`library/*` upstream) need `/library/`
  in the pull URI with a custom rule, e.g.
  `<account>.dkr.ecr.<region>.amazonaws.com/docker-hub/library/nginx:latest`.
  The default `docker-library` rule maps `library/*` automatically.
- For `upstream_repository_prefix`, unset is documented to behave as
  `ROOT`; the API may echo `ROOT` back on an unset value, which on this
  ForceNew attribute can surface as a perpetual replacement plan — set
  `upstream_repository_prefix = "ROOT"` explicitly on ECR-to-ECR rules
  (as in the example) to pin it.
- Repositories created lazily on first pull default to mutable tags,
  AES256 encryption and no policies; use a repository creation template
  (AWS-native, registry-level) or pre-create matching `aws/ecr` entries
  to control their settings.
- Pull-through cache rules are registry-scoped and not supported in the
  GovCloud partition.
- `registry.gitlab.com` upstreams work only with GitLab SaaS
  (gitlab.com), not self-managed GitLab. FIPS service endpoints are not
  supported on the first pull of an image.

## Import

`aws_ecr_pull_through_cache_rule` ← `ecr_repository_prefix`, e.g.
`ecr-public` or `docker-hub`.
