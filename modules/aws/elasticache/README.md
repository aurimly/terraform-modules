# aws/elasticache

Map-keyed module for AWS ElastiCache: Redis/Valkey replication groups
(single or clustered mode) and memcached clusters in one module. Covers
subnet groups and parameter groups (both module-created or
pass-through), AUTH tokens (including write-only), TLS and KMS
encryption, snapshots, log delivery, and maintenance windows.

## Destroy semantics (read before using)

- Removing a redis entry **deletes the replication group and all its
  data** unless `final_snapshot_identifier` is set — ElastiCache has no
  `skip_final_snapshot` switch (unlike RDS); a final snapshot happens
  only when you name one.
- `final_snapshot_identifier` and `snapshot_name` must be unique in the
  region and **cannot be reused after restore**; plan names accordingly.
- Redis replication groups materialize as clusters named
  `<replication_group_id>-00N`; those IDs are also region-unique.
- Module-created subnet and parameter groups are named after the input
  map key and are region-unique — a name collision with an existing
  group fails at apply.
- Memcached nodes are deleted immediately with the module (no final
  snapshot concept exists for memcached).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `redis_clusters` | `map(object)` | `{}` | Redis/Valkey replication groups keyed by an arbitrary unique ID. Map keys must not contain `.` (validated — subnet/parameter group addresses derive from the key). |
| `memcached_clusters` | `map(object)` | `{}` | Memcached clusters keyed by an arbitrary unique ID. Same no-`.` rule (validated, consistency). |

