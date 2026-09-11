resource "google_monitoring_dashboard" "dashboard" {
  for_each = var.dashboards

  dashboard_json = each.value.dashboard_json
  project        = each.value.project_id
}

resource "google_monitoring_alert_policy" "alert_policy" {
  for_each = var.alert_policies

  display_name          = each.value.display_name
  combiner              = each.value.combiner
  project               = each.value.project_id
  enabled               = each.value.enabled
  notification_channels = each.value.notification_channels
  user_labels           = each.value.user_labels

  dynamic "documentation" {
    for_each = each.value.documentation != null ? [each.value.documentation] : []

    content {
      content   = documentation.value.content
      mime_type = documentation.value.mime_type
      subject   = documentation.value.subject

      dynamic "links" {
        for_each = documentation.value.links

        content {
          display_name = links.value.display_name
          url          = links.value.url
        }
      }
    }
  }

  dynamic "alert_strategy" {
    for_each = each.value.alert_strategy != null ? [each.value.alert_strategy] : []

    content {
      auto_close = alert_strategy.value.auto_close

      dynamic "notification_rate_limit" {
        for_each = alert_strategy.value.notification_rate_limit != null ? [alert_strategy.value.notification_rate_limit] : []

        content {
          period = notification_rate_limit.value.period
        }
      }
    }
  }

  dynamic "conditions" {
    for_each = each.value.conditions

    content {
      display_name = conditions.value.display_name

      dynamic "condition_threshold" {
        for_each = conditions.value.condition_threshold != null ? [conditions.value.condition_threshold] : []

        content {
          filter                  = condition_threshold.value.filter
          duration                = condition_threshold.value.duration
          comparison              = condition_threshold.value.comparison
          threshold_value         = condition_threshold.value.threshold_value
          denominator_filter      = condition_threshold.value.denominator_filter
          evaluation_missing_data = condition_threshold.value.evaluation_missing_data

          dynamic "trigger" {
            for_each = condition_threshold.value.trigger != null ? [condition_threshold.value.trigger] : []

            content {
              count   = trigger.value.count
              percent = trigger.value.percent
            }
          }

          dynamic "aggregations" {
            for_each = condition_threshold.value.aggregations

            content {
              alignment_period     = aggregations.value.alignment_period
              per_series_aligner   = aggregations.value.per_series_aligner
              cross_series_reducer = aggregations.value.cross_series_reducer
              group_by_fields      = aggregations.value.group_by_fields
            }
          }

          dynamic "denominator_aggregations" {
            for_each = condition_threshold.value.denominator_aggregations

            content {
              alignment_period     = denominator_aggregations.value.alignment_period
              per_series_aligner   = denominator_aggregations.value.per_series_aligner
              cross_series_reducer = denominator_aggregations.value.cross_series_reducer
              group_by_fields      = denominator_aggregations.value.group_by_fields
            }
          }
        }
      }

      dynamic "condition_absent" {
        for_each = conditions.value.condition_absent != null ? [conditions.value.condition_absent] : []

        content {
          filter   = condition_absent.value.filter
          duration = condition_absent.value.duration

          dynamic "trigger" {
            for_each = condition_absent.value.trigger != null ? [condition_absent.value.trigger] : []

            content {
              count   = trigger.value.count
              percent = trigger.value.percent
            }
          }

          dynamic "aggregations" {
            for_each = condition_absent.value.aggregations

            content {
              alignment_period     = aggregations.value.alignment_period
              per_series_aligner   = aggregations.value.per_series_aligner
              cross_series_reducer = aggregations.value.cross_series_reducer
              group_by_fields      = aggregations.value.group_by_fields
            }
          }
        }
      }

      dynamic "condition_monitoring_query_language" {
        for_each = conditions.value.condition_monitoring_query_language != null ? [conditions.value.condition_monitoring_query_language] : []

        content {
          query                   = condition_monitoring_query_language.value.query
          duration                = condition_monitoring_query_language.value.duration
          evaluation_missing_data = condition_monitoring_query_language.value.evaluation_missing_data

          dynamic "trigger" {
            for_each = condition_monitoring_query_language.value.trigger != null ? [condition_monitoring_query_language.value.trigger] : []

            content {
              count   = trigger.value.count
              percent = trigger.value.percent
            }
          }
        }
      }

      dynamic "condition_prometheus_query_language" {
        for_each = conditions.value.condition_prometheus_query_language != null ? [conditions.value.condition_prometheus_query_language] : []

        content {
          query               = condition_prometheus_query_language.value.query
          duration            = condition_prometheus_query_language.value.duration
          evaluation_interval = condition_prometheus_query_language.value.evaluation_interval
        }
      }
    }
  }
}
