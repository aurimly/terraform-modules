mock_provider "google" {}

run "jobs" {
  command = plan

  variables {
    jobs = {
      "wordcount" = {
        name              = "example-df-wordcount"
        template_gcs_path = "gs://example-bucket/templates/wordcount"
        temp_gcs_location = "gs://example-bucket/tmp"
        parameters = {
          inputFile = "gs://example-bucket/input.txt"
          output    = "gs://example-bucket/output"
        }
        max_workers      = 4
        on_delete        = "cancel"
        region           = "europe-west1"
        machine_type     = "n1-standard-2"
        ip_configuration = "WORKER_IP_PRIVATE"
      }
      "streaming" = {
        name                    = "example-df-streaming"
        template_gcs_path       = "gs://example-bucket/templates/streaming"
        temp_gcs_location       = "gs://example-bucket/tmp"
        enable_streaming_engine = true
        service_account_email   = "df-worker@example-prj.iam.gserviceaccount.com"
        additional_experiments  = ["enable_stackdriver_agent_metrics"]
        parameters = {
          inputSubscription = "projects/example-prj/subscriptions/example-sub"
        }
      }
    }
  }
}

run "rejects_invalid_job_name" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name              = "Example_Job"
        template_gcs_path = "gs://example-bucket/templates/wordcount"
        temp_gcs_location = "gs://example-bucket/tmp"
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_bad_on_delete" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name              = "example-df-bad"
        template_gcs_path = "gs://example-bucket/templates/wordcount"
        temp_gcs_location = "gs://example-bucket/tmp"
        on_delete         = "terminate"
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_bad_ip_configuration" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name              = "example-df-bad"
        template_gcs_path = "gs://example-bucket/templates/wordcount"
        temp_gcs_location = "gs://example-bucket/tmp"
        ip_configuration  = "WORKER_IP_NONE"
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_non_gs_template_path" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name              = "example-df-bad"
        template_gcs_path = "https://example-bucket.storage.googleapis.com/templates/wordcount"
        temp_gcs_location = "gs://example-bucket/tmp"
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_non_gs_temp_location" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name              = "example-df-bad"
        template_gcs_path = "gs://example-bucket/templates/wordcount"
        temp_gcs_location = "example-bucket/tmp"
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_bad_deletion_policy" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name              = "example-df-bad"
        template_gcs_path = "gs://example-bucket/templates/wordcount"
        temp_gcs_location = "gs://example-bucket/tmp"
        deletion_policy   = "KEEP"
      }
    }
  }

  expect_failures = [var.jobs]
}
