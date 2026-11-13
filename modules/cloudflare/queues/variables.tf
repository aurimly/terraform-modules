variable "account_id" {
  description = "Fallback Cloudflare account ID used when a queue omits its own account_id. Must be set if any queue omits account_id. Consumers ride the account of the queue they reference."
  type        = string
  default     = ""
}

variable "queues" {
  description = "Map of Cloudflare Queues keyed by an arbitrary unique identifier. Each entry creates one cloudflare_queue; consumers reference queues by these keys."
  type = map(object({
    queue_name   = string
    account_id   = optional(string)
    jurisdiction = optional(string)
    settings = optional(object({
      delivery_delay           = optional(number)
      delivery_paused          = optional(bool)
      message_retention_period = optional(number)
    }))
  }))

  validation {
    condition = alltrue([
      for key in keys(var.queues) : can(regex("^[^.]+$", key))
    ])
    error_message = "queue map keys must not contain '.' — consumer resource addresses are composed as <queue-key>.<consumer-key>."
  }

  validation {
    condition = alltrue(flatten([
      for key, q in var.queues : [
        for other_key, r in var.queues :
        key == other_key || lower(q.queue_name) != lower(r.queue_name) || ((q.account_id != null && q.account_id != "") ? q.account_id : var.account_id) != ((r.account_id != null && r.account_id != "") ? r.account_id : var.account_id)
      ]
    ]))
    error_message = "queue names must be unique within their account, case-insensitively — two entries sharing a resolved account_id and queue_name conflict at apply."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.jurisdiction == null || contains(["eu", "us", "fedramp"], q.jurisdiction)])
    error_message = "jurisdiction must be one of eu, us or fedramp."
  }

  validation {
    condition     = alltrue([for q in var.queues : length(trimspace(q.queue_name)) > 0])
    error_message = "queue_name must not be empty or whitespace; it is the queue's API identifier."
  }
}

variable "consumers" {
  description = "Map of queue consumers keyed by an arbitrary unique identifier. Each entry creates one cloudflare_queue_consumer attached to the queue named by queue_key. Destination lists (email, pagerduty, webhooks) apply to the \"notification\" consumer type."
  type = map(object({
    queue_key         = string
    type              = string
    script_name       = optional(string)
    dead_letter_queue = optional(string)
    settings = optional(object({
      batch_size             = optional(number)
      max_concurrency        = optional(number)
      max_retries            = optional(number)
      max_wait_time_ms       = optional(number)
      retry_delay            = optional(number)
      visibility_timeout_ms  = optional(number)
      email_destinations     = optional(list(string), [])
      pagerduty_destinations = optional(list(string), [])
      webhook_destinations   = optional(list(string), [])
    }))
  }))

  validation {
    condition = alltrue([
      for key in keys(var.consumers) : can(regex("^[^.]+$", key)) && alltrue([
        for consumer_key, consumer in var.consumers : can(regex("^[^.]+$", consumer.queue_key))
      ])
    ])
    error_message = "consumer map keys and queue_key values must not contain '.' — consumer resource addresses are composed as <queue-key>.<consumer-key>."
  }

  validation {
    condition = alltrue([
      for consumer_key, consumer in var.consumers : contains(keys(var.queues), consumer.queue_key)
    ])
    error_message = "queue_key must name an entry of var.queues — consumers are wired to queues managed by this module; a dangling key fails at plan with this message instead of an index error."
  }

  validation {
    condition     = alltrue([for consumer_key, consumer in var.consumers : contains(["worker", "http_pull", "notification"], consumer.type)])
    error_message = "type must be one of worker, http_pull or notification."
  }

  validation {
    condition = alltrue([
      for consumer_key, consumer in var.consumers : consumer.type != "worker" || consumer.script_name != null && length(trimspace(consumer.script_name)) > 0
    ])
    error_message = "worker consumers must set script_name — the queue delivers batches to that Worker."
  }

  validation {
    condition = alltrue([
      for consumer_key, consumer in var.consumers : consumer.dead_letter_queue == null || length(trimspace(consumer.dead_letter_queue)) > 0
    ])
    error_message = "dead_letter_queue must be a non-empty queue NAME (not an ID) of an existing queue in the same account."
  }
}
