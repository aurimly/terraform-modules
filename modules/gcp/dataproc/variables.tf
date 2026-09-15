variable "clusters" {
  description = "Map of Dataproc clusters keyed by an arbitrary identifier. Each entry creates one google_dataproc_cluster with an optional GA cluster_config, plus optional IAM bindings. Dataproc on GKE virtual clusters are out of scope."
  type = map(object({
    name                          = string
    region                        = string
    project_id                    = optional(string)
    labels                        = optional(map(string), {})
    deletion_policy               = optional(string)
    graceful_decommission_timeout = optional(string)
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })), {})
    cluster_config = optional(object({
      staging_bucket = optional(string)
      temp_bucket    = optional(string)
      cluster_tier   = optional(string)
      engine         = optional(string)
      gce_cluster_config = optional(object({
        zone                   = optional(string)
        network                = optional(string)
        subnetwork             = optional(string)
        service_account        = optional(string)
        service_account_scopes = optional(list(string))
        tags                   = optional(list(string))
        internal_ip_only       = optional(bool)
        metadata               = optional(map(string))
        shielded_instance_config = optional(object({
          enable_secure_boot          = optional(bool)
          enable_vtpm                 = optional(bool)
          enable_integrity_monitoring = optional(bool)
        }))
      }))
      master_config = optional(object({
        num_instances    = optional(number)
        machine_type     = optional(string)
        min_cpu_platform = optional(string)
        disk_config = optional(object({
          boot_disk_type                   = optional(string)
          boot_disk_size_gb                = optional(number)
          boot_disk_provisioned_iops       = optional(number)
          boot_disk_provisioned_throughput = optional(number)
          num_local_ssds                   = optional(number)
          local_ssd_interface              = optional(string)
        }))
        accelerators = optional(list(object({
          accelerator_type  = string
          accelerator_count = number
        })), [])
      }))
      worker_config = optional(object({
        num_instances     = optional(number)
        machine_type      = optional(string)
        min_cpu_platform  = optional(string)
        min_num_instances = optional(number)
        disk_config = optional(object({
          boot_disk_type                   = optional(string)
          boot_disk_size_gb                = optional(number)
          boot_disk_provisioned_iops       = optional(number)
          boot_disk_provisioned_throughput = optional(number)
          num_local_ssds                   = optional(number)
          local_ssd_interface              = optional(string)
        }))
        accelerators = optional(list(object({
          accelerator_type  = string
          accelerator_count = number
        })), [])
      }))
      preemptible_worker_config = optional(object({
        num_instances  = optional(number)
        preemptibility = optional(string)
        disk_config = optional(object({
          boot_disk_type    = optional(string)
          boot_disk_size_gb = optional(number)
          num_local_ssds    = optional(number)
        }))
      }))
      software_config = optional(object({
        image_version       = optional(string)
        override_properties = optional(map(string), {})
        optional_components = optional(list(string))
      }))
      initialization_actions = optional(list(object({
        script      = string
        timeout_sec = optional(number)
      })), [])
      encryption_config = optional(object({
        kms_key_name = string
      }))
      lifecycle_config = optional(object({
        idle_delete_ttl  = optional(string)
        auto_delete_time = optional(string)
      }))
      autoscaling_config = optional(object({
        policy_uri = string
      }))
    }))
  }))

  validation {
    condition     = alltrue([for k, c in var.clusters : can(regex("^[a-z][a-z0-9-]{0,50}$", c.name))])
    error_message = "name must be up to 51 characters, start with a lowercase letter and contain only lowercase letters, digits and hyphens (Dataproc cluster names cannot contain underscores or uppercase letters)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : can(regex("^[a-z]+-[a-z]+[0-9]+$", c.region))])
    error_message = "region must be a valid GCP region name (e.g. europe-west1). Requiring region here is deliberate; the provider default region (global) is rarely what anyone wants."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", c.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], c.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.cluster_config == null || c.cluster_config.preemptible_worker_config == null || c.cluster_config.preemptible_worker_config.preemptibility == null ||
      contains(["PREEMPTIBLE", "NON_PREEMPTIBLE", "SPOT", "PREEMPTIBILITY_UNSPECIFIED"], c.cluster_config.preemptible_worker_config.preemptibility)
    ])
    error_message = "cluster_config.preemptible_worker_config.preemptibility must be one of PREEMPTIBLE, NON_PREEMPTIBLE, SPOT or PREEMPTIBILITY_UNSPECIFIED (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.cluster_config == null || c.cluster_config.gce_cluster_config == null || c.cluster_config.gce_cluster_config.network == null || c.cluster_config.gce_cluster_config.subnetwork == null
    ])
    error_message = "cluster_config.gce_cluster_config: network conflicts with subnetwork; set one of the two, not both."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.cluster_config == null ||
      alltrue([
        for g in concat(
          c.cluster_config.master_config != null ? [c.cluster_config.master_config] : [],
          c.cluster_config.worker_config != null ? [c.cluster_config.worker_config] : []
        ) : alltrue([for a in concat(g.accelerators, []) : a.accelerator_count >= 0])
      ])
    ])
    error_message = "accelerators.accelerator_count must not be negative."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.cluster_config == null ||
      alltrue([
        for g in concat(
          c.cluster_config.master_config != null ? [c.cluster_config.master_config] : [],
          c.cluster_config.worker_config != null ? [c.cluster_config.worker_config] : [],
          c.cluster_config.preemptible_worker_config != null ? [c.cluster_config.preemptible_worker_config] : []
        ) : alltrue([for d in concat(g.disk_config != null ? [g.disk_config] : [], []) : (d.num_local_ssds == null || d.num_local_ssds >= 0)])
      ])
    ])
    error_message = "disk_config.num_local_ssds must not be negative."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.cluster_config == null || c.cluster_config.lifecycle_config == null ||
      c.cluster_config.lifecycle_config.idle_delete_ttl == null || can(regex("^[0-9]+(\\.[0-9]+)?s$", c.cluster_config.lifecycle_config.idle_delete_ttl))
    ])
    error_message = "cluster_config.lifecycle_config.idle_delete_ttl must be a duration string in seconds terminated by 's' (e.g. 600s)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : length(distinct([for b in c.role_bindings : b.role])) == length(c.role_bindings)])
    error_message = "role_bindings.role must be unique within each cluster; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.role_bindings : length(b.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }

  validation {
    condition     = alltrue([for k in keys(var.clusters) : !can(regex("/", k))])
    error_message = "cluster keys must not contain '/'; it is used as a composite-key separator in the IAM binding outputs."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for bk in keys(c.role_bindings) : !can(regex("/", bk))])])
    error_message = "role_bindings keys must not contain '/'; it is used as a composite-key separator in outputs."
  }
}
