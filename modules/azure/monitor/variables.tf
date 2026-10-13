variable "action_groups" {
  description = "Map of Azure Monitor action groups keyed by an arbitrary identifier. Each entry creates one azurerm_monitor_action_group; the nested receiver maps flatten into the group's per-type receiver blocks."
  type = map(object({
    name                = string
    resource_group_name = string
    short_name          = string
    location            = optional(string)
    enabled             = optional(bool, true)

    arm_role_receivers = optional(map(object({
      name                    = string
      role_id                 = string
      use_common_alert_schema = optional(bool)
    })), {})

    email_receivers = optional(map(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool)
    })), {})

    itsm_receivers = optional(map(object({
      name                 = string
      workspace_id         = string
      connection_id        = string
      ticket_configuration = string
      region               = string
    })), {})

    webhook_receivers = optional(map(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool)

      aad_auth = optional(object({
        object_id      = string
        identifier_uri = optional(string)
        tenant_id      = optional(string)
      }))
    })), {})

    automation_runbook_receivers = optional(map(object({
      name                    = string
      automation_account_id   = string
      runbook_name            = string
      webhook_resource_id     = string
      is_global_runbook       = bool
      service_uri             = string
      use_common_alert_schema = optional(bool)
    })), {})

    azure_app_push_receivers = optional(map(object({
      name          = string
      email_address = string
    })), {})

    azure_function_receivers = optional(map(object({
      name                     = string
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
      use_common_alert_schema  = optional(bool)
    })), {})

    event_hub_receivers = optional(map(object({
      name                    = string
      event_hub_name          = string
      event_hub_namespace     = string
      subscription_id         = optional(string)
      tenant_id               = optional(string)
      use_common_alert_schema = optional(bool)
    })), {})

    logic_app_receivers = optional(map(object({
      name                    = string
      resource_id             = string
      callback_url            = string
      use_common_alert_schema = optional(bool)
    })), {})

    sms_receivers = optional(map(object({
      name         = string
      country_code = string
      phone_number = string
    })), {})

    voice_receivers = optional(map(object({
      name         = string
      country_code = string
      phone_number = string
    })), {})

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for group in var.action_groups : length(group.short_name) <= 12
    ])
    error_message = "short_name must be at most 12 characters — the Azure API limit; the name is what receivers and alert rules see."
  }

  validation {
    condition = alltrue(concat(
      [for group_key in keys(var.action_groups) : !can(regex("\\.", group_key))],
      flatten([
        for group in var.action_groups : concat(
          [for key in keys(group.arm_role_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.email_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.itsm_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.webhook_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.automation_runbook_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.azure_app_push_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.azure_function_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.event_hub_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.logic_app_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.sms_receivers) : !can(regex("\\.", key))],
          [for key in keys(group.voice_receivers) : !can(regex("\\.", key))]
        )
      ])
    ))
    error_message = "map keys of action_groups and its nested receiver maps must not contain \".\" — keys are composed into identifiers of the form \"<group_key>.<key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      length(distinct([for receiver in concat(
        values(group.email_receivers),
        values(group.arm_role_receivers),
        values(group.webhook_receivers),
        values(group.itsm_receivers),
        values(group.automation_runbook_receivers),
        values(group.azure_app_push_receivers),
        values(group.azure_function_receivers),
        values(group.event_hub_receivers),
        values(group.logic_app_receivers),
        values(group.sms_receivers),
        values(group.voice_receivers)
        ) : lower(receiver.name)])) == length(concat(
        values(group.email_receivers),
        values(group.arm_role_receivers),
        values(group.webhook_receivers),
        values(group.itsm_receivers),
        values(group.automation_runbook_receivers),
        values(group.azure_app_push_receivers),
        values(group.azure_function_receivers),
        values(group.event_hub_receivers),
        values(group.logic_app_receivers),
        values(group.sms_receivers),
        values(group.voice_receivers)
      ))
    ])
    error_message = "receiver names must be unique case-insensitively across ALL receiver types within an action group — the Azure API rejects duplicate names across types (e.g. an email receiver and a webhook receiver sharing one name) at apply time."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for itsm in group.itsm_receivers :
        can(jsondecode(itsm.ticket_configuration))
        && can(jsondecode(itsm.ticket_configuration)["PayloadRevision"])
        && can(jsondecode(itsm.ticket_configuration)["WorkItemType"])
      ])
    ])
    error_message = "itsm ticket_configuration must be valid JSON containing the PayloadRevision and WorkItemType keys — an empty object {} or JSON without the required keys is rejected by the Azure API when the action group is saved."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      length(group.tags) <= 50 && alltrue([for tag_key, tag_value in group.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "metric_alerts" {
  description = "Map of Azure Monitor metric alerts keyed by an arbitrary identifier. Each entry creates one azurerm_monitor_metric_alert; static criteria, dynamic criteria and action blocks flatten from the nested maps below."
  type = map(object({
    name                = string
    resource_group_name = string
    scopes              = list(string)
    description         = optional(string)
    severity            = optional(number)
    window_size         = optional(string)
    frequency           = optional(string)
    enabled             = optional(bool, true)
    auto_mitigate       = optional(bool, true)
    tags                = optional(map(string), {})

    target_resource_type     = optional(string)
    target_resource_location = optional(string)

    criteria = optional(map(object({
      metric_namespace       = string
      metric_name            = string
      aggregation            = string
      operator               = string
      threshold              = number
      skip_metric_validation = optional(bool)

      dimensions = optional(map(object({
        name     = string
        operator = string
        values   = list(string)
      })))
    })), {})

    dynamic_criteria = optional(object({
      metric_namespace         = string
      metric_name              = string
      aggregation              = string
      operator                 = string
      alert_sensitivity        = string
      evaluation_total_count   = optional(number)
      evaluation_failure_count = optional(number)
      ignore_data_before       = optional(string)
      skip_metric_validation   = optional(bool)

      dimensions = optional(map(object({
        name     = string
        operator = string
        values   = list(string)
      })))
    }))

    web_test_criteria = optional(object({
      web_test_id           = string
      component_id          = string
      failed_location_count = number
    }))

    actions = optional(map(object({
      action_group_id    = string
      webhook_properties = optional(map(string))
    })), {})
  }))

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      (
        (length(alert.criteria) > 0 ? 1 : 0)
        + (alert.dynamic_criteria != null ? 1 : 0)
        + (alert.web_test_criteria != null ? 1 : 0)
      ) == 1
    ])
    error_message = "each metric alert needs exactly one of static criteria, dynamic_criteria or web_test_criteria — the Azure API accepts only one criteria flavor per alert."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alert.severity == null || (alert.severity >= 0 && alert.severity <= 4)
    ])
    error_message = "severity must be between 0 (critical) and 4 (verbose) — Azure rejects anything else."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alert.window_size == null || contains(["PT1M", "PT5M", "PT15M", "PT30M", "PT1H", "PT6H", "PT12H", "P1D"], alert.window_size)
    ])
    error_message = "window_size must be one of PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H or P1D — the documented ISO-8601 evaluation window durations."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alert.frequency == null || contains(["PT1M", "PT5M", "PT15M", "PT30M", "PT1H"], alert.frequency)
    ])
    error_message = "frequency must be one of PT1M, PT5M, PT15M, PT30M or PT1H — the documented ISO-8601 evaluation frequencies."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alert.window_size == null || alert.frequency == null || (
        lookup({ PT1M = 1, PT5M = 5, PT15M = 15, PT30M = 30, PT1H = 60, PT6H = 360, PT12H = 720, P1D = 1440 }, alert.window_size)
        > lookup({ PT1M = 1, PT5M = 5, PT15M = 15, PT30M = 30, PT1H = 60 }, alert.frequency)
      )
    ])
    error_message = "window_size must be strictly greater than frequency — e.g. a PT1M window on a PT5M frequency is rejected by the API."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      !(
        length(alert.scopes) > 1
        || anytrue([
          for scope in alert.scopes :
          can(regex("^/?subscriptions/[^/]+/?$", scope)) || can(regex("^/?subscriptions/[^/]+/resourceGroups/[^/]+/?$", scope))
        ])
      ) || (alert.target_resource_type != null && alert.target_resource_location != null)
    ])
    error_message = "target_resource_type and target_resource_location are required when the scopes are a subscription, a resource group or multiple scopes — the API only accepts multi/RG/subscription scoping with an explicit target resource type."
  }

  validation {
    condition = alltrue(flatten([
      for alert in var.metric_alerts : [
        for criterion in alert.criteria :
        contains(["Equals", "GreaterThan", "GreaterThanOrEqual", "LessThan", "LessThanOrEqual"], criterion.operator)
        && contains(["Average", "Minimum", "Maximum", "Total", "Count"], criterion.aggregation)
        && alltrue([for dimension in coalesce(criterion.dimensions, {}) : contains(["Include", "Exclude", "StartsWith"], dimension.operator)])
      ]
    ]))
    error_message = "static criteria operators must be one of Equals, GreaterThan, GreaterThanOrEqual, LessThan or LessThanOrEqual; aggregation one of Average, Minimum, Maximum, Total or Count; dimension operators one of Include, Exclude or StartsWith."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alert.dynamic_criteria == null || (
        contains(["GreaterThan", "LessThan", "GreaterOrLessThan"], alert.dynamic_criteria.operator)
        && contains(["Average", "Minimum", "Maximum", "Total", "Count"], alert.dynamic_criteria.aggregation)
        && contains(["Low", "Medium", "High"], alert.dynamic_criteria.alert_sensitivity)
        && (alert.dynamic_criteria.evaluation_total_count == null || (alert.dynamic_criteria.evaluation_total_count >= 1 && alert.dynamic_criteria.evaluation_total_count <= 10))
        && (alert.dynamic_criteria.evaluation_failure_count == null || (alert.dynamic_criteria.evaluation_failure_count >= 1 && alert.dynamic_criteria.evaluation_failure_count <= 10))
        && alltrue([for dimension in coalesce(alert.dynamic_criteria.dimensions, {}) : contains(["Include", "Exclude", "StartsWith"], dimension.operator)])
      )
    ])
    error_message = "dynamic_criteria operators must be one of GreaterThan, LessThan or GreaterOrLessThan; aggregation one of Average, Minimum, Maximum, Total or Count; alert_sensitivity one of Low, Medium or High; evaluation counts between 1 and 10; dimension operators one of Include, Exclude or StartsWith."
  }

  validation {
    condition = alltrue(concat(
      [for key in keys(var.metric_alerts) : !can(regex("\\.", key))],
      flatten([
        for alert in var.metric_alerts : concat(
          [
            for criterion_key, criterion in alert.criteria :
            !can(regex("\\.", criterion_key))
            && alltrue([for dimension_key in keys(coalesce(criterion.dimensions, {})) : !can(regex("\\.", dimension_key))])
          ],
          [for action_key in keys(alert.actions) : !can(regex("\\.", action_key))]
        )
      ])
    ))
    error_message = "map keys of metric_alerts and its nested criteria, dimensions and actions maps must not contain \".\" — criteria and action keys are composed into identifiers of the form \"<alert_key>.<key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      length(alert.tags) <= 50 && alltrue([for tag_key, tag_value in alert.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "activity_log_alerts" {
  description = "Map of Azure Monitor activity log alerts keyed by an arbitrary identifier. Each entry creates one azurerm_monitor_activity_log_alert with a single criteria object; the recommendation fields and the resource-health/service-health sub-objects only apply to their categories."
  type = map(object({
    name                = string
    resource_group_name = string
    scopes              = list(string)
    location            = optional(string, "global")
    description         = optional(string)
    enabled             = optional(bool, true)
    tags                = optional(map(string), {})

    criteria = object({
      category       = string
      caller         = optional(string)
      operation_name = optional(string)

      resource_providers = optional(list(string))
      resource_types     = optional(list(string))
      resource_groups    = optional(list(string))
      resource_ids       = optional(list(string))
      statuses           = optional(list(string))
      sub_statuses       = optional(list(string))

      recommendation_type     = optional(string)
      recommendation_category = optional(string)
      recommendation_impact   = optional(string)

      resource_health = optional(object({
        current  = optional(list(string))
        previous = optional(list(string))
        reason   = optional(list(string))
      }))

      service_health = optional(object({
        events    = optional(list(string))
        locations = optional(list(string))
        services  = optional(list(string))
      }))
    })

    actions = optional(map(object({
      action_group_id    = string
      webhook_properties = optional(map(string))
    })), {})
  }))

  validation {
    condition = alltrue([
      for alert in var.activity_log_alerts : contains(["global", "westeurope", "northeurope", "eastus2euap"], alert.location)
    ])
    error_message = "location must be global, westeurope, northeurope or eastus2euap — the documented values the activity log alert API accepts; the module defaults to global."
  }

  validation {
    condition = alltrue([
      for alert in var.activity_log_alerts : contains(["Administrative", "ServiceHealth", "ResourceHealth", "Autoscale", "Security", "Recommendation", "Policy"], alert.criteria.category)
    ])
    error_message = "criteria.category must be one of Administrative, ServiceHealth, ResourceHealth, Autoscale, Security or Recommendation."
  }

  validation {
    condition = alltrue([
      for alert in var.activity_log_alerts :
      alltrue([
        for field_name, field_value in {
          recommendation_type     = alert.criteria.recommendation_type
          recommendation_category = alert.criteria.recommendation_category
          recommendation_impact   = alert.criteria.recommendation_impact
        } : field_value == null
      ]) || alert.criteria.category == "Recommendation"
    ])
    error_message = "recommendation_type, recommendation_category and recommendation_impact are only definable when criteria.category = \"Recommendation\" — the API rejects them with any other category."
  }

  validation {
    condition = alltrue([
      for alert in var.activity_log_alerts :
      alert.criteria.recommendation_category == null || contains(
        ["Cost", "Reliability", "OperationalExcellence", "HighAvailability", "Performance", "Security"],
        alert.criteria.recommendation_category
      )
    ])
    error_message = "criteria.recommendation_category must be one of Cost, Reliability, OperationalExcellence, HighAvailability, Performance or Security."
  }

  validation {
    condition = alltrue([
      for alert in var.activity_log_alerts :
      alert.criteria.recommendation_impact == null || contains(["High", "Medium", "Low"], alert.criteria.recommendation_impact)
    ])
    error_message = "criteria.recommendation_impact must be one of High, Medium or Low."
  }

  validation {
    condition = alltrue(concat(
      [for alert_key in keys(var.activity_log_alerts) : !can(regex("\\.", alert_key))],
      flatten([
        for alert in var.activity_log_alerts :
        [for action_key in keys(alert.actions) : !can(regex("\\.", action_key))]
      ])
    ))
    error_message = "map keys of activity_log_alerts and its nested actions maps must not contain \".\" — action keys are composed into identifiers of the form \"<alert_key>.<key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue([
      for alert in var.activity_log_alerts :
      length(alert.tags) <= 50 && alltrue([for tag_key, tag_value in alert.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "scheduled_query_rules" {
  description = "Map of Azure Monitor v2 scheduled query rules (log alert rules) keyed by an arbitrary identifier. Each entry creates one azurerm_monitor_scheduled_query_rules_alert_v2; criteria flatten from the nested map and the single action block is wired from its object."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    scopes              = list(string)
    description         = optional(string)
    display_name        = optional(string)
    enabled             = optional(bool, true)
    severity            = number

    evaluation_frequency = string
    window_duration      = string

    mute_actions_after_alert_duration = optional(string)
    query_time_range_override         = optional(string)
    auto_mitigation_enabled           = optional(bool)
    skip_query_validation             = optional(bool)
    workspace_alerts_storage_enabled  = optional(bool)
    target_resource_types             = optional(list(string))
    tags                              = optional(map(string), {})

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    criteria = optional(map(object({
      query                   = string
      operator                = string
      threshold               = number
      time_aggregation_method = string

      metric_measure_column = optional(string)
      resource_id_column    = optional(string)

      dimension = optional(map(object({
        name     = string
        operator = string
        values   = list(string)
      })), {})

      failing_periods = optional(object({
        minimum_failing_periods_to_trigger_alert = number
        number_of_evaluation_periods             = number
      }))
    })), {})

    action = optional(object({
      action_groups     = optional(list(string))
      custom_properties = optional(map(string))
      email_subject     = optional(string)
    }))
  }))

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules : length(rule.scopes) == 1
    ])
    error_message = "each scheduled query rule needs exactly one scoped resource ID — the v2 API accepts exactly one scope per rule (to alert on a resource group or subscription, keep it as the single scope and pair with target_resource_types)."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules :
      rule.severity >= 0 && rule.severity <= 4
    ])
    error_message = "severity must be between 0 (critical) and 4 (verbose) — Azure rejects anything else."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules : contains(["PT1M", "PT5M", "PT10M", "PT15M", "PT30M", "PT45M", "PT1H", "PT2H", "PT3H", "PT4H", "PT5H", "PT6H", "P1D"], rule.evaluation_frequency)
    ])
    error_message = "evaluation_frequency must be one of PT1M, PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, PT6H or P1D — the documented ISO-8601 evaluation frequencies."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules : can(regex(
        "^P(([0-9]+([.,][0-9]+)?D)|(([0-9]+D)?T([0-9]+([.,][0-9]+)?[HMS])+))$",
        rule.window_duration
      ))
    ])
    error_message = "window_duration must be an ISO-8601 duration with a day component or an hours/minutes/seconds time component (e.g. PT1H, PT2H30M, P1DT12H) — the API rejects any other spelling."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules :
      sum([for part in regexall("([0-9]+)([DHMS])", rule.window_duration) : tonumber(part[0]) * lookup({ D = 1440, H = 60, M = 1, S = 0 }, part[1])])
      >= sum([for part in regexall("([0-9]+)([DHMS])", rule.evaluation_frequency) : tonumber(part[0]) * lookup({ D = 1440, H = 60, M = 1, S = 0 }, part[1])])
    ])
    error_message = "window_duration must be at least as long as evaluation_frequency — the rule needs room for evaluations inside the window (the API also caps the lookback at the window × failing periods, at most 48 hours; see Notes)."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules :
      rule.mute_actions_after_alert_duration == null || (
        can(regex(
          "^P(([0-9]+([.,][0-9]+)?D)|(([0-9]+D)?T([0-9]+([.,][0-9]+)?[HMS])+))$",
          rule.mute_actions_after_alert_duration
        ))
        && sum([for part in regexall("([0-9]+)([DHMS])", rule.mute_actions_after_alert_duration) : tonumber(part[0]) * lookup({ D = 1440, H = 60, M = 1, S = 0 }, part[1])])
        >= sum([for part in regexall("([0-9]+)([DHMS])", rule.evaluation_frequency) : tonumber(part[0]) * lookup({ D = 1440, H = 60, M = 1 }, part[1])])
      )
    ])
    error_message = "mute_actions_after_alert_duration must be an ISO-8601 duration (patterns as window_duration) and at least as long as evaluation_frequency."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules :
      !(rule.auto_mitigation_enabled == true && rule.mute_actions_after_alert_duration != null)
    ])
    error_message = "auto_mitigation_enabled is mutually exclusive with mute_actions_after_alert_duration — automatic mitigation and scripted muting cannot be combined."
  }

  validation {
    condition = alltrue(concat(
      [for key in keys(var.scheduled_query_rules) : !can(regex("\\.", key))],
      flatten([
        for rule in var.scheduled_query_rules : [
          for criterion_key, criterion in coalesce(rule.criteria, {}) :
          !can(regex("\\.", criterion_key))
          && alltrue([for dimension_key in keys(criterion.dimension) : !can(regex("\\.", dimension_key))])
        ]
      ])
    ))
    error_message = "map keys of scheduled_query_rules and its nested criteria and dimension maps must not contain \".\" — criteria keys are composed into identifiers of the form \"<rule_key>.<key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for rule in var.scheduled_query_rules : [
        for criterion in coalesce(rule.criteria, {}) :
        contains(["Equal", "GreaterThan", "GreaterThanOrEqual", "LessThan", "LessThanOrEqual"], criterion.operator)
        && contains(["Count", "Average", "Minimum", "Maximum", "Total"], criterion.time_aggregation_method)
        && ((criterion.metric_measure_column == null) == (criterion.time_aggregation_method == "Count"))
        && alltrue([for dimension in criterion.dimension : contains(["Include", "Exclude"], dimension.operator)])
        && (criterion.failing_periods == null || (
          criterion.failing_periods.minimum_failing_periods_to_trigger_alert >= 1
          && criterion.failing_periods.minimum_failing_periods_to_trigger_alert <= 6
          && criterion.failing_periods.number_of_evaluation_periods >= 1
          && criterion.failing_periods.number_of_evaluation_periods <= 6
          && criterion.failing_periods.minimum_failing_periods_to_trigger_alert <= criterion.failing_periods.number_of_evaluation_periods
        ))
      ]
    ]))
    error_message = "criteria operators must be one of Equal, GreaterThan, GreaterThanOrEqual, LessThan or LessThanOrEqual; time_aggregation_method one of Count, Average, Minimum, Maximum or Total (metric_measure_column required whenever Count is not used and rejected with Count); dimension operators one of Include or Exclude; failing periods between 1 and 6 with minimum_failing_periods_to_trigger_alert ≤ number_of_evaluation_periods."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules :
      rule.identity == null || !contains(["UserAssigned", "SystemAssigned, UserAssigned"], rule.identity.type) || (length(coalesce(rule.identity.identity_ids, [])) > 0 && alltrue([for id in rule.identity.identity_ids : can(regex("^/", id))]))
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — full ARM resource IDs of user-assigned managed identities (starting with \"/\")."
  }

  validation {
    condition = alltrue([
      for rule in var.scheduled_query_rules :
      length(rule.tags) <= 50 && alltrue([for tag_key, tag_value in rule.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "diagnostic_settings" {
  description = "Map of Azure Monitor diagnostic settings keyed by an arbitrary identifier. Each entry creates one azurerm_monitor_diagnostic_setting on an arbitrary target resource — one name per target; the settings bridge the target's platform logs and metrics to the azure/log-analytics module's workspace, another destination ID or a partner solution."
  type = map(object({
    name               = string
    target_resource_id = string

    logs = optional(list(object({
      category       = optional(string)
      category_group = optional(string)
    })), [])

    metric_categories = optional(list(string), [])

    log_analytics_destination_type = optional(string)
    eventhub_name                  = optional(string)

    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    partner_solution_id            = optional(string)
  }))

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      (
        (setting.log_analytics_workspace_id != null ? 1 : 0)
        + (setting.storage_account_id != null ? 1 : 0)
        + (setting.eventhub_authorization_rule_id != null ? 1 : 0)
        + (setting.partner_solution_id != null ? 1 : 0)
      ) >= 1
    ])
    error_message = "each diagnostic setting needs at least one destination — one of log_analytics_workspace_id, storage_account_id, eventhub_authorization_rule_id or partner_solution_id (the API rejects settings without a route)."
  }

  validation {
    condition = alltrue(flatten([
      for setting in var.diagnostic_settings :
      [
        for entry in setting.logs :
        (entry.category != null ? 1 : 0) + (entry.category_group != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "each logs entry needs exactly one of category (e.g. AuditLogs) or category_group (e.g. allLogs) — the Azure API accepts one per enabled_log block, mixed lists are fine."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      setting.log_analytics_destination_type == null || (
        setting.log_analytics_workspace_id != null
        && contains(["Dedicated", "AzureDiagnostics"], setting.log_analytics_destination_type)
      )
    ])
    error_message = "log_analytics_destination_type must be Dedicated or AzureDiagnostics and is only meaningful together with log_analytics_workspace_id."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      setting.eventhub_name == null || setting.eventhub_authorization_rule_id != null
    ])
    error_message = "eventhub_name requires eventhub_authorization_rule_id — the authorization rule scopes the hub access; see Notes for its (namespace-level) shape."
  }

  validation {
    condition     = alltrue([for setting_key in keys(var.diagnostic_settings) : !can(regex("\\.", setting_key))])
    error_message = "map key of diagnostic_settings entries must not contain \".\" — keys feed the \"<key>\" output mapping; dots would make outputs ambiguous."
  }
}
