variable "services" {
  description = "Map of ECS services keyed by an arbitrary identifier. Each entry creates one aws_ecs_task_definition and one aws_ecs_service running it."
  type = map(object({
    name    = string
    cluster = string
    task_definition = object({
      family                   = string
      container_definitions    = string
      cpu                      = optional(number)
      memory                   = optional(number)
      network_mode             = optional(string, "awsvpc")
      requires_compatibilities = optional(list(string), ["FARGATE"])
      execution_role_arn       = optional(string)
      task_role_arn            = optional(string)
      runtime_platform = optional(object({
        cpu_architecture        = optional(string)
        operating_system_family = optional(string)
      }))
      ephemeral_storage = optional(object({
        size_in_gib = number
      }))
      track_latest = optional(bool)
      volumes = optional(map(object({
        name      = string
        host_path = optional(string)
        efs_volume_configuration = optional(object({
          file_system_id          = string
          root_directory          = optional(string)
          transit_encryption      = optional(string)
          transit_encryption_port = optional(number)
          authorization_config = optional(object({
            access_point_id = optional(string)
            iam             = optional(string)
          }))
        }))
      })), {})
      tags = optional(map(string), {})
    })
    desired_count = optional(number, 1)
    launch_type   = optional(string, "FARGATE")
    capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      weight            = number
      base              = optional(number, 0)
    })), [])
    network_configuration = optional(object({
      subnets            = list(string)
      security_group_ids = optional(list(string), [])
      assign_public_ip   = optional(bool, false)
    }))
    load_balancers = optional(map(object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    })), {})
    deployment_maximum_percent         = optional(number, 200)
    deployment_minimum_healthy_percent = optional(number, 100)
    deployment_circuit_breaker = optional(object({
      enable   = bool
      rollback = optional(bool, false)
    }))
    health_check_grace_period_seconds = optional(number)
    platform_version                  = optional(string)
    enable_execute_command            = optional(bool, false)
    force_new_deployment              = optional(bool, false)
    propagate_tags                    = optional(string)
    enable_ecs_managed_tags           = optional(bool)
    tags                              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.services : length(s.name) >= 1 && length(s.name) <= 255 && can(regex("^[a-zA-Z0-9_-]+$", s.name))])
    error_message = "name must be 1-255 characters of letters, digits, hyphens and underscores (ECS service naming rules)."
  }

  validation {
    condition     = alltrue([for s in var.services : length(s.task_definition.family) >= 1 && length(s.task_definition.family) <= 255 && can(regex("^[a-zA-Z0-9_-]+$", s.task_definition.family))])
    error_message = "task_definition.family must be 1-255 characters of letters, digits, hyphens and underscores (ECS task definition naming rules)."
  }

  validation {
    condition     = alltrue([for s in var.services : contains(["awsvpc", "bridge", "host", "none"], s.task_definition.network_mode)])
    error_message = "task_definition.network_mode must be one of awsvpc, bridge, host or none (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.services : alltrue([for c in s.task_definition.requires_compatibilities : contains(["EC2", "FARGATE", "EXTERNAL", "MANAGED_INSTANCES"], c)])])
    error_message = "task_definition.requires_compatibilities values must be among EC2, FARGATE, EXTERNAL and MANAGED_INSTANCES (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.services : contains(["FARGATE", "EC2", "EXTERNAL"], s.launch_type)])
    error_message = "launch_type must be one of FARGATE, EC2 or EXTERNAL (case-sensitive; superseded by capacity_provider_strategy when that is set)."
  }

  validation {
    condition     = alltrue([for s in var.services : s.propagate_tags == null || contains(["SERVICE", "TASK_DEFINITION"], s.propagate_tags)])
    error_message = "propagate_tags must be SERVICE or TASK_DEFINITION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.services : can(jsondecode(s.task_definition.container_definitions))])
    error_message = "task_definition.container_definitions must be a valid JSON container definition document (build it with jsonencode() consumer-side)."
  }

  validation {
    condition     = alltrue([for s in var.services : try(length(jsondecode(s.task_definition.container_definitions)) > 0, false)])
    error_message = "task_definition.container_definitions must decode to a non-empty list of container definition objects."
  }

  validation {
    condition = alltrue([for s in var.services : alltrue([
      for c in jsondecode(s.task_definition.container_definitions) :
      try(can(regex("\\S", tostring(c.name))) && can(regex("\\S", tostring(c.image))), false)
    ])])
    error_message = "task_definition.container_definitions: every container needs non-empty name and image strings (the API rejects unknown or unnamed containers)."
  }

  validation {
    condition     = alltrue([for s in var.services : !contains(s.task_definition.requires_compatibilities, "FARGATE") || (s.task_definition.cpu != null && s.task_definition.memory != null && s.task_definition.network_mode == "awsvpc")])
    error_message = "FARGATE task definitions require cpu, memory and network_mode = awsvpc (the API rejects FARGATE task defs without cpu/memory/awsvpc)."
  }

  validation {
    condition     = alltrue([for s in var.services : s.task_definition.network_mode != "awsvpc" || (s.network_configuration != null && length(s.network_configuration.subnets) > 0)])
    error_message = "services running awsvpc task definitions require network_configuration with at least one subnet (the API rejects an awsvpc service without network configuration)."
  }

  validation {
    condition     = alltrue([for s in var.services : s.task_definition.network_mode == "awsvpc" || s.network_configuration == null])
    error_message = "network_configuration is only valid with network_mode = awsvpc (the API rejects network configuration on bridge/host task defs)."
  }

  validation {
    condition = alltrue([for s in var.services : alltrue([
      for _, lb in s.load_balancers :
      anytrue([for c in jsondecode(s.task_definition.container_definitions) : try(c.name == lb.container_name, false)])
    ])])
    error_message = "load_balancers.container_name must reference a container defined in task_definition.container_definitions (the API rejects unknown containers)."
  }

  validation {
    condition     = alltrue([for s in var.services : s.deployment_circuit_breaker == null || !s.deployment_circuit_breaker.rollback || s.deployment_circuit_breaker.enable])
    error_message = "deployment_circuit_breaker.rollback requires deployment_circuit_breaker.enable."
  }

  validation {
    condition     = alltrue([for s in var.services : s.task_definition.ephemeral_storage == null || (s.task_definition.ephemeral_storage.size_in_gib >= 21 && s.task_definition.ephemeral_storage.size_in_gib <= 200)])
    error_message = "task_definition.ephemeral_storage.size_in_gib must be between 21 and 200 GiB (FARGATE ephemeral storage limits)."
  }
}
