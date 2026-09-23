resource "aws_db_instance" "instance" {
  for_each = var.instances

  identifier                            = each.value.identifier
  identifier_prefix                     = each.value.identifier_prefix
  engine                                = each.value.engine
  engine_version                        = each.value.engine_version
  instance_class                        = each.value.instance_class
  db_name                               = each.value.database_name
  username                              = each.value.master_username
  password                              = each.value.master_password
  port                                  = each.value.port
  allocated_storage                     = each.value.allocated_storage
  max_allocated_storage                 = each.value.max_allocated_storage
  storage_type                          = each.value.storage_type
  iops                                  = each.value.iops
  storage_throughput                    = each.value.storage_throughput
  storage_encrypted                     = each.value.storage_encrypted
  kms_key_id                            = each.value.kms_key_id
  multi_az                              = each.value.multi_az
  publicly_accessible                   = each.value.publicly_accessible
  db_subnet_group_name                  = each.value.db_subnet_group_name
  vpc_security_group_ids                = each.value.security_group_ids
  parameter_group_name                  = each.value.parameter_group_name
  option_group_name                     = each.value.option_group_name
  backup_retention_period               = each.value.backup_retention_period
  backup_window                         = each.value.backup_window
  maintenance_window                    = each.value.maintenance_window
  copy_tags_to_snapshot                 = each.value.copy_tags_to_snapshot
  skip_final_snapshot                   = each.value.skip_final_snapshot
  final_snapshot_identifier             = each.value.final_snapshot_identifier
  deletion_protection                   = each.value.deletion_protection
  auto_minor_version_upgrade            = each.value.auto_minor_version_upgrade
  allow_major_version_upgrade           = each.value.allow_major_version_upgrade
  apply_immediately                     = each.value.apply_immediately
  character_set_name                    = each.value.character_set_name
  timezone                              = each.value.timezone
  ca_cert_identifier                    = each.value.ca_cert_identifier
  monitoring_interval                   = each.value.enhanced_monitoring_interval
  monitoring_role_arn                   = each.value.enhanced_monitoring_role_arn
  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_kms_key_id       = each.value.performance_insights_kms_key_id
  performance_insights_retention_period = each.value.performance_insights_retention_period
  delete_automated_backups              = each.value.delete_automated_backups
  backup_target                         = each.value.backup_target

  tags = merge(each.value.tags, { Name = coalesce(each.value.identifier, each.value.identifier_prefix) })

  lifecycle {
    precondition {
      condition     = (each.value.identifier != null) != (each.value.identifier_prefix != null)
      error_message = "instance \"${each.key}\" must set exactly one of identifier or identifier_prefix."
    }

    precondition {
      condition     = each.value.skip_final_snapshot || each.value.final_snapshot_identifier != null
      error_message = "instance \"${each.key}\": set final_snapshot_identifier when skip_final_snapshot is false (the API requires one on delete)."
    }

    precondition {
      condition     = each.value.kms_key_id == null || each.value.storage_encrypted
      error_message = "instance \"${each.key}\": kms_key_id requires storage_encrypted = true."
    }
  }
}

