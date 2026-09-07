variable "instances" {
  description = "Map of compute instances keyed by an arbitrary identifier. Each entry creates one google_compute_instance plus optional additional disks and IAM bindings."
  type = map(object({
    name                      = string
    zone                      = string
    machine_type              = string
    project_id                = optional(string)
    description               = optional(string)
    hostname                  = optional(string)
    can_ip_forward            = optional(bool)
    allow_stopping_for_update = optional(bool)
    deletion_protection       = optional(bool)
    min_cpu_platform          = optional(string)
    tags                      = optional(list(string))
    labels                    = optional(map(string), {})
    metadata                  = optional(map(string))
    metadata_startup_script   = optional(string)
    boot_disk = object({
      image       = optional(string)
      source      = optional(string)
      type        = optional(string)
      size        = optional(number)
      labels      = optional(map(string))
      auto_delete = optional(bool, true)
      device_name = optional(string)
      mode        = optional(string)
    })
    disks = optional(list(object({
      name        = string
      size        = optional(number)
      type        = optional(string)
      description = optional(string)
      labels      = optional(map(string))
      mode        = optional(string)
      device_name = optional(string)
    })), [])
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
    iam_role_bindings = optional(map(object({
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
    condition     = alltrue([for i in var.instances : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", i.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", i.zone))])
    error_message = "zone must look like a GCP zone name (e.g. us-central1-a); it is a shape check, not a list of valid zones."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", i.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for i in var.instances : (i.boot_disk.image != null) != (i.boot_disk.source != null)])
    error_message = "boot_disk needs exactly one of image (a new disk is created from it) or source (an existing disk is attached)."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.boot_disk.mode == null || i.boot_disk.mode == "READ_WRITE"])
    error_message = "boot_disk.mode must be READ_WRITE; boot disks cannot be READ_ONLY."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for d in i.disks : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", d.name))]) && length(distinct([for d in i.disks : d.name])) == length(i.disks)])
    error_message = "disks[].name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035); disk names must be distinct within an entry."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for d in i.disks : (d.mode == null || contains(["READ_WRITE", "READ_ONLY"], d.mode)) && (d.size == null || d.size > 0)])])
    error_message = "disks[].mode must be READ_WRITE or READ_ONLY (case-sensitive); disks[].size must be greater than 0 when set."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.network_interfaces) > 0])
    error_message = "network_interfaces must be non-empty; every instance needs at least one interface."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for n in i.network_interfaces : n.network != null || n.subnetwork != null])])
    error_message = "each network_interfaces entry must set at least one of network or subnetwork."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for n in i.network_interfaces : n.nic_type == null || contains(["GVNIC", "VIRTIO_NET", "MRDMA", "IRDMA", "IDPF"], n.nic_type)])])
    error_message = "network_interfaces.nic_type must be one of GVNIC, VIRTIO_NET, MRDMA, IRDMA or IDPF (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for n in i.network_interfaces : n.stack_type == null || contains(["IPV4_ONLY", "IPV4_IPV6", "IPV6_ONLY"], n.stack_type)])])
    error_message = "network_interfaces.stack_type must be one of IPV4_ONLY, IPV4_IPV6 or IPV6_ONLY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for n in i.network_interfaces : (n.access_config == null || n.access_config.network_tier == null || contains(["PREMIUM", "FIXED_STANDARD", "STANDARD"], n.access_config.network_tier)) && (n.ipv6_access_config == null || n.ipv6_access_config.network_tier == null || contains(["PREMIUM", "STANDARD"], n.ipv6_access_config.network_tier))])])
    error_message = "access_config.network_tier must be one of PREMIUM, FIXED_STANDARD or STANDARD (case-sensitive); ipv6_access_config.network_tier must be PREMIUM or STANDARD."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.metadata_startup_script == null || i.metadata == null || !contains(keys(i.metadata), "startup-script")])
    error_message = "metadata_startup_script cannot be combined with a startup-script key in metadata."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.service_account == null || length(i.service_account.scopes) > 0])
    error_message = "service_account.scopes must be non-empty when service_account is set (e.g. [\"cloud-platform\"])."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.scheduling == null || alltrue([for s in [i.scheduling] : (s.on_host_maintenance == null || contains(["MIGRATE", "TERMINATE"], s.on_host_maintenance)) && (s.provisioning_model == null || contains(["STANDARD", "SPOT"], s.provisioning_model)) && (s.instance_termination_action == null || (contains(["STOP", "DELETE"], s.instance_termination_action) && s.provisioning_model == "SPOT")) && !(s.preemptible == true && s.automatic_restart == true)])])
    error_message = "scheduling.on_host_maintenance must be MIGRATE or TERMINATE; scheduling.provisioning_model must be STANDARD or SPOT; scheduling.instance_termination_action must be STOP or DELETE and requires provisioning_model SPOT; preemptible cannot be combined with automatic_restart = true."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.scheduling == null || alltrue([for a in i.scheduling.node_affinities : contains(["IN", "NOT_IN"], a.operator)])])
    error_message = "scheduling.node_affinities.operator must be IN or NOT_IN (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : (i.network_performance_config == null || i.network_performance_config.total_egress_bandwidth_tier == null || contains(["TIER_1", "DEFAULT"], i.network_performance_config.total_egress_bandwidth_tier)) && (i.confidential_instance_config == null || i.confidential_instance_config.confidential_instance_type == null || contains(["SEV", "SEV_SNP", "TDX"], i.confidential_instance_config.confidential_instance_type)) && alltrue([for g in i.guest_accelerators : g.count >= 1])])
    error_message = "network_performance_config.total_egress_bandwidth_tier must be TIER_1 or DEFAULT (case-sensitive); confidential_instance_config.confidential_instance_type must be one of SEV, SEV_SNP or TDX; guest_accelerators[].count must be at least 1."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(distinct([for r in i.iam_role_bindings : r.role])) == length(i.iam_role_bindings)])
    error_message = "iam_role_bindings.role must be unique within each instance; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for r in i.iam_role_bindings : length(r.members) > 0])])
    error_message = "iam_role_bindings.members must contain at least one member."
  }
}
