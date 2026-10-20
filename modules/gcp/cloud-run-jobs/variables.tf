variable "jobs" {
  description = "Map of Cloud Run jobs keyed by an arbitrary identifier. Each entry creates one google_cloud_run_v2_job plus optional IAM bindings."
  type = map(object({
    name                = string
    location            = string
    project_id          = optional(string)
    launch_stage        = optional(string)
    labels              = optional(map(string), {})
    annotations         = optional(map(string), {})
    tags                = optional(map(string))
    deletion_protection = optional(bool, true)
    deletion_policy     = optional(string)
    binary_authorization = optional(object({
      breakglass_justification = optional(string)
      use_default              = optional(bool)
      policy                   = optional(string)
    }))
    template = object({
      task_count            = optional(number)
      parallelism           = optional(number)
      max_retries           = optional(number)
      timeout               = optional(string)
      service_account       = optional(string)
      encryption_key        = optional(string)
      execution_environment = optional(string)
      node_selector = optional(object({
        accelerator = string
      }))
      vpc_access = optional(object({
        connector = optional(string)
        egress    = optional(string)
        network_interfaces = optional(list(object({
          network    = string
          subnetwork = string
          tags       = optional(list(string), [])
        })), [])
      }))
      containers = list(object({
        name    = optional(string)
        image   = string
        command = optional(list(string))
        args    = optional(list(string))
        env = optional(list(object({
          name  = string
          value = optional(string)
          value_source = optional(object({
            secret_key_ref = object({
              secret  = string
              version = string
            })
          }))
        })), [])
        resources = optional(object({
          limits = optional(map(string), {})
        }))
        ports = optional(list(object({
          name           = optional(string)
          container_port = optional(number, 8080)
        })), [])
        volume_mounts = optional(list(object({
          name       = string
          mount_path = string
          sub_path   = optional(string)
        })), [])
        startup_probe = optional(object({
          initial_delay_seconds = optional(number)
          timeout_seconds       = optional(number)
          period_seconds        = optional(number)
          failure_threshold     = optional(number)
          http_get = optional(object({
            path = optional(string)
            http_headers = optional(list(object({
              name  = string
              value = optional(string)
            })), [])
          }))
          grpc = optional(object({
            port    = optional(number)
            service = optional(string)
          }))
          tcp_socket = optional(object({
            port = optional(number)
          }))
        }))
      }))
      volumes = optional(list(object({
        name = string
        secret = optional(object({
          secret       = string
          default_mode = optional(number)
          items = optional(list(object({
            path    = string
            version = optional(string)
            mode    = optional(number)
          })), [])
        }))
        cloud_sql_instance = optional(object({
          instances = list(string)
        }))
        nfs = optional(object({
          server    = string
          path      = optional(string)
          read_only = optional(bool)
        }))
        gcs = optional(object({
          bucket        = string
          mount_options = optional(list(string))
          read_only     = optional(bool)
        }))
        empty_dir = optional(object({
          medium     = optional(string)
          size_limit = optional(string)
        }))
      })), [])
    })
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
    condition     = alltrue([for j in var.jobs : can(regex("^[a-z]([-a-z0-9]{2,61}[a-z0-9])$", j.name))])
    error_message = "name must be 4 to 63 characters, start with a letter, and contain only lowercase letters, digits and hyphens (Cloud Run naming rules). Immutable; changing forces replacement."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", j.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], j.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.template.execution_environment == null || contains(["EXECUTION_ENVIRONMENT_GEN1", "EXECUTION_ENVIRONMENT_GEN2"], j.template.execution_environment)])
    error_message = "template.execution_environment must be one of EXECUTION_ENVIRONMENT_GEN1 or EXECUTION_ENVIRONMENT_GEN2."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.template.vpc_access == null || j.template.vpc_access.connector == null || length(j.template.vpc_access.network_interfaces) == 0])
    error_message = "vpc_access.connector (serverless connector) and vpc_access.network_interfaces (Direct VPC egress) are mutually exclusive."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.template.vpc_access == null || j.template.vpc_access.egress == null || contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], j.template.vpc_access.egress)])
    error_message = "vpc_access.egress must be one of ALL_TRAFFIC or PRIVATE_RANGES_ONLY."
  }

  validation {
    condition     = alltrue([for j in var.jobs : length(j.template.containers) >= 1])
    error_message = "each job requires at least one container."
  }

  validation {
    condition = alltrue([
      for j in var.jobs : alltrue([
        for c in j.template.containers : alltrue([
          for e in c.env : (e.value != null) != (e.value_source != null)
        ])
      ])
    ])
    error_message = "each env variable must set exactly one of value or value_source."
  }

  validation {
    condition = alltrue([
      for j in var.jobs : alltrue([
        for c in j.template.containers : c.startup_probe == null || length([
          for pt in ["http_get", "grpc", "tcp_socket"] : pt if c.startup_probe[pt] != null
        ]) == 1
      ])
    ])
    error_message = "each startup_probe must set exactly one of http_get, grpc or tcp_socket."
  }

  validation {
    condition = alltrue([
      for j in var.jobs : alltrue([
        for v in j.template.volumes : length([
          for t in ["secret", "cloud_sql_instance", "nfs", "gcs", "empty_dir"] : t if v[t] != null
        ]) == 1
      ])
    ])
    error_message = "each volume must set exactly one of secret, cloud_sql_instance, nfs, gcs or empty_dir."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.template.parallelism == null || j.template.task_count == null || j.template.parallelism <= j.template.task_count])
    error_message = "template.parallelism must not exceed template.task_count."
  }

  validation {
    condition     = alltrue([for j in var.jobs : length(distinct([for r in j.role_bindings : r.role])) == length(j.role_bindings)])
    error_message = "role_bindings.role must be unique within each job; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for j in var.jobs : alltrue([for r in j.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }
}
