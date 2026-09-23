resource "aws_s3_bucket" "bucket" {
  for_each = var.buckets

  bucket              = each.value.name
  bucket_prefix       = each.value.bucket_prefix
  force_destroy       = each.value.force_destroy
  object_lock_enabled = each.value.object_lock_enabled
  tags                = merge(each.value.tags, { Name = coalesce(each.value.name, each.value.bucket_prefix) })

  lifecycle {
    precondition {
      condition     = (each.value.name != null) != (each.value.bucket_prefix != null)
      error_message = "bucket \"${each.key}\" must set exactly one of name or bucket_prefix (AWS requires one; the API rejects both)."
    }

    precondition {
      condition     = each.value.object_lock == null || each.value.object_lock_enabled
      error_message = "bucket \"${each.key}\" must set object_lock_enabled = true to manage an object_lock configuration."
    }

    precondition {
      condition     = each.value.replication == null || each.value.versioning != null
      error_message = "bucket \"${each.key}\" must enable versioning to manage a replication configuration."
    }
  }
}

resource "aws_s3_bucket_accelerate_configuration" "accelerate" {
  for_each = { for k, b in var.buckets : k => b if b.acceleration_status != null }

  bucket                = aws_s3_bucket.bucket[each.key].id
  expected_bucket_owner = each.value.expected_bucket_owner
  status                = each.value.acceleration_status
}

resource "aws_s3_bucket_request_payment_configuration" "request_payer" {
  for_each = { for k, b in var.buckets : k => b if b.request_payer != null }

  bucket                = aws_s3_bucket.bucket[each.key].id
  expected_bucket_owner = each.value.expected_bucket_owner
  payer                 = each.value.request_payer
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  for_each = { for k, b in var.buckets : k => b if b.public_access_block != null }

  bucket                  = aws_s3_bucket.bucket[each.key].id
  block_public_acls       = each.value.public_access_block.block_public_acls
  block_public_policy     = each.value.public_access_block.block_public_policy
  ignore_public_acls      = each.value.public_access_block.ignore_public_acls
  restrict_public_buckets = each.value.public_access_block.restrict_public_buckets
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  for_each = { for k, b in var.buckets : k => b if b.ownership_controls != null }

  bucket = aws_s3_bucket.bucket[each.key].id

  rule {
    object_ownership = each.value.ownership_controls.object_ownership
  }
}

resource "aws_s3_bucket_acl" "acl" {
  for_each = { for k, b in var.buckets : k => b if b.acl != null }

  bucket = aws_s3_bucket.bucket[each.key].id
  acl    = each.value.acl

  depends_on = [aws_s3_bucket_ownership_controls.ownership_controls]
}

resource "aws_s3_bucket_policy" "policy" {
  for_each = { for k, b in var.buckets : k => b if b.policy != null }

  bucket = aws_s3_bucket.bucket[each.key].id
  policy = each.value.policy
}

