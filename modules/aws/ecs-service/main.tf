resource "aws_ecs_task_definition" "task_definition" {
  for_each = var.services

  family                   = each.value.task_definition.family
  container_definitions    = each.value.task_definition.container_definitions
  cpu                      = each.value.task_definition.cpu
  memory                   = each.value.task_definition.memory
  network_mode             = each.value.task_definition.network_mode
  requires_compatibilities = each.value.task_definition.requires_compatibilities
  execution_role_arn       = each.value.task_definition.execution_role_arn
  task_role_arn            = each.value.task_definition.task_role_arn
  track_latest             = each.value.task_definition.track_latest

  dynamic "runtime_platform" {
    for_each = each.value.task_definition.runtime_platform != null ? [each.value.task_definition.runtime_platform] : []

    content {
      cpu_architecture        = runtime_platform.value.cpu_architecture
      operating_system_family = runtime_platform.value.operating_system_family
    }
  }

  dynamic "ephemeral_storage" {
    for_each = each.value.task_definition.ephemeral_storage != null ? [each.value.task_definition.ephemeral_storage] : []

    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }
  }

  dynamic "volume" {
    for_each = each.value.task_definition.volumes

    content {
      name      = volume.value.name
      host_path = volume.value.host_path

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []

        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config != null ? [volume.value.efs_volume_configuration.authorization_config] : []

            content {
              access_point_id = authorization_config.value.access_point_id
              iam             = authorization_config.value.iam
            }
          }
        }
      }
    }
  }

  tags = merge(each.value.task_definition.tags, { Name = each.value.task_definition.family })
}

resource "aws_ecs_service" "service" {
  for_each = var.services

  name            = each.value.name
  cluster         = each.value.cluster
  task_definition = aws_ecs_task_definition.task_definition[each.key].arn
  desired_count   = each.value.desired_count

  # capacity_provider_strategy supersedes launch_type; the API rejects both.
  launch_type = length(each.value.capacity_provider_strategy) > 0 ? null : each.value.launch_type

  dynamic "capacity_provider_strategy" {
    for_each = each.value.capacity_provider_strategy

    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  dynamic "network_configuration" {
    for_each = each.value.network_configuration != null ? [each.value.network_configuration] : []

    content {
      subnets          = network_configuration.value.subnets
      security_groups  = network_configuration.value.security_group_ids
      assign_public_ip = network_configuration.value.assign_public_ip
    }
  }

  dynamic "load_balancer" {
    for_each = each.value.load_balancers

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent

  dynamic "deployment_circuit_breaker" {
    for_each = each.value.deployment_circuit_breaker != null ? [each.value.deployment_circuit_breaker] : []

    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  health_check_grace_period_seconds = each.value.health_check_grace_period_seconds
  platform_version                  = each.value.platform_version
  enable_execute_command            = each.value.enable_execute_command
  force_new_deployment              = each.value.force_new_deployment
  propagate_tags                    = each.value.propagate_tags
  enable_ecs_managed_tags           = each.value.enable_ecs_managed_tags

  tags = merge(each.value.tags, { Name = each.value.name })
}
