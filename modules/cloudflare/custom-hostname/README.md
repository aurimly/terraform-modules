# cloudflare/custom-hostname

Map-keyed module for Cloudflare SSL for SaaS custom hostnames. Each entry
creates one `cloudflare_custom_hostname` in the zone resolved from the
entry's `zone_id` or the module-level fallback. An optional per-zone
fallback origin (`cloudflare_custom_hostname_fallback_origin`, one per
zone) is created when `fallback_origin` is set.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone_id` | `string` | `""` | Fallback zone ID for entries (and the fallback origin) that omit `zone_id`. |
| `hostnames` | `map(object)` | — | Map of custom hostnames keyed by an arbitrary unique ID. |
| `fallback_origin` | `object` | `null` | Optional zone fallback origin (`origin`, optional `zone_id`). |

Plan-time validation: `hostname` is non-empty; hostnames are unique within
the resolved zone, case-insensitively; `ssl.type` is `dv`;
`ssl.method` is `http`/`txt`/`email`; `ssl.bundle_method` is
`ubiquitous`/`optimal`/`force`; `ssl.certificate_authority` is
`digicert`/`google`/`lets_encrypt`/`ssl_com`; `ssl.custom_cert_bundle`
holds one or two pairs; `ssl.settings` enums are `on`/`off` and
`min_tls_version` is one of `1.0`–`1.3`. A missing `zone_id` on both
levels fails the lifecycle precondition with a keyed message.

### `hostnames` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `hostname` | `string` | — | The custom hostname that points traffic to the zone via CNAME. Changing it reorders and revalidates the underlying certificate. |
| `zone_id` | `string` | `null` | Zone for this hostname; falls back to the module-level `zone_id` when omitted. |
| `custom_metadata` | `map(string)` | `null` | Arbitrary consumer metadata stored with the hostname. |
| `custom_origin_server` | `string` | `null` | Hostname where traffic for this custom hostname is sent; overrides the zone's fallback origin. |
| `custom_origin_sni` | `string` | `null` | SNI value sent to the custom origin. Not configurable with the default/fallback origin server; also accepts the literal `:request_host_header:` to pass the client's original host header through. |
| `ssl` | `object` | `null` | Certificate configuration for the hostname (see below). |

### `hostnames.*.ssl` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | `"dv"` | Only `dv` (Domain Validation) is accepted for custom hostnames. |
| `method` | `string` | `null` | Domain Validation method: `http`, `txt` or `email`. `txt` pairs with the `ownership_verifications` output to place the verification record. |
| `bundle_method` | `string` | `null` | `ubiquitous`, `optimal` or `force`. |
| `certificate_authority` | `string` | `null` | `digicert`, `google`, `lets_encrypt` or `ssl_com`. |
| `cloudflare_branding` | `bool` | `null` | Include Cloudflare branding in the certificate. |
| `wildcard` | `bool` | `null` | Request a wildcard certificate for the hostname. |
| `custom_certificate` | `string` | `null` | PEM certificate to use instead of one issued by Cloudflare. |
| `custom_key` | `string` | `null` | Private key for `custom_certificate` (sensitive; persisted in state). |
| `custom_csr_id` | `string` | `null` | ID of a Cloudflare-held CSR for the certificate. |
| `custom_cert_bundle` | `list(object)` | `null` | One or two `{custom_certificate, custom_key}` pairs covering the hostname and a wildcard of it. |
| `settings` | `object` | `null` | TLS settings: `ciphers`, `early_hints`, `http2`, `tls_1_3` (`on`/`off`) and `min_tls_version` (`1.0`–`1.3`). |

## Outputs

| Name | Description |
|---|---|
| `custom_hostname_ids` | Map of key => custom hostname ID. |
| `custom_hostname_statuses` | Map of key => activation status (advisory; drifts outside Terraform). |
| `ownership_verifications` | Map of key => `{type, name, value}` TXT verification record (may be null until the API returns it). Feed into `modules/cloudflare/dns-records` to activate. |
| `fallback_origin_status` | Fallback origin activation status, or `null` when unset. |
| `fallback_origin_errors` | Fallback origin activation errors, or `null` when unset. |

## Example

```hcl
zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

fallback_origin = {
  origin = "saas.example.com"
}

hostnames = {
  "acme" = {
    hostname             = "app.customer.example"
    custom_origin_server = "origin.example.com"
    ssl = {
      method = "txt"
    }
  }
}
```

## Notes

- `ssl.type` is `dv`-only — the API rejects every other certificate type
  for custom hostnames.
- Activation is asynchronous: `status` values (`pending`, `active`,
  `moved`, …) settle outside Terraform, so `custom_hostname_statuses` and
  `fallback_origin_status` are advisory outputs; a plan may show them as
  drift.
- With `ssl.method = "txt"` (or the API falling back to TXT validation),
  read `ownership_verifications` and place the returned `{name, value}` as
  a TXT record in the customer's zone — the hostname stays `pending`
  until the record verifies.
- The fallback origin must exist as a DNS record in the zone before it
  activates; the module creates the `cloudflare_custom_hostname_fallback_origin`
  resource, the DNS record is consumer-side (e.g. `modules/cloudflare/dns-records`).
- `custom_key` and `custom_cert_bundle` keys are sensitive and persisted
  in state like any certificate input; the module outputs nothing
  sensitive.
- The caller needs `SSL and Certificates Edit` on the zone (the provider's
  permission list names SSL and Certificates Read/Write).

## Import

`cloudflare_custom_hostname` ← `<zone_id>/<custom_hostname_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d`.

`cloudflare_custom_hostname_fallback_origin` ← `<zone_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353` — the fallback origin is identified by
its zone.
