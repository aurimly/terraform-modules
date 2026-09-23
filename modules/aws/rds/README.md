# aws/rds

Map-keyed module for Amazon RDS: standalone DB instances and Aurora/RDS
clusters with member instances — one entry per database, plan-time
validated for the common API rejections.

## Destroy semantics (read before using)

- **Instances**: the final-snapshot guard applies. With
  `skip_final_snapshot = false` (default) the delete takes a final
  snapshot named by `final_snapshot_identifier` (required, precondition);
  with `skip_final_snapshot = true` the instance is deleted with **no
  final snapshot** and `delete_automated_backups` (default provider
  behavior) also drops automated backups. Deletion protection
  (`deletion_protection = true`, default `false`) blocks API deletion —
  disable it first.
- **Clusters**: same final-snapshot guard. Cluster deletion refuses when
  member instances still exist — the module destroys member instances
  before the cluster within the same run (instance resources are keyed
  under the cluster), but Terraform does not order that strictly: if a
  destroy plan fails on the cluster, apply again after instances are
  gone.
- Renaming `identifier`/`identifier_prefix` **replaces** the instance or
  cluster (new DB, data migrated only via snapshots).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | `{}` | Map of standalone RDS instances keyed by an arbitrary unique ID. |
| `clusters` | `map(object)` | `{}` | Map of Aurora/RDS clusters (with nested member instances) keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `identifier` | `string` | — | DB instance identifier (naming rules validated). Set this **or** `identifier_prefix` (validated). Immutable; changing replaces the instance. |
| `identifier_prefix` | `string` | — | Prefix for a provider-generated unique identifier. |
| `engine` | `string` | — | RDS engine identifier: `mysql`, `postgres`, `mariadb`, `oracle-*`, `sqlserver-*`, `aurora-*`, `custom-*`, `db2-*` (validated). |
| `engine_version` | `string` | — | Engine version; pin explicitly for reproducibility. |
| `instance_class` | `string` | — | Instance class, e.g. `db.t3.medium`, `db.r6g.xlarge`. |
| `database_name` | `string` | — | Initial database name (API-named `db_name`). |
| `master_username` | `string` | — | Master username; required with `master_password` for most engines at creation. |
| `master_password` | `string` | — | Master password. Prefer `manage_master_user_password` paths (IAM auth / Secrets Manager) consumer-side; this module passes the plaintext only if you choose to supply it. |
| `port` | `number` | — | Listen port. |
| `allocated_storage` | `number` | — | Allocated storage in GiB. |
| `max_allocated_storage` | `number` | — | Storage autoscaling upper bound in GiB. |
| `storage_type` | `string` | — | `standard`, `gp2`, `gp3`, `io1`, `io2` (validated). |
| `iops` | `number` | — | Provisioned IOPS; requires `io1`/`io2`/`gp3` (validated). |
| `storage_throughput` | `number` | — | Storage throughput; `gp3` only (validated). |
| `storage_encrypted` | `bool` | — | Encryption at rest. |
| `kms_key_id` | `string` | — | CMK; requires `storage_encrypted = true` (precondition/validated). |
| `multi_az` | `bool` | — | Multi-AZ deployment. |
| `publicly_accessible` | `bool` | `false` | Public IP assignment. |
| `db_subnet_group_name` | `string` | — | DB subnet group (required). |
| `security_group_ids` | `list(string)` | `[]` | VPC security groups. |
| `parameter_group_name` | `string` | — | Parameter group. |
| `option_group_name` | `string` | — | Option group (Oracle/SQL Server). |
| `backup_retention_period` | `number` | — | Automated backup retention in days, 0–35 (validated). |
| `backup_window` | `string` | — | Preferred backup window (`hh:mm-hh:mm`). |
| `maintenance_window` | `string` | — | Preferred maintenance window (`ddd:hh:mm-ddd:hh:mm`). |
| `copy_tags_to_snapshot` | `bool` | — | Copy tags to snapshots. |
| `skip_final_snapshot` | `bool` | `false` | Skip the final snapshot on destroy — see Destroy semantics. |
| `final_snapshot_identifier` | `string` | — | Final snapshot name; required when `skip_final_snapshot = false` (precondition/validated). |
| `deletion_protection` | `bool` | `false` | API-level deletion guard. |
| `auto_minor_version_upgrade` | `bool` | — | Auto minor version upgrades. |
| `allow_major_version_upgrade` | `bool` | — | Allow major version upgrade apply. |
| `apply_immediately` | `bool` | — | Apply changes outside the maintenance window. |
| `character_set_name` | `string` | — | Character set (MySQL/Oracle). |
| `timezone` | `string` | — | Timezone (SQL Server/Oracle). |
| `ca_cert_identifier` | `string` | — | Server certificate CA. |
| `enhanced_monitoring_interval` | `number` | — | Enhanced monitoring granularity in seconds (0, 1, 5, 10, 15, 30, 60). |
| `enhanced_monitoring_role_arn` | `string` | — | IAM role for enhanced monitoring. |
| `performance_insights_enabled` | `bool` | — | Performance Insights. |
| `performance_insights_kms_key_id` | `string` | — | PI CMK. |
| `performance_insights_retention_period` | `number` | — | PI retention (7, 731...). |
| `delete_automated_backups` | `bool` | — | Drop automated backups on delete. |
| `backup_target` | `string` | — | `region` or `outposts` (validated). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = identifier` (consumer tags win). |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `identifier` | `string` | — | Cluster identifier (naming rules validated); set this **or** `identifier_prefix` (validated). Immutable; changing replaces the cluster. |
| `identifier_prefix` | `string` | — | Prefix for a generated identifier. |
| `engine` | `string` | — | `aurora-mysql`, `aurora-postgresql`, `mysql`, `postgres` (validated; multi-AZ DB cluster data API uses the latter two). |
| `engine_version` | `string` | — | Engine version. |
| `engine_mode` | `string` | — | `provisioned`, `serverless`, `parallelquery`, `global`, `multimaster`, `iopt1` (validated). |
| `database_name` | `string` | — | Initial database name. |
| `master_username` | `string` | — | Master username. |
| `master_password` | `string` | — | Master password (see the plaintext caveat on `instances`). |
| `port` | `number` | — | Listen port. |
| `storage_encrypted` | `bool` | — | Encryption at rest. |
| `kms_key_id` | `string` | — | CMK; requires `storage_encrypted = true` (precondition/validated). |
| `db_subnet_group_name` | `string` | — | DB subnet group (required). |
| `security_group_ids` | `list(string)` | `[]` | VPC security groups. |
| `parameter_group_name` | `string` | — | Cluster parameter group. |
| `backup_retention_period` | `number` | — | Backup retention in days. |
| `backup_window` | `string` | — | Preferred backup window. |
| `maintenance_window` | `string` | — | Preferred maintenance window. |
| `copy_tags_to_snapshot` | `bool` | — | Copy tags to snapshots. |
| `skip_final_snapshot` | `bool` | `false` | Skip the final snapshot on destroy — see Destroy semantics. |
| `final_snapshot_identifier` | `string` | — | Required when `skip_final_snapshot = false` (precondition/validated). |
| `deletion_protection` | `bool` | `false` | API-level deletion guard. |
| `storage_type` | `string` | — | `aurora`, `aurora-iopt1`, `io1`, `io2`, `gp3` (validated). |
| `allocated_storage` | `number` | — | Allocated storage (multi-AZ clusters with `io1`/`io2`/`gp3`). |
| `iops` | `number` | — | Provisioned IOPS. |
| `apply_immediately` | `bool` | — | Apply changes immediately. |
| `enable_http_endpoint` | `bool` | — | Data API (Aurora Serverless v2/Provisioned with http endpoint). |
| `network_type` | `string` | — | `IPV4` or `DUAL` (validated). |
| `serverlessv2_scaling` | `object` | — | `{min_capacity, max_capacity}` for Serverless v2; aurora engines only (precondition). |
| `instances` | `map(object)` | — | Cluster member instances (at least one, validated); see the `instances` object table. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = identifier`. |

