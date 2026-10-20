variable "account_id" {
  description = "Fallback Cloudflare account ID used when a project omits its own account_id. Must be set if any project omits account_id."
  type        = string
  default     = ""
}

variable "projects" {
  description = "Map of Pages projects keyed by an arbitrary unique identifier."
  type = map(object({
    name              = string
    production_branch = string
    account_id        = optional(string)
    build_config = optional(object({
      build_caching       = optional(bool)
      build_command       = optional(string)
      destination_dir     = optional(string)
      root_dir            = optional(string)
      web_analytics_tag   = optional(string)
      web_analytics_token = optional(string)
    }))
    source = optional(object({
      type = string
      config = object({
        owner                          = optional(string)
        owner_id                       = optional(string)
        repo_name                      = optional(string)
        repo_id                        = optional(string)
        production_branch              = optional(string)
        pr_comments_enabled            = optional(bool)
        preview_deployment_setting     = optional(string)
        preview_branch_includes        = optional(list(string))
        preview_branch_excludes        = optional(list(string))
        path_includes                  = optional(list(string))
        path_excludes                  = optional(list(string))
        production_deployments_enabled = optional(bool)
      })
    }))
    deployment_configs = optional(object({
      preview = optional(object({
        compatibility_date                   = optional(string)
        compatibility_flags                  = optional(list(string), [])
        always_use_latest_compatibility_date = optional(bool)
        env_vars = optional(map(object({
          type  = string
          value = string
        })))
        build_image_major_version = optional(number)
        fail_open                 = optional(bool)
        limits = optional(object({
          cpu_ms = optional(number)
        }))
        placement = optional(object({
          mode = optional(string)
        }))
        kv_namespaces = optional(map(object({
          namespace_id = string
        })))
        r2_buckets = optional(map(object({
          name         = string
          jurisdiction = optional(string)
        })))
        d1_databases = optional(map(object({
          id = string
        })))
        durable_object_namespaces = optional(map(object({
          namespace_id = string
        })))
        hyperdrive_bindings = optional(map(object({
          id = string
        })))
        queue_producers = optional(map(object({
          name = string
        })))
        services = optional(map(object({
          service     = string
          entrypoint  = optional(string)
          environment = optional(string)
        })))
        mtls_certificates = optional(map(object({
          certificate_id = string
        })))
        analytics_engine_datasets = optional(map(object({
          dataset = string
        })))
        vectorize_bindings = optional(map(object({
          index_name = string
        })))
        ai_bindings = optional(map(object({
          project_id = string
        })))
        browsers = optional(map(object({})))
      }))
      production = optional(object({
        compatibility_date                   = optional(string)
        compatibility_flags                  = optional(list(string), [])
        always_use_latest_compatibility_date = optional(bool)
        env_vars = optional(map(object({
          type  = string
          value = string
        })))
        build_image_major_version = optional(number)
        fail_open                 = optional(bool)
        limits = optional(object({
          cpu_ms = optional(number)
        }))
        placement = optional(object({
          mode = optional(string)
        }))
        kv_namespaces = optional(map(object({
          namespace_id = string
        })))
        r2_buckets = optional(map(object({
          name         = string
          jurisdiction = optional(string)
        })))
        d1_databases = optional(map(object({
          id = string
        })))
        durable_object_namespaces = optional(map(object({
          namespace_id = string
        })))
        hyperdrive_bindings = optional(map(object({
          id = string
        })))
        queue_producers = optional(map(object({
          name = string
        })))
        services = optional(map(object({
          service     = string
          entrypoint  = optional(string)
          environment = optional(string)
        })))
        mtls_certificates = optional(map(object({
          certificate_id = string
        })))
        analytics_engine_datasets = optional(map(object({
          dataset = string
        })))
        vectorize_bindings = optional(map(object({
          index_name = string
        })))
        ai_bindings = optional(map(object({
          project_id = string
        })))
        browsers = optional(map(object({})))
      }))
    }))
    domains = optional(list(string), [])
  }))

  validation {
    condition     = alltrue([for p in var.projects : can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", p.name))])
    error_message = "name must contain only lowercase letters, digits and hyphens, start and end with a letter or digit. It is part of the project's identity and import ID; renaming forces project replacement."
  }

  validation {
    condition     = alltrue([for p in var.projects : p.source == null || contains(["github", "gitlab"], p.source.type)])
    error_message = "source.type must be one of github or gitlab."
  }

  validation {
    condition = alltrue([
      for p in var.projects : p.source == null || p.source.config == null || p.source.config.preview_deployment_setting == null ||
      contains(["all", "none", "custom"], p.source.config.preview_deployment_setting)
    ])
    error_message = "source.config.preview_deployment_setting must be one of all, none or custom."
  }

  validation {
    condition = alltrue([
      for p in var.projects : p.source == null || p.source.config == null ||
      (p.source.config.preview_deployment_setting == "custom" ||
        (length(coalesce(p.source.config.preview_branch_includes, [])) == 0 &&
      length(coalesce(p.source.config.preview_branch_excludes, [])) == 0))
    ])
    error_message = "source.config.preview_branch_includes and preview_branch_excludes can only be used with preview_deployment_setting = \"custom\"."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.projects : [
        for side in try([p.deployment_configs.preview, p.deployment_configs.production], []) :
        [
          for e in coalesce(try(side.env_vars, {}), {}) : contains(["plain_text", "secret_text"], e.type)
        ]
      ]
    ]))
    error_message = "deployment_configs env_vars type must be one of plain_text or secret_text."
  }

  validation {
    condition     = length(distinct(flatten([for p in var.projects : p.domains]))) == length(flatten([for p in var.projects : p.domains]))
    error_message = "each custom domain may be attached to at most one project; remove duplicate domains across projects."
  }
}
