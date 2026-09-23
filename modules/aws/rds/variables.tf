variable "instances" {
  description = "Map of standalone RDS DB instances keyed by an arbitrary identifier. Each entry creates one aws_db_instance."
  type = map(object({
    identifier                            = optional(string)
    identifier_prefix                     = optional(string)
    engine                                = string
    engine_version                        = optional(string)
    instance_class                        = string
    database_name                         = optional(string)
    master_username                       = optional(string)
    master_password                       = optional(string)
    port                                  = optional(number)
    allocated_storage                     = optional(number)
    max_allocated_storage                 = optional(number)
    storage_type                          = optional(string)
    iops                                  = optional(number)
    storage_throughput                    = optional(number)
    storage_encrypted                     = optional(bool)
    kms_key_id                            = optional(string)
    multi_az                              = optional(bool)
    publicly_accessible                   = optional(bool, false)
    db_subnet_group_name                  = string
    security_group_ids                    = optional(list(string), [])
    parameter_group_name                  = optional(string)
    option_group_name                     = optional(string)
    backup_retention_period               = optional(number)
    backup_window                         = optional(string)
    maintenance_window                    = optional(string)
    copy_tags_to_snapshot                 = optional(bool)
    skip_final_snapshot                   = optional(bool, false)
    final_snapshot_identifier             = optional(string)
    deletion_protection                   = optional(bool, false)
    auto_minor_version_upgrade            = optional(bool)
    allow_major_version_upgrade           = optional(bool)
    apply_immediately                     = optional(bool)
    character_set_name                    = optional(string)
    timezone                              = optional(string)
    ca_cert_identifier                    = optional(string)
    enhanced_monitoring_interval          = optional(number)
    enhanced_monitoring_role_arn          = optional(string)
    performance_insights_enabled          = optional(bool)
    performance_insights_kms_key_id       = optional(string)
    performance_insights_retention_period = optional(number)
    delete_automated_backups              = optional(bool)
    backup_target                         = optional(string)
    tags                                  = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for db in var.instances : (db.identifier != null) != (db.identifier_prefix != null)])
    error_message = "each instance must set exactly one of identifier or identifier_prefix."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.identifier == null || length(db.identifier) <= 63 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", db.identifier)) && !can(regex("--", db.identifier))])
    error_message = "identifier must be up to 63 characters, start with a letter, contain alphanumerics and hyphens without consecutive hyphens, and not end with a hyphen (RDS identifier rules)."
  }

  validation {
    condition     = alltrue([for db in var.instances : contains(["aurora-mysql", "aurora-postgresql", "mysql", "postgres", "mariadb", "oracle-ee", "oracle-se2", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web", "custom-aurora-mysql", "custom-aurora-postgresql", "custom-oracle-ee", "custom-oracle-se2", "custom-sqlserver-ee", "custom-sqlserver-se", "custom-sqlserver-ex", "custom-sqlserver-web", "db2-ae", "db2-se"], db.engine)])
    error_message = "engine must be a valid RDS engine identifier (mysql, postgres, mariadb, oracle-*, sqlserver-*, aurora-*, custom-*, db2-*)."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.storage_type == null || contains(["standard", "gp2", "gp3", "io1", "io2"], db.storage_type)])
    error_message = "storage_type must be one of standard, gp2, gp3, io1 or io2 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.storage_throughput == null || db.storage_type == "gp3"])
    error_message = "storage_throughput is only valid with storage_type = \"gp3\"."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.iops == null || contains(["io1", "io2", "gp3"], db.storage_type)])
    error_message = "iops requires storage_type io1, io2 or gp3."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.kms_key_id == null || db.storage_encrypted == true])
    error_message = "kms_key_id requires storage_encrypted = true."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.skip_final_snapshot || db.final_snapshot_identifier != null])
    error_message = "set final_snapshot_identifier when skip_final_snapshot is false (the API requires one on delete)."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.backup_target == null || contains(["region", "outposts"], db.backup_target)])
    error_message = "backup_target must be one of region or outposts (case-sensitive)."
  }

  validation {
    condition     = alltrue([for db in var.instances : db.backup_retention_period == null || db.backup_retention_period <= 35])
    error_message = "backup_retention_period must be at most 35 days (RDS maximum)."
  }
}

