# aws/cloudfront

Map-keyed module for CloudFront distributions: origins (custom and S3
via Origin Access Control), default and ordered cache behaviors,
viewer TLS, WAF attachment, logging, aliases, custom error responses,
and geographic restrictions. Cache, origin-request and
response-headers policies are passed as ID strings — the module does
not create shared account-level policy objects.

## Destroy semantics (read before using)

- Destroying a distribution takes **20–40 minutes**: CloudFront
  disables the distribution first and waits for edge propagation. Plan
  destroys accordingly.
- `retain_on_delete = true` removes the distribution from state but
  leaves it live in AWS (still serving and billing) — use only to hand
  a distribution to another workspace.
- `wait_for_deployment` gates applies, not destroys.
- OAC resources attached to removed origins are deleted with the
  distribution's entry; S3 bucket policies referencing `oac_arns` must
  be updated by their owner first.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `distributions` | `map(object)` | `{}` | Distributions keyed by an arbitrary unique ID. Distribution map keys and origin map keys must not contain `.` (validated — OAC addresses and composite outputs use both). |

### `distributions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Distribution enabled. |
| `comment` | `string` | — | Distribution comment. |
| `default_root_object` | `string` | — | e.g. `index.html`. |
| `http_version` | `string` | `http2and3` | `http1.1`, `http2`, `http2and3` or `http3` (validated). Module default differs from the provider default `http2`. |
| `is_ipv6_enabled` | `bool` | `true` | IPv6 (module default differs from the provider default `false`). |
| `wait_for_deployment` | `bool` | `true` | Wait for the apply to propagate to edges. |
| `price_class` | `string` | — | `PriceClass_100`, `PriceClass_200` or `PriceClass_All` (validated); omit for `PriceClass_All`. |
| `retain_on_delete` | `bool` | `false` | Dangerous: leave the distribution live in AWS while removing it from state. |
| `web_acl_id` | `string` | — | WAFv2 WebACL ARN (CloudFront-scope, us-east-1). |
| `aliases` | `list(string)` | `[]` | CNAME aliases; pair with an ACM certificate in us-east-1. |
| `viewer_certificate` | `object` | — | See below. Omit to use the CloudFront default certificate (`cloudfront_default_certificate = true`). Exactly one of the three sources (validated when set). |
| `logging` | `object` | — | `{bucket, prefix, include_cookies}` — standard (v1) logging to an S3 bucket. |
| `restrictions` | `object` | — | `{geo_restriction = {restriction_type, locations}}`; omitted → `restriction_type = "none"` is emitted. |
| `custom_error_responses` | `map(object)` | `{}` | Keyed arbitrarily; `{error_code, response_code, response_page_path, error_caching_min_ttl}`. `error_code` must be 400–599 and unique per distribution; `response_code`/`response_page_path` set together, else neither (validated). |
| `origins` | `map(object)` | — | Required, ≥ 1 origin (validated). Map key = `origin_id`. See below. |
| `default_cache_behavior` | `object` | — | Required. See below. |
| `ordered_cache_behaviors` | `map(object)` | `{}` | Keyed arbitrarily; same shape as `default_cache_behavior` plus `path_pattern`. See precedence note. |
| `tags` | `map(string)` | `{}` | Tags; passed through unchanged. |

### `distributions[*].viewer_certificate` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `acm_certificate_arn` | `string` | — | ACM certificate ARN (must live in us-east-1 for CloudFront). |
| `iam_certificate_id` | `string` | — | Imported-certificate IAM ID. |
| `cloudfront_default_certificate` | `bool` | — | Use the `*.cloudfront.net` default cert; then `minimum_protocol_version` must be null or `TLSv1` and `ssl_support_method` must not be set (validated). |
| `minimum_protocol_version` | `string` | — | Custom certificates default to `TLSv1.2_2021`; the default certificate sends none (AWS uses TLSv1). |
| `ssl_support_method` | `string` | — | `sni-only`, `vip` or `static-ip` (validated). |

