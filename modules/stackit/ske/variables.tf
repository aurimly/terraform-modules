variable "clusters" {
  description = "Map of STACKIT Kubernetes Engine (SKE) clusters keyed by an arbitrary identifier. Each entry creates one cluster with node pools and, if the entry sets kubeconfig, one short-lived kubeconfig."
  type = map(object({
    name                   = string
    project_id             = string
    region                 = optional(string)
    kubernetes_version_min = optional(string)
    node_pools = map(object({
      name                    = string
      machine_type            = string
      availability_zones      = list(string)
      minimum                 = number
      maximum                 = number
      allow_system_components = optional(bool)
      cri                     = optional(string)
      os_name                 = optional(string)
      os_version_min          = optional(string)
      max_surge               = optional(number)
      max_unavailable         = optional(number)
      volume_type             = optional(string)
      volume_size             = optional(number)
      labels                  = optional(map(string))
      taints = optional(list(object({
        key    = string
        effect = string
        value  = optional(string)
      })))
    }))
    access = optional(object({
      idp = optional(object({
        enabled = optional(bool)
        type    = optional(string)
      }))
    }))
    audit = optional(object({
      enabled = optional(bool)
    }))
    extensions = optional(object({
      acl = optional(object({
        enabled       = bool
        allowed_cidrs = list(string)
      }))
      dns = optional(object({
        enabled     = bool
        gateway_api = optional(bool)
        zones       = optional(list(string))
      }))
      observability = optional(object({
        enabled     = bool
        instance_id = optional(string)
      }))
      application_load_balancer = optional(object({
        enabled = bool
      }))
    }))
    hibernations = optional(list(object({
      start    = string
      end      = string
      timezone = optional(string)
    })))
    maintenance = optional(object({
      enable_kubernetes_version_updates    = optional(bool)
      enable_machine_image_version_updates = optional(bool)
      start                                = optional(string)
      end                                  = optional(string)
    }))
    network = optional(object({
      id = optional(string)
      control_plane = optional(object({
        access_scope = optional(string)
      }))
    }))
    kubeconfig = optional(object({
      expiration     = optional(number)
      refresh        = optional(bool)
      refresh_before = optional(number)
    }))
  }))

  validation {
    condition     = alltrue([for c in var.clusters : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", c.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for c in var.clusters : !can(regex(",", c.name))])
    error_message = "name must not contain a comma (the cluster import ID is comma-joined)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.kubernetes_version_min == null || can(regex("^\\d+\\.\\d+$", c.kubernetes_version_min)) || can(regex("^\\d+\\.\\d+\\.\\d+$", c.kubernetes_version_min))])
    error_message = "kubernetes_version_min must be a version: major.minor (e.g. 1.31) or full semver (e.g. 1.31.1)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : alltrue([for np in c.node_pools : np.os_version_min == null || can(regex("^\\d+\\.\\d+$", np.os_version_min)) || can(regex("^\\d+\\.\\d+\\.\\d+$", np.os_version_min))])])
    error_message = "node_pools os_version_min must be a version: major.minor (e.g. 1.31) or full semver (e.g. 1.31.1)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : alltrue([for np in c.node_pools : np.minimum >= 0 && np.maximum >= np.minimum])])
    error_message = "node_pools minimum must be 0 or greater, and maximum must be greater than or equal to minimum."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : alltrue([
        for np in c.node_pools : !(np.max_surge == null && np.max_unavailable == null) &&
        (np.max_surge == null || (np.max_surge > 0 && np.max_surge >= length(np.availability_zones))) &&
        (np.max_unavailable == null || (np.max_unavailable > 0 && np.max_unavailable >= length(np.availability_zones)))
      ])
    ])
    error_message = "node_pools max_surge and max_unavailable cannot both be unset; each set value must be greater than 0 and at least the number of availability_zones (API rule)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : length(distinct([for np in c.node_pools : np.name])) == length(c.node_pools)])
    error_message = "node_pools names must be unique within a cluster (the API identifies pools by name)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : alltrue([for np in c.node_pools : np.taints == null || alltrue([for t in np.taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], t.effect)])])])
    error_message = "node_pools taints effect must be one of NoSchedule, PreferNoSchedule or NoExecute."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.access == null || c.access.idp == null || c.access.idp.type == null || c.access.idp.type == "stackit"])
    error_message = "access.idp.type must be \"stackit\"."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : c.extensions == null || c.extensions.acl == null ||
      alltrue([for cidr in c.extensions.acl.allowed_cidrs : can(cidrnetmask(cidr))])
    ])
    error_message = "extensions.acl.allowed_cidrs entries must be valid IPv4 CIDRs (e.g. 10.1.0.0/16)."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : c.extensions == null || c.extensions.observability == null ||
      !(c.extensions.observability.enabled == true && c.extensions.observability.instance_id == null)
    ])
    error_message = "extensions.observability.instance_id must be set when extensions.observability.enabled is true."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.maintenance == null || ((c.maintenance.start == null) == (c.maintenance.end == null))])
    error_message = "maintenance start and end must be set together (mirrors the provider rule)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.maintenance == null || (c.maintenance.start == null || can(regex("^\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})?$", c.maintenance.start)))])
    error_message = "maintenance start must be an RFC3339 full-time (e.g. 01:23:45Z)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.maintenance == null || (c.maintenance.end == null || can(regex("^\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})?$", c.maintenance.end)))])
    error_message = "maintenance end must be an RFC3339 full-time (e.g. 02:23:45Z)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.network == null || c.network.id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", c.network.id))])
    error_message = "network.id must be a network UUID."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.network == null || c.network.control_plane == null || c.network.control_plane.access_scope == null || contains(["PUBLIC", "SNA"], c.network.control_plane.access_scope)])
    error_message = "network.control_plane.access_scope must be one of PUBLIC or SNA."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.kubeconfig == null || c.kubeconfig.expiration == null || c.kubeconfig.expiration > 0])
    error_message = "kubeconfig.expiration must be greater than 0."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.kubeconfig == null || c.kubeconfig.refresh_before == null || c.kubeconfig.refresh == true])
    error_message = "kubeconfig.refresh_before requires kubeconfig.refresh = true (the module is stricter than the provider here: upstream silently ignores refresh_before without refresh)."
  }
}
