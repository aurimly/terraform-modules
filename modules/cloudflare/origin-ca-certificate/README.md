# cloudflare/origin-ca-certificate

Map-keyed module for Cloudflare Origin CA certificates: certificates for
origin servers, generated from your own CSR.

**Authentication requirement — read first.** The Origin CA endpoints do not
accept API tokens. The provider consuming this module must be configured
with the Origin CA key (provider-level `api_user_service_key` argument or
the `CLOUDFLARE_API_USER_SERVICE_KEY` environment variable). Provider
configs that only use API tokens fail on every operation of this module.

The resource has no `account_id` or `zone_id`: Origin CA certificates are
user-scoped. Researched against provider 5.24.0; the `required_providers`
floor stays the repo-wide `>= 5.0.0`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `certificates` | `map(object)` | — | Map of certificates keyed by an arbitrary unique ID. |

### `certificates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `csr` | `string` | — | PEM CSR (the key pair is yours — Cloudflare signs it and never sees the private key). Newlines included, e.g. `file()` output or a heredoc. |
| `hostnames` | `list(string)` | — | Hostnames the certificate secures. Wildcards: single-level `*.` prefix only and the suffix must be fully qualified (e.g. `*.example.com`). |
| `request_type` | `string` | — | `origin-rsa`, `origin-ecc`, or `keyless-certificate`. |
| `requested_validity` | `number` | `null` | Validity in days: `7`, `30`, `90`, `365`, `730`, `1095`, `5475`. Omit to use the CA default. |

Every attribute change replaces the certificate, and the old certificate
stops being served only after origins are redeployed with the new one —
plan replacements as a rollout, not a switch flip.

## Outputs

- `certificate_ids` — keyed by certificate key.
- `certificates` — issued PEM certificates. Public values (the provider
  schema does not mark them sensitive), but any output lands in state.
- `certificate_expiries` — expiry timestamps, keyed by certificate key.

## Example

```hcl
certificates = {
  "example-origin" = {
    csr          = file("${path.module}/example-origin.csr")
    hostnames    = ["example.com", "*.example.com"]
    request_type = "origin-ecc"
    requested_validity = 5475
  }
}
```

## Import

| Resource | Import ID |
|---|---|
| `cloudflare_origin_ca_certificate` | `<certificate_id>` |
