locals {
  metric_alert_criteria = merge([
    for alert_key, alert in var.metric_alerts : {
      for criterion_key, criterion in coalesce(alert.criteria, {}) : "${alert_key}.${criterion_key}" => merge(criterion, {
        dimensions = { for dimension_key, dimension in try(criterion.dimensions, {}) : dimension_key => dimension }
      })
    }
  ]...)

  metric_alert_actions = merge([
    for alert_key, alert in var.metric_alerts : {
      for action_key, action in alert.actions : "${alert_key}.${action_key}" => action
    }
  ]...)

  activity_log_alert_actions = merge([
    for alert_key, alert in var.activity_log_alerts : {
      for action_key, action in alert.actions : "${alert_key}.${action_key}" => action
    }
  ]...)

  scheduled_query_criteria = merge([
    for rule_key, rule in var.scheduled_query_rules : {
      for criterion_key, criterion in coalesce(rule.criteria, {}) : "${rule_key}.${criterion_key}" => merge(criterion, {
        dimension = { for dimension_key, dimension in try(criterion.dimension, {}) : dimension_key => dimension }
      })
    }
  ]...)
}

resource "azurerm_monitor_action_group" "action_group" {
  for_each = var.action_groups

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  short_name          = each.value.short_name
  location            = each.value.location
  enabled             = each.value.enabled
  tags                = each.value.tags

  dynamic "arm_role_receiver" {
    for_each = each.value.arm_role_receivers

    content {
      name                    = arm_role_receiver.value.name
      role_id                 = arm_role_receiver.value.role_id
      use_common_alert_schema = arm_role_receiver.value.use_common_alert_schema
    }
  }

  dynamic "email_receiver" {
    for_each = each.value.email_receivers

    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  dynamic "itsm_receiver" {
    for_each = each.value.itsm_receivers

    content {
      name                 = itsm_receiver.value.name
      workspace_id         = itsm_receiver.value.workspace_id
      connection_id        = itsm_receiver.value.connection_id
      ticket_configuration = itsm_receiver.value.ticket_configuration
      region               = itsm_receiver.value.region
    }
  }

  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers

    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema

      dynamic "aad_auth" {
        for_each = webhook_receiver.value.aad_auth != null ? [webhook_receiver.value.aad_auth] : []

        content {
          object_id      = aad_auth.value.object_id
          identifier_uri = aad_auth.value.identifier_uri
          tenant_id      = aad_auth.value.tenant_id
        }
      }
    }
  }

  dynamic "automation_runbook_receiver" {
    for_each = each.value.automation_runbook_receivers

    content {
      name                    = automation_runbook_receiver.value.name
      automation_account_id   = automation_runbook_receiver.value.automation_account_id
      runbook_name            = automation_runbook_receiver.value.runbook_name
      webhook_resource_id     = automation_runbook_receiver.value.webhook_resource_id
      is_global_runbook       = automation_runbook_receiver.value.is_global_runbook
      service_uri             = automation_runbook_receiver.value.service_uri
      use_common_alert_schema = automation_runbook_receiver.value.use_common_alert_schema
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = each.value.azure_app_push_receivers

    content {
      name          = azure_app_push_receiver.value.name
      email_address = azure_app_push_receiver.value.email_address
    }
  }

  dynamic "azure_function_receiver" {
    for_each = each.value.azure_function_receivers

    content {
      name                     = azure_function_receiver.value.name
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name            = azure_function_receiver.value.function_name
      http_trigger_url         = azure_function_receiver.value.http_trigger_url
      use_common_alert_schema  = azure_function_receiver.value.use_common_alert_schema
    }
  }

  dynamic "event_hub_receiver" {
    for_each = each.value.event_hub_receivers

    content {
      name                    = event_hub_receiver.value.name
      event_hub_name          = event_hub_receiver.value.event_hub_name
      event_hub_namespace     = event_hub_receiver.value.event_hub_namespace
      subscription_id         = event_hub_receiver.value.subscription_id
      tenant_id               = event_hub_receiver.value.tenant_id
      use_common_alert_schema = event_hub_receiver.value.use_common_alert_schema
    }
  }

  dynamic "logic_app_receiver" {
    for_each = each.value.logic_app_receivers

    content {
      name                    = logic_app_receiver.value.name
      resource_id             = logic_app_receiver.value.resource_id
      callback_url            = logic_app_receiver.value.callback_url
      use_common_alert_schema = logic_app_receiver.value.use_common_alert_schema
    }
  }

  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers

    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "voice_receiver" {
    for_each = each.value.voice_receivers

    content {
      name         = voice_receiver.value.name
      country_code = voice_receiver.value.country_code
      phone_number = voice_receiver.value.phone_number
    }
  }
}

