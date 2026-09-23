# aws/ecs-cluster

Map-keyed module for ECS clusters: container insights, execute-command
configuration (KMS key, CloudWatch or S3 logging), and total cluster
capacity provider association (built-in FARGATE/FARGATE_SPOT or
consumer-managed provider names) with an optional default strategy.

## Destroy semantics (read before using)

- Removing a key destroys the cluster. ECS refuses to delete a cluster
  while services or tasks still exist **in that cluster** — services live
  in the separate `aws/ecs-service` module, so destroy order is services
  first, cluster second (with Terragrunt dependencies, reverse the
  dependency direction).
- The capacity-provider association is authoritative for the cluster:
  clearing `capacity_providers` (and the default strategy) removes the
  association, not just its drift.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | `{}` | Map of clusters keyed by an arbitrary unique ID. |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cluster name, 1–255 characters of letters, digits, hyphens and underscores (validated). |
| `enable_container_insights` | `bool` | — | Explicit `enabled`/`disabled` for container insights; leaving it unset keeps the account default. |
| `execute_command_configuration` | `object` | — | `{kms_key_id, logging, log_configuration}` — execute-command session recording. `logging` is `DEFAULT`, `OVERRIDE` or `NONE` (validated); `OVERRIDE` requires `log_configuration` (validated). |
| `execute_command_configuration.log_configuration` | `object` | — | `{cloud_watch_log_group_name, cloud_watch_encryption_enabled, s3_bucket_name, s3_bucket_encryption_enabled, s3_key_prefix}` — CloudWatch or S3 destination for session logs. |
| `capacity_providers` | `list(string)` | `[]` | Capacity providers to associate with the cluster. `FARGATE` and `FARGATE_SPOT` are built-in names; other names must exist (ASG-backed providers are managed consumer-side). Presence manages the `aws_ecs_cluster_capacity_providers` association. |
| `default_capacity_provider_strategy` | `list(object)` | `[]` | Default strategy entries `{capacity_provider, weight, base}` — every capacity provider must appear in `capacity_providers` (validated). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

## Outputs

`cluster_ids` — map of cluster key => cluster ID.
`cluster_arns` — map of cluster key => cluster ARN.
`cluster_names` — map of cluster key => cluster name.

## Example

```hcl
clusters = {
  "main" = {
    name                      = "example-main"
    enable_container_insights = true
    capacity_providers        = ["FARGATE", "FARGATE_SPOT"]
    default_capacity_provider_strategy = [
      { capacity_provider = "FARGATE", weight = 1 },
      { capacity_provider = "FARGATE_SPOT", weight = 1 }
    ]
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not cluster names.
- `FARGATE` / `FARGATE_SPOT` are built-in provider names — associate them
  by name; no `aws_ecs_capacity_provider` resource is needed. ASG-backed
  custom providers are out of this module's scope: manage
  `aws_ecs_capacity_provider` consumer-side and pass the name in
  `capacity_providers`.
- Execute-command recording also needs `enable_execute_command` on the
  service (see `aws/ecs-service`) and SSM permissions on the task role —
  consumer-side.
- `managed_storage_configuration` (FARGATE ephemeral-storage KMS key) and
  `service_connect_defaults` are natural KMS-pairing candidates, omitted
  here as a future addition if a consumer needs them. Service connect and
  Cloud Map service registries are likewise out of scope.

## Import

`aws_ecs_cluster` ← cluster name.
`aws_ecs_cluster_capacity_providers` ← cluster name.
