variable "zone_id" {
  description = "Cloudflare zone ID the rulesets belong to."
  type        = string
}

variable "rulesets" {
  description = "Map of zone-level custom rulesets keyed by an arbitrary unique identifier. One ruleset per phase (Cloudflare allows a single custom ruleset per phase entrypoint). Rules is an ordered list — evaluation order matters."
  type = map(object({
    phase       = string
    name        = string
    description = optional(string)
    rules = optional(list(object({
      action      = string
      expression  = string
      description = optional(string)
      enabled     = optional(bool)
      ref         = optional(string)
      logging = optional(object({
        enabled = optional(bool)
      }))
      ratelimit = optional(object({
        characteristics            = list(string)
        period                     = number
        requests_per_period        = optional(number)
        mitigation_timeout         = optional(number)
        counting_expression        = optional(string)
        requests_to_origin         = optional(bool)
        score_per_period           = optional(number)
        score_response_header_name = optional(string)
      }))
      exposed_credential_check = optional(object({
        username_expression = string
        password_expression = string
      }))
      action_parameters = optional(object({
        overrides = optional(object({
          enabled           = optional(bool)
          action            = optional(string)
          sensitivity_level = optional(string)
          rules = optional(list(object({
            id                = string
            enabled           = optional(bool)
            action            = optional(string)
            score_threshold   = optional(number)
            sensitivity_level = optional(string)
          })))
          categories = optional(list(object({
            category          = string
            enabled           = optional(bool)
            action            = optional(string)
            sensitivity_level = optional(string)
          })))
        }))
        matched_data = optional(object({
          public_key = string
        }))
        response = optional(object({
          content      = string
          content_type = string
          status_code  = number
        }))
        id          = optional(string)
        phases      = optional(list(string))
        rulesets    = optional(list(string))
        rules       = optional(map(list(string)))
        host_header = optional(string)
        sni = optional(object({
          value = string
        }))
        origin = optional(object({
          host = optional(string)
          port = optional(number)
        }))
        uri = optional(object({
          path  = optional(object({ value = optional(string), expression = optional(string) }))
          query = optional(object({ value = optional(string), expression = optional(string) }))
        }))
        headers = optional(map(object({
          operation  = string
          value      = optional(string)
          expression = optional(string)
        })))
        request_fields             = optional(list(object({ name = string })))
        response_fields            = optional(list(object({ name = string, preserve_duplicates = optional(bool) })))
        transformed_request_fields = optional(list(object({ name = string })))
        cookie_fields              = optional(list(object({ name = string })))
        from_value = optional(object({
          target_url = object({
            value      = optional(string)
            expression = optional(string)
          })
          status_code           = optional(number)
          preserve_query_string = optional(bool)
        }))
        from_list = optional(object({
          name = string
          key  = string
        }))
      }))
    })))
  }))
}
