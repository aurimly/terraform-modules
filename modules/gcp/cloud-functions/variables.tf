variable "functions" {
  description = "Map of Cloud Functions (2nd gen) keyed by an arbitrary identifier. Each entry creates one google_cloudfunctions2_function plus optional IAM bindings."
  type = map(object({
    name            = string
    location        = string
    project_id      = optional(string)
    description     = optional(string)
    labels          = optional(map(string), {})
    kms_key_name    = optional(string)
    deletion_policy = optional(string, "PREVENT")
    build_config = object({
      runtime                 = string
      entrypoint              = optional(string)
      worker_pool             = optional(string)
      service_account         = optional(string)
      docker_repository       = optional(string)
      environment_variables   = optional(map(string), {})
      automatic_update_policy = optional(bool)
      on_deploy_update_policy = optional(bool)
      source = object({
        storage_source = optional(object({
          bucket     = string
          object     = string
          generation = optional(string)
        }))
        repo_source = optional(object({
          project_id   = optional(string)
          repo_name    = optional(string)
          branch_name  = optional(string)
          tag_name     = optional(string)
          commit_sha   = optional(string)
          dir          = optional(string)
          invert_regex = optional(bool)
        }))
      })
    })
    service_config = optional(object({
      min_instance_count               = optional(number)
      max_instance_count               = optional(number)
      available_memory                 = optional(string)
      available_cpu                    = optional(string)
      timeout_seconds                  = optional(number)
      environment_variables            = optional(map(string), {})
      ingress_settings                 = optional(string)
      vpc_connector                    = optional(string)
      vpc_connector_egress_settings    = optional(string)
      service_account_email            = optional(string)
      max_instance_request_concurrency = optional(number)
      all_traffic_on_latest_revision   = optional(bool)
      binary_authorization_policy      = optional(string)
      direct_vpc_egress                = optional(string)
      direct_vpc_network_interface = optional(object({
        network    = optional(string)
        subnetwork = optional(string)
        tags       = optional(list(string), [])
      }))
      secret_environment_variables = optional(list(object({
        key        = string
        project_id = string
        secret     = string
        version    = string
      })), [])
      secret_volumes = optional(list(object({
        mount_path = string
        project_id = string
        secret     = string
        versions = optional(list(object({
          version = string
          path    = string
        })), [])
      })), [])
    }))
    event_trigger = optional(object({
      trigger_region        = optional(string)
      event_type            = string
      pubsub_topic          = optional(string)
      service_account_email = optional(string)
      retry_policy          = optional(string)
      event_filters = optional(list(object({
        attribute = string
        value     = string
        operator  = optional(string)
      })), [])
    }))
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        expression  = string
        description = optional(string)
      }))
    })), {})
  }))

  validation {
    condition     = alltrue([for f in var.functions : can(regex("^[a-z]([-a-z0-9]{2,61}[a-z0-9])$", f.name))])
    error_message = "name must be 4 to 63 characters, start with a letter, and contain only lowercase letters, digits and hyphens (module-level convention; kebab-case keeps the generated Cloud Run service name aligned)."
  }

  validation {
    condition     = alltrue([for f in var.functions : can(regex("^[a-z]+-[a-z]+[0-9]+$", f.location))])
    error_message = "location must be a valid GCP region name (e.g. europe-west1)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", f.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for f in var.functions : contains(["DELETE", "ABANDON", "PREVENT"], f.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.functions : length(f.build_config.runtime) > 0])
    error_message = "build_config.runtime is required (e.g. nodejs20, python312, go122)."
  }

  validation {
    condition     = alltrue([for f in var.functions : (f.build_config.source.storage_source != null) != (f.build_config.source.repo_source != null)])
    error_message = "build_config.source must set exactly one of storage_source or repo_source."
  }

  validation {
    condition     = alltrue([for f in var.functions : !(f.build_config.automatic_update_policy != null && f.build_config.automatic_update_policy && f.build_config.on_deploy_update_policy != null && f.build_config.on_deploy_update_policy)])
    error_message = "build_config.automatic_update_policy and build_config.on_deploy_update_policy are mutually exclusive."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.service_config == null || f.service_config.ingress_settings == null || contains(["ALLOW_ALL", "ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"], f.service_config.ingress_settings)])
    error_message = "service_config.ingress_settings must be one of ALLOW_ALL, ALLOW_INTERNAL_ONLY or ALLOW_INTERNAL_AND_GCLB (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.service_config == null || f.service_config.vpc_connector_egress_settings == null || contains(["VPC_CONNECTOR_EGRESS_SETTINGS_UNSPECIFIED", "PRIVATE_RANGES_ONLY", "ALL_TRAFFIC"], f.service_config.vpc_connector_egress_settings)])
    error_message = "service_config.vpc_connector_egress_settings must be one of VPC_CONNECTOR_EGRESS_SETTINGS_UNSPECIFIED, PRIVATE_RANGES_ONLY or ALL_TRAFFIC (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.service_config == null || f.service_config.direct_vpc_egress == null || contains(["VPC_EGRESS_ALL_TRAFFIC", "VPC_EGRESS_PRIVATE_RANGES_ONLY"], f.service_config.direct_vpc_egress)])
    error_message = "service_config.direct_vpc_egress must be one of VPC_EGRESS_ALL_TRAFFIC or VPC_EGRESS_PRIVATE_RANGES_ONLY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for f in var.functions : f.service_config == null || alltrue([
        f.service_config.vpc_connector == null || (f.service_config.direct_vpc_egress == null && f.service_config.direct_vpc_network_interface == null)
      ])
    ])
    error_message = "service_config.vpc_connector (Serverless VPC Access) and direct VPC egress (direct_vpc_egress / direct_vpc_network_interface) are mutually exclusive."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.event_trigger == null || f.event_trigger.retry_policy == null || contains(["RETRY_POLICY_UNSPECIFIED", "RETRY_POLICY_DO_NOT_RETRY", "RETRY_POLICY_RETRY"], f.event_trigger.retry_policy)])
    error_message = "event_trigger.retry_policy must be one of RETRY_POLICY_UNSPECIFIED, RETRY_POLICY_DO_NOT_RETRY or RETRY_POLICY_RETRY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for f in var.functions : f.event_trigger == null || alltrue([
        for filter in f.event_trigger.event_filters :
        length(filter.attribute) > 0 && length(filter.value) > 0 && (filter.operator == null || filter.operator == "match-path-pattern")
      ])
    ])
    error_message = "event_trigger.event_filters entries need non-empty attribute and value; operator may only be match-path-pattern."
  }

  validation {
    condition     = alltrue([for f in var.functions : length(distinct([for r in f.role_bindings : r.role])) == length(f.role_bindings)])
    error_message = "role_bindings.role must be unique within each function; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for f in var.functions : alltrue([for r in f.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }
}
