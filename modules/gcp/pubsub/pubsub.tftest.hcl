mock_provider "google" {}

run "topics" {
  command = plan

  variables {
    topics = {
      "events" = {
        name       = "example-events"
        project_id = "example-prj"
        schema_settings = {
          schema   = "projects/example-prj/schemas/example-schema"
          encoding = "JSON"
        }
        message_storage_policy = {
          allowed_persistence_regions = ["europe-west4"]
          enforce_in_transit          = true
        }
        role_bindings = {
          "publishers" = {
            role    = "roles/pubsub.publisher"
            members = ["serviceAccount:prod-ingest@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
      "notifications" = {
        name = "example-notifications"
        subscriptions = {
          "webhooks" = {
            name                 = "example-webhooks"
            ack_deadline_seconds = 30
            push_config = {
              push_endpoint = "https://example.net/hooks"
              oidc_token = {
                service_account_email = "sa-webhook-rt@example-prj.iam.gserviceaccount.com"
              }
            }
            retry_policy = {
              minimum_backoff = "10s"
              maximum_backoff = "300s"
            }
            dead_letter_policy = {
              dead_letter_topic     = "projects/example-prj/topics/example-dlq"
              max_delivery_attempts = 10
            }
            role_bindings = {
              "consumers" = {
                role    = "roles/pubsub.subscriber"
                members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
              }
            }
          }
          "load" = {
            name = "example-bq-load"
            bigquery_config = {
              table          = "example-prj.example_dataset.example_events"
              write_metadata = true
            }
          }
          "export" = {
            name              = "example-storage-export"
            expiration_policy = { ttl = "" }
            cloud_storage_config = {
              bucket       = "example-archive"
              max_duration = "60s"
              avro_config  = { use_topic_schema = true }
            }
          }
        }
      }
    }
  }
}

run "rejects_two_sink_configs" {
  command = plan

  variables {
    topics = {
      "events" = {
        name = "example-events"
        subscriptions = {
          "load" = {
            name = "example-bq-load"
            bigquery_config = {
              table = "example-prj.example_dataset.example_events"
            }
            cloud_storage_config = {
              bucket = "example-archive"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.topics]
}

run "rejects_expiration_policy_ttl" {
  command = plan

  variables {
    topics = {
      "events" = {
        name = "example-events"
        subscriptions = {
          "pull" = {
            name              = "example-pull"
            expiration_policy = { ttl = "10s" }
          }
        }
      }
    }
  }

  expect_failures = [var.topics]
}

run "rejects_bad_dead_letter_topic" {
  command = plan

  variables {
    topics = {
      "events" = {
        name = "example-events"
        subscriptions = {
          "pull" = {
            name = "example-pull"
            dead_letter_policy = {
              dead_letter_topic     = "example-dlq"
              max_delivery_attempts = 10
            }
          }
        }
      }
    }
  }

  expect_failures = [var.topics]
}

run "rejects_bad_bigquery_table" {
  command = plan

  variables {
    topics = {
      "events" = {
        name = "example-events"
        subscriptions = {
          "load" = {
            name = "example-bq-load"
            bigquery_config = {
              table = "projects/example-prj/datasets/example_dataset/tables/example_events"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.topics]
}
