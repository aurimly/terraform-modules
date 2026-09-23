variable "topics" {
  description = "Map of SNS topics keyed by an arbitrary identifier. Each entry creates one aws_sns_topic plus optional policy and subscriptions."
  type = map(object({
    name                        = optional(string)
    name_prefix                 = optional(string)
    fifo                        = optional(bool, false)
    display_name                = optional(string)
    signature_version           = optional(string)
    tracing_mode                = optional(string)
    content_based_deduplication = optional(bool)
    policy                      = optional(string)
    kms_master_key_id           = optional(string)
    delivery_policy             = optional(string)
    application_feedback = optional(object({
      success_feedback_role_arn    = optional(string)
      failure_feedback_role_arn    = optional(string)
      success_feedback_sample_rate = optional(number)
    }))
    lambda_feedback = optional(object({
      success_feedback_role_arn    = optional(string)
      failure_feedback_role_arn    = optional(string)
      success_feedback_sample_rate = optional(number)
    }))
    http_feedback = optional(object({
      success_feedback_role_arn    = optional(string)
      failure_feedback_role_arn    = optional(string)
      success_feedback_sample_rate = optional(number)
    }))
    sqs_feedback = optional(object({
      success_feedback_role_arn    = optional(string)
      failure_feedback_role_arn    = optional(string)
      success_feedback_sample_rate = optional(number)
    }))
    firehose_feedback = optional(object({
      success_feedback_role_arn    = optional(string)
      failure_feedback_role_arn    = optional(string)
      success_feedback_sample_rate = optional(number)
    }))
    subscriptions = optional(map(object({
      protocol               = string
      endpoint               = string
      endpoint_auto_confirms = optional(bool)
      confirmation_timeout   = optional(number)
      raw_message_delivery   = optional(bool)
      delivery_policy        = optional(string)
      filter_policy          = optional(string)
      filter_policy_scope    = optional(string)
      redrive_policy         = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for t in var.topics : t.name == null || (length(t.name) <= 256 && can(regex("^[a-zA-Z0-9_-]+(\\.fifo)?$", t.name)))])
    error_message = "name must be up to 256 characters of alphanumerics, hyphens and underscores; FIFO topic names must end in .fifo (SNS naming rules)."
  }

  validation {
    condition     = alltrue([for t in var.topics : t.signature_version == null || contains(["1", "2"], tostring(t.signature_version))])
    error_message = "signature_version must be 1 or 2 (SNS SignatureVersion values; 2 enables SigV4 security features)."
  }

  validation {
    condition     = alltrue([for t in var.topics : t.tracing_mode == null || contains(["Active", "PassThrough"], t.tracing_mode)])
    error_message = "tracing_mode must be one of Active or PassThrough (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for f in [t.application_feedback, t.lambda_feedback, t.http_feedback, t.sqs_feedback, t.firehose_feedback] : alltrue([
          f == null || f.success_feedback_sample_rate == null || f.success_feedback_sample_rate >= 0 && f.success_feedback_sample_rate <= 100
        ])
      ]
    ]))
    error_message = "feedback success_feedback_sample_rate must be between 0 and 100 (SNS sampling percentage)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : contains(["http", "https", "email", "email-json", "sms", "sqs", "application", "lambda", "firehose"], s.protocol)
      ]
    ]))
    error_message = "subscriptions.protocol must be one of http, https, email, email-json, sqs, application, lambda or firehose (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : (s.protocol == "email" || s.protocol == "email-json") || can(regex("^(arn:|http://|https://)", s.endpoint))
      ]
    ]))
    error_message = "subscriptions.endpoint must be an ARN or URL for non-email protocols (email endpoints are addresses and cannot be validated as ARNs)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : s.endpoint_auto_confirms == null || s.endpoint_auto_confirms == false || contains(["http", "https"], s.protocol)
      ]
    ]))
    error_message = "subscriptions.endpoint_auto_confirms only applies to http/https subscriptions (other protocols auto-confirm or need explicit action)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : s.raw_message_delivery == null || s.raw_message_delivery == false || contains(["sqs", "http", "https", "email-json", "firehose"], s.protocol)
      ]
    ]))
    error_message = "subscriptions.raw_message_delivery only applies to sqs, http, https, email-json and firehose protocols."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : s.filter_policy_scope == null || s.filter_policy != null
      ]
    ]))
    error_message = "subscriptions.filter_policy_scope requires filter_policy to be set."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : s.filter_policy_scope == null || contains(["MessageAttributes", "MessageBody"], s.filter_policy_scope)
      ]
    ]))
    error_message = "subscriptions.filter_policy_scope must be one of MessageAttributes or MessageBody (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : s.filter_policy == null || can(jsondecode(s.filter_policy))
      ]
    ]))
    error_message = "subscriptions.filter_policy must be a valid JSON filter policy document."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.topics : [
        for s in t.subscriptions : s.redrive_policy == null || can(jsondecode(s.redrive_policy))
      ]
    ]))
    error_message = "subscriptions.redrive_policy must be a valid JSON redrive policy document."
  }

  validation {
    condition     = alltrue([for t in var.topics : t.delivery_policy == null || can(jsondecode(t.delivery_policy))])
    error_message = "delivery_policy must be a valid JSON delivery policy document."
  }

  validation {
    condition = alltrue([
      for t in var.topics : t.fifo == false || alltrue([
        for s in t.subscriptions : contains(["sqs", "application", "lambda"], s.protocol)
      ])
    ])
    error_message = "FIFO topics only accept sqs, application and lambda subscription protocols (SNS supports no first-in-first-out delivery to other protocols)."
  }
}