variable "clusters" {
  description = "Map of Aurora/RDS clusters keyed by an arbitrary identifier. Each entry creates one aws_rds_cluster plus its aws_rds_cluster_instance members."
  type = map(object({
    identifier                = optional(string)
    identifier_prefix         = optional(string)
    engine                    = string
    engine_version            = optional(string)
    engine_mode               = optional(string)
    database_name             = optional(string)
    master_username           = optional(string)
    master_password           = optional(string)
    port                      = optional(number)
    storage_encrypted         = optional(bool)
    kms_key_id                = optional(string)
    db_subnet_group_name      = string
    security_group_ids        = optional(list(string), [])
    parameter_group_name      = optional(string)
    backup_retention_period   = optional(number)
    backup_window             = optional(string)
    maintenance_window        = optional(string)
    copy_tags_to_snapshot     = optional(bool)
    skip_final_snapshot       = optional(bool, false)
    final_snapshot_identifier = optional(string)
    deletion_protection       = optional(bool, false)
    storage_type              = optional(string)
    allocated_storage         = optional(number)
    iops                      = optional(number)
    apply_immediately         = optional(bool)
    enable_http_endpoint      = optional(bool)
    network_type              = optional(string)
    serverlessv2_scaling = optional(object({
      min_capacity = number
      max_capacity = number
    }))
    instances = map(object({
      identifier                            = optional(string)
      identifier_prefix                     = optional(string)
      instance_class                        = string
      publicly_accessible                   = optional(bool, false)
      performance_insights_enabled          = optional(bool)
      performance_insights_kms_key_id       = optional(string)
      performance_insights_retention_period = optional(number)
      monitoring_interval                   = optional(number)
      monitoring_role_arn                   = optional(string)
      auto_minor_version_upgrade            = optional(bool)
      promotion_tier                        = optional(number)
      ca_cert_identifier                    = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for c in var.clusters : (c.identifier != null) != (c.identifier_prefix != null)])
    error_message = "each cluster must set exactly one of identifier or identifier_prefix."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.identifier == null || length(c.identifier) <= 63 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", c.identifier)) && !can(regex("--", c.identifier))])
    error_message = "identifier must be up to 63 characters, start with a letter, contain alphanumerics and hyphens without consecutive hyphens, and not end with a hyphen (RDS identifier rules)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : contains(["aurora-mysql", "aurora-postgresql", "mysql", "postgres"], c.engine)])
    error_message = "cluster engine must be one of aurora-mysql, aurora-postgresql, mysql or postgres (the cluster resource also accepts multi-az via engine_mode, not engine)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.engine_mode == null || contains(["provisioned", "serverless", "parallelquery", "global", "multimaster", "iopt1"], c.engine_mode)])
    error_message = "engine_mode must be one of provisioned, serverless, parallelquery, global, multimaster or iopt1 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.storage_type == null || contains(["aurora", "aurora-iopt1", "io1", "io2", "gp3"], c.storage_type)])
    error_message = "cluster storage_type must be one of aurora, aurora-iopt1, io1, io2 or gp3 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.serverlessv2_scaling == null || c.serverlessv2_scaling.min_capacity <= c.serverlessv2_scaling.max_capacity])
    error_message = "clusters.serverlessv2_scaling: min_capacity must be less than or equal to max_capacity."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.network_type == null || contains(["IPV4", "DUAL"], c.network_type)])
    error_message = "network_type must be one of IPV4 or DUAL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.skip_final_snapshot || c.final_snapshot_identifier != null])
    error_message = "set final_snapshot_identifier when skip_final_snapshot is false (the API requires one on delete)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.kms_key_id == null || c.storage_encrypted == true])
    error_message = "kms_key_id requires storage_encrypted = true."
  }

  validation {
    condition     = alltrue([for c in var.clusters : length(c.instances) > 0])
    error_message = "clusters require at least one member instance (an empty cluster cannot serve; create it consumer-side if you truly need zero instances)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : alltrue([for i in c.instances : (i.identifier != null) != (i.identifier_prefix != null)])])
    error_message = "each cluster instance must set exactly one of identifier or identifier_prefix."
  }
}
