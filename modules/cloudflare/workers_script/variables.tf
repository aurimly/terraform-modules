variable "account_id" {
  description = "Cloudflare account ID that owns the Workers."
  type        = string
}

variable "workers" {
  description = "Map of Workers keyed by an arbitrary unique identifier. Manages the Worker record only — script content, versions, bindings and deployments stay with wrangler/CI. Terraform owns the record-level knobs declared below; omitted knobs reset to their defaults."
  type = map(object({
    name    = string
    logpush = optional(bool)
    tags    = optional(set(string), [])
    subdomain = optional(object({
      enabled          = optional(bool)
      previews_enabled = optional(bool)
    }))
    tail_consumers = optional(set(string), [])
    observability = optional(object({
      enabled            = optional(bool)
      head_sampling_rate = optional(number)
      logs = optional(object({
        enabled            = optional(bool)
        head_sampling_rate = optional(number)
        destinations       = optional(list(string))
        invocation_logs    = optional(bool)
        persist            = optional(bool)
      }))
      traces = optional(object({
        enabled            = optional(bool)
        head_sampling_rate = optional(number)
        destinations       = optional(list(string))
        persist            = optional(bool)
        propagation_policy = optional(string)
      }))
    }))
  }))
}