### `distributions[*].origins` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `domain_name` | `string` | — | Origin DNS name (bucket endpoint, ALB DNS, ...). |
| `origin_path` | `string` | — | Path prefix CloudFront forwards after the alias. |
| `connection_attempts` | `number` | — | 1–3 attempts (AWS default 3). |
| `connection_timeout` | `number` | — | 1–10 seconds (AWS default 10). |
| `response_completion_timeout` | `number` | — | v6-only attribute: wait for a response to finish streaming; must be ≥ the custom origin's `origin_read_timeout` when set. |
| `origin_shield` | `object` | — | `{enabled (default false), origin_shield_region}`; enabled requires `origin_shield_region` (validated). |
| `custom_headers` | `map(object)` | `{}` | Keyed arbitrarily; `{name, value}` forwarded to the origin. |
| `oac` | `object` | — | Module creates the `aws_cloudfront_origin_access_control`: `{origin_type (default s3), signing_behavior (default always), signing_protocol (default sigv4), description}`. `origin_type` is provider-validated (`s3`, `mediastore`, `lambda`, `mediapackagev2`). Mutually exclusive with `s3_origin_access_identity` and `custom_origin_config` (validated). |
| `s3_origin_access_identity` | `string` | — | Legacy OAI **access identity path**: `origin-access-identity/cloudfront/EOXXXXXXX` (not the bare ID). |
| `custom_origin_config` | `object` | — | Custom origins (ALB, on-prem): `{http_port, https_port, origin_protocol_policy, origin_ssl_protocols, ip_address_type, origin_keepalive_timeout, origin_read_timeout}`. `origin_protocol_policy` ∈ `http-only`, `https-only`, `match-viewer`; `origin_ssl_protocols` ⊆ `SSLv3`, `TLSv1`, `TLSv1.1`, `TLSv1.2` (validated; AWS defaults: keepalive 5s, read 30s). |

### Cache behavior objects (`default_cache_behavior`, `ordered_cache_behaviors[*]`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `path_pattern` | `string` | — | Ordered behaviors only (validated: present in that shape). e.g. `/static/*`; default behavior must not set it. |
| `target_origin_id` | `string` | — | The `origins` map key to route to. Checked at apply against the distribution's origins (precondition). |
| `viewer_protocol_policy` | `string` | — | `allow-all`, `https-only` or `redirect-to-https` (validated). |
| `allowed_methods` | `list(string)` | `["GET", "HEAD", "OPTIONS"]` | `GET/HEAD/OPTIONS/PUT/POST/PATCH/DELETE` (validated). |
| `cached_methods` | `list(string)` | `["GET", "HEAD"]` | Subset of `allowed_methods` (validated). |
| `cache_policy_id` | `string` | — | Required behavior field: a managed (e.g. `658327ea-f89d-4fab-a63d-7e88639e27f2` Managed-CachingOptimized) or custom cache policy ID. The legacy forwarded-values path is not modeled. |
| `origin_request_policy_id` | `string` | — | Managed e.g. `216adef6-5c7f-47e4-b989-5492eafa07d3` AllViewer; omit to forward nothing extra. |
| `response_headers_policy_id` | `string` | — | Managed e.g. `5cc3b908-e619-4b99-88e5-2cf7f45965bd` CORS-with-preflight-ResponseHeaders. |
| `compress` | `bool` | — | Gzip/Brotli compression. |
| `trusted_key_groups` | `list(string)` | — | Key-group IDs for signed URLs. |
| `smooth_streaming` | `bool` | — | Smooth Streaming path support. |
| `field_level_encryption_id` | `string` | — | Field-level encryption config ID. |
| `realtime_log_config_arn` | `string` | — | Real-time log config ARN (pair with `aws/cloudwatch` log groups in the config). |

## Outputs

`distribution_ids`, `distribution_arns`,
`distribution_domain_names` (`dxxxx.cloudfront.net`),
`distribution_hosted_zone_ids` (alias-target zone ID, constant
`Z2FDTNDATAQYW2`), `distribution_status`, `distribution_etags` — keyed
by the input key. `oac_ids`, `oac_arns` — keyed
`"dist-key.origin-key"`, one per origin that set `oac`.

