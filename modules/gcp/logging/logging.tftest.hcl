mock_provider "google" {}

run "sinks" {
  command = plan

  variables {
    sinks = {
      "audit" = {
        name        = "example-audit-sink"
        destination = "storage.googleapis.com/example-audit-logs"
        filter      = "logName:\"cloudaudit.googleapis.com\""
        exclusions = [
          {
            name        = "ns.exclusion1"
            filter      = "severity<ERROR"
            description = "keep info"
          },
        ]
      }
      "metrics" = {
        name                   = "example-metrics-sink"
        destination            = "pubsub.googleapis.com/projects/example-prj/topics/example-logs"
        filter                 = "severity>=WARNING"
        unique_writer_identity = true
      }
      "camel" = {
        name                   = "nsexclusion1.example_2"
        destination            = "bigquery.googleapis.com/datasets/example_logs"
        filter                 = "resource.type=\"gke_cluster\""
        unique_writer_identity = true
        bigquery_options = {
          use_partitioned_tables = true
        }
      }
    }
  }
}

run "rejects_bad_destination" {
  command = plan

  variables {
    sinks = {
      "audit" = {
        name        = "example-audit-sink"
        destination = "https://example.com"
        filter      = "severity>=WARNING"
      }
    }
  }

  expect_failures = [var.sinks]
}

run "rejects_bad_bigquery_options" {
  command = plan

  variables {
    sinks = {
      "audit" = {
        name                   = "example-audit-sink"
        destination            = "bigquery.googleapis.com/datasets/example_logs"
        filter                 = "severity>=WARNING"
        unique_writer_identity = false
        bigquery_options = {
          use_partitioned_tables = true
        }
      }
    }
  }

  expect_failures = [var.sinks]
}

run "rejects_bad_exclusion_name" {
  command = plan

  variables {
    sinks = {
      "audit" = {
        name        = "example-audit-sink"
        destination = "storage.googleapis.com/example-audit-logs"
        filter      = "severity>=WARNING"
        exclusions = [
          {
            name   = "-bad"
            filter = "severity<ERROR"
          },
        ]
      }
    }
  }

  expect_failures = [var.sinks]
}
