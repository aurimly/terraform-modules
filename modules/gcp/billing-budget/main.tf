resource "google_billing_budget" "budget" {
  for_each = var.budgets

  billing_account = each.value.billing_account
  display_name    = each.value.display_name
  ownership_scope = each.value.ownership_scope
  deletion_policy = each.value.deletion_policy

  dynamic "amount" {
    for_each = [each.value.amount]

    content {
      last_period_amount = amount.value.last_period_amount

      dynamic "specified_amount" {
        for_each = amount.value.specified_amount != null ? [amount.value.specified_amount] : []

        content {
          currency_code = specified_amount.value.currency_code
          units         = specified_amount.value.units
          nanos         = specified_amount.value.nanos
        }
      }
    }
  }

  dynamic "budget_filter" {
    for_each = each.value.budget_filter != null ? [each.value.budget_filter] : []

    content {
      projects               = budget_filter.value.projects
      resource_ancestors     = budget_filter.value.resource_ancestors
      credit_types_treatment = budget_filter.value.credit_types_treatment
      credit_types           = budget_filter.value.credit_types
      services               = budget_filter.value.services
      subaccounts            = budget_filter.value.subaccounts
      labels                 = budget_filter.value.labels
      calendar_period        = budget_filter.value.calendar_period

      dynamic "custom_period" {
        for_each = budget_filter.value.custom_period != null ? [budget_filter.value.custom_period] : []

        content {
          dynamic "start_date" {
            for_each = [budget_filter.value.custom_period.start_date]

            content {
              year  = start_date.value.year
              month = start_date.value.month
              day   = start_date.value.day
            }
          }

          dynamic "end_date" {
            for_each = budget_filter.value.custom_period.end_date != null ? [budget_filter.value.custom_period.end_date] : []

            content {
              year  = end_date.value.year
              month = end_date.value.month
              day   = end_date.value.day
            }
          }
        }
      }
    }
  }

  dynamic "threshold_rules" {
    for_each = each.value.threshold_rules

    content {
      threshold_percent = threshold_rules.value.threshold_percent
      spend_basis       = threshold_rules.value.spend_basis
    }
  }

  dynamic "all_updates_rule" {
    for_each = each.value.all_updates_rule != null ? [each.value.all_updates_rule] : []

    content {
      pubsub_topic                     = all_updates_rule.value.pubsub_topic
      schema_version                   = all_updates_rule.value.schema_version
      monitoring_notification_channels = all_updates_rule.value.monitoring_notification_channels
      disable_default_iam_recipients   = all_updates_rule.value.disable_default_iam_recipients
      enable_project_level_recipients  = all_updates_rule.value.enable_project_level_recipients
    }
  }
}
