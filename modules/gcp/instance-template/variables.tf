variable "templates" {
  description = "Map of instance templates keyed by an arbitrary identifier. Each entry creates one google_compute_instance_template. Templates are immutable in GCP; use name_prefix for rolling updates behind a managed instance group."
  type = map(object({
    name                    = optional(string)
    name_prefix             = optional(string)
    machine_type            = string
    project_id              = optional(string)
    region                  = optional(string)
    description             = optional(string)
    instance_description    = optional(string)
    labels                  = optional(map(string), {})
    metadata                = optional(map(string))
    metadata_startup_script = optional(string)
    tags                    = optional(list(string))
    can_ip_forward          = optional(bool)
    min_cpu_platform        = optional(string)
    resource_policies       = optional(list(string))
    disks = list(object({
      source_image           = optional(string)
      source_snapshot        = optional(string)
      source                 = optional(string)
      boot                   = optional(bool)
      auto_delete            = optional(bool)
      device_name            = optional(string)
      disk_name              = optional(string)
      disk_type              = optional(string)
      disk_size_gb           = optional(number)
      mode                   = optional(string)
      interface              = optional(string)
      type                   = optional(string)
      labels                 = optional(map(string))
      provisioned_iops       = optional(number)
      provisioned_throughput = optional(number)
      resource_policies      = optional(list(string))
      source_image_encryption_key = optional(object({
        kms_key_self_link       = string
        kms_key_service_account = optional(string)
      }))
      source_snapshot_encryption_key = optional(object({
        kms_key_self_link       = string
        kms_key_service_account = optional(string)
      }))
      disk_encryption_key = optional(object({
        kms_key_self_link       = string
        kms_key_service_account = optional(string)
      }))
    }))
    network_interfaces = list(object({
      network            = optional(string)
      subnetwork         = optional(string)
      subnetwork_project = optional(string)
      network_ip         = optional(string)
      nic_type           = optional(string)
      stack_type         = optional(string)
      queue_count        = optional(number)
      access_config = optional(object({
        nat_ip       = optional(string)
        network_tier = optional(string)
      }))
      ipv6_access_config = optional(object({
        network_tier = optional(string)
      }))
      alias_ip_ranges = optional(list(object({
        ip_cidr_range         = string
        subnetwork_range_name = optional(string)
      })), [])
    }))
    service_account = optional(object({
      email  = optional(string)
      scopes = list(string)
    }))
    scheduling = optional(object({
      automatic_restart           = optional(bool)
      on_host_maintenance         = optional(string)
      preemptible                 = optional(bool)
      provisioning_model          = optional(string)
      instance_termination_action = optional(string)
      node_affinities = optional(list(object({
        key      = string
        operator = string
        values   = list(string)
      })), [])
    }))
    shielded_instance_config = optional(object({
      enable_secure_boot          = optional(bool)
      enable_vtpm                 = optional(bool)
      enable_integrity_monitoring = optional(bool)
    }))
    guest_accelerators = optional(list(object({
      type  = string
      count = number
    })), [])
    advanced_machine_features = optional(object({
      enable_nested_virtualization = optional(bool)
      threads_per_core             = optional(number)
      visible_core_count           = optional(number)
    }))
    confidential_instance_config = optional(object({
      enable_confidential_compute = optional(bool)
      confidential_instance_type  = optional(string)
    }))
    network_performance_config = optional(object({
      total_egress_bandwidth_tier = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for t in var.templates : (t.name == null) != (t.name_prefix == null)])
    error_message = "Exactly one of name or name_prefix must be set."
  }

  validation {
    condition     = alltrue([for t in var.templates : (t.name == null || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", t.name))) && (t.name_prefix == null || can(regex("^[a-z][-a-z0-9]{0,53}$", t.name_prefix)))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035). name_prefix must be 1 to 54 lowercase characters (digits and hyphens allowed) so the generated suffix keeps the full name within 63 characters."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.region == null || can(regex("^[a-z]+-[a-z]+[0-9]+$", t.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", t.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for t in var.templates : length(t.disks) > 0])
    error_message = "disks must be non-empty; every template needs at least one disk entry."
  }

  validation {
    condition     = alltrue([for t in var.templates : alltrue([for d in t.disks : d.disk_type == "local-ssd" || d.source_image != null || d.source_snapshot != null || d.source != null])])
    error_message = "each disks[] entry needs one of source_image, source_snapshot or source; the only exception is a disk_type of local-ssd."
  }

  validation {
    condition     = alltrue([for t in var.templates : length([for d in t.disks : d if d.boot == true]) <= 1])
    error_message = "at most one disks[] entry per template may set boot = true."
  }

  validation {
    condition     = alltrue([for t in var.templates : alltrue([for d in t.disks : (d.disk_name == null || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", d.disk_name))) && (d.mode == null || contains(["READ_WRITE", "READ_ONLY"], d.mode)) && !(d.boot == true && d.mode == "READ_ONLY")])])
    error_message = "disks[].disk_name must be a valid RFC1035 name when set; disks[].mode must be READ_WRITE or READ_ONLY (case-sensitive); boot disks cannot be READ_ONLY."
  }

  validation {
    condition     = alltrue([for t in var.templates : length(t.network_interfaces) > 0 && alltrue([for n in t.network_interfaces : n.network != null || n.subnetwork != null])])
    error_message = "network_interfaces must be non-empty and each interface must set at least one of network or subnetwork."
  }

  validation {
    condition     = alltrue([for t in var.templates : alltrue([for n in t.network_interfaces : n.nic_type == null || contains(["GVNIC", "VIRTIO_NET", "MRDMA", "IRDMA", "IDPF"], n.nic_type)])])
    error_message = "network_interfaces.nic_type must be one of GVNIC, VIRTIO_NET, MRDMA, IRDMA or IDPF (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.templates : alltrue([for n in t.network_interfaces : n.stack_type == null || contains(["IPV4_ONLY", "IPV4_IPV6", "IPV6_ONLY"], n.stack_type)])])
    error_message = "network_interfaces.stack_type must be one of IPV4_ONLY, IPV4_IPV6 or IPV6_ONLY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.templates : alltrue([for n in t.network_interfaces : (n.access_config == null || n.access_config.network_tier == null || contains(["PREMIUM", "FIXED_STANDARD", "STANDARD"], n.access_config.network_tier)) && (n.ipv6_access_config == null || n.ipv6_access_config.network_tier == null || contains(["PREMIUM", "STANDARD"], n.ipv6_access_config.network_tier))])])
    error_message = "access_config.network_tier must be one of PREMIUM, FIXED_STANDARD or STANDARD (case-sensitive); ipv6_access_config.network_tier must be PREMIUM or STANDARD."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.metadata_startup_script == null || t.metadata == null || !contains(keys(t.metadata), "startup-script")])
    error_message = "metadata_startup_script cannot be combined with a startup-script key in metadata."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.service_account == null || length(t.service_account.scopes) > 0])
    error_message = "service_account.scopes must be non-empty when service_account is set (e.g. [\"cloud-platform\"])."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.scheduling == null || alltrue([for s in [t.scheduling] : (s.on_host_maintenance == null || contains(["MIGRATE", "TERMINATE"], s.on_host_maintenance)) && (s.provisioning_model == null || contains(["STANDARD", "SPOT"], s.provisioning_model)) && (s.instance_termination_action == null || (contains(["STOP", "DELETE"], s.instance_termination_action) && s.provisioning_model == "SPOT")) && !(s.preemptible == true && s.automatic_restart == true)])])
    error_message = "scheduling.on_host_maintenance must be MIGRATE or TERMINATE; scheduling.provisioning_model must be STANDARD or SPOT; scheduling.instance_termination_action must be STOP or DELETE and requires provisioning_model SPOT; preemptible cannot be combined with automatic_restart = true."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.scheduling == null || alltrue([for a in t.scheduling.node_affinities : contains(["IN", "NOT_IN"], a.operator)])])
    error_message = "scheduling.node_affinities.operator must be IN or NOT_IN (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.network_performance_config == null || t.network_performance_config.total_egress_bandwidth_tier == null || contains(["TIER_1", "DEFAULT"], t.network_performance_config.total_egress_bandwidth_tier)])
    error_message = "network_performance_config.total_egress_bandwidth_tier must be TIER_1 or DEFAULT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.templates : t.confidential_instance_config == null || t.confidential_instance_config.confidential_instance_type == null || contains(["SEV", "SEV_SNP", "TDX"], t.confidential_instance_config.confidential_instance_type)])
    error_message = "confidential_instance_config.confidential_instance_type must be one of SEV, SEV_SNP or TDX (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.templates : alltrue([for g in t.guest_accelerators : g.count >= 1])])
    error_message = "guest_accelerators[].count must be at least 1."
  }
}
