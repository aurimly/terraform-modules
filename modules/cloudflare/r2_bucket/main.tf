terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_r2_bucket" "bucket" {
  for_each = var.buckets

  account_id    = coalesce(each.value.account_id, var.account_id)
  name          = each.value.name
  location      = each.value.location
  jurisdiction  = each.value.jurisdiction
  storage_class = each.value.storage_class

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "bucket \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }
  }
}

locals {
  custom_domains = {
    for d in flatten([
      for key, bucket in var.buckets : [
        for domain in bucket.custom_domains : {
          bucket_key   = key
          account_id   = bucket.account_id
          bucket_name  = bucket.name
          jurisdiction = bucket.jurisdiction
          domain       = domain
        }
      ]
    ]) : "${d.bucket_key}/${d.domain.domain}" => d
  }
}

resource "cloudflare_r2_bucket_lifecycle" "lifecycle" {
  for_each = { for key, bucket in var.buckets : key => bucket if length(bucket.lifecycle_rules) > 0 }

  account_id   = coalesce(each.value.account_id, var.account_id)
  bucket_name  = each.value.name
  jurisdiction = each.value.jurisdiction
  rules = [for rule in each.value.lifecycle_rules : {
    id                                 = rule.id
    enabled                            = rule.enabled
    conditions                         = rule.conditions
    abort_multipart_uploads_transition = rule.abort_multipart_uploads_transition
    delete_objects_transition          = rule.delete_objects_transition
    storage_class_transitions          = rule.storage_class_transitions
  }]

  depends_on = [cloudflare_r2_bucket.bucket]
}

resource "cloudflare_r2_bucket_cors" "cors" {
  for_each = { for key, bucket in var.buckets : key => bucket if length(bucket.cors_rules) > 0 }

  account_id   = coalesce(each.value.account_id, var.account_id)
  bucket_name  = each.value.name
  jurisdiction = each.value.jurisdiction
  rules = [for rule in each.value.cors_rules : {
    id              = rule.id
    allowed         = rule.allowed
    expose_headers  = rule.expose_headers
    max_age_seconds = rule.max_age_seconds
  }]

  depends_on = [cloudflare_r2_bucket.bucket]
}

resource "cloudflare_r2_custom_domain" "domain" {
  for_each = local.custom_domains

  account_id   = coalesce(each.value.account_id, var.account_id)
  bucket_name  = each.value.bucket_name
  jurisdiction = each.value.jurisdiction
  domain       = each.value.domain.domain
  zone_id      = each.value.domain.zone_id
  enabled      = each.value.domain.enabled
  min_tls      = each.value.domain.min_tls
  ciphers      = each.value.domain.ciphers

  depends_on = [cloudflare_r2_bucket.bucket]
}

resource "cloudflare_r2_managed_domain" "managed" {
  for_each = { for key, bucket in var.buckets : key => bucket if bucket.managed_domain != null }

  account_id   = coalesce(each.value.account_id, var.account_id)
  bucket_name  = each.value.name
  jurisdiction = each.value.jurisdiction
  enabled      = each.value.managed_domain

  depends_on = [cloudflare_r2_bucket.bucket]
}
