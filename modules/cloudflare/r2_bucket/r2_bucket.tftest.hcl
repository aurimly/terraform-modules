mock_provider "cloudflare" {
  mock_resource "cloudflare_r2_managed_domain" {
    defaults = {
      domain    = "pub-example-assets.r2.dev"
      bucket_id = "example-bucket-id"
    }
  }
  mock_resource "cloudflare_r2_custom_domain" {
    defaults = {
      status = {
        ownership = "owned"
        ssl       = "active"
      }
      zone_name = "example.com"
    }
  }
}

run "full_bucket_options" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    buckets = {
      "assets-eu" = {
        name         = "example-assets"
        location     = "eeur"
        jurisdiction = "eu"
        lifecycle_rules = [
          {
            id         = "abort-stale-uploads"
            enabled    = true
            conditions = { prefix = "" }
            abort_multipart_uploads_transition = {
              condition = { type = "Age", max_age = 86400 }
            }
          },
          {
            id         = "expire-logs"
            conditions = { prefix = "logs/" }
            delete_objects_transition = {
              condition = { type = "Age", max_age = 2592000 }
            }
          },
          {
            id         = "transition-cold"
            conditions = { prefix = "cold/" }
            storage_class_transitions = [
              { condition = { type = "Date", date = "2027-01-01T00:00:00Z" }, storage_class = "InfrequentAccess" },
            ]
          },
        ]
        cors_rules = [
          {
            id = "browser"
            allowed = {
              methods = ["GET", "HEAD"]
              origins = ["https://www.example.com"]
              headers = ["*"]
            }
            expose_headers  = ["ETag"]
            max_age_seconds = 3600
          },
        ]
        custom_domains = [
          { domain = "assets.example.com", zone_id = "36ca64a6d92827b8a6b90be344bb1bfd" },
          { domain = "cdn.example.com", zone_id = "36ca64a6d92827b8a6b90be344bb1bfd", enabled = true, min_tls = "1.2", ciphers = ["ECDHE_RSA_AES_128_GCM_SHA256"] },
        ]
        managed_domain = true
      }
      "plain" = {
        name = "example-plain"
      }
      "no-public" = {
        name           = "example-no-public"
        managed_domain = false
      }
    }
  }

  assert {
    condition     = output.bucket_names["assets-eu"] == "example-assets"
    error_message = "bucket name keyed by map key"
  }

  assert {
    condition     = output.bucket_r2_dev_domains["assets-eu"] == "pub-example-assets.r2.dev"
    error_message = "r2.dev domain output for the managed bucket"
  }

  assert {
    condition     = output.custom_domain_statuses["assets-eu/assets.example.com"].ssl == "active"
    error_message = "custom domain status keyed by composite key"
  }
}

run "rejects_age_with_date" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    buckets = {
      "bad" = {
        name = "example-bad"
        lifecycle_rules = [
          {
            id         = "bad"
            conditions = { prefix = "" }
            delete_objects_transition = {
              condition = { type = "Age", max_age = 100, date = "2027-01-01T00:00:00Z" }
            }
          },
        ]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_date_with_max_age" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    buckets = {
      "bad" = {
        name = "example-bad"
        lifecycle_rules = [
          {
            id         = "bad"
            conditions = { prefix = "" }
            delete_objects_transition = {
              condition = { type = "Date", date = "2027-01-01T00:00:00Z", max_age = 100 }
            }
          },
        ]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_storage_transition_with_both" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    buckets = {
      "bad" = {
        name = "example-bad"
        lifecycle_rules = [
          {
            id         = "bad"
            conditions = { prefix = "" }
            storage_class_transitions = [
              { condition = { type = "Date", date = "2027-01-01T00:00:00Z", max_age = 100 }, storage_class = "InfrequentAccess" },
            ]
          },
        ]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_bad_storage_class" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    buckets = {
      "bad" = {
        name = "example-bad"
        lifecycle_rules = [
          {
            id         = "bad"
            conditions = { prefix = "" }
            storage_class_transitions = [
              { condition = { type = "Age", max_age = 100 }, storage_class = "Archive" },
            ]
          },
        ]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_non_age_abort" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    buckets = {
      "bad" = {
        name = "example-bad"
        lifecycle_rules = [
          {
            id         = "bad"
            conditions = { prefix = "" }
            abort_multipart_uploads_transition = {
              condition = { type = "Days", max_age = 86400 }
            }
          },
        ]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_bad_min_tls" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    buckets = {
      "bad" = {
        name = "example-bad"
        custom_domains = [
          { domain = "bad.example.com", zone_id = "36ca64a6d92827b8a6b90be344bb1bfd", min_tls = "0.9" },
        ]
      }
    }
  }

  expect_failures = [var.buckets]
}