## Example

```hcl
inputs = {
  distributions = {
    "web" = {
      comment             = "example web distribution"
      default_root_object = "index.html"
      price_class         = "PriceClass_200"
      aliases             = ["example.example.com"]
      web_acl_id          = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/example/00000000-0000-0000-0000-000000000000"
      viewer_certificate = {
        acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
        ssl_support_method       = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
      }
      logging = {
        bucket = dependency.buckets.outputs.bucket_regional_domain_names["cdn-logs"]
        prefix = "cdn/"
      }
      custom_error_responses = {
        "403" = { error_code = 403, response_code = 404, response_page_path = "/errors/404.html", error_caching_min_ttl = 30 }
        "500" = { error_code = 500, response_code = 200, response_page_path = "/errors/index.html", error_caching_min_ttl = 10 }
      }
      origins = {
        "s3" = {
          domain_name = dependency.assets.outputs.regional_domain_names["static"]
          oac = {}
        }
        "api" = {
          domain_name = dependency.alb.outputs.lb_dns_names["public"]
          custom_origin_config = {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "https-only"
            origin_ssl_protocols   = ["TLSv1.2"]
          }
          origin_shield = {
            enabled              = true
            origin_shield_region = "us-east-1"
          }
        }
      }
      default_cache_behavior = {
        target_origin_id           = "s3"
        viewer_protocol_policy     = "redirect-to-https"
        cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e27f2"
        response_headers_policy_id = "5cc3b908-e619-4b99-88e5-2cf7f45965bd"
        compress                   = true
      }
      ordered_cache_behaviors = {
        "api" = {
          path_pattern               = "/api/*"
          target_origin_id           = "api"
          viewer_protocol_policy     = "https-only"
          allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
          cached_methods             = ["GET", "HEAD"]
          cache_policy_id            = "4135ea2d-6df8-44a3-9df3-86159e2a4e63"
          origin_request_policy_id   = "216adef6-5c7f-47e4-b989-5492eafa07d3"
          compress                   = true
        }
      }
      tags = { Environment = "example" }
    }
  }
}
```

## Notes

- **AWS provider >= 6.0.0 required** — `logging_config` block form and
  `response_completion_timeout` are v6 schema; the module declares no
  `required_providers` (like all `modules/aws/*` here), so pin the
  provider at the consumer's root.
- **Minimum pricing-tier impact**: `origin_shield` is billed separately
  — the module default is `enabled = false`, and enabling it requires
  `origin_shield_region` (validated).
- S3 origins with `oac = {}` create one OAC per origin, named
  `<dist-key>-<origin-key>` (keep composite map keys short — OAC names
  are capped at 64 characters); wire the bucket policy yourself: allow
  `cloudfront.amazonaws.com` `s3:GetObject` on the bucket prefix with
  condition `AWS:SourceArn = distribution_arns[key]` (pair with
  `aws/s3-bucket`, `oac_arns`/`distribution_arns` outputs).
- Aliases require an ACM certificate in **us-east-1** regardless of the
  distribution's region.
- v1 logging (`logging`) requires the target bucket to grant
  `FULL_CONTROL` to the `awslogsdelivery` canonical ID
  (`c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0`),
  and costs extra; alternatively use v2 delivery
  (`aws_cloudwatch_log_delivery_*`) or S3 access logs consumer-side.
- Ordered cache behaviors are emitted in map-key (lexicographic) order;
  avoid overlapping `path_pattern`s, or name keys deliberately to
  control precedence.
- `custom_error_responses` map keys are arbitrary; use the error code
  for readability — uniqueness of `error_code` is validated.
- Pairing: origins' `domain_name` from `aws/alb` DNS names or
  `aws/s3-bucket` endpoints; `web_acl_id` from a WAFv2 cloudfront-scope
  ACL; `cache_policy_id` etc. from AWS managed policies or
  consumer-managed custom policies.

## Import

`aws_cloudfront_distribution` ← distribution ID.
`aws_cloudfront_origin_access_control` ← OAC ID.
