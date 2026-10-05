variable "account_id" {
  description = "Fallback Cloudflare account ID used when a bucket omits its own account_id. Must be set if any bucket omits account_id."
  type        = string
  default     = ""
}

variable "buckets" {
  description = "Map of R2 buckets keyed by an arbitrary unique identifier."
  type = map(object({
    account_id    = optional(string)
    name          = string
    location      = optional(string)
    jurisdiction  = optional(string)
    storage_class = optional(string)
  }))
}
