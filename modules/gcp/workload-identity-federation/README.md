# gcp/workload-identity-federation

Map-keyed module for Workload Identity Federation pools with nested providers
and optional service account token-creator grants.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `pools` | `map(object)` | — | Map of pools keyed by an arbitrary unique ID; providers nest per pool and flatten to composite keys (`pool key/provider key`). |

### `pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `pool_id` | `string` | — | Pool ID, 4–32 lowercase letters, digits or hyphens; `gcp-` prefix is reserved (validated). Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the pool lives in; defaults to the provider-level project. Format validated. |
| `display_name` | `string` | — | Human-readable name. |
| `description` | `string` | — | Up to 256 chars. |
| `disabled` | `bool` | `false` | Disables the pool. |
| `mode` | `string` | — | One of `FEDERATION_ONLY`, `TRUST_DOMAIN`, `SYSTEM_TRUST_DOMAIN` (validated); unset = `FEDERATION_ONLY`. Immutable after creation; `TRUST_DOMAIN` pools cannot have providers. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `providers` | `map(object)` | `{}` | Nested providers; see the `providers` object table. |

### `providers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `provider_id` | `string` | — | Provider ID, 4–32 lowercase letters, digits or hyphens; `gcp-` prefix reserved (validated). Immutable. |
| `display_name` | `string` | — | Human-readable name. |
| `description` | `string` | — | Up to 256 chars. |
| `disabled` | `bool` | `false` | Disables the provider. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `attribute_condition` | `string` | — | CEL expression gating which identities map (e.g. `assertion.aud == \"https://...\"`). |
| `attribute_mapping` | `map(string)` | — | `[local name] = [assertion claim mapping]` free map. For OIDC providers the API requires a `google.subject` key (validated); AWS providers get a default mapping when unset. |
| `oidc` | `object` | — | `{issuer_uri, allowed_audiences, jwks_json}`; `issuer_uri` is a required HTTPS URL (validated). Mutually exclusive with the other protocol blocks (validated — exactly one required). |
| `saml` | `object` | — | `{idp_metadata_xml}` — raw IdP metadata XML. |
| `aws` | `object` | — | `{account_id}` — 12 digits (validated). |
| `x509` | `object` | — | `{trust_store}` — see the `x509` object table. |
| `token_creators` | `map(object)` | `{}` | `{service_account, member}` per entry — grants `roles/iam.workloadIdentityUser` on the given service account to `member`. |

### `x509` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `trust_store` | `object` | — | Required inside x509. |
| `trust_store.trust_anchors` | `list(object)` | — | At least one `{pem_certificate}` entry (validated). |
| `trust_store.intermediate_cas` | `list(object)` | — | Optional additional `{pem_certificate}` entries. |

## Outputs

`pool_names` — map of pool key => pool resource name (fully-qualified).
`pool_ids` — map of pool key => pool ID.
`provider_names` — map of provider composite key => provider resource name
(fully-qualified).
`provider_ids` — map of provider composite key => provider ID.
`token_creator_members` — map of token-creator composite key
(pool key/provider key/creator key) => IAM member (the WIF principal URI).

## Example

```hcl
pools = {
  "ci" = {
    pool_id      = "example-ci-pool"
    display_name = "CI federation"
    providers = {
      "gh" = {
        provider_id  = "example-gh-oidc"
        display_name = "GitHub Actions"
        attribute_mapping = {
          "google.subject"       = "assertion.sub"
          "attribute.repository" = "assertion.repository"
        }
        oidc = {
          issuer_uri        = "https://token.actions.githubusercontent.com"
          allowed_audiences = ["https://iam.googleapis.com/projects/example-prj/locations/global/workloadIdentityPools/example-ci-pool/providers/example-gh-oidc"]
        }
        token_creators = {
          "deployer" = {
            service_account = "deploy-rt@example-prj.iam.gserviceaccount.com"
            member          = "principalSet://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/example-ci-pool/attribute.repository/example-org/example-repo"
          }
        }
      }
      "aws" = {
        provider_id  = "example-aws"
        display_name = "AWS cross-cloud"
        attribute_mapping = {
          "google.subject"     = "assertion.sub"
          "attribute.aws_role" = "assertion.arn"
        }
        aws = { account_id = "123456789012" }
      }
    }
  }
  "partners" = {
    pool_id     = "example-partners-pool"
    description = "Partner SSO"
    providers = {
      "saml" = {
        provider_id  = "example-partner-saml"
        display_name = "Partner IdP"
        attribute_mapping = {
          "google.subject" = "assertion.name_id"
        }
        saml = { idp_metadata_xml = "base64-or-vaulted" }
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not pool/provider IDs — the key only
  decouples your config from the names.
- Each provider federates exactly one protocol; the module validates that
  exactly one of `oidc`, `saml`, `aws`, `x509` is set (plan time). Switching a
  provider's protocol forces replacement.
- There is no dedicated Azure protocol block in the current google provider;
  Microsoft Entra federation is modeled through the `oidc` block
  (`issuer_uri = \"https://sts.windows.net/{tenant-id}\"`) with
  `azure::`-prefixed claim paths in `attribute_mapping` (e.g.
  `"google.subject" = \"azure::\" + assertion.sub`).
- `mode` is immutable and `TRUST_DOMAIN`/`SYSTEM_TRUST_DOMAIN` pools cannot
  have providers; creating a pool with a different mode means a new
  `pool_id`.
- Pool and provider deletion is restricted at the API (deleted entries stay
  recoverable for 30 days). Use `disabled = true` to take a pool or provider
  out of service without hitting the deletion window; `deletion_policy =
  ABANDON`/`PREVENT` map to the provider's destroy semantics.
- `token_creators` produces non-authoritative
  `google_service_account_iam_member` grants (`roles/iam.workloadIdentityUser`)
  per provider, so several providers can grant on the same service account
  without fighting over the policy. `service_account` takes the email or the
  fully-qualified name; the cross-project case always works because the SA
  email carries its own project domain. Members with `principal://` or
  `principalSet://` only, validated. Consumer-side use `gcp/service-account-iam`
  for other roles.
- Pair with `gcp/project-services`
  (`iam.googleapis.com`, `sts.googleapis.com`) and `gcp/service-account`
  for the target accounts; this module does not enable APIs itself.
- The identity running Terraform needs IAM admin on the pool project plus
  `roles/iam.workloadIdentityPoolAdmin` to create pools, providers and
  service account IAM updates.

## Import

`google_iam_workload_identity_pool` ←
`projects/{project}/locations/global/workloadIdentityPools/{pool_id}`.
`google_iam_workload_identity_pool_provider` ←
`projects/{project}/locations/global/workloadIdentityPools/{pool_id}/providers/{provider_id}`.
`google_service_account_iam_member` ← space-delimited
`{service_account} roles/{role} {member}`, e.g.
`projects/example-prj/serviceAccounts/deploy-rt@example-prj.iam.gserviceaccount.com
roles/iam.workloadIdentityUser
principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/example-ci-pool/subject/example-subject`.
