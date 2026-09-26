variable "redis_clusters" {
  description = "Map of ElastiCache Redis/Valkey replication groups keyed by an arbitrary identifier. Each entry creates one aws_elasticache_replication_group plus optional subnet and parameter groups."
  type = map(object({
    replication_group_id = string
    description          = optional(string, "Managed by Terraform")
    engine               = optional(string, "redis")
    engine_version       = optional(string)
    node_type            = string
    port                 = optional(number)

    num_cache_clusters          = optional(number)
    preferred_cache_cluster_azs = optional(list(string))
    num_node_groups             = optional(number)
    replicas_per_node_group     = optional(number)

    automatic_failover_enabled = optional(bool)
    multi_az_enabled           = optional(bool)

    subnet_ids         = optional(list(string))
    subnet_group_name  = optional(string)
    security_group_ids = optional(list(string), [])

    parameter_group_name = optional(string)
    parameter_group = optional(object({
      family      = string
      parameters  = optional(map(string), {})
      description = optional(string)
    }))

    auth_token                 = optional(string)
    auth_token_wo              = optional(string)
    auth_token_wo_version      = optional(number)
    transit_encryption_enabled = optional(bool)
    at_rest_encryption_enabled = optional(bool)
    kms_key_id                 = optional(string)
    auto_minor_version_upgrade = optional(bool)
    maintenance_window         = optional(string)
    apply_immediately          = optional(bool, false)
    notification_topic_arn     = optional(string)

    snapshot_retention_limit  = optional(number)
    snapshot_window           = optional(string)
    final_snapshot_identifier = optional(string)
    snapshot_name             = optional(string)
    snapshot_arns             = optional(list(string))

    log_delivery_configurations = optional(map(object({
      destination      = string
      destination_type = string
      log_format       = string
      log_type         = string
    })), {})

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.redis_clusters) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (subnet and parameter group resource addresses are derived from the cluster key)."
  }

  validation {
    condition     = alltrue([for c in var.redis_clusters : can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", c.replication_group_id)) && !can(regex("--", c.replication_group_id))])
    error_message = "replication_group_id must start with a lowercase letter, contain only lowercase alphanumerics and single (non-consecutive) hyphens, not end with a hyphen and be 2-40 characters (ElastiCache naming rules; AWS lowercases supplied IDs; customer-supplied IDs only)."
  }

  validation {
    condition     = alltrue([for c in var.redis_clusters : contains(["redis", "valkey"], c.engine)])
    error_message = "engine must be redis or valkey (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.redis_clusters : c.engine_version == null || can(regex("^\\d+\\.\\d+$", c.engine_version))])
    error_message = "engine_version must be a major.minor string such as \"7.1\" (the provider selects the latest compatible patch; Redis and Valkey version lines differ)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : !((c.num_cache_clusters != null) && (c.num_node_groups != null))
    ])
    error_message = "num_cache_clusters and num_node_groups are mutually exclusive; set neither for a default single-cluster group (provider default num_cache_clusters = 1)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : c.preferred_cache_cluster_azs == null || c.num_cache_clusters == null || length(c.preferred_cache_cluster_azs) == c.num_cache_clusters
    ])
    error_message = "preferred_cache_cluster_azs length must match num_cache_clusters."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : c.replicas_per_node_group == null || c.num_node_groups != null
    ])
    error_message = "replicas_per_node_group can only be set together with num_node_groups (cluster mode)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : c.num_node_groups == null || (c.num_node_groups >= 1 && c.num_node_groups <= 500 && (c.replicas_per_node_group == null || c.replicas_per_node_group >= 0 && c.replicas_per_node_group <= 5))
    ])
    error_message = "num_node_groups must be 1-500 (shards; range depends on node type) and replicas_per_node_group 0-5 (ElastiCache API limits)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : c.num_node_groups == null || c.automatic_failover_enabled == true
    ])
    error_message = "cluster-mode replication groups (num_node_groups) require automatic_failover_enabled = true (the API rejects cluster mode without failover)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : !(c.multi_az_enabled == true && c.automatic_failover_enabled != true)
    ])
    error_message = "multi_az_enabled requires automatic_failover_enabled = true."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : !(c.automatic_failover_enabled == true && c.num_cache_clusters != null && c.num_cache_clusters < 2)
    ])
    error_message = "automatic_failover_enabled = true requires num_cache_clusters >= 2 (AWS rejects failover on a single cluster)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : (c.subnet_ids != null) != (c.subnet_group_name != null)
    ])
    error_message = "exactly one of subnet_ids or subnet_group_name must be set per cluster."
  }

  validation {
    condition     = alltrue([for c in var.redis_clusters : (c.subnet_ids == null) || (c.subnet_ids != null && length(c.subnet_ids) >= 2)])
    error_message = "subnet_ids must contain at least 2 subnet IDs across different availability zones (ElastiCache requirement for failover-capable groups)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : !((c.parameter_group != null) && (c.parameter_group_name != null))
    ])
    error_message = "parameter_group and parameter_group_name are mutually exclusive; omit both to use the engine default parameter group."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : (c.auth_token == null || can(regex("^.{16,128}$", c.auth_token))) && (c.auth_token_wo == null || can(regex("^.{16,128}$", c.auth_token_wo)))
    ])
    error_message = "auth_token / auth_token_wo must be 16-128 characters (usable ASCII excluding some characters, per Redis AUTH rules)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters :
      (c.auth_token == null && c.auth_token_wo == null)
      || (c.auth_token == null && c.auth_token_wo != null && c.auth_token_wo_version != null)
      || (c.auth_token != null && c.auth_token_wo == null && c.auth_token_wo_version == null)
    ])
    error_message = "exactly one of auth_token or auth_token_wo is required; setting auth_token_wo also requires auth_token_wo_version (rotation buster)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : (c.auth_token == null && c.auth_token_wo == null) || c.transit_encryption_enabled == true
    ])
    error_message = "setting an auth token requires transit_encryption_enabled (the API rejects AUTH without in-transit TLS)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : c.kms_key_id == null || (c.at_rest_encryption_enabled == true)
    ])
    error_message = "kms_key_id requires at_rest_encryption_enabled = true."
  }

  validation {
    condition     = alltrue([for c in var.redis_clusters : c.maintenance_window == null || can(regex("^[a-z]{3}:[0-9]{2}:[0-9]{2}-[a-z]{3}:[0-9]{2}:[0-9]{2}$", c.maintenance_window))])
    error_message = "maintenance_window must match the ddd:hh24:mi-ddd:hh24:mi format, e.g. \"sun:05:00-sun:09:00\" (lowercase day abbreviations)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : alltrue([
        for k, l in c.log_delivery_configurations : k == l.log_type && contains(["cloudwatch-logs", "kinesis-firehose"], l.destination_type) && contains(["json", "text"], l.log_format) && contains(["slow-log", "engine-log"], l.log_type)
      ])
    ])
    error_message = "log_delivery_configurations entries must be keyed by their log_type (slow-log or engine-log, max one of each) and use destination_type cloudwatch-logs or kinesis-firehose, log_format json or text (all case-sensitive)."
  }

  validation {
    condition = alltrue([
      for c in var.redis_clusters : length(distinct([for c2 in var.redis_clusters : c2.replication_group_id])) == length(var.redis_clusters)
    ])
    error_message = "replication_group_id must be unique across all entries (ElastiCache IDs are region-unique)."
  }
}

