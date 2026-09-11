variable "services" {
  description = "Map of Cloud Run services keyed by an arbitrary identifier. Each entry creates one google_cloud_run_v2_service plus optional IAM bindings."
  type = map(object({
    name                 = string
    location             = string
    project_id           = optional(string)
    description          = optional(string)
    ingress              = optional(string)
    launch_stage         = optional(string)
    labels               = optional(map(string), {})
    annotations          = optional(map(string), {})
    deletion_protection  = optional(bool, true)
    default_uri_disabled = optional(bool)
    custom_audiences     = optional(list(string))
    binary_authorization = optional(object({
      breakglass_justification = optional(string)
      use_default              = optional(bool)
      policy                   = optional(string)
    }))
    template = object({
      encryption_key                   = optional(string)
      service_account                  = optional(string)
      timeout                          = optional(string)
      max_instance_request_concurrency = optional(number)
      scaling = optional(object({
        min_instance_count = optional(number)
        max_instance_count = optional(number)
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
            secret_key_ref = optional(object({
              secret  = string
              version = optional(string)
            }))
          }))
        })), [])
        resources = optional(object({
          limits            = optional(map(string), {})
          startup_cpu_boost = optional(bool)
          cpu_idle          = optional(bool)
        }))
        ports = optional(list(object({
          name           = optional(string)
          container_port = optional(number, 8080)
        })), [])
        volume_mounts = optional(list(object({
          name       = string
          mount_path = string
        })), [])
        startup_probe = optional(object({
          timeout_seconds   = optional(number)
          period_seconds    = optional(number)
          failure_threshold = optional(number)
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
        liveness_probe = optional(object({
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
    traffic = optional(list(object({
      percent  = number
      type     = optional(string)
      revision = optional(string)
      tag      = optional(string)
    })), [])
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
    condition     = alltrue([for s in var.services : can(regex("^[a-z]([-a-z0-9]{2,61}[a-z0-9])$", s.name))])
    error_message = "name must be 4 to 63 characters, start with a letter, and contain only lowercase letters, digits and hyphens (Cloud Run naming rules). Immutable; changing forces replacement."
  }

  validation {
    condition     = alltrue([for s in var.services : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for s in var.services : s.ingress == null || contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], s.ingress)])
    error_message = "ingress must be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }

  validation {
    condition     = alltrue([for s in var.services : s.template.vpc_access == null || s.template.vpc_access.connector == null || length(s.template.vpc_access.network_interfaces) == 0])
    error_message = "vpc_access.connector (serverless connector) and vpc_access.network_interfaces (Direct VPC egress) are mutually exclusive."
  }

  validation {
    condition     = alltrue([for s in var.services : s.template.vpc_access == null || s.template.vpc_access.egress == null || contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], s.template.vpc_access.egress)])
    error_message = "vpc_access.egress must be one of ALL_TRAFFIC or PRIVATE_RANGES_ONLY."
  }

  validation {
    condition     = alltrue([for s in var.services : length(s.template.containers) >= 1])
    error_message = "each service requires at least one container."
  }

  validation {
    condition = alltrue([
      for s in var.services : alltrue([
        for c in s.template.containers : alltrue([
          for e in c.env : (e.value != null) != (e.value_source != null)
        ])
      ])
    ])
    error_message = "each env variable must set exactly one of value or value_source."
  }

  validation {
    condition = alltrue([
      for s in var.services : alltrue([
        for c in s.template.containers : alltrue(flatten([
          for p in [c.startup_probe, c.liveness_probe] : p == null ? [] : [length([
            for pt in ["http_get", "grpc", "tcp_socket"] : pt if p[pt] != null
          ]) == 1]
        ]))
      ])
    ])
    error_message = "each probe must set exactly one of http_get, grpc or tcp_socket."
  }

  validation {
    condition = alltrue([
      for s in var.services : alltrue([
        for v in s.template.volumes : length([
          for t in ["secret", "cloud_sql_instance", "nfs", "gcs", "empty_dir"] : t if v[t] != null
        ]) == 1
      ])
    ])
    error_message = "each volume must set exactly one of secret, cloud_sql_instance, nfs, gcs or empty_dir."
  }

  validation {
    condition = alltrue([
      for s in var.services : alltrue(flatten([
        for t in s.traffic : [
          t.percent >= 0 && t.percent <= 100,
          t.type == null || contains(["TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST", "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"], t.type),
          t.type != "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION" || t.revision != null,
        ]
      ]))
    ])
    error_message = "traffic.percent must be 0 to 100; type must be one of TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST or TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION, and REVISION requires revision to be set."
  }

  validation {
    condition     = alltrue([for s in var.services : length(s.traffic) == 0 || sum([for t in s.traffic : t.percent]) == 100])
    error_message = "traffic percent values must sum to 100 per service."
  }

  validation {
    condition     = alltrue([for s in var.services : length(distinct([for r in s.role_bindings : r.role])) == length(s.role_bindings)])
    error_message = "role_bindings.role must be unique within each service; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for s in var.services : alltrue([for r in s.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }
}
