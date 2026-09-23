# aws/ecs-service

Map-keyed module for ECS services: each entry creates one task definition
(and its containers via JSON) and one service running it, with FARGATE
first, optional capacity provider strategies, awsvpc networking, ALB/NLB
target wiring and deployment circuit breaker.

The task definition is nested inside each service entry — a service's
task definition is 1:1 with it, which also enables plan-time checks
between them. FARGATE-first defaults (`network_mode = "awsvpc"`,
`requires_compatibilities = ["FARGATE"]`, `launch_type = "FARGATE"`) are
a deliberate deviation from provider defaults; EC2 consumers override all
three explicitly.

## Destroy semantics (read before using)

- Removing a key drains and deletes the service (tasks stop
  asynchronously; targets deregister from target groups), then deletes
  the task definition resource from state — **task definition revisions
  are never deleted by the API**; old revisions linger in the account.
- Deleting the cluster requires all services gone (see `aws/ecs-cluster`).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `services` | `map(object)` | `{}` | Map of services keyed by an arbitrary unique ID. |

### `services` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Service name, 1–255 characters of letters/digits/hyphens/underscores (validated). |
| `cluster` | `string` | — | Cluster ARN (from `aws/ecs-cluster` `cluster_arns`). |
| `task_definition` | `object` | — | Per-service task definition; see the table below. |
| `desired_count` | `number` | `1` | Desired task count. |
| `launch_type` | `string` | `FARGATE` | `FARGATE`, `EC2` or `EXTERNAL` (validated). Silently superseded when `capacity_provider_strategy` is set (the API rejects both). |
| `capacity_provider_strategy` | `list(object)` | `[]` | Strategy entries `{capacity_provider, weight, base}`. Changing it requires `force_new_deployment = true`. |
| `network_configuration` | `object` | — | `{subnets, security_group_ids, assign_public_ip}`. Required for awsvpc (validated); forbidden otherwise. |
| `load_balancers` | `map(object)` | `{}` | Map of `{target_group_arn, container_name, container_port}` — `container_name` must exist in the container definitions JSON (validated). Pair with `aws/alb` target groups (`target_type = "ip"` for awsvpc services). |
| `deployment_maximum_percent` | `number` | `200` | Max healthy tasks during a deployment. |
| `deployment_minimum_healthy_percent` | `number` | `100` | Min healthy tasks during a deployment. |
| `deployment_circuit_breaker` | `object` | — | `{enable, rollback}` — fail closed on bad deployments and optionally roll back. |
| `health_check_grace_period_seconds` | `number` | — | Grace period before counting tasks toward the minimum. |
| `platform_version` | `string` | — | Fargate platform version; defaults to `LATEST`, which is not pinned and updates on its own. |
| `enable_execute_command` | `bool` | `false` | Allow exec into tasks; pair with cluster execute-command configuration and task-role SSM permissions. |
| `force_new_deployment` | `bool` | `false` | Force a fresh deployment on change (needed for capacity-provider strategy updates). |
| `propagate_tags` | `string` | — | `SERVICE` or `TASK_DEFINITION` (validated). |
| `enable_ecs_managed_tags` | `bool` | — | ECS-managed tags on the service. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |
| `task_definition.family` | `string` | — | Family name, 1–255 characters of letters/digits/hyphens/underscores (validated). |
| `task_definition.container_definitions` | `string` | — | JSON container definitions — build with `jsonencode()` consumer-side (deterministic string, no formatting diffs). Validated: decodes to a list, every container has non-empty `name` and `image`. |
| `task_definition.cpu` | `number` | — | Task-level CPU units (1024 = 1 vCPU). Required for FARGATE (validated). |
| `task_definition.memory` | `number` | — | Task-level memory in MiB. Required for FARGATE (validated). |
| `task_definition.network_mode` | `string` | `awsvpc` | `awsvpc`, `bridge`, `host` or `none` (validated). |
| `task_definition.requires_compatibilities` | `list(string)` | `["FARGATE"]` | Among `EC2`, `FARGATE`, `EXTERNAL`, `MANAGED_INSTANCES` (validated). |
| `task_definition.execution_role_arn` | `string` | — | Task execution role (pull, logs, secrets). |
| `task_definition.task_role_arn` | `string` | — | Application role for the containers. |
| `task_definition.runtime_platform` | `object` | — | `{cpu_architecture, operating_system_family}`. |
| `task_definition.ephemeral_storage` | `object` | — | `{size_in_gib}` — 21–200 GiB (validated). |
| `task_definition.track_latest` | `bool` | — | Track the latest ACTIVE revision instead of the one in state (provider floor 5.37 — keep pins at the consumer root). |
| `task_definition.volumes` | `map(object)` | `{}` | Map of `{name, host_path, efs_volume_configuration}` volumes; EFS config nests `{file_system_id, root_directory, transit_encryption, transit_encryption_port, authorization_config}` with `{access_point_id, iam}`. |
| `task_definition.tags` | `map(string)` | `{}` | Task-definition tags; merged with `Name = family`. |

## Outputs

`service_arns` — map of service key => service ARN.
`service_names` — map of service key => service name.
`task_definition_arns` — map of service key => task definition ARN
(including the `:revision` suffix).

## Example

```hcl
services = {
  "api" = {
    name    = "example-api"
    cluster = dependency.cluster.outputs.cluster_arns["main"]
    task_definition = {
      family                = "example-api"
      container_definitions = jsonencode([
        {
          name  = "api"
          image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-api:latest"
          portMappings = [
            { containerPort = 8080, protocol = "tcp" }
          ]
        }
      ])
      cpu    = 256
      memory = 512
    }
    network_configuration = {
      subnets            = dependency.network.outputs.subnet_ids["private"]
      security_group_ids = dependency.network.outputs.security_group_ids["tasks"]
    }
    deployment_circuit_breaker = {
      enable   = true
      rollback = true
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not service names; multiple
  services can share a name on different clusters.
- Task definition changes create a **new revision** on every apply and
  the service rolls to it; revisions are never deleted by the API.
- **A non-empty `capacity_provider_strategy` supersedes `launch_type`
  silently** — the module nulls `launch_type` because the API rejects
  both; an explicit `launch_type = "EC2"` next to a strategy is ignored.
  Strategy changes additionally need `force_new_deployment = true` to
  roll out.
- The service `iam_role` (EC2-classic style role for bridge/host with
  load balancers) is deliberately not exposed: awsvpc is the module's
  default path and the API forbids specifying it there.
- Execute-command pairs with `aws/ecs-cluster`
  `execute_command_configuration` plus task-role SSM permissions.
- Autoscaling is out of scope (`aws_appautoscaling_target/policy`
  consumer-side): an external Application Auto Scaling target will
  change `desired_count` and the diff shows drift — either ignore the
  `desired_count` diff or manage scaling in the same state.
- Service connect, Cloud Map registries, placement
  constraints/strategies and `scheduling_strategy = "DAEMON"` are out of
  scope; add consumer-side or on request.

## Import

`aws_ecs_service` ← `<cluster-name>/<service-name>`.
`aws_ecs_task_definition` ← full task definition ARN
(`arn:...:task-definition/<family>:<revision>`).