variable "memcached_clusters" {
  description = "Map of ElastiCache memcached clusters keyed by an arbitrary identifier. Each entry creates one aws_elasticache_cluster plus optional subnet and parameter groups."
  type = map(object({
    cluster_id                   = string
    engine_version               = optional(string)
    node_type                    = string
    num_cache_nodes              = optional(number, 1)
    az_mode                      = optional(string)
    availability_zone            = optional(string)
    preferred_availability_zones = optional(list(string))
    port                         = optional(number)

    subnet_ids         = optional(list(string))
    subnet_group_name  = optional(string)
    security_group_ids = optional(list(string), [])

    parameter_group_name = optional(string)
    parameter_group = optional(object({
      family      = string
      parameters  = optional(map(string), {})
      description = optional(string)
    }))

    transit_encryption_enabled = optional(bool)
    maintenance_window         = optional(string)
    apply_immediately          = optional(bool, false)
    notification_topic_arn     = optional(string)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.memcached_clusters) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (subnet and parameter group resource addresses are derived from the cluster key)."
  }

  validation {
    condition     = alltrue([for c in var.memcached_clusters : can(regex("^[a-z][a-z0-9-]{0,48}[a-z0-9]$", c.cluster_id)) && !can(regex("--", c.cluster_id))])
    error_message = "cluster_id must start with a lowercase letter, contain only lowercase alphanumerics and single (non-consecutive) hyphens, not end with a hyphen and be 2-50 characters (ElastiCache naming rules; ASCII only)."
  }

  validation {
    condition     = alltrue([for c in var.memcached_clusters : c.engine_version == null || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", c.engine_version))])
    error_message = "engine_version must be a major.minor.patch string such as \"1.6.38\" (memcached versions are three-part)."
  }

  validation {
    condition     = alltrue([for c in var.memcached_clusters : c.num_cache_nodes >= 1 && c.num_cache_nodes <= 40])
    error_message = "num_cache_nodes must be between 1 and 40 for memcached (ElastiCache API limit)."
  }

  validation {
    condition     = alltrue([for c in var.memcached_clusters : c.az_mode == null || contains(["single-az", "cross-az"], c.az_mode)])
    error_message = "az_mode must be single-az or cross-az (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for c in var.memcached_clusters : c.az_mode != "cross-az" || c.num_cache_nodes > 1
    ])
    error_message = "az_mode = \"cross-az\" requires num_cache_nodes > 1."
  }

  validation {
    condition = alltrue([
      for c in var.memcached_clusters : c.availability_zone == null || c.az_mode != "cross-az"
    ])
    error_message = "availability_zone pins all nodes to one AZ and cannot be set with az_mode = \"cross-az\" (multi-AZ placement uses preferred_availability_zones)."
  }

  validation {
    condition = alltrue([
      for c in var.memcached_clusters : c.preferred_availability_zones == null || length(c.preferred_availability_zones) == c.num_cache_nodes
    ])
    error_message = "preferred_availability_zones length must match num_cache_nodes."
  }

  validation {
    condition = alltrue([
      for c in var.memcached_clusters : (c.subnet_ids != null) != (c.subnet_group_name != null)
    ])
    error_message = "exactly one of subnet_ids or subnet_group_name must be set per cluster."
  }

  validation {
    condition = alltrue([
      for c in var.memcached_clusters : (c.parameter_group != null) != (c.parameter_group_name != null)
    ])
    error_message = "exactly one of parameter_group or parameter_group_name is required (the provider requires parameter_group_name unless the cluster belongs to a replication group, which this module does not use; memcached clusters stand alone)."
  }

  validation {
    condition = alltrue([
      for c in var.memcached_clusters : length(distinct([for c2 in var.memcached_clusters : c2.cluster_id])) == length(var.memcached_clusters)
    ])
    error_message = "cluster_id must be unique across all entries (ElastiCache IDs are region-unique)."
  }
}
