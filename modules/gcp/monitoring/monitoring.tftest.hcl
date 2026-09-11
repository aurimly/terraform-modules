mock_provider "google" {}

run "dashboards_and_alerts" {
  command = plan

  variables {
    dashboards = {
      "main" = {
        dashboard_json = jsonencode({
          displayName = "Example dashboards"
          gridLayout = {
            widgets = [
              {
                title = "Cloud Run request count"
                xyChart = {
                  dataSets = [{
                    timeSeriesQuery = {
                      timeSeriesFilter = {
                        filter = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\""
                      }
                    }
                  }]
                }
              },
            ]
          }
        })
      }
    }
    alert_policies = {
      "api-latency" = {
        display_name = "example-api p99 latency"
        combiner     = "OR"
        conditions = [
          {
            display_name = "p99 latency > 500ms"
            condition_threshold = {
              filter     = "metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\""
              duration   = "60s"
              comparison = "COMPARISON_GT"
              aggregations = [
                {
                  alignment_period   = "60s"
                  per_series_aligner = "ALIGN_PERCENTILE_99"
                },
              ]
            }
          }
        ]
      }
    }
  }
}

run "rejects_invalid_dashboard_json" {
  command = plan

  variables {
    dashboards = {
      "main" = {
        dashboard_json = "not json{"
      }
    }
    alert_policies = {}
  }

  expect_failures = [var.dashboards]
}

run "rejects_missing_display_name" {
  command = plan

  variables {
    dashboards = {
      "main" = {
        dashboard_json = jsonencode({ gridLayout = {} })
      }
    }
    alert_policies = {}
  }

  expect_failures = [var.dashboards]
}

run "rejects_no_conditions" {
  command = plan

  variables {
    dashboards = {}
    alert_policies = {
      "latency" = {
        display_name = "example-api latency"
        combiner     = "OR"
        conditions   = []
      }
    }
  }

  expect_failures = [var.alert_policies]
}

run "rejects_two_condition_types" {
  command = plan

  variables {
    dashboards = {}
    alert_policies = {
      "latency" = {
        display_name = "example-api latency"
        combiner     = "OR"
        conditions = [
          {
            display_name = "latency"
            condition_threshold = {
              filter     = "metric.type=\"run.googleapis.com/request_latencies\""
              duration   = "60s"
              comparison = "COMPARISON_GT"
            }
            condition_absent = {
              filter   = "metric.type=\"run.googleapis.com/request_latencies\""
              duration = "60s"
            }
          }
        ]
      }
    }
  }

  expect_failures = [var.alert_policies]
}

run "rejects_bad_comparison" {
  command = plan

  variables {
    dashboards = {}
    alert_policies = {
      "latency" = {
        display_name = "example-api latency"
        combiner     = "OR"
        conditions = [
          {
            display_name = "latency"
            condition_threshold = {
              filter     = "metric.type=\"run.googleapis.com/request_latencies\""
              duration   = "60s"
              comparison = "GT"
            }
          }
        ]
      }
    }
  }

  expect_failures = [var.alert_policies]
}
