locals {
  redis_subnet_groups = {
    for k, c in var.redis_clusters : k => c
    if c.subnet_ids != null
  }

  redis_parameter_groups = {
    for k, c in var.redis_clusters : k => c
    if c.parameter_group != null
  }

  memcached_subnet_groups = {
    for k, c in var.memcached_clusters : k => c
    if c.subnet_ids != null
  }

  memcached_parameter_groups = {
    for k, c in var.memcached_clusters : k => c
    if c.parameter_group != null
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  for_each = local.redis_subnet_groups

  name        = each.key
  description = "Replication group ${each.key} subnet group"
  subnet_ids  = each.value.subnet_ids

  tags = merge(each.value.tags, { Name = each.key })
}

resource "aws_elasticache_parameter_group" "redis" {
  for_each = local.redis_parameter_groups

  family      = each.value.parameter_group.family
  name        = each.key
  description = coalesce(each.value.parameter_group.description, "Replication group ${each.key} parameter group")

  dynamic "parameter" {
    for_each = each.value.parameter_group.parameters

    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(each.value.tags, { Name = each.key })
}

resource "aws_elasticache_replication_group" "redis" {
  for_each = var.redis_clusters

  replication_group_id = each.value.replication_group_id
  description          = each.value.description
  engine               = each.value.engine
  engine_version       = each.value.engine_version
  node_type            = each.value.node_type
  port                 = each.value.port

  num_cache_clusters          = each.value.num_cache_clusters
  preferred_cache_cluster_azs = each.value.preferred_cache_cluster_azs
  num_node_groups             = each.value.num_node_groups
  replicas_per_node_group     = each.value.replicas_per_node_group

  automatic_failover_enabled = each.value.automatic_failover_enabled
  multi_az_enabled           = each.value.multi_az_enabled

  subnet_group_name = each.value.subnet_ids != null ? aws_elasticache_subnet_group.redis[each.key].name : each.value.subnet_group_name

  security_group_ids = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null

  parameter_group_name = each.value.parameter_group_name != null ? each.value.parameter_group_name : try(aws_elasticache_parameter_group.redis[each.key].name, null)

  transit_encryption_enabled = each.value.transit_encryption_enabled
  at_rest_encryption_enabled = each.value.at_rest_encryption_enabled
  kms_key_id                 = each.value.kms_key_id
  auth_token                 = each.value.auth_token
  auth_token_wo              = each.value.auth_token_wo
  auth_token_wo_version      = each.value.auth_token_wo_version
  auto_minor_version_upgrade = each.value.auto_minor_version_upgrade
  maintenance_window         = each.value.maintenance_window
  apply_immediately          = each.value.apply_immediately
  notification_topic_arn     = each.value.notification_topic_arn

  snapshot_retention_limit  = each.value.snapshot_retention_limit
  snapshot_window           = each.value.snapshot_window
  final_snapshot_identifier = each.value.final_snapshot_identifier
  snapshot_name             = each.value.snapshot_name
  snapshot_arns             = each.value.snapshot_arns

  dynamic "log_delivery_configuration" {
    for_each = each.value.log_delivery_configurations

    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  tags = merge(each.value.tags, { Name = each.value.replication_group_id })
}

resource "aws_elasticache_subnet_group" "memcached" {
  for_each = local.memcached_subnet_groups

  name        = each.key
  description = "Cluster ${each.key} subnet group"
  subnet_ids  = each.value.subnet_ids

  tags = merge(each.value.tags, { Name = each.key })
}

resource "aws_elasticache_parameter_group" "memcached" {
  for_each = local.memcached_parameter_groups

  family      = each.value.parameter_group.family
  name        = each.key
  description = coalesce(each.value.parameter_group.description, "Cluster ${each.key} parameter group")

  dynamic "parameter" {
    for_each = each.value.parameter_group.parameters

    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(each.value.tags, { Name = each.key })
}

resource "aws_elasticache_cluster" "memcached" {
  for_each = var.memcached_clusters

  cluster_id      = each.value.cluster_id
  engine          = "memcached"
  engine_version  = each.value.engine_version
  node_type       = each.value.node_type
  num_cache_nodes = each.value.num_cache_nodes

  az_mode                      = each.value.az_mode
  availability_zone            = each.value.availability_zone
  preferred_availability_zones = each.value.preferred_availability_zones
  port                         = each.value.port

  subnet_group_name = each.value.subnet_ids != null ? aws_elasticache_subnet_group.memcached[each.key].name : each.value.subnet_group_name

  security_group_ids = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null

  parameter_group_name = each.value.parameter_group != null ? aws_elasticache_parameter_group.memcached[each.key].name : each.value.parameter_group_name

  transit_encryption_enabled = each.value.transit_encryption_enabled
  maintenance_window         = each.value.maintenance_window
  apply_immediately          = each.value.apply_immediately
  notification_topic_arn     = each.value.notification_topic_arn

  lifecycle {
    precondition {
      condition = length([
        for rid in values(var.redis_clusters) : rid.replication_group_id
        if rid.replication_group_id == each.value.cluster_id
      ]) == 0
      error_message = "memcached cluster \"${each.key}\": cluster_id must not equal any redis replication_group_id (ElastiCache IDs share a region-unique namespace; a collision fails at apply — Redis clusters materialize as <replication_group_id>-00N)."
    }
  }

  tags = merge(each.value.tags, { Name = each.value.cluster_id })
}
