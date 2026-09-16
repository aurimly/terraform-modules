mock_provider "google" {}

run "triggers" {
  command = plan

  variables {
    triggers = {
      "pubsub-to-runner" = {
        name                    = "example-pubsub-to-runner"
        location                = "us-central1"
        service_account         = "projects/example-prj/serviceAccounts/example-trigger@example-prj.iam.gserviceaccount.com"
        pubsub_topic            = "projects/example-prj/topics/example-inbound"
        event_data_content_type = "application/json"
        labels                  = { env = "example" }
        matching_criteria = [
          { attribute = "type", value = "google.cloud.pubsub.topic.v1.messagePublished" }
        ]
        cloud_run_service = {
          service = "example-runner"
          region  = "us-central1"
          path    = "/events"
        }
        retry_policy = {
          max_attempts = 1
        }
      }
      "audit-to-workflow" = {
        name     = "example-audit-to-workflow"
        location = "us-central1"
        matching_criteria = [
          { attribute = "type", value = "google.cloud.audit.storage.buckets.v1.updated" },
          { attribute = "resourceName", value = "projects/_/buckets/example-bucket", operator = "match-path-pattern" }
        ]
        workflow = "projects/example-prj/locations/us-central1/workflows/example-wf"
      }
    }
  }
}

run "rejects_no_type_criterion" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name     = "example-bad"
        location = "us-central1"
        matching_criteria = [
          { attribute = "resourceName", value = "projects/_/buckets/example-bucket" }
        ]
        cloud_run_service = {
          service = "example-runner"
          region  = "us-central1"
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_two_destinations" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name     = "example-bad"
        location = "us-central1"
        matching_criteria = [
          { attribute = "type", value = "google.cloud.pubsub.topic.v1.messagePublished" }
        ]
        cloud_run_service = {
          service = "example-runner"
          region  = "us-central1"
        }
        http_endpoint = {
          uri = "https://example.test.local/hook"
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_retry_without_run_destination" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name     = "example-bad"
        location = "us-central1"
        matching_criteria = [
          { attribute = "type", value = "google.cloud.pubsub.topic.v1.messagePublished" }
        ]
        http_endpoint = {
          uri = "https://example.test.local/hook"
        }
        retry_policy = {
          max_attempts = 1
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_topic_without_messagepublished" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name         = "example-bad"
        location     = "us-central1"
        pubsub_topic = "projects/example-prj/topics/example-inbound"
        matching_criteria = [
          { attribute = "type", value = "google.cloud.storage.object.v1.finalized" }
        ]
        http_endpoint = {
          uri = "https://example.test.local/hook"
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_deletion_abandon_conflict" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name            = "example-bad"
        location        = "us-central1"
        deletion_policy = "KEEP"
        matching_criteria = [
          { attribute = "type", value = "google.cloud.pubsub.topic.v1.messagePublished" }
        ]
        cloud_run_service = {
          service = "example-runner"
          region  = "us-central1"
        }
      }
    }
  }

  expect_failures = [var.triggers]
}