resource "aws_s3_bucket_versioning" "versioning" {
  for_each = { for k, b in var.buckets : k => b if b.versioning != null }

  bucket                = aws_s3_bucket.bucket[each.key].id
  expected_bucket_owner = each.value.expected_bucket_owner
  mfa                   = each.value.versioning.mfa

  versioning_configuration {
    status     = each.value.versioning.status
    mfa_delete = each.value.versioning.mfa_delete
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = { for k, b in var.buckets : k => b if b.encryption != null }

  bucket                = aws_s3_bucket.bucket[each.key].id
  expected_bucket_owner = each.value.expected_bucket_owner

  rule {
    bucket_key_enabled = each.value.encryption.bucket_key_enabled

    apply_server_side_encryption_by_default {
      sse_algorithm     = each.value.encryption.sse_algorithm
      kms_master_key_id = each.value.encryption.kms_master_key_id
    }
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  for_each = { for k, b in var.buckets : k => b if b.website != null }

  bucket                = aws_s3_bucket.bucket[each.key].id
  expected_bucket_owner = each.value.expected_bucket_owner

  dynamic "index_document" {
    for_each = each.value.website.index_document != null ? [each.value.website.index_document] : []

    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = each.value.website.error_document != null ? [each.value.website.error_document] : []

    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = each.value.website.redirect_host != null ? [each.value.website.redirect_host] : []

    content {
      host_name = redirect_all_requests_to.value
      protocol  = each.value.website.redirect_protocol
    }
  }

  dynamic "routing_rule" {
    for_each = each.value.website.routing_rules

    content {
      dynamic "condition" {
        for_each = [routing_rule.value.condition]

        content {
          http_error_code_returned_equals = condition.value.http_error_code_returned_equals
          key_prefix_equals               = condition.value.key_prefix_equals
        }
      }

      dynamic "redirect" {
        for_each = [routing_rule.value.redirect]

        content {
          host_name               = redirect.value.host_name
          http_redirect_code      = redirect.value.http_redirect_code
          protocol                = redirect.value.protocol
          replace_key_with        = redirect.value.replace_key_with
          replace_key_prefix_with = redirect.value.replace_key_prefix_with
        }
      }
    }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  for_each = { for k, b in var.buckets : k => b if b.logging != null }

  bucket                = aws_s3_bucket.bucket[each.key].id
  expected_bucket_owner = each.value.expected_bucket_owner
  target_bucket         = each.value.logging.target_bucket
  target_prefix         = each.value.logging.target_prefix
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  for_each = { for k, b in var.buckets : k => b if length(b.cors) > 0 }

  bucket = aws_s3_bucket.bucket[each.key].id

  dynamic "cors_rule" {
    for_each = each.value.cors

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = { for k, b in var.buckets : k => b if length(b.lifecycle_rules) > 0 }

  bucket = aws_s3_bucket.bucket[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.status
      prefix = rule.value.prefix

      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []

        content {
          object_size_greater_than = filter.value.object_size_greater_than
          object_size_less_than    = filter.value.object_size_less_than
          prefix                   = filter.value.prefix

          dynamic "and" {
            for_each = filter.value.and != null ? [filter.value.and] : []

            content {
              object_size_greater_than = and.value.object_size_greater_than
              object_size_less_than    = and.value.object_size_less_than
              prefix                   = and.value.prefix
              tags                     = and.value.tags
            }
          }

          dynamic "tag" {
            for_each = filter.value.tag != null ? [filter.value.tag] : []

            content {
              key   = tag.value.key
              value = tag.value.value
            }
          }
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []

        content {
          date                         = expiration.value.date
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          date          = transition.value.date
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions

        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "object_lock" {
  for_each = { for k, b in var.buckets : k => b if b.object_lock != null }

  bucket                = aws_s3_bucket.bucket[each.key].id
  expected_bucket_owner = each.value.expected_bucket_owner
  token                 = each.value.object_lock.token

  dynamic "rule" {
    for_each = each.value.object_lock.default_retention != null ? [1] : []

    content {
      default_retention {
        mode  = each.value.object_lock.default_retention.mode
        days  = each.value.object_lock.default_retention.days
        years = each.value.object_lock.default_retention.years
      }
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  for_each = { for k, b in var.buckets : k => b if b.replication != null }

  bucket = aws_s3_bucket.bucket[each.key].id
  role   = each.value.replication.role

  dynamic "rule" {
    for_each = each.value.replication.rules

    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = rule.value.priority

      dynamic "filter" {
        for_each = rule.value.filter_prefix != null ? [rule.value.filter_prefix] : []

        content {
          prefix = filter.value
        }
      }

      dynamic "destination" {
        for_each = [rule.value.destination]

        content {
          bucket        = destination.value.bucket
          storage_class = destination.value.storage_class
          account       = destination.value.account_id
        }
      }

      dynamic "delete_marker_replication" {
        for_each = rule.value.delete_marker_replication_status != null ? [rule.value.delete_marker_replication_status] : []

        content {
          status = delete_marker_replication.value
        }
      }

      dynamic "source_selection_criteria" {
        for_each = rule.value.source_sse_kms_status != null ? [rule.value.source_sse_kms_status] : []

        content {
          sse_kms_encrypted_objects {
            status = source_selection_criteria.value
          }
        }
      }
    }
  }
}

resource "aws_s3_bucket_notification" "notification" {
  for_each = { for k, b in var.buckets : k => b if length(b.notifications) > 0 }

  bucket = aws_s3_bucket.bucket[each.key].id

  dynamic "lambda_function" {
    for_each = [for n in each.value.notifications : n if n.type == "lambda"]

    content {
      lambda_function_arn = lambda_function.value.arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  dynamic "queue" {
    for_each = [for n in each.value.notifications : n if n.type == "queue"]

    content {
      queue_arn     = queue.value.arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "topic" {
    for_each = [for n in each.value.notifications : n if n.type == "sns"]

    content {
      topic_arn     = topic.value.arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}
