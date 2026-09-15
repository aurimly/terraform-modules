# gcp/dataproc

Map-keyed module for Google Cloud Dataproc: classic GCE clusters with the GA
`cluster_config` surface (master/worker/secondary-worker group config, software,
network, encryption, lifecycle, autoscaling policy wiring), plus cluster IAM
bindings.

**`google_dataproc_cluster` does not support import — manage clusters from day
one in Terraform.**

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | — | Map of clusters keyed by an arbitrary unique ID. |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Up to 51 chars, lowercase letters/digits/hyphens, starts with a letter (validated — no underscores or uppercase). Immutable; changing forces replacement. |
| `region` | `string` | — | GCP region (validated). Deliberately required — the provider default region (`global`) is rarely what anyone wants. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `labels` | `map(string)` | `{}` | Labels (updatable in place — one of the few). |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). |
| `graceful_decommission_timeout` | `string` | — | Duration string (e.g. `120s`, max 1 day) for graceful decommission on node-count changes. |
| `cluster_config` | `object` | — | See `cluster_config` object table. |
| `role_bindings` | `map(object)` | `{}` | Cluster IAM bindings; see `role_bindings` object table — one resource per (cluster, role). |

### `cluster_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `staging_bucket` | `string` | — | GCS staging bucket; auto-created server-side when unset. |
| `temp_bucket` | `string` | — | GCS temp bucket; auto-created server-side when unset. |
| `cluster_tier` / `engine` | `string` | — | Newer GA-first fields, passed through as-is (no enum validated). |
| `gce_cluster_config` | `object` | — | `{zone, network, subnetwork, service_account, service_account_scopes, tags, internal_ip_only, metadata, shielded_instance_config{enable_secure_boot, enable_vtpm, enable_integrity_monitoring}}`; network conflicts with subnetwork (validated). |
| `master_config` / `worker_config` | `object` | — | `{num_instances, machine_type, min_cpu_platform, min_num_instances (worker only), disk_config, accelerators}`; see `disk_config`/`accelerators` tables. |
| `preemptible_worker_config` | `object` | — | `{num_instances, preemptibility, disk_config}`; the API alias for the *secondary* worker group — SPOT works. |
| `software_config` | `object` | — | `{image_version, override_properties, optional_components}`. |
| `initialization_actions` | `list(object)` | `[]` | `{script (gs:// URI), timeout_sec}` per entry. |
| `encryption_config` | `object` | — | `{kms_key_name}` CMEK for PD encryption. |
| `lifecycle_config` | `object` | — | `{idle_delete_ttl, auto_delete_time}`. |
| `autoscaling_config` | `object` | — | `{policy_uri}` fully-qualified policy URI. |

### `disk_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `boot_disk_type` | `string` | — | `pd-ssd` or `pd-standard`. |
| `boot_disk_size_gb` | `number` | — | GB (min 10). |
| `boot_disk_provisioned_iops` / `boot_disk_provisioned_throughput` | `number` | — | Provisioned disk performance. |
| `num_local_ssds` | `number` | — | Local SSDs per node, >= 0 (validated). |
| `local_ssd_interface` | `string` | — | `scsi` or `nvme`. (Not exposed on `preemptible_worker_config.disk_config`.) |

### `accelerators` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `accelerator_type` | `string` | — | Short name, e.g. `nvidia-tesla-k80`. |
| `accelerator_count` | `number` | — | >= 0 (validated). |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/dataproc.editor`. Must be unique within the cluster (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

## Outputs

`cluster_names` — map of cluster key => cluster name.
`cluster_ids` — map of cluster key =>
`projects/<project>/regions/<region>/clusters/<name>`; only populated for
clusters with an explicit `project_id` (when unset, the provider-level
project applies — the `google_dataproc_cluster` resource exports no
computed full name).
`cluster_effective_labels` — map of cluster key => effective labels.
`iam_binding_roles` — map of `"<cluster key>/<binding key>"` => role.

## Example

```hcl
clusters = {
  "spark" = {
    name   = "example-spark"
    region = "europe-west1"
    graceful_decommission_timeout = "600s"
    cluster_config = {
      staging_bucket = "example-prj-dataproc-staging"
      software_config = {
        image_version = "2.2.50-rocky9"
        override_properties = {
          "dataproc:dataproc.allow.zero.workers" = "true"
        }
      }
      gce_cluster_config = {
        subnetwork            = "projects/example-prj/regions/europe-west1/subnetworks/example-sn"
        internal_ip_only      = true
        service_account       = "dataproc-wkr@example-prj.iam.gserviceaccount.com"
        service_account_scopes = ["cloud-platform"]
      }
      master_config = {
        num_instances = 1
        machine_type  = "n2-standard-4"
        disk_config   = { boot_disk_type = "pd-ssd", boot_disk_size_gb = 100 }
      }
      worker_config = {
        num_instances = 2
        machine_type  = "n2-standard-4"
        disk_config   = { boot_disk_size_gb = 100, num_local_ssds = 1 }
      }
      preemptible_worker_config = {
        num_instances  = 2
        preemptibility = "SPOT"
      }
      initialization_actions = [
        { script = "gs://example-bucket/bootstrap.sh", timeout_sec = 500 },
      ]
      lifecycle_config = {
        idle_delete_ttl = "1800s"
      }
    }
    role_bindings = {
      "users" = {
        role    = "roles/dataproc.viewer"
        members = ["group:example-analysts@example.com"]
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- **Not importable**: `google_dataproc_cluster` does not support import —
  this is a manage-from-day-one module. IAM bindings are importable.
- **Cluster changes recreate the cluster**: per the API, all arguments
  except `labels` and the worker/secondary `num_instances` are
  non-updatable — most `cluster_config` changes destroy and recreate the
  whole cluster. Plan accordingly.
- Secondary workers: `preemptible_worker_config` is the API's
  secondaryWorkerConfig alias — `preemptibility = "SPOT"` is the modern
  short-lived capacity choice.
- Worker service account needs `roles/dataproc.worker` on the project and
  `roles/storage.objectViewer` on the staging bucket; the network needs
  internal-IP reachability (pair with `gcp/subnet`);
  `internal_ip_only` requires Private Google Access on the subnetwork.
- Pair with `gcp/project-services` (`dataproc.googleapis.com`).
- Out of scope: Dataproc on GKE (`virtual_cluster_config`), Kerberos
  `security_config` (URI-based KMS/GCS wiring deferred to a follow-up),
  beta-only `endpoint_config`/`metastore_config` (still marked beta in the
  provider), `auxiliary_node_groups`, `dataproc_metric_config`.

## Import

`google_dataproc_cluster` — **no import support**; manage from day one.
`google_dataproc_cluster_iam_binding` ←
`projects/{project}/regions/{region}/clusters/{cluster} {role}` (space
delimited; custom roles use the full
`projects/…/roles/…` name).
