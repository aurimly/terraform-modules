variable "trails" {
  description = "Map of CloudTrail trails keyed by an arbitrary identifier. Each entry creates one aws_cloudtrail; the S3 delivery bucket and its CloudTrail bucket policy stay consumer-side."
  type = map(object({
    name                          = string
    s3_bucket_name                = string
    s3_key_prefix                 = optional(string)
    is_multi_region_trail         = optional(bool, false)
    is_organization_trail         = optional(bool, false)
    enable_log_file_validation    = optional(bool, false)
    enable_logging                = optional(bool, true)
    include_global_service_events = optional(bool, true)
    kms_key_id                    = optional(string)
    cloud_watch_logs_group_arn    = optional(string)
    cloud_watch_logs_role_arn     = optional(string)
    sns_topic_name                = optional(string)
    recursive_logging             = optional(bool)
    event_selectors = optional(map(object({
      read_write_type                  = optional(string, "All")
      include_management_events        = optional(bool, true)
      exclude_management_event_sources = optional(list(string), [])
      data_resources = optional(map(object({
        type   = string
        values = list(string)
      })), {})
    })), {})
    advanced_event_selectors = optional(map(object({
      name = optional(string)
      field_selectors = map(object({
        field           = string
        equals          = optional(list(string))
        starts_with     = optional(list(string))
        ends_with       = optional(list(string))
        not_equals      = optional(list(string))
        not_starts_with = optional(list(string))
        not_ends_with   = optional(list(string))
      }))
    })), {})
    insight_types = optional(list(string), [])
    tags          = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for t in var.trails : can(regex("^[A-Za-z0-9._-]{3,128}$", t.name))])
    error_message = "name must be 3-128 characters of alphanumerics, dots, underscores and hyphens (CloudTrail trail naming rules)."
  }

  validation {
    condition     = alltrue([for t in var.trails : can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", t.s3_bucket_name))])
    error_message = "s3_bucket_name must be a valid S3 bucket name (3-63 characters, lowercase)."
  }

  validation {
    condition     = alltrue([for t in var.trails : t.cloud_watch_logs_group_arn == null || can(regex("^arn:[^:]*:logs:[^:]*:[^:]*:log-group:[^:*]+$", t.cloud_watch_logs_group_arn))])
    error_message = "cloud_watch_logs_group_arn must be a log-group ARN without the :* stream suffix (the module appends it)."
  }

  validation {
    condition     = alltrue([for t in var.trails : (t.cloud_watch_logs_group_arn == null) == (t.cloud_watch_logs_role_arn == null)])
    error_message = "cloud_watch_logs_group_arn and cloud_watch_logs_role_arn must be set together or both omitted (CloudTrail rejects one without the other)."
  }

  validation {
    condition     = alltrue([for t in var.trails : (length(t.event_selectors) == 0 || length(t.advanced_event_selectors) == 0)])
    error_message = "event_selectors and advanced_event_selectors are mutually exclusive per trail (the CloudTrail API rejects both)."
  }

  validation {
    condition     = alltrue([for t in var.trails : length(t.event_selectors) <= 5])
    error_message = "at most 5 event_selectors per trail (CloudTrail limit)."
  }

  validation {
    condition     = alltrue(flatten([for t in var.trails : [for e in t.event_selectors : contains(["ReadOnly", "WriteOnly", "All"], e.read_write_type)]]))
    error_message = "event_selectors.read_write_type must be ReadOnly, WriteOnly or All (case-sensitive, matching the CloudTrail API)."
  }

  validation {
    condition     = alltrue(flatten([for t in var.trails : [for e in t.event_selectors : alltrue([for s in e.exclude_management_event_sources : contains(["kms.amazonaws.com", "rdsdata.amazonaws.com"], s)])]]))
    error_message = "event_selectors.exclude_management_event_sources entries must be kms.amazonaws.com or rdsdata.amazonaws.com (the only values the CloudTrail API accepts)."
  }

  validation {
    condition     = alltrue(flatten([for t in var.trails : [for e in t.event_selectors : alltrue([for d in e.data_resources : contains(["AWS::S3::Object", "AWS::Lambda::Function", "AWS::DynamoDB::Table"], d.type)])]]))
    error_message = "event_selectors.data_resources.type must be one of AWS::S3::Object, AWS::Lambda::Function or AWS::DynamoDB::Table (case-sensitive, matching the CloudTrail API)."
  }

  validation {
    condition     = alltrue(flatten([for t in var.trails : [for a in t.advanced_event_selectors : alltrue([for f in a.field_selectors : contains(["readOnly", "eventSource", "eventName", "eventCategory", "resources.type", "resources.ARN"], f.field)])]]))
    error_message = "advanced_event_selectors.field_selectors.field must be one of readOnly, eventSource, eventName, eventCategory, resources.type or resources.ARN (case-sensitive, matching the CloudTrail API)."
  }

  validation {
    condition     = alltrue(flatten([for t in var.trails : [for a in t.advanced_event_selectors : alltrue([for f in a.field_selectors : contains(["readOnly", "eventCategory", "resources.type"], f.field) ? (f.starts_with == null && f.ends_with == null && f.not_equals == null && f.not_starts_with == null && f.not_ends_with == null) : true])]]))
    error_message = "advanced_event_selectors.field_selectors: the readOnly, eventCategory and resources.type fields accept equals only (the CloudTrail API rejects the other operators on them)."
  }

  validation {
    condition = alltrue(flatten([for t in var.trails : [for e in t.event_selectors :
      length(e.exclude_management_event_sources) == 0 || e.include_management_events
    ]]))
    error_message = "event_selectors.exclude_management_event_sources requires include_management_events = true (the CloudTrail API rejects the exclusion otherwise)."
  }

  validation {
    condition = alltrue(flatten([for t in var.trails : [for a in t.advanced_event_selectors : alltrue([for f in a.field_selectors :
      length([for op in [f.equals, f.starts_with, f.ends_with, f.not_equals, f.not_starts_with, f.not_ends_with] : op if op != null]) == 1
    ])]]))
    error_message = "advanced_event_selectors.field_selectors must set exactly one operator (the CloudTrail API requires a single operator per field selector)."
  }

  validation {
    condition     = alltrue([for t in var.trails : alltrue([for i in t.insight_types : contains(["ApiCallRateInsight", "ApiErrorRateInsight"], i)])])
    error_message = "insight_types entries must be ApiCallRateInsight or ApiErrorRateInsight (case-sensitive, matching the CloudTrail API)."
  }

  validation {
    condition     = alltrue([for t in var.trails : length(t.insight_types) == length(distinct(t.insight_types))])
    error_message = "insight_types entries must be distinct (one insight_selector block per type)."
  }
}
