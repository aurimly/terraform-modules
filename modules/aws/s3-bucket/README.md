# aws/s3-bucket

Map-keyed module for S3 buckets with the standalone sub-resource set:
versioning, encryption, public access block, ownership controls, policy,
lifecycle, object lock, replication, notifications, website, logging, CORS, ACL.

## Destroy semantics (read before using)

- The module sets **no `lifecycle { prevent_destroy }`** on the bucket (that
  rule only accepts literals, so it cannot default on and stay overridable;
  hashicorp/terraform#22544). Removal protection is the natural AWS-side
  guard instead: destroying a key removes the bucket unless objects exist in it —
  S3 refuses to delete non-empty buckets and the destroy fails at the bucket, after the
  sub-resources were already destroyed in the same run. `force_destroy =
  true` (default `false`) flips this: S3 empties and deletes the bucket, wiping **all object
  versions and markers**. Do not set it on buckets you cannot afford to
  lose; keep it an explicit consumer decision for state/backups buckets.
- `object_lock` with `COMPLIANCE` mode survives even `force_destroy`:
  locked object versions cannot be deleted until the retention window
  passes, so both plain destroy and force_destroy fail with objects
  under lock.
- The `aws_s3_bucket_notifications` resource is authoritative: removing an
  entry drops that notification configuration on the bucket; clearing the
  list removes notifications entirely (API restrictions on notification
  target counts apply, see Notes).
- Removing the `versioning` entry *suspends* versioning (the versioning
  resource's delete path), it does not return the bucket to unversioned —
  the S3 API has no path back to unversioned.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `buckets` | `map(object)` | `{}` | Map of buckets keyed by an arbitrary unique ID. |

### `buckets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Globally unique bucket name, validated shape-wise (lowercase, 3–63, no `..`, no IP form). Set this **or** `bucket_prefix` (validated). Immutable; changing replaces the bucket. |
| `bucket_prefix` | `string` | — | Prefix for a provider-generated unique name (`<prefix>-<random>`); at least 3 chars, validated. Use when names must not be known at plan time. |
| `force_destroy` | `bool` | `false` | Delete the bucket with all object versions on destroy. Dangerous — see Destroy semantics. |
| `object_lock_enabled` | `bool` | — | Enable Object Lock on the bucket at creation (required for `object_lock`). Object Lock can only be set **at creation** here; enabling later requires the AWS Support token path. |
| `acceleration_status` | `string` | — | One of `Enabled`, `Suspended` (validated); presence manages the accelerate configuration. |
| `request_payer` | `string` | — | One of `Requester`, `BucketOwner` (validated); presence manages the request-payer setting. |
| `expected_bucket_owner` | `string` | — | Account ID guard passed to supported sub-resources (not to the bucket itself). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |
| `acl` | `string` | — | One of `private`, `public-read`, `public-read-write`, `aws-exec-read`, `authenticated-read` (validated). Canned ACL; set only if you use ACLs at all. Incompatible with `ownership_controls.object_ownership = BucketOwnerEnforced` (validated). |
| `policy` | `string` | — | JSON bucket policy text. |
| `public_access_block` | `object` | — | `{block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets}` — all four required (no managed defaults). Matches AWS's account-level `true` defaults when all set `true`. |
| `ownership_controls` | `object` | — | `{object_ownership}` — one of `BucketOwnerPreferred`, `ObjectsWriter`, `BucketOwnerEnforced` (validated). |
| `versioning` | `object` | — | `{status, mfa_delete, mfa}`. `status` one of `Enabled`, `Suspended`, `Disabled` (validated; `Disabled` only at create/import of unversioned buckets). `mfa_delete` one of `Enabled`/`Disabled` with `mfa` = MFA serial + code when enabling. |
| `encryption` | `object` | — | `{sse_algorithm, kms_master_key_id, bucket_key_enabled}`. `sse_algorithm` one of `AES256`, `aws:kms`, `aws:kms:dsse` (validated); `kms_master_key_id` requires a `aws:kms*` algorithm; setting the key id alone implies `aws:kms`. |
| `logging` | `object` | — | `{target_bucket, target_prefix}` — presence enables access-log delivery. |
| `website` | `object` | — | `{index_document, error_document, redirect_host, redirect_protocol, routing_rules}`; at least one target required, `redirect_host` excludes `index_document` (validated). `routing_rules` — see table. |
| `cors` | `list(object)` | `[]` | `{allowed_methods, allowed_origins, allowed_headers, expose_headers, max_age_seconds}`. |
| `lifecycle_rules` | `list(object)` | `[]` | Apply-phase configuration; see the `lifecycle_rules` object table. |
| `object_lock` | `object` | — | `{token, default_retention:{mode, days, years}}`. `mode` one of `GOVERNANCE`, `COMPLIANCE` (validated); exactly one of `days`/`years` (validated). |
| `replication` | `object` | — | `{role, rules}`; requires `versioning` (validated). See the `replication` object table. |
| `notifications` | `list(object)` | `[]` | `{type, arn, events, filter_prefix, filter_suffix}`; `type` one of `lambda`, `queue`, `sns` (validated). Authoritative per bucket. |

### `website.routing_rules` object

| Attribute | Type | Description |
|---|---|---|
| `condition` | `object` | `{key_prefix_equals, http_error_code_returned_equals}`. |
| `redirect` | `object` | `{host_name, protocol, replace_key_with, replace_key_prefix_with, http_redirect_code}`. |

### `lifecycle_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `id` | `string` | — | Rule identifier; provider default is provider-generated. |
| `status` | `string` | `Enabled` | One of `Enabled`, `Disabled` (validated). |
| `prefix` | `string` | — | Legacy prefix filter; **required unless `filter` is set** (validated). |
| `filter` | `object` | — | `{prefix, tags, tag, and}`; `tag` and `and` mutually exclusive (validated); `and` is `{prefix, tags, object_size_greater_than, object_size_less_than}`. |
| `abort_incomplete_multipart_upload_days` | `number` | — | Presence toggles the abort block. |
| `expiration` | `object` | — | `{days, date, expired_object_delete_marker}`. |
| `noncurrent_version_expiration` | `object` | — | `{noncurrent_days, newer_noncurrent_versions}`. |
| `transitions` | `list(object)` | `[]` | `{days, date, storage_class}`; class one of `STANDARD_IA`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `GLACIER_IR`, `DEEP_ARCHIVE` (validated); `storage_class` required (validated). |
| `noncurrent_version_transitions` | `list(object)` | `[]` | `{noncurrent_days, storage_class}`; same class enum (validated). At least one action per rule is required (validated). |

### `replication` object

| Attribute | Type | Description |
|---|---|---|
| `role` | `string` | IAM role ARN for replication. |
| `rules[].id` | `string` | Rule ID. |
| `rules[].status` | `string` | `Enabled` (default) or `Disabled` (validated). |
| `rules[].priority` | `number` | Needed when multiple rules potentially overlap. |
| `rules[].filter_prefix` | `string` | Prefix filter; presence toggles the filter block. |
| `rules[].destination.bucket` | `string` | Destination bucket ARN or name. |
| `rules[].destination.account_id` | `string` | Destination account (cross-account). |
| `rules[].destination.storage_class` | `string` | Target class enum (validated). |
| `rules[].delete_marker_replication_status` | `string` | `Enabled`/`Disabled` (validated). |
| `rules[].source_sse_kms_status` | `string` | `Enabled`/`Disabled` (validated); needs `priority` when multiple rules. |

## Outputs

`bucket_ids` — map of bucket key => bucket ID (the name).
`bucket_arns` — map of bucket key => bucket ARN.
`bucket_regions` — map of bucket key => region.
`bucket_regional_domain_names` — map of bucket key => regional domain name.
`bucket_regional_zone_domain_names` — map of bucket key => regional zone domain name (dual-stack friendly).
`bucket_hosted_zone_ids` — map of bucket key => Route 53 zone ID of the endpoint (alias targets).
`bucket_website_endpoints` — map of bucket key => website endpoint (only with a website config).

## Example

```hcl
buckets = {
  "logs" = {
    name          = "example-logs"
    force_destroy = false
    public_access_block = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    ownership_controls = {
      object_ownership = "BucketOwnerEnforced"
    }
    encryption = {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "arn:aws:kms:eu-central-1:111111111111:key/example"
      bucket_key_enabled = true
    }
    versioning = {
      status = "Enabled"
    }
    lifecycle_rules = {
      "abort-parts" = {
        prefix                                 = "tmp/"
        abort_incomplete_multipart_upload_days = 7
      }
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not bucket names. Bucket names are
  globally unique anyway; the key only decouples your config from the name.
- The bucket plus its configuration sub-resources are deliberately split
  (v4+ provider style). Everything except `acl` is applied after the bucket;
  S3 propagates config changes near-instantly but the API is eventually
  consistent on versioning enablement — see the 15-minute note in the AWS
  docs before writing objects after enabling versioning.
- `notifications` is authoritative per bucket: the notification resource is
  replaced when the entry set changes; you cannot split notifications of one
  bucket across two module instances.
- `expected_bucket_owner` is passed to the sub-resources that accept it; the
  bucket resource itself does not take it. Set it (or leave it off) uniformly.
- Pair with `aws/iam-role` for the replication role (replication needs
  s3:GetReplicationConfiguration, s3:ListBucket, s3:GetObjectVersion,
  s3:GetObjectVersionAcl, s3:GetObjectVersionTagging on the source and
  s3:Replicate* on the destination) and `aws/kms-key` when replicating
  SSE-KMS objects.

## Import

`aws_s3_bucket` ← bucket name or `arn:aws:s3:::<bucket>`. Note that import
resets `force_destroy` to `false` in state — apply after import to restore
the module value.
`aws_s3_bucket_policy` ← `s3_bucket_policy:<bucket>` (with optional
`:<expected_bucket_owner>` suffix).
`aws_s3_bucket_versioning` ← `<bucket>` (with optional `,<expected_owner>`
suffix, comma-delimited).
`aws_s3_bucket_website_configuration` ← `<bucket-or-arn>`.
`aws_s3_bucket_lifecycle_configuration` ← bucket name.
`aws_s3_bucket_cors_configuration` ← bucket name.
`aws_s3_bucket_acl` ← bucket (with optional `,expected-owner` suffix).
`aws_s3_bucket_logging` ← bucket name.
`aws_s3_bucket_replication_configuration` ← bucket name.
`aws_s3_bucket_server_side_encryption_configuration` ← bucket name.
`aws_s3_bucket_public_access_block` ← bucket name or account-level ID.
`aws_s3_bucket_ownership_controls` ← bucket name.
`aws_s3_bucket_notification` ← bucket name.
`aws_s3_bucket_accelerate_configuration` ← bucket name.
`aws_s3_bucket_request_payer` ← bucket name.
`aws_s3_bucket_object_lock_configuration` ← bucket name.
