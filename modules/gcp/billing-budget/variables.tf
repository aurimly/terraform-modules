variable "budgets" {
  description = "Map of billing budgets keyed by an arbitrary identifier. Each entry creates one google_billing_budget."
  type = map(object({
    billing_account = string
    display_name    = string
    ownership_scope = optional(string)
    deletion_policy = optional(string)
    amount = object({
      last_period_amount = optional(bool)
      specified_amount = optional(object({
        currency_code = optional(string, "USD")
        units         = optional(string)
        nanos         = optional(number)
      }))
    })
    budget_filter = optional(object({
      projects               = optional(list(string))
      resource_ancestors     = optional(list(string))
      credit_types_treatment = optional(string, "INCLUDE_ALL_CREDITS")
      credit_types           = optional(list(string))
      services               = optional(list(string))
      subaccounts            = optional(list(string))
      labels                 = optional(map(string))
      calendar_period        = optional(string)
      custom_period = optional(object({
        start_date = object({
          year  = number
          month = number
          day   = number
        })
        end_date = optional(object({
          year  = number
          month = number
          day   = number
        }))
      }))
    }))
    threshold_rules = optional(list(object({
      threshold_percent = number
      spend_basis       = optional(string, "CURRENT_SPEND")
    })), [])
    all_updates_rule = optional(object({
      pubsub_topic                     = optional(string)
      schema_version                   = optional(string, "1.0")
      monitoring_notification_channels = optional(list(string))
      disable_default_iam_recipients   = optional(bool, false)
      enable_project_level_recipients  = optional(bool)
    }))
  }))

  validation {
    condition     = alltrue([for b in var.budgets : can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", b.billing_account))])
    error_message = "billing_account must look like a billing account id (e.g. A1B2C3-D4E5F6-G7H8I9); it is a shape check, not a list of valid accounts."
  }

  validation {
    condition     = alltrue([for b in var.budgets : length(b.display_name) <= 60])
    error_message = "display_name must be at most 60 characters (API limit)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.ownership_scope == null || contains(["ALL_USERS", "BILLING_ACCOUNT"], b.ownership_scope)])
    error_message = "ownership_scope must be one of ALL_USERS or BILLING_ACCOUNT (case-sensitive); omit it to leave the default scope."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], b.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : (b.amount.last_period_amount != null && b.amount.last_period_amount) != (b.amount.specified_amount != null)])
    error_message = "amount must specify exactly one of last_period_amount = true or specified_amount."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.amount.last_period_amount == null || b.amount.last_period_amount])
    error_message = "amount.last_period_amount must be true when set; the provider rejects false (use specified_amount instead)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.budget_filter == null || contains(["INCLUDE_ALL_CREDITS", "EXCLUDE_ALL_CREDITS", "INCLUDE_SPECIFIED_CREDITS"], b.budget_filter.credit_types_treatment)])
    error_message = "budget_filter.credit_types_treatment must be one of INCLUDE_ALL_CREDITS, EXCLUDE_ALL_CREDITS or INCLUDE_SPECIFIED_CREDITS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.budget_filter == null || b.budget_filter.credit_types_treatment != "INCLUDE_SPECIFIED_CREDITS" || b.budget_filter.credit_types != null])
    error_message = "budget_filter.credit_types is required when credit_types_treatment is INCLUDE_SPECIFIED_CREDITS."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.budget_filter == null || b.budget_filter.credit_types_treatment == "INCLUDE_SPECIFIED_CREDITS" || b.budget_filter.credit_types == null])
    error_message = "budget_filter.credit_types must be empty unless credit_types_treatment is INCLUDE_SPECIFIED_CREDITS."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.budget_filter == null || b.budget_filter.calendar_period == null || contains(["MONTH", "QUARTER", "YEAR"], b.budget_filter.calendar_period)])
    error_message = "budget_filter.calendar_period must be one of MONTH, QUARTER or YEAR (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.budget_filter == null || b.budget_filter.calendar_period == null || b.budget_filter.custom_period == null])
    error_message = "budget_filter accepts exactly one of calendar_period or custom_period; setting both is rejected by the API."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.budget_filter == null || b.budget_filter.custom_period == null || (b.budget_filter.custom_period.start_date.month >= 1 && b.budget_filter.custom_period.start_date.month <= 12 && b.budget_filter.custom_period.start_date.day >= 1 && b.budget_filter.custom_period.start_date.day <= 31)])
    error_message = "budget_filter.custom_period.start_date must have month in 1-12 and day in 1-31."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.budget_filter == null || b.budget_filter.custom_period == null || b.budget_filter.custom_period.end_date == null || (b.budget_filter.custom_period.end_date.month >= 1 && b.budget_filter.custom_period.end_date.month <= 12 && b.budget_filter.custom_period.end_date.day >= 1 && b.budget_filter.custom_period.end_date.day <= 31)])
    error_message = "budget_filter.custom_period.end_date must have month in 1-12 and day in 1-31."
  }

  validation {
    condition     = alltrue([for b in var.budgets : alltrue([for r in b.threshold_rules : r.threshold_percent >= 0])])
    error_message = "threshold_rules.threshold_percent must be >= 0 (a 1.0-based percentage; 0.5 = 50%, values above 1.0 are valid)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : alltrue([for r in b.threshold_rules : contains(["CURRENT_SPEND", "FORECASTED_SPEND"], r.spend_basis)])])
    error_message = "threshold_rules.spend_basis must be one of CURRENT_SPEND or FORECASTED_SPEND (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.all_updates_rule == null || b.all_updates_rule.schema_version == "1.0"])
    error_message = "all_updates_rule.schema_version must be 1.0 (the only version the API accepts today)."
  }

  validation {
    condition     = alltrue([for b in var.budgets : b.all_updates_rule == null || b.all_updates_rule.monitoring_notification_channels == null || length(b.all_updates_rule.monitoring_notification_channels) <= 5])
    error_message = "all_updates_rule.monitoring_notification_channels accepts at most 5 channel names."
  }
}