### `redis_clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `replication_group_id` | `string` | — | Customer-supplied group ID: lowercase alphanumerics and hyphens, starts with a letter, no trailing hyphen, 2–40 chars (validated). Region-unique; must be unique across entries and across both variables (validated). |
| `description` | `string` | `Managed by Terraform` | Group description. |
| `engine` | `string` | `redis` | `redis` or `valkey` (validated). |
| `engine_version` | `string` | — | Major.minor, e.g. `7.1`; the API picks the latest compatible patch (running version in `engine_version_actual`). Changing the minor here upgrades the group (next maintenance window unless `apply_immediately`). |
| `node_type` | `string` | — | e.g. `cache.t4g.small`. |
| `port` | `number` | — | Node port (AWS default 6379). |
| `num_cache_clusters` | `number` | — | Replica-group (non-cluster-mode) size. Mutually exclusive with `num_node_groups` (validated); both omitted = a single cluster. |
| `preferred_cache_cluster_azs` | `list(string)` | — | AZs per cache cluster; length must equal `num_cache_clusters` (validated). |
| `num_node_groups` | `number` | — | Cluster-mode shard count (1–500, validated). |
| `replicas_per_node_group` | `number` | — | Cluster-mode replicas per shard (0–5, validated); requires `num_node_groups` (validated). AWS default: 1. |
| `automatic_failover_enabled` | `bool` | — | Required `true` for cluster mode or multi-AZ; with `num_cache_clusters` set it requires ≥ 2 clusters (validated). |
| `multi_az_enabled` | `bool` | — | Requires `automatic_failover_enabled = true` (validated). |
| `subnet_ids` | `list(string)` | — | Subnet IDs (≥ 2 distinct AZs, validated) — module creates the subnet group. Exactly one of `subnet_ids`/`subnet_group_name` (validated). |
| `subnet_group_name` | `string` | — | Existing subnet group pass-through. |
| `security_group_ids` | `list(string)` | `[]` | SG IDs pass-through (pair with `aws/security-group`); empty = the default VPC SG. |
| `parameter_group_name` | `string` | — | Existing parameter group pass-through. Mutually exclusive with `parameter_group` (validated). |
| `parameter_group` | `object` | — | Module-created group: `{family, parameters (map), description}`. `family` e.g. `redis7.0`, `valkey8`. |
| `auth_token` | `string` | — | AUTH token in state (sensitive). 16–128 chars (validated); requires `transit_encryption_enabled`. |
| `auth_token_wo` | `string` | — | Write-only AUTH token (provider v6; not in state); use with `auth_token_wo_version` (validated pair). |
| `auth_token_wo_version` | `number` | — | Rotation buster for `auth_token_wo`. |
| `transit_encryption_enabled` | `bool` | — | TLS in transit; required for AUTH (validated). |
| `at_rest_encryption_enabled` | `bool` | — | Encryption at rest (engine default differs: `false` for redis, `true` for valkey). |
| `kms_key_id` | `string` | — | KMS key for at-rest encryption; requires `at_rest_encryption_enabled = true` (validated). |
| `auto_minor_version_upgrade` | `bool` | — | AWS default: `true` (redis ≥ 6). |
| `maintenance_window` | `string` | — | `ddd:hh24:mi-ddd:hh24:mi`, e.g. `sun:05:00-sun:09:00` (validated). |
| `apply_immediately` | `bool` | `false` | Apply changes outside the maintenance window. |
| `notification_topic_arn` | `string` | — | SNS topic ARN for events. |
| `snapshot_retention_limit` | `number` | — | Automatic-snapshot retention (days). |
| `snapshot_window` | `string` | — | Automatic snapshot window (`hh24:mi-hh24:mi` UTC). |
| `final_snapshot_identifier` | `string` | — | Name a final snapshot on destroy (see destroy semantics). |
| `snapshot_name` | `string` | — | Seed from an existing Redis snapshot name. |
| `snapshot_arns` | `list(string)` | — | Seed from snapshot ARNs. |
| `log_delivery_configurations` | `map(object)` | `{}` | Keyed by `log_type` (`slow-log`, `engine-log` — key must equal the entry's log_type, enforcing max one of each; validated): `{destination, destination_type, log_format, log_type}` with `destination_type` `cloudwatch-logs`/`kinesis-firehose` and `log_format` `json`/`text` (validated). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = <replication_group_id>`. |

### `memcached_clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_id` | `string` | — | Same rules as `replication_group_id` but 2–50 chars (validated). |
| `engine_version` | `string` | — | Three-part version, e.g. `1.6.38` (validated). |
| `node_type` | `string` | — | e.g. `cache.t4g.small`. |
| `num_cache_nodes` | `number` | `1` | 1–40 (validated). |
| `az_mode` | `string` | — | `single-az` or `cross-az` (validated); `cross-az` requires `num_cache_nodes > 1` (validated). |
| `availability_zone` | `string` | — | Pins all nodes to one AZ; cannot combine with `az_mode = "cross-az"` (validated). |
| `preferred_availability_zones` | `list(string)` | — | Length must equal `num_cache_nodes` (validated). |
| `port` | `number` | — | Memcached port (default 11211). |
| `subnet_ids` | `list(string)` | — | Subnet IDs; module-created group. Exactly one of `subnet_ids`/`subnet_group_name` (validated). |
| `subnet_group_name` | `string` | — | Existing subnet group pass-through. |
| `security_group_ids` | `list(string)` | `[]` | SG IDs pass-through. |
| `parameter_group_name` | `string` | — | e.g. `default.memcached1.6`. Exactly one of `parameter_group_name`/`parameter_group` is required (validated). |
| `parameter_group` | `object` | — | Module-created group: `{family, parameters (map), description}`; `family` e.g. `memcached1.6`. |
| `transit_encryption_enabled` | `bool` | — | TLS; supported for memcached 1.6.12+ in a VPC. Memcached has no AUTH-token support in this module (and no log delivery — Redis-only per the provider). |
| `maintenance_window` | `string` | — | As redis. |
| `apply_immediately` | `bool` | `false` | As redis. |
| `notification_topic_arn` | `string` | — | As redis. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = <cluster_id>`. |

Memcached does not support `log_delivery_configurations` or snapshots
(Redis-only per the provider) — those attributes exist only on
`redis_clusters`.

## Outputs

Redis — all maps keyed by the `redis_clusters` input key:
`redis_cluster_ids` (replication group IDs), `redis_arns`,
`redis_primary_endpoints` + `redis_primary_ports`,
`redis_reader_endpoints` (null for cluster-mode keys — those endpoints
only exist in cluster-mode-disabled groups), `redis_configuration_endpoints`
(`{address, port}` objects; populated for cluster-mode groups only),
`redis_member_cluster_ids` (`<id>-00N` lists), `redis_subnet_group_names`,
`redis_parameter_group_names` (resolved names — module-created,
pass-through or engine default).

Memcached — all keyed identically: `memcached_cluster_ids`,
`memcached_arns`, `memcached_configuration_endpoints` (`{address, port}`
— the client-facing address), `memcached_addresses`, `memcached_ports`
and `memcached_cache_node_ids` (lists, one entry per node),
`memcached_subnet_group_names`, `memcached_parameter_group_names`.

## Example

```hcl
inputs = {
  redis_clusters = {
    "app-cache" = {
      replication_group_id       = "example-app-cache"
      node_type                  = "cache.t4g.small"
      num_cache_clusters         = 2
      automatic_failover_enabled = true
      multi_az_enabled           = true
      subnet_ids                 = dependency.subnets.outputs.subnet_ids["private-app"]
      security_group_ids         = [dependency.sgs.outputs.security_group_ids["redis"]]
      engine_version             = "7.1"
      parameter_group = {
        family = "redis7.1"
      }
      auth_token_wo         = "1234567890abcdef1234"
      auth_token_wo_version = 1
      transit_encryption_enabled  = true
      at_rest_encryption_enabled  = true
      kms_key_id                  = dependency.kms.outputs.key_arns["cache"]
      snapshot_retention_limit    = 7
      maintenance_window          = "sun:05:00-sun:09:00"
      log_delivery_configurations = {
        "slow-log" = {
          destination      = dependency.logs.outputs.log_group_names["slow-log"]
          destination_type = "cloudwatch-logs"
          log_format       = "json"
          log_type         = "slow-log"
        }
      }
      tags = { Environment = "example" }
    }
  }
  memcached_clusters = {
    "sessions" = {
      cluster_id     = "example-sessions"
      node_type      = "cache.t4g.small"
      num_cache_nodes = 2
      az_mode        = "cross-az"
      subnet_ids     = dependency.subnets.outputs.subnet_ids["private-app"]
      parameter_group_name = "default.memcached1.6"
    }
  }
}
```

## Notes

- **AWS provider >= 6.0.0 required** — `auth_token_wo`/
  `auth_token_wo_version` are write-only attributes added in v6; the
  module declares no `required_providers` (like all `modules/aws/*`
  here), so pin the provider at the consumer's root.
- Plaintext `auth_token` lands in Terraform state; prefer
  `auth_token_wo` fed from a secret — the value is write-only and
  `auth_token_wo_version` bumps trigger rotation.
- Omitting both `parameter_group_name` and `parameter_group` uses the
  engine default parameter group. Module-created parameter-group
  `family` strings must match the engine (`redis7.1`, `valkey8`,
  `memcached1.6`, ... — check the ElastiCache console/engine docs).
- ElastiCache needs subnets in **at least two AZs**; the subnet-group
  path validates ≥ 2 IDs in the input.
- Valkey defaults to at-rest encryption on in AWS; redis defaults off.
  `kms_key_id` requires explicitly setting
  `at_rest_encryption_enabled = true` for either engine (validated).
- Cluster-mode groups (`num_node_groups`) require
  `automatic_failover_enabled = true` and a replication group;
  `redis_configuration_endpoints` carries the CONFIG endpoint, app
  clients must support cluster mode.
- AWS lowercases supplied cluster IDs; the module's ID validations are
  stricter (lowercase-first, no consecutive hyphens) so configurations
  stay deterministic in plan — exact API rules are looser.
- Pairing: `subnet_ids` with `aws/subnet`, `security_group_ids` with
  `aws/security-group`, `notification_topic_arn` with `aws/sns`,
  log delivery destinations with `aws/cloudwatch` log groups / Kinesis
  Firehose delivery streams, `kms_key_id` with `aws/kms`.

## Import

`aws_elasticache_replication_group` ← replication group ID.
`aws_elasticache_cluster` ← cluster ID.
`aws_elasticache_subnet_group` ← subnet group name.
`aws_elasticache_parameter_group` ← parameter group name.
