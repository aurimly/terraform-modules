variable "apis" {
  description = "Map of API Gateway HTTP APIs (v2) keyed by an arbitrary identifier. Each entry creates one aws_apigatewayv2_api with its authorizers, integrations, routes, and optional stage (plus a deployment when the stage opts out of auto_deploy)."
  type = map(object({
    name                         = string
    protocol                     = optional(string, "HTTP")
    description                  = optional(string)
    disable_execute_api_endpoint = optional(bool, false)
    version                      = optional(string)
    ip_address_type              = optional(string)
    route_key                    = optional(string)
    cors_configuration = optional(object({
      allow_credentials = optional(bool)
      allow_headers     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_origins     = optional(list(string))
      expose_headers    = optional(list(string))
      max_age           = optional(number)
    }))
    authorizers = optional(map(object({
      name             = string
      authorizer_type  = optional(string, "JWT")
      identity_sources = list(string)
      jwt_configuration = object({
        audience = optional(list(string), [])
        issuer   = optional(string)
      })
    })), {})
    integrations = optional(map(object({
      integration_type          = string
      integration_uri           = optional(string)
      integration_method        = optional(string)
      integration_subtype       = optional(string)
      passthrough_behavior      = optional(string)
      payload_format_version    = optional(string)
      content_handling_strategy = optional(string)
      timeout_milliseconds      = optional(number)
      request_parameters        = optional(map(string))
      connection_type           = optional(string)
      connection_id             = optional(string)
      credentials_arn           = optional(string)
      description               = optional(string)
      tls_config = optional(object({
        server_name_to_verify = optional(string)
      }))
    })), {})
    routes = optional(map(object({
      route_key                  = string
      integration_key            = string
      authorization_type         = optional(string)
      authorizer_key             = optional(string)
      api_key_required           = optional(bool)
      request_models             = optional(map(string))
      model_selection_expression = optional(string)
      operation_name             = optional(string)
    })), {})
    stage = optional(object({
      name                  = string
      auto_deploy           = optional(bool, true)
      description           = optional(string)
      client_certificate_id = optional(string)
      stage_variables       = optional(map(string))
      access_log_settings = optional(object({
        destination_arn = string
        format          = string
      }))
      default_route_settings = optional(object({
        throttling_burst_limit   = optional(number)
        throttling_rate_limit    = optional(number)
        detailed_metrics_enabled = optional(bool)
        data_trace_enabled       = optional(bool)
        logging_level            = optional(string)
      }))
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for a in var.apis : contains(["HTTP", "WEBSOCKET"], a.protocol)])
    error_message = "protocol must be one of HTTP or WEBSOCKET (case-sensitive) — the API Gateway v2 `protocol_type` values."
  }

  validation {
    condition     = alltrue([for a in var.apis : a.ip_address_type == null || contains(["ipv4", "dualstack"], a.ip_address_type)])
    error_message = "ip_address_type must be one of ipv4 or dualstack."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apis : [
        for i in a.integrations : contains(["AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY", "MOCK"], i.integration_type)
      ]
    ]))
    error_message = "integrations.integration_type must be one of AWS, AWS_PROXY, HTTP, HTTP_PROXY or MOCK (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apis : [
        for i in a.integrations : i.payload_format_version == null || contains(["1.0", "2.0"], tostring(i.payload_format_version))
      ]
    ]))
    error_message = "integrations.payload_format_version must be 1.0 or 2.0."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apis : [
        for i in a.integrations : i.integration_subtype == null || can(regex("^aws-api\\.", i.integration_subtype))
      ]
    ]))
    error_message = "integrations.integration_subtype must be an aws-api.* subtype (service integrations only)."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apis : [
        for i in a.integrations : i.connection_type == null || contains(["INTERNET", "VPC_LINK"], i.connection_type)
      ]
    ]))
    error_message = "integrations.connection_type must be one of INTERNET or VPC_LINK (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apis : [
        for i in a.integrations : i.timeout_milliseconds == null || i.timeout_milliseconds >= 50 && i.timeout_milliseconds <= 30000
      ]
    ]))
    error_message = "integrations.timeout_milliseconds must be between 50 and 30000 (API Gateway v2 upper bound)."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apis : [
        for i in a.integrations : i.passthrough_behavior == null || contains(["WHEN_NO_MATCH", "WHEN_NO_TEMPLATES", "NEVER"], i.passthrough_behavior)
      ]
    ]))
    error_message = "integrations.passthrough_behavior must be one of WHEN_NO_MATCH, WHEN_NO_TEMPLATES or NEVER (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for a in var.apis : a.stage == null || can(regex("^[a-zA-Z0-9-_]{1,128}$", a.stage.name))
    ])
    error_message = "stage.name must be up to 128 characters of alphanumerics, underscores and hyphens (stage naming rules); auto_deploy defaults to true and manages a deployment for you."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apis : [
        for r in a.routes : r.authorization_type == null || contains(["NONE", "JWT"], r.authorization_type)
      ]
    ]))
    error_message = "routes.authorization_type must be one of NONE or JWT (case-sensitive; AWS_IAM and CUSTOM authorizers are out of scope)."
  }

  validation {
    condition = alltrue([
      for a in var.apis : a.stage == null || a.stage.default_route_settings == null || a.stage.default_route_settings.logging_level == null || contains(["OFF", "INFO", "ERROR"], a.stage.default_route_settings.logging_level)
    ])
    error_message = "stage.default_route_settings.logging_level must be one of OFF, INFO or ERROR (case-sensitive)."
  }
}

variable "domain_names" {
  description = "Map of custom domain names keyed by an arbitrary identifier. Certificate is consumer-managed (pair with `aws/acm`); REGIONAL endpoint recommended."
  type = map(object({
    domain_name                            = string
    certificate_arn                        = string
    endpoint_type                          = string
    security_policy                        = string
    ip_address_type                        = optional(string)
    ownership_verification_certificate_arn = optional(string)
    mutual_tls_authentication = optional(object({
      truststore_uri     = string
      truststore_version = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for d in var.domain_names : contains(["REGIONAL", "EDGE"], d.endpoint_type)])
    error_message = "endpoint_type must be one of REGIONAL or EDGE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for d in var.domain_names : d.ip_address_type == null || contains(["ipv4", "dualstack"], d.ip_address_type)])
    error_message = "ip_address_type must be one of ipv4 or dualstack."
  }

  validation {
    condition     = alltrue([for d in var.domain_names : contains(["TLS_1_0", "TLS_1_2", "TLS_1_3"], d.security_policy)])
    error_message = "security_policy must be one of TLS_1_0, TLS_1_2 or TLS_1_3 (prefer TLS_1_2 or TLS_1_3)."
  }
}

variable "api_mappings" {
  description = "Map of API mappings binding an api (by key) to a domain (by key), with an optional path prefix. `stage_name` defaults to the api's stage ($default otherwise). Mappings sharing a domain must have distinct path prefixes (\"\" once)."
  type = map(object({
    api_key         = string
    domain_key      = string
    api_mapping_key = optional(string, "")
    stage_name      = optional(string)
  }))
  default = {}

  validation {
    condition     = length(var.api_mappings) == length(distinct([for k, m in var.api_mappings : "${m.domain_key}.${m.api_mapping_key}"]))
    error_message = "domain_key + api_mapping_key pairs must be unique across api_mappings (two mappings cannot share the same path on one domain)."
  }
}