### `clusters.instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `identifier` | `string` | — | Member identifier; set this **or** `identifier_prefix` (validated). |
| `identifier_prefix` | `string` | — | Prefix for a generated identifier. |
| `instance_class` | `string` | — | Instance class (Aurora classes, e.g. `db.serverless` for v2). |
| `publicly_accessible` | `bool` | `false` | Public IP assignment. |
| `performance_insights_enabled` | `bool` | — | Performance Insights. |
| `performance_insights_kms_key_id` | `string` | — | PI CMK. |
| `performance_insights_retention_period` | `number` | — | PI retention. |
| `monitoring_interval` | `number` | — | Enhanced monitoring granularity. |
| `monitoring_role_arn` | `string` | — | Monitoring role ARN. |
| `auto_minor_version_upgrade` | `bool` | — | Auto minor upgrades. |
| `promotion_tier` | `number` | — | Failover priority tier (0–15). |
| `ca_cert_identifier` | `string` | — | Server certificate CA. |

## Outputs

`instance_arns` — map of instance key => ARN.
`instance_addresses` — map of instance key => connection address.
`instance_endpoints` — map of instance key => `host:port`.
`cluster_arns` — map of cluster key => ARN.
`cluster_endpoints` — map of cluster key => writer `host:port`.
`cluster_reader_endpoints` — map of cluster key => reader `host:port`.
`cluster_ids` — map of cluster key => cluster identifier.
`cluster_instance_ids` — map of `"cluster-key.instance-key"` => member identifier.

