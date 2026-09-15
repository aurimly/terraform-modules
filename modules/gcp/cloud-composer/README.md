# gcp/cloud-composer

Map-keyed module for Google Cloud Composer (Managed Airflow, Gen 3)
environments: software config (image version, Airflow overrides, PyPI
packages, env vars), workload sizing, maintenance windows, scheduled
snapshots, metadata retention, encryption, and networking.

**Compatibility: this module targets Managed Airflow Gen 3 (Composer 3)
only — Composer 3 image versions (`composer-3-*`) are validated. Consumers
running pinned Composer 2 environments (Gen 2) cannot use it; a Gen 2
surface would be a separate module or a later MINOR addition.**

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `environments` | `map(object)` | — | Map of environments keyed by an arbitrary unique ID. |

### `environments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Up to 63 chars, letters/digits/hyphens (validated). Immutable; changing forces replacement. |
| `region` | `string` | — | GCP region (validated). Deliberately required for a region-scoped module. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `labels` | `map(string)` | `{}` | User labels. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). Note: the environment's GCS bucket is NOT deleted with the environment. |
| `storage_config` | `object` | — | `{bucket}` (required inside the block) — reuse an existing bucket. |
| `config` | `object` | — | See `config` object table. |

### `config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `environment_size` | `string` | — | One of `ENVIRONMENT_SIZE_SMALL`, `ENVIRONMENT_SIZE_MEDIUM`, `ENVIRONMENT_SIZE_LARGE` (validated). |
| `enable_private_environment` | `bool` | — | Create a private environment (no public IPs for tenant components). |
| `enable_private_builds_only` | `bool` | — | PyPI builds get private connectivity to Google services only. |
| `node_config` | `object` | — | `{network, subnetwork, service_account, tags, composer_network_attachment, composer_internal_ipv4_cidr_block}`; subnetwork requires network. Gen-3 style: custom VPC attach via `network`/`subnetwork` or an existing `composer_network_attachment`. |
| `encryption_config` | `object` | — | `{kms_key_name}` fully-qualified CMEK key. Immutable. |
| `maintenance_window` | `object` | — | `{start_time, end_time, recurrence}`; recurrence is an RFC-5545 RRULE with `FREQ=DAILY` or `FREQ=WEEKLY;BYDAY=...` (validated). |
| `software_config` | `object` | — | See `software_config` object table. |
| `workloads_config` | `object` | — | All sub-blocks optional: `scheduler {cpu, memory_gb, storage_gb, count}`, `triggerer {cpu, memory_gb, count}` (cpu/memory/count are Required per the API when present), `web_server {cpu, memory_gb, storage_gb}`, `worker {cpu, memory_gb, storage_gb, min_count, max_count}` (min_count <= max_count validated), `dag_processor {cpu, memory_gb, storage_gb, count}` (count Required when present). |
| `recovery_config` | `object` | — | `{scheduled_snapshots_config {enabled, snapshot_location, snapshot_creation_schedule (unix-cron), time_zone}}`. |
| `data_retention_config` | `object` | — | `{airflow_metadata_retention_config {retention_mode, retention_days}}`; `retention_mode` one of `RETENTION_MODE_ENABLED`, `RETENTION_MODE_DISABLED` (validated). |

### `software_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `image_version` | `string` | — | Must be Composer 3 (`composer-3-airflow-<version>`, validated); e.g. `composer-3-airflow-2.6.3-build.4`. Immutable across majors — see Notes. |
| `airflow_config_overrides` | `map(string)` | `{}` | `section-option` keys, e.g. `core-dags_are_paused_at_creation`. |
| `pypi_packages` | `map(string)` | `{}` | Package name → version specifier (empty string for unpinned). |
| `env_variables` | `map(string)` | `{}` | `AIRFLOW__`-style keys are rejected by the API (validated); use `airflow_config_overrides` instead. |
| `web_server_plugins_mode` | `string` | — | `ENABLED` or `DISABLED` (validated). |
| `cloud_data_lineage_integration` | `object` | — | `{enabled}`. |

## Outputs

`environment_names` — map of environment key => name.
`environment_ids` — map of environment key =>
`projects/<project>/locations/<region>/environments/<name>`.
`environment_urls` — map of environment key => Airflow web UI URI.
`dag_gcs_prefixes` — map of environment key =>
`gs://<bucket>/dags/...` prefix (the provider exposes no bucket attribute;
the prefix identifies the bucket).
`gke_clusters` — map of environment key => GKE cluster name.

## Example

```hcl
environments = {
  "main" = {
    name   = "example-airflow"
    region = "europe-west1"
    config = {
      software_config = {
        image_version = "composer-3-airflow-2.10.2-build.3"
        airflow_config_overrides = {
          "core-dags_are_paused_at_creation" = "True"
        }
        pypi_packages = {
          "numpy" = ">=1.26.0"
        }
        env_variables = {
          "EXAMPLE_VARIABLE" = "value"
        }
      }
      workloads_config = {
        scheduler = {
          count     = 1
          cpu       = 0.5
          memory_gb = 2
        }
        triggerer = {
          cpu       = 0.5
          memory_gb = 1
          count     = 1
        }
        dag_processor = {
          count     = 1
          cpu       = 0.5
          memory_gb = 2
        }
        worker = {
          min_count = 1
          max_count = 3
          cpu       = 0.5
          memory_gb = 2
        }
      }
      node_config = {
        network         = "projects/example-prj/global/networks/vpc-example-prd"
        subnetwork      = "projects/example-prj/regions/europe-west1/subnetworks/example-sn"
        service_account = "composer-wkr@example-prj.iam.gserviceaccount.com"
      }
      maintenance_window = {
        start_time = "2024-01-01T00:00:00Z"
        end_time   = "2024-01-01T04:00:00Z"
        recurrence = "FREQ=WEEKLY;BYDAY=MO,TH"
      }
      recovery_config = {
        scheduled_snapshots_config = {
          enabled                    = true
          snapshot_creation_schedule = "0 0 * * *"
          time_zone                  = "UTC"
        }
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- Pair with `gcp/project-services` (`composer.googleapis.com`). There is no
  per-environment IAM resource — access control is project-level IAM plus
  Airflow RBAC (Airflow-level users/roles stay consumer-side, as does
  everything running inside Airflow: DAGs, scheduler tuning asks belong in
  `workloads_config`).
- The service account in `node_config.service_account` needs the
  `roles/composer.worker` role.
- Creating/updating an environment takes roughly 25 minutes; some config
  errors are only surfaced at apply time.
- `image_version` upgrades in place only between minor/patch Airflow
  versions (and builds); across major versions the environment is
  recreated (create a new environment instead).
- Most `software_config`/`workloads_config` fields update in place; PyPI
  package install failures can fail the update — check logs consumer-side.
  The web server CPU/memory/storage cannot be changed after creation.
- The environment's GCS bucket is not automatically deleted with the
  environment (`storage_config.bucket` must already exist when set).
- `traffic_routing_config` (Beta, Gen 3) is deliberately out of scope, as
  are the Gen 2/Gen 1 blocks (`private_environment_config`,
  `master_authorized_networks_config`, `web_server_network_access_control`,
  `node_count`, ...).

## Import

`google_composer_environment` ←
`projects/{project}/locations/{region}/environments/{name}`.