resource "aws_rds_cluster" "cluster" {
  for_each = var.clusters

  cluster_identifier              = each.value.identifier
  cluster_identifier_prefix       = each.value.identifier_prefix
  engine                          = each.value.engine
  engine_version                  = each.value.engine_version
  engine_mode                     = each.value.engine_mode
  database_name                   = each.value.database_name
  master_username                 = each.value.master_username
  master_password                 = each.value.master_password
  port                            = each.value.port
  storage_encrypted               = each.value.storage_encrypted
  kms_key_id                      = each.value.kms_key_id
  db_subnet_group_name            = each.value.db_subnet_group_name
  vpc_security_group_ids          = each.value.security_group_ids
  db_cluster_parameter_group_name = each.value.parameter_group_name
  backup_retention_period         = each.value.backup_retention_period
  preferred_backup_window         = each.value.backup_window
  preferred_maintenance_window    = each.value.maintenance_window
  copy_tags_to_snapshot           = each.value.copy_tags_to_snapshot
  skip_final_snapshot             = each.value.skip_final_snapshot
  final_snapshot_identifier       = each.value.final_snapshot_identifier
  deletion_protection             = each.value.deletion_protection
  storage_type                    = each.value.storage_type
  allocated_storage               = each.value.allocated_storage
  iops                            = each.value.iops
  apply_immediately               = each.value.apply_immediately
  enable_http_endpoint            = each.value.enable_http_endpoint
  network_type                    = each.value.network_type

  dynamic "serverlessv2_scaling_configuration" {
    for_each = each.value.serverlessv2_scaling != null ? [each.value.serverlessv2_scaling] : []

    content {
      max_capacity = serverlessv2_scaling.value.max_capacity
      min_capacity = serverlessv2_scaling.value.min_capacity
    }
  }

  tags = merge(each.value.tags, { Name = coalesce(each.value.identifier, each.value.identifier_prefix) })

  lifecycle {
    precondition {
      condition     = (each.value.identifier != null) != (each.value.identifier_prefix != null)
      error_message = "cluster \"${each.key}\" must set exactly one of identifier or identifier_prefix."
    }

    precondition {
      condition     = each.value.skip_final_snapshot || each.value.final_snapshot_identifier != null
      error_message = "cluster \"${each.key}\": set final_snapshot_identifier when skip_final_snapshot is false (the API requires one on delete)."
    }

    precondition {
      condition     = each.value.kms_key_id == null || each.value.storage_encrypted
      error_message = "cluster \"${each.key}\": kms_key_id requires storage_encrypted = true."
    }

    precondition {
      condition     = each.value.serverlessv2_scaling == null || each.value.engine == "aurora-postgresql" || each.value.engine == "aurora-mysql"
      error_message = "cluster \"${each.key}\": serverlessv2_scaling only applies to aurora-postgresql and aurora-mysql engine clusters."
    }
  }
}

resource "aws_rds_cluster_instance" "cluster_instance" {
  for_each = { for k, v in local.cluster_instances : k => v }

  identifier                            = each.value.identifier
  identifier_prefix                     = each.value.identifier_prefix
  cluster_identifier                    = each.value.cluster_identifier
  engine                                = each.value.engine
  engine_version                        = each.value.engine_version
  instance_class                        = each.value.instance_class
  publicly_accessible                   = each.value.publicly_accessible
  db_subnet_group_name                  = each.value.db_subnet_group_name
  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_kms_key_id       = each.value.performance_insights_kms_key_id
  performance_insights_retention_period = each.value.performance_insights_retention_period
  monitoring_interval                   = each.value.monitoring_interval
  monitoring_role_arn                   = each.value.monitoring_role_arn
  auto_minor_version_upgrade            = each.value.auto_minor_version_upgrade
  promotion_tier                        = each.value.promotion_tier
  ca_cert_identifier                    = each.value.ca_cert_identifier

  lifecycle {
    precondition {
      condition     = (each.value.identifier != null) != (each.value.identifier_prefix != null)
      error_message = "cluster instance \"${each.key}\" must set exactly one of identifier or identifier_prefix."
    }
  }
}

locals {
  cluster_instances = merge([
    for cluster_key, cluster in var.clusters : {
      for inst_key, inst in cluster.instances : "${cluster_key}.${inst_key}" => {
        cluster_identifier                    = aws_rds_cluster.cluster[cluster_key].cluster_identifier
        engine                                = cluster.engine
        engine_version                        = cluster.engine_version
        identifier                            = inst.identifier
        identifier_prefix                     = inst.identifier_prefix
        instance_class                        = inst.instance_class
        publicly_accessible                   = inst.publicly_accessible
        db_subnet_group_name                  = cluster.db_subnet_group_name
        performance_insights_enabled          = inst.performance_insights_enabled
        performance_insights_kms_key_id       = inst.performance_insights_kms_key_id
        performance_insights_retention_period = inst.performance_insights_retention_period
        monitoring_interval                   = inst.monitoring_interval
        monitoring_role_arn                   = inst.monitoring_role_arn
        auto_minor_version_upgrade            = inst.auto_minor_version_upgrade
        promotion_tier                        = inst.promotion_tier
        ca_cert_identifier                    = inst.ca_cert_identifier
      }
    }
  ]...)
}