resource "azurerm_monitor_metric_alert" "metric_alert" {
  for_each = var.metric_alerts

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  window_size         = each.value.window_size
  frequency           = each.value.frequency
  enabled             = each.value.enabled
  auto_mitigate       = each.value.auto_mitigate
  tags                = each.value.tags

  target_resource_type     = each.value.target_resource_type
  target_resource_location = each.value.target_resource_location

  dynamic "criteria" {
    for_each = { for key, criterion in local.metric_alert_criteria : key => criterion if split(".", key)[0] == each.key }

    content {
      metric_namespace = criteria.value.metric_namespace
      metric_name      = criteria.value.metric_name
      aggregation      = criteria.value.aggregation
      operator         = criteria.value.operator
      threshold        = criteria.value.threshold

      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = criteria.value.dimensions

        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criteria != null ? [each.value.dynamic_criteria] : []

    content {
      metric_namespace  = dynamic_criteria.value.metric_namespace
      metric_name       = dynamic_criteria.value.metric_name
      aggregation       = dynamic_criteria.value.aggregation
      operator          = dynamic_criteria.value.operator
      alert_sensitivity = dynamic_criteria.value.alert_sensitivity

      evaluation_total_count   = dynamic_criteria.value.evaluation_total_count
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count
      ignore_data_before       = dynamic_criteria.value.ignore_data_before

      skip_metric_validation = dynamic_criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = coalesce(dynamic_criteria.value.dimensions, {})

        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "application_insights_web_test_location_availability_criteria" {
    for_each = each.value.web_test_criteria != null ? [each.value.web_test_criteria] : []

    content {
      web_test_id           = application_insights_web_test_location_availability_criteria.value.web_test_id
      component_id          = application_insights_web_test_location_availability_criteria.value.component_id
      failed_location_count = application_insights_web_test_location_availability_criteria.value.failed_location_count
    }
  }

  dynamic "action" {
    for_each = { for key, action in local.metric_alert_actions : key => action if split(".", key)[0] == each.key }

    content {
      action_group_id    = action.value.action_group_id
      webhook_properties = action.value.webhook_properties
    }
  }
}

resource "azurerm_monitor_activity_log_alert" "activity_log_alert" {
  for_each = var.activity_log_alerts

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  scopes              = each.value.scopes
  description         = each.value.description
  enabled             = each.value.enabled
  tags                = each.value.tags

  criteria {
    category       = each.value.criteria.category
    caller         = each.value.criteria.caller
    operation_name = each.value.criteria.operation_name

    resource_providers = each.value.criteria.resource_providers
    resource_types     = each.value.criteria.resource_types
    resource_groups    = each.value.criteria.resource_groups
    resource_ids       = each.value.criteria.resource_ids
    statuses           = each.value.criteria.statuses
    sub_statuses       = each.value.criteria.sub_statuses

    recommendation_type     = each.value.criteria.recommendation_type
    recommendation_category = each.value.criteria.recommendation_category
    recommendation_impact   = each.value.criteria.recommendation_impact

    dynamic "resource_health" {
      for_each = each.value.criteria.resource_health != null ? [each.value.criteria.resource_health] : []

      content {
        current  = each.value.criteria.resource_health.current
        previous = each.value.criteria.resource_health.previous
        reason   = each.value.criteria.resource_health.reason
      }
    }

    dynamic "service_health" {
      for_each = each.value.criteria.service_health != null ? [each.value.criteria.service_health] : []

      content {
        events    = each.value.criteria.service_health.events
        locations = each.value.criteria.service_health.locations
        services  = each.value.criteria.service_health.services
      }
    }
  }

  dynamic "action" {
    for_each = { for key, action in local.activity_log_alert_actions : key => action if split(".", key)[0] == each.key }

    content {
      action_group_id    = action.value.action_group_id
      webhook_properties = action.value.webhook_properties
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "scheduled_query_rule" {
  for_each = var.scheduled_query_rules

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  scopes              = each.value.scopes
  description         = each.value.description
  display_name        = each.value.display_name
  enabled             = each.value.enabled
  severity            = each.value.severity

  evaluation_frequency              = each.value.evaluation_frequency
  window_duration                   = each.value.window_duration
  mute_actions_after_alert_duration = each.value.mute_actions_after_alert_duration
  query_time_range_override         = each.value.query_time_range_override

  auto_mitigation_enabled          = each.value.auto_mitigation_enabled
  skip_query_validation            = each.value.skip_query_validation
  workspace_alerts_storage_enabled = each.value.workspace_alerts_storage_enabled
  target_resource_types            = each.value.target_resource_types
  tags                             = each.value.tags

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "action" {
    for_each = each.value.action != null ? [each.value.action] : []

    content {
      action_groups     = action.value.action_groups
      custom_properties = action.value.custom_properties
      email_subject     = action.value.email_subject
    }
  }

  dynamic "criteria" {
    for_each = { for key, criterion in local.scheduled_query_criteria : key => criterion if split(".", key)[0] == each.key }

    content {
      query                   = criteria.value.query
      operator                = criteria.value.operator
      threshold               = criteria.value.threshold
      time_aggregation_method = criteria.value.time_aggregation_method

      metric_measure_column = criteria.value.metric_measure_column
      resource_id_column    = criteria.value.resource_id_column

      dynamic "dimension" {
        for_each = criteria.value.dimension

        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }

      dynamic "failing_periods" {
        for_each = criteria.value.failing_periods != null ? [criteria.value.failing_periods] : []

        content {
          minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods_to_trigger_alert
          number_of_evaluation_periods             = failing_periods.value.number_of_evaluation_periods
        }
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  for_each = var.diagnostic_settings

  name               = each.value.name
  target_resource_id = each.value.target_resource_id

  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  eventhub_name                  = each.value.eventhub_name
  partner_solution_id            = each.value.partner_solution_id

  dynamic "enabled_log" {
    for_each = each.value.logs

    content {
      category       = enabled_log.value.category
      category_group = enabled_log.value.category_group
    }
  }

  dynamic "enabled_metric" {
    for_each = each.value.metric_categories

    content {
      category = enabled_metric.value
    }
  }
}
