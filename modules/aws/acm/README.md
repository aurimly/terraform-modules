# aws/acm

Map-keyed module for AWS Certificate Manager: certificate requests (DNS,
email, and Private CA), subject alternative names, key algorithms,
transparency-logging preference, and optional in-module Route 53 DNS
validation records wired to an `aws_acm_certificate_validation` resource.

## Destroy semantics (read before using)

- Removing a certificate key destroys the validation records and the
  validation resource first (graph edge), then requests certificate
  deletion — a clean teardown of the whole validation chain. On the
  handoff path (`create_validation_records = false`) the certificate
  deletes but the externally owned records survive under their
  out-of-module ownership; stale validation records left in the zone are
  the consumer's to clean up.
- Fail-closed consumers: any ALB/NLB/CloudFront still referencing the
  ARN loses TLS when the certificate goes — AWS allows deleting a
  certificate while it is in use; it is the referencing resource's
  update that fails. Plan replacements by pointing consumers at the new
  `certificate_arns` value first.
- Removing a SAN removes its validation record only when no other
  certificate in the invocation still claims the same record-set
  (records are shared across certificates; see Notes). Wildcard and base
  domains (`*.example.com` and `example.com`) share one validation
  record-set.
- Changing `domain_name`, `validation_method`, `key_algorithm` or the
  Private CA ARN forces a new certificate (downtime until re-validated);
  see the force-new table in Notes.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `certificates` | `map(object)` | `{}` | Map of certificates keyed by an arbitrary unique ID. |
| `zone_keys` | `map(string)` | `{}` | Map of zone key => hosted zone ID (starts with `Z`) used to resolve the certificates' `route53_zone` references. Feed from the `aws/route53-zone` `zone_ids` output or any id map. |

### `certificates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `domain_name` | `string` | — | Primary domain name, wildcard allowed (`*.example.com`); DNS-name shape (validated). Becomes the `Name` tag. |
| `subject_alternative_names` | `set(string)` | `[]` | Additional SAN domains (up to 100 at the API; initial quota 10). |
| `validation_method` | `string` | `DNS` | `DNS` or `EMAIL` (validated). Must be unset (`null`) for Private CA certificates. |
| `certificate_authority_arn` | `string` | — | ARN of an ACM Private CA (pass-through, pair with AWS Private CA); requires `validation_method = null` (validated). |
| `key_algorithm` | `string` | — | `EC_prime256v1`, `EC_secp384r1`, `EC_secp521r1`, `RSA_1024`, `RSA_2048`, `RSA_3072` or `RSA_4096` (validated); default `RSA_2048` at the API. |
| `options` | `object` | — | `{certificate_transparency_logging_preference, export}`. Preference is `ENABLED`/`DISABLED` (default `ENABLED`); `export` is `ENABLED`/`DISABLED` — exportable public certificates carry additional charges, and Private CA certificates cannot be exported. |
| `validation_option` | `list(object)` | — | `{domain_name, validation_domain}` per domain — where ACM should place the validation resource for that domain (`validation_domain` must be the domain itself or a superdomain). DNS validation only (validated). |
| `route53_zone` | `string` | — | A `zone_keys` map key resolving to the hosted zone that holds the validation records. Exactly one of this or `route53_zone_id` (validated). |
| `route53_zone_id` | `string` | — | Hosted zone ID (`Z...`) pass-through for zones managed outside `zone_keys`. Exactly one of this or `route53_zone` (validated). |
| `create_validation_records` | `bool` | `true` | Write the DNS validation records in this module and wait for validation via `aws_acm_certificate_validation`. No-op for EMAIL-validated certificates. DNS + default-on without zone info fails at plan time. Set `false` when the records are managed in `aws/route53-records` (the handoff path — see Notes). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = domain_name` (consumer tags win on any other key). |

## Outputs

`certificate_arns`, `certificate_domain_names`, `certificate_statuses` —
maps of certificate key => ARN / primary domain / status.

`certificate_domain_validation_options` — map of certificate key => list
of domain validation objects (`domain_name`, `resource_record_name`,
`resource_record_type`, `resource_record_value`); populated for
DNS-validated certificates. The hand-rolled-records path creates its
records from these values.

`validation_record_fqdns` — map of certificate key => set of validation
record FQDNs created by this module (only for certificates validated
in-module).

`certificate_not_afters` — map of certificate key => expiration
timestamp (expiry monitoring).

## Example

```hcl
zone_keys = dependency.zone.outputs.zone_ids

certificates = {
  "example-wildcard" = {
    domain_name               = "example.com"
    subject_alternative_names = ["*.example.com"]
    route53_zone              = "public"

    tags = {
      Environment = "example"
    }
  },
  "example-email" = {
    domain_name       = "example.org"
    validation_method = "EMAIL"

    options = {
      certificate_transparency_logging_preference = "DISABLED"
    }
  },
}
```

Serve the certificate on a load balancer with the `aws/alb` module:
`certificate_arn = dependency.acm.outputs.certificate_arns["example-wildcard"]`
on a listener.

## Notes

- Keys are arbitrary unique identifiers, not domain names. Two key
  spaces exist in this module: the user-chosen certificate keys (no
  dots, validated) and the DVO-derived validation record names
  (`_hash.example.com`, dots by nature) — record names are AWS
  internals, not configuration surface.
- Validation records are written in-module by default (`create_validation_records
  = true`) and keyed by resolved zone plus validation domain, so
  overlapping certificates (base and wildcard sharing a SAN) share one
  record instead of colliding at apply time. Single-writer caution: when
  the module writes the validation records, the same records must NOT
  also be managed in `aws/route53-records` — the duplicate record-set
  conflicts, whichever path applies second. The shared-record model has
  one residual edge: if two certificates ever produced different
  validation values for the same record-set (ACM reuses the token per
  domain in an account, so this does not happen normally), the first
  certificate validates and the second stays `PENDING_VALIDATION` until
  re-issued.
- EMAIL-validated certificates create no records and no validation
  resource; renewal notices go to the domain's standard administrative
  mailboxes (hostmaster/administrator/webmaster/postmaster at the
  validation domain).
- The handoff path (`create_validation_records = false`) needs the DVO
  output to create records in `aws/route53-records` and a
  consumer-side `aws_acm_certificate_validation` wired to those record
  FQDNs; the module then only requests the certificate.
- In-module validation records use TTL 300 (module choice, not an
  input); the records must stay in place for managed renewal to work.
- Force-new attributes: `domain_name`, `validation_method`,
  `key_algorithm`, `certificate_authority_arn` — changing any of them
  replaces the certificate (new ARN; re-point consumers before
  destroying the old one). SAN, option, and tag changes update in place.
- Private CA certificates are eligible for managed renewal once
  exported or associated with another AWS service; ACM starts renewal
  60 days before the 395-day expiry by default.

## Import

`aws_acm_certificate` ← certificate ARN
(`arn:aws:acm:region:account:certificate/uuid`).
`aws_acm_certificate_validation` ← certificate ARN.
`aws_route53_record` ← `zone-id::record-name::record-type`
(e.g. `Z0123456789ABCDEFGHIJ::_abc123.example.com::CNAME`); import into
`validation["<zone-id>|<domain>"]` matching the claim key in your
configuration.