## Example

```hcl
clusters = {
  "main" = {
    identifier_prefix = "example-"
    engine            = "aurora-postgresql"
    engine_version    = "15.4"
    database_name     = "exampledb"
    master_username   = "exampleadmin"
    db_subnet_group_name = "example-db-subnet-group"
    security_group_ids = ["sg-0123456789abcdef0"]
    storage_encrypted = true
    serverlessv2_scaling = {
      min_capacity = 0.5
      max_capacity = 16
    }
    instances = {
      "writer" = {
        identifier_prefix = "example-writer-"
        instance_class    = "db.serverless"
      }
      "reader" = {
        identifier_prefix = "example-reader-"
        instance_class    = "db.serverless"
        promotion_tier    = 1
      }
    }
    tags = {
      Environment = "example"
    }
  }
}

instances = {
  "legacy" = {
    identifier            = "example-legacy-db"
    engine                = "postgres"
    engine_version        = "15.4"
    instance_class        = "db.t3.medium"
    allocated_storage     = 50
    max_allocated_storage = 500
    storage_type          = "gp3"
    db_subnet_group_name  = "example-db-subnet-group"
    multi_az              = true
    storage_encrypted     = true
    backup_retention_period = 14
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not identifiers/ARNs.
- `master_password` is plaintext in state when supplied; prefer AWS
  Secrets Manager-managed master passwords (consumer-side
  `manage_master_user_password = true` is not exposed here yet — file an
  issue if needed) or supply the password from a secret manager
  reference.
- Failover ordering: `promotion_tier = 0` fails over first; the writer
  instance key is only convention, not API-enforced.
- Pair with `aws/security-group` and `aws/subnet` (plus a DB subnet
  group resource consumer-side) for the network plumbing.

## Import

`aws_db_instance` ← instance identifier.
`aws_rds_cluster` ← cluster identifier.
`aws_rds_cluster_instance` ← member instance identifier.
Import addresses follow the composite keys of the outputs for cluster
members (`cluster_instance["cluster-key.instance-key"]`).
