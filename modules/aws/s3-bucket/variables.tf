variable "buckets" {
  description = "Map of buckets keyed by an arbitrary identifier. Each entry creates one aws_s3_bucket plus optional bucket sub-resources."
  type = map(object({
    name                  = optional(string)
    bucket_prefix         = optional(string)
    force_destroy         = optional(bool)
    object_lock_enabled   = optional(bool)
    acceleration_status   = optional(string)
    request_payer         = optional(string)
    expected_bucket_owner = optional(string)
    tags                  = optional(map(string), {})
    acl                   = optional(string)
    policy                = optional(string)
    public_access_block = optional(object({
      block_public_acls       = bool
      block_public_policy     = bool
      ignore_public_acls      = bool
      restrict_public_buckets = bool
    }))
    ownership_controls = optional(object({
      object_ownership = string
    }))
    versioning = optional(object({
      status     = string
      mfa_delete = optional(string)
      mfa        = optional(string)
    }))
    encryption = optional(object({
      sse_algorithm      = optional(string)
      kms_master_key_id  = optional(string)
      bucket_key_enabled = optional(bool)
    }))
    logging = optional(object({
      target_bucket = string
      target_prefix = optional(string)
    }))
    website = optional(object({
      index_document    = optional(string)
      error_document    = optional(string)
      redirect_host     = optional(string)
      redirect_protocol = optional(string)
      routing_rules = optional(list(object({
        condition = object({
          key_prefix_equals               = optional(string)
          http_error_code_returned_equals = optional(string)
        })
        redirect = object({
          host_name               = optional(string)
          protocol                = optional(string)
          replace_key_with        = optional(string)
          replace_key_prefix_with = optional(string)
          http_redirect_code      = optional(number)
        })
      })))
    }))
    cors = optional(list(object({
      allowed_headers = optional(list(string))
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })), [])
    lifecycle_rules = optional(list(object({
      id     = optional(string)
      status = optional(string, "Enabled")
      prefix = optional(string)
      tags   = optional(map(string))
      filter = optional(object({
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
        prefix                   = optional(string)
        tags                     = optional(map(string))
        and = optional(object({
          object_size_greater_than = optional(number)
          object_size_less_than    = optional(number)
          prefix                   = optional(string)
          tags                     = optional(map(string))
        }))
        tag = optional(object({
          key   = string
          value = string
        }))
      }))
      abort_incomplete_multipart_upload_days = optional(number)
      expiration = optional(object({
        days                         = optional(number)
        date                         = optional(string)
        expired_object_delete_marker = optional(bool)
      }))
      noncurrent_version_expiration = optional(object({
        noncurrent_days           = optional(number)
        newer_noncurrent_versions = optional(number)
      }))
      transitions = optional(list(object({
        date          = optional(string)
        days          = optional(number)
        storage_class = optional(string)
      })), [])
      noncurrent_version_transitions = optional(list(object({
        noncurrent_days = optional(number)
        storage_class   = optional(string)
      })), [])
    })), [])
    object_lock = optional(object({
      token = optional(string)
      default_retention = optional(object({
        mode  = string
        days  = optional(number)
        years = optional(number)
      }))
    }))
    replication = optional(object({
      role = string
      rules = list(object({
        id                               = optional(string)
        status                           = optional(string, "Enabled")
        priority                         = optional(number)
        delete_marker_replication_status = optional(string)
        filter_prefix                    = optional(string)
        destination = object({
          bucket        = string
          account_id    = optional(string)
          storage_class = optional(string)
        })
        source_sse_kms_status = optional(string)
      }))
    }))
    notifications = optional(list(object({
      type          = string
      arn           = string
      events        = list(string)
      filter_prefix = optional(string)
      filter_suffix = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for b in var.buckets : b.name == null || (can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", b.name)) && !can(regex("\\.\\.", b.name)))])
    error_message = "name must be 3 to 63 characters with lowercase letters, digits, dots and hyphens; start and end with a letter or digit; must not contain consecutive dots or form an IP address."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.name == null || !can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", b.name))])
    error_message = "name must not be formatted as an IP address (AWS S3 naming rule)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.bucket_prefix == null || can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", b.bucket_prefix))])
    error_message = "bucket_prefix must be 3 to 63 characters with lowercase letters, digits and hyphens, starting and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.request_payer == null || contains(["Requester", "BucketOwner"], b.request_payer)])
    error_message = "request_payer must be one of Requester or BucketOwner (case-sensitive as the API expects)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.acceleration_status == null || contains(["Enabled", "Suspended"], b.acceleration_status)])
    error_message = "acceleration_status must be one of Enabled or Suspended (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.acl == null || contains(["private", "public-read", "public-read-write", "aws-exec-read", "authenticated-read"], b.acl)])
    error_message = "acl must be one of private, public-read, public-read-write, aws-exec-read or authenticated-read (lowercase, case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.ownership_controls == null || contains(["BucketOwnerPreferred", "ObjectsWriter", "BucketOwnerEnforced"], b.ownership_controls.object_ownership)])
    error_message = "ownership_controls.object_ownership must be one of BucketOwnerPreferred, ObjectsWriter or BucketOwnerEnforced (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.versioning == null || contains(["Enabled", "Suspended", "Disabled"], b.versioning.status)])
    error_message = "versioning.status must be one of Enabled, Suspended or Disabled; Disabled is only valid while creating or importing a resource for an unversioned bucket."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.versioning == null || b.versioning.mfa_delete == null || contains(["Enabled", "Disabled"], b.versioning.mfa_delete)])
    error_message = "versioning.mfa_delete must be one of Enabled or Disabled (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.encryption == null || b.encryption.sse_algorithm == null || contains(["AES256", "aws:kms", "aws:kms:dsse"], b.encryption.sse_algorithm)])
    error_message = "encryption.sse_algorithm must be one of AES256, aws:kms or aws:kms:dsse (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.encryption == null || b.encryption.sse_algorithm != "AES256" || b.encryption.kms_master_key_id == null])
    error_message = "encryption.kms_master_key_id must not be set when sse_algorithm is AES256 (AES256 uses S3-managed keys)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.encryption == null || b.encryption.sse_algorithm != null || b.encryption.kms_master_key_id != null])
    error_message = "encryption requires at least one of sse_algorithm or kms_master_key_id (setting kms_master_key_id alone implies aws:kms)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.ownership_controls == null || b.ownership_controls.object_ownership != "BucketOwnerEnforced" || b.acl == null])
    error_message = "acl cannot be set when ownership_controls.object_ownership is BucketOwnerEnforced (the API rejects ACLs then)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.public_access_block == null || alltrue([for v in [b.public_access_block.block_public_acls, b.public_access_block.block_public_policy, b.public_access_block.ignore_public_acls, b.public_access_block.restrict_public_buckets] : v != null])])
    error_message = "public_access_block requires all four booleans explicitly (the API has no usable defaults for a managed posture)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.website == null || anytrue([b.website.index_document != null, b.website.error_document != null, b.website.redirect_host != null])])
    error_message = "website requires at least one of index_document, error_document or redirect_host."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.website == null || b.website.redirect_host == null || b.website.index_document == null])
    error_message = "website redirect_all_requests_to (redirect_host) cannot be combined with index_document (the API rejects both)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.website == null || b.website.redirect_protocol == null || contains(["http", "https"], b.website.redirect_protocol)])
    error_message = "website.redirect_protocol must be one of http or https (lowercase)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for c in b.cors : alltrue([for m in c.allowed_methods : contains(["GET", "PUT", "HEAD", "POST", "DELETE"], m)])])])
    error_message = "cors.allowed_methods must be an AWS S3 method list (GET, PUT, HEAD, POST, DELETE). Every element is validated."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for c in b.cors : length(c.allowed_origins) > 0])])
    error_message = "cors.allowed_origins must contain at least one origin (the API rejects an empty list)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : r.status == null || contains(["Enabled", "Disabled"], r.status)])])
    error_message = "lifecycle_rules.status must be one of Enabled or Disabled (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : r.prefix != null || r.filter != null])])
    error_message = "lifecycle_rules requires prefix or filter (the API rejects rules without one of the two)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : r.filter == null || !(r.filter.tag != null && r.filter.and != null)])])
    error_message = "lifecycle_rules.filter.tag and filter.and are mutually exclusive; AWS requires exactly one of and or tag structurally under filter."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : r.filter == null || r.filter.tag == null || r.filter.tags == null])])
    error_message = "lifecycle_rules.filter: set tags (map form) or tag (single-tag form), not both."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : anytrue([r.abort_incomplete_multipart_upload_days != null, r.expiration != null, r.noncurrent_version_expiration != null, length(r.transitions) > 0, length(r.noncurrent_version_transitions) > 0])])])
    error_message = "lifecycle_rules requires at least one action: abort_incomplete_multipart_upload_days, expiration, noncurrent_version_expiration, transitions or noncurrent_version_transitions."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : alltrue([for t in r.transitions : (t.storage_class != null)])])])
    error_message = "lifecycle_rules.transitions.storage_class is required for every transition action."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : alltrue([for t in r.transitions : contains(["GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER_IR", "DEEP_ARCHIVE"], t.storage_class)])])])
    error_message = "lifecycle_rules.transitions.storage_class must be one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING or GLACIER_IR (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : alltrue([for t in r.noncurrent_version_transitions : contains(["GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER_IR", "DEEP_ARCHIVE"], t.storage_class)])])])
    error_message = "lifecycle_rules.noncurrent_version_transitions.storage_class must be one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER_IR or DEEP_ARCHIVE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.object_lock == null || b.object_lock.default_retention == null || (b.object_lock.default_retention.days != null) != (b.object_lock.default_retention.years != null)])
    error_message = "object_lock.default_retention requires exactly one of days or years (the API rejects both)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.object_lock == null || b.object_lock.default_retention == null || contains(["GOVERNANCE", "COMPLIANCE"], b.object_lock.default_retention.mode)])
    error_message = "object_lock.default_retention.mode must be one of GOVERNANCE or COMPLIANCE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.replication == null || alltrue([for r in b.replication.rules : r.status == null || contains(["Enabled", "Disabled"], r.status)])])
    error_message = "replication.rules.status must be one of Enabled or Disabled (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.replication == null || alltrue([for r in b.replication.rules : r.destination.storage_class == null || contains(["STANDARD", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE"], r.destination.storage_class)])])
    error_message = "replication.rules.destination.storage_class must be one of STANDARD, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER or DEEP_ARCHIVE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.replication == null || alltrue([for r in b.replication.rules : r.delete_marker_replication_status == null || contains(["Enabled", "Disabled"], r.delete_marker_replication_status)])])
    error_message = "replication.rules.delete_marker_replication_status must be one of Enabled or Disabled (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.replication == null || alltrue([for r in b.replication.rules : r.source_sse_kms_status == null || contains(["Enabled", "Disabled"], r.source_sse_kms_status)])])
    error_message = "replication.rules.source_sse_kms_status must be one of Enabled or Disabled (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for n in b.notifications : contains(["lambda", "queue", "sns"], n.type)])])
    error_message = "notifications.type must be one of lambda, queue or sns (the target destination and its resource argument shape)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for n in b.notifications : n.type != "lambda" || can(regex("^arn:", n.arn))])])
    error_message = "notifications.arn must be a full ARN (starts with arn:) for every notification target."
  }
}
