variable "warehouses" {
  description = "Map of Snowflake warehouses keyed by an arbitrary identifier. Each entry creates one snowflake_warehouse."
  type = map(object({
    name                                = string
    warehouse_type                      = optional(string)
    warehouse_size                      = optional(string)
    min_cluster_count                   = optional(number)
    max_cluster_count                   = optional(number)
    scaling_policy                      = optional(string)
    auto_suspend                        = optional(number)
    auto_resume                         = optional(bool)
    initially_suspended                 = optional(bool)
    comment                             = optional(string)
    enable_query_acceleration           = optional(bool)
    query_acceleration_max_scale_factor = optional(number)
    resource_constraint                 = optional(string)
    generation                          = optional(string)
    resource_monitor                    = optional(string)
    max_concurrency_level               = optional(number)
    statement_timeout_in_seconds        = optional(number)
    statement_queued_timeout_in_seconds = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for w in var.warehouses : can(regex("^[^|.\"]+$", w.name))])
    error_message = "name must not contain \"|\", \" or . (provider limitation on warehouse identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.warehouse_type == null || contains(["STANDARD", "SNOWPARK-OPTIMIZED"], upper(w.warehouse_type))])
    error_message = "warehouse_type must be STANDARD or SNOWPARK-OPTIMIZED (case-insensitive, matching the provider)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.warehouse_size == null || contains(["XSMALL", "X-SMALL", "SMALL", "MEDIUM", "LARGE", "XLARGE", "X-LARGE", "XXLARGE", "X2LARGE", "2X-LARGE", "XXXLARGE", "X3LARGE", "3X-LARGE", "X4LARGE", "4X-LARGE", "X5LARGE", "5X-LARGE", "X6LARGE", "6X-LARGE"], upper(w.warehouse_size))])
    error_message = "warehouse_size must be one of the warehouse sizes the provider accepts (canonical XSMALL..X6LARGE names or their hyphenated/nominal aliases, case-insensitive)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.scaling_policy == null || contains(["STANDARD", "ECONOMY"], upper(w.scaling_policy))])
    error_message = "scaling_policy must be STANDARD or ECONOMY (case-insensitive, matching the provider)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.generation == null || contains(["1", "2"], w.generation)])
    error_message = "generation must be \"1\" or \"2\" (provider: case-insensitive; applies to standard warehouses only)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.resource_constraint == null || contains(["MEMORY_1X", "MEMORY_1X_X86", "MEMORY_16X", "MEMORY_16X_X86", "MEMORY_64X", "MEMORY_64X_X86"], upper(w.resource_constraint))])
    error_message = "resource_constraint must be one of MEMORY_1X, MEMORY_1X_x86, MEMORY_16X, MEMORY_16X_x86, MEMORY_64X or MEMORY_64X_x86 (case-insensitive; provider accepts the memory-based values only — standard-warehouse generations go through `generation`)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.generation == null || w.warehouse_type == null || upper(w.warehouse_type) == "STANDARD"])
    error_message = "generation applies to standard warehouses only — set it to null for SNOWPARK-OPTIMIZED warehouses."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.resource_constraint == null || (w.warehouse_type != null && upper(w.warehouse_type) == "SNOWPARK-OPTIMIZED")])
    error_message = "resource_constraint applies to SNOWPARK-OPTIMIZED warehouses only — set warehouse_type = \"SNOWPARK-OPTIMIZED\" or set resource_constraint to null."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : (w.min_cluster_count == null || w.min_cluster_count >= 1) && (w.max_cluster_count == null || w.max_cluster_count >= 1)])
    error_message = "min_cluster_count and max_cluster_count must be 1 or greater (single-cluster warehouses are 1)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.min_cluster_count == null || w.max_cluster_count == null || w.min_cluster_count <= w.max_cluster_count])
    error_message = "min_cluster_count must be less than or equal to max_cluster_count (equal values run the warehouse in Maximized mode; a smaller min runs Auto-scale)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.auto_suspend == null || w.auto_suspend >= 0])
    error_message = "auto_suspend must be 0 or greater (0 means the warehouse never suspends — discouraged for cost reasons)."
  }

  validation {
    condition     = alltrue([for w in var.warehouses : w.query_acceleration_max_scale_factor == null || (w.query_acceleration_max_scale_factor >= 0 && w.query_acceleration_max_scale_factor <= 100)])
    error_message = "query_acceleration_max_scale_factor must be between 0 and 100 (0 removes the limit)."
  }

  validation {
    condition = alltrue(flatten([
      for key, w in var.warehouses : [
        for other_key, n in var.warehouses :
        key == other_key || upper(w.name) != upper(n.name)
      ]
    ]))
    error_message = "warehouse names must be unique within the account, case-insensitively — two entries sharing a name conflict at apply."
  }
}
