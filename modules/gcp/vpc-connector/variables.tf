variable "connectors" {
  description = "Map of Serverless VPC Access connectors keyed by an arbitrary identifier."
  type = map(object({
    name          = string
    region        = optional(string)
    project_id    = optional(string)
    network       = optional(string)
    ip_cidr_range = optional(string)
    subnet = optional(object({
      name       = string
      project_id = optional(string)
    }))
    machine_type    = optional(string)
    min_instances   = optional(number)
    max_instances   = optional(number)
    min_throughput  = optional(number)
    max_throughput  = optional(number)
    deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for k, c in var.connectors : can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", c.name))])
    error_message = "connectors.name must be a lowercase RFC1035 label: lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : length(c.name) <= 25])
    error_message = "connectors.name must be at most 25 characters (the VPC Access connector API limit, unlike the usual 63-character GCP name limit)."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : c.region == null || can(regex("^[a-z]+-[a-z]+[0-9]+$", c.region))])
    error_message = "connectors.region must be a GCP region (e.g. us-central1); omit it to use the provider-level region."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : c.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", c.project_id))])
    error_message = "connectors.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : (c.subnet != null) != (c.ip_cidr_range != null)])
    error_message = "connectors must use exactly one connectivity mode: subnet (shared-VPC subnet) or ip_cidr_range (dedicated range in network), not both."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : c.ip_cidr_range == null || c.network != null])
    error_message = "connectors.network is required when ip_cidr_range is set."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : c.ip_cidr_range == null || can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])/(3[0-2]|[12][0-9]|[0-9])$", c.ip_cidr_range))])
    error_message = "connectors.ip_cidr_range must be an IPv4 CIDR (the API requires a /28 or larger subnet in the network)."
  }

  validation {
    condition = alltrue([
      for k, c in var.connectors : alltrue([
        !((c.min_instances != null) && (c.min_throughput != null)),
        !((c.max_instances != null) && (c.max_throughput != null)),
        (c.min_instances != null) == (c.max_instances != null),
        (c.min_throughput != null) == (c.max_throughput != null),
      ])
    ])
    error_message = "connectors autoscaling must be either instance-based (min_instances and max_instances) or throughput-based (min_throughput and max_throughput); do not mix the two knobs and set the pair only."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : (c.min_instances == null || c.min_instances >= 2) && (c.max_instances == null || c.max_instances >= 3) && (c.min_instances == null || c.max_instances == null || c.min_instances < c.max_instances)])
    error_message = "connectors instances scaling: min_instances 2-9, max_instances 3-10 (API bounds), with min_instances < max_instances."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : (c.min_instances == null || c.min_instances <= 9) && (c.max_instances == null || c.max_instances <= 10)])
    error_message = "connectors instances scaling: min_instances 2-9, max_instances 3-10 (API bounds), with min_instances < max_instances."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : (c.min_throughput == null || (c.min_throughput >= 200 && c.min_throughput <= 900)) && (c.max_throughput == null || (c.max_throughput >= 300 && c.max_throughput <= 1000))])
    error_message = "connectors throughput scaling: min_throughput 200-900, max_throughput 300-1000 (API bounds), with min_throughput < max_throughput."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : (c.min_throughput == null || c.min_throughput % 100 == 0) && (c.max_throughput == null || c.max_throughput % 100 == 0)])
    error_message = "connectors min_throughput and max_throughput must be multiples of 100."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : c.min_throughput == null || c.max_throughput == null || c.min_throughput < c.max_throughput])
    error_message = "connectors throughput scaling: min_throughput 200-900, max_throughput 300-1000 (API bounds), with min_throughput < max_throughput."
  }

  validation {
    condition     = alltrue([for k, c in var.connectors : c.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], c.deletion_policy)])
    error_message = "connectors.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}
