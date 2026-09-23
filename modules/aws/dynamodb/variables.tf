variable "tables" {
  description = "Map of DynamoDB tables keyed by an arbitrary identifier. Each entry creates one aws_dynamodb_table."
  type = map(object({
    name                        = string
    hash_key                    = string
    range_key                   = optional(string)
    billing_mode                = optional(string, "PAY_PER_REQUEST")
    read_capacity               = optional(number)
    write_capacity              = optional(number)
    table_class                 = optional(string, "STANDARD")
    deletion_protection_enabled = optional(bool, true)
    stream_enabled              = optional(bool, false)
    stream_view_type            = optional(string)
    tags                        = optional(map(string), {})
    attributes = map(object({
      type = string
    }))
    global_secondary_indexes = optional(map(object({
      name               = string
      hash_key           = string
      range_key          = optional(string)
      projection_type    = optional(string, "ALL")
      non_key_attributes = optional(list(string))
      read_capacity      = optional(number)
      write_capacity     = optional(number)
    })), {})
    local_secondary_indexes = optional(map(object({
      name               = string
      range_key          = string
      projection_type    = optional(string, "ALL")
      non_key_attributes = optional(list(string))
    })), {})
    ttl = optional(object({
      attribute_name = string
      enabled        = optional(bool, true)
    }))
    point_in_time_recovery = optional(object({
      enabled                 = optional(bool, true)
      recovery_period_in_days = optional(number)
    }))
    server_side_encryption = optional(object({
      enabled     = optional(bool, true)
      kms_key_arn = optional(string)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for t in var.tables : length(t.name) >= 3 && length(t.name) <= 255 && can(regex("^[a-zA-Z0-9_.-]+$", t.name))])
    error_message = "name must be 3 to 255 characters with letters, digits, underscores, dots and hyphens (DynamoDB naming rules)."
  }

  validation {
    condition     = alltrue([for t in var.tables : contains(["PAY_PER_REQUEST", "PROVISIONED"], t.billing_mode)])
    error_message = "billing_mode must be one of PAY_PER_REQUEST or PROVISIONED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.billing_mode != "PROVISIONED" || (t.read_capacity != null && t.write_capacity != null)])
    error_message = "PROVISIONED tables require both read_capacity and write_capacity."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.billing_mode != "PAY_PER_REQUEST" || (t.read_capacity == null && t.write_capacity == null)])
    error_message = "PAY_PER_REQUEST tables must not set read_capacity or write_capacity (the API rejects provisioned throughput with on-demand mode)."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.table_class == null || contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], t.table_class)])
    error_message = "table_class must be one of STANDARD or STANDARD_INFREQUENT_ACCESS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.tables : length(t.attributes) > 0])
    error_message = "attributes must contain at least one entry (DynamoDB requires the full key schema)."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for a in t.attributes : contains(["S", "N", "B"], a.type)])])
    error_message = "attributes.type must be one of S, N or B (case-sensitive DynamoDB attribute types)."
  }

  validation {
    condition     = alltrue([for t in var.tables : can(t.attributes[t.hash_key])])
    error_message = "attributes must contain the hash_key."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.range_key == null || can(t.attributes[t.range_key])])
    error_message = "attributes must contain the range_key when it is set."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.stream_view_type == null || t.stream_enabled])
    error_message = "stream_view_type requires stream_enabled = true."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.stream_view_type == null || contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], t.stream_view_type)])
    error_message = "stream_view_type must be one of KEYS_ONLY, NEW_IMAGE, OLD_IMAGE or NEW_AND_OLD_IMAGES (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for g in t.global_secondary_indexes : can(t.attributes[g.hash_key])])])
    error_message = "every global_secondary_indexes hash_key must exist in attributes."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for g in t.global_secondary_indexes : g.range_key == null || can(t.attributes[g.range_key])])])
    error_message = "every global_secondary_indexes range_key must exist in attributes when set."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for l in t.local_secondary_indexes : can(t.attributes[l.range_key])])])
    error_message = "every local_secondary_indexes range_key must exist in attributes."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.billing_mode != "PAY_PER_REQUEST" || alltrue([for g in t.global_secondary_indexes : g.read_capacity == null && g.write_capacity == null])])
    error_message = "global_secondary_indexes read_capacity/write_capacity are only valid on PROVISIONED tables (the API rejects them with PAY_PER_REQUEST)."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.billing_mode != "PROVISIONED" || alltrue([for g in t.global_secondary_indexes : g.read_capacity != null && g.write_capacity != null])])
    error_message = "PROVISIONED tables require read_capacity and write_capacity on every global_secondary_indexes entry."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for g in t.global_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], g.projection_type)])])
    error_message = "global_secondary_indexes.projection_type must be one of ALL, KEYS_ONLY or INCLUDE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for g in t.global_secondary_indexes : g.projection_type != "INCLUDE" || (length(coalesce(g.non_key_attributes, [])) > 0)])])
    error_message = "global_secondary_indexes.projection_type = INCLUDE requires non_key_attributes."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for l in t.local_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], l.projection_type)])])
    error_message = "local_secondary_indexes.projection_type must be one of ALL, KEYS_ONLY or INCLUDE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.tables : alltrue([for l in t.local_secondary_indexes : l.projection_type != "INCLUDE" || (length(coalesce(l.non_key_attributes, [])) > 0)])])
    error_message = "local_secondary_indexes.projection_type = INCLUDE requires non_key_attributes."
  }

  validation {
    condition     = alltrue([for t in var.tables : length(t.global_secondary_indexes) <= 20])
    error_message = "a table supports at most 20 global secondary indexes."
  }

  validation {
    condition     = alltrue([for t in var.tables : length(t.local_secondary_indexes) <= 5])
    error_message = "a table supports at most 5 local secondary indexes."
  }

  validation {
    condition     = alltrue([for t in var.tables : t.server_side_encryption == null || t.server_side_encryption.kms_key_arn == null || can(regex("^arn:", t.server_side_encryption.kms_key_arn))])
    error_message = "server_side_encryption.kms_key_arn must be a full ARN (starts with arn:)."
  }
}
