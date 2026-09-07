# gcp/instance-template

Map-keyed module for Google Cloud instance templates.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `templates` | `map(object)` | — | Map of instance templates keyed by an arbitrary unique ID; each entry creates one `google_compute_instance_template`. |

### `templates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Template name; 1–63 lowercase RFC1035 characters. Mutually exclusive with `name_prefix` (exactly one required, validated). Templates are immutable — changing anything replaces the template. |
| `name_prefix` | `string` | — | Prefix for an auto-generated unique name, 1–54 lowercase characters (commonly ending in `-`). Use for rolling updates behind a managed instance group; the module always applies `create_before_destroy`. |
| `machine_type` | `string` | — | e.g. `e2-medium`. Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the template lives in; defaults to the provider-level project. Format validated. |
| `region` | `string` | — | The template itself is global; `region` only pins regional resources (e.g. `subnetwork` names). Shape-validated, not a region list. |
| `description` | `string` | — | Human-readable description of the template itself. |
| `instance_description` | `string` | — | Description stamped onto instances created from the template. |
| `labels` | `map(string)` | `{}` | Labels for instances created from the template. |
| `metadata` | `map(string)` | — | Instance metadata. |
| `metadata_startup_script` | `string` | — | Startup script; cannot be combined with a `startup-script` key in `metadata` (validated). |
| `tags` | `list(string)` | — | Network tags for firewall rule targeting. |
| `can_ip_forward` | `bool` | — | Allow packet forwarding (NAT/router instances). |
| `min_cpu_platform` | `string` | — | Minimum CPU platform (e.g. `AMD Milan`). |
| `resource_policies` | `list(string)` | — | Self links of resource policies to attach (currently max 1). |
| `disks` | `list(object)` | — | At least one disk entry (validated); at most one with `boot = true` (validated). See the `disks` entry table. Immutable; changing forces replacement. |
| `network_interfaces` | `list(object)` | — | One or more; each must set `network` or `subnetwork` (validated). See the `network_interfaces` table. |
| `service_account` | `object` | — | `{email, scopes}`; `scopes` non-empty when set (e.g. `["cloud-platform"]`). |
| `scheduling` | `object` | — | See the `scheduling` table. |
| `shielded_instance_config` | `object` | — | `{enable_secure_boot (default false), enable_vtpm (default true), enable_integrity_monitoring (default true)}`. Requires a Shielded-VM-capable boot image. |
| `guest_accelerators` | `list(object)` | `[]` | `{type, count}` GPU entries; `count >= 1` (validated). |
| `advanced_machine_features` | `object` | — | `{enable_nested_virtualization, threads_per_core, visible_core_count}`. |
| `confidential_instance_config` | `object` | — | `{enable_confidential_compute, confidential_instance_type}`; type one of `SEV`, `SEV_SNP`, `TDX` (validated). Without `SEV` + `min_cpu_platform` `AMD Milan`/`AMD Genoa`, `on_host_maintenance` must be `TERMINATE`. |
| `network_performance_config` | `object` | — | `{total_egress_bandwidth_tier}`; one of `TIER_1`, `DEFAULT` (validated). |

### `disks` entry

| Attribute | Type | Default | Description |
|---|---|---|---|
| `source_image` | `string` | — | Image (name or self link) to create the disk from. One of `source_image`, `source_snapshot`, `source` required unless `disk_type = "local-ssd"` (validated). |
| `source_snapshot` | `string` | — | Snapshot to create the disk from. |
| `source` | `string` | — | Name (**not** self link) of an existing persistent disk to attach. |
| `boot` | `bool` | — | Mark this disk as the boot disk (max one per template, validated). |
| `auto_delete` | `bool` | — | Delete the disk when its instance is deleted. |
| `device_name` | `string` | — | Device name reflected in the guest OS. |
| `disk_name` | `string` | — | Created disk name; RFC1035-validated. Defaults to an API-generated name. |
| `disk_type` | `string` | — | e.g. `pd-ssd`, `pd-balanced`, `hyperdisk-balanced`, `local-ssd`. |
| `disk_size_gb` | `number` | — | Size in GB; derived from the source image when unset. |
| `mode` | `string` | — | `READ_WRITE` or `READ_ONLY` (validated); boot disks cannot be `READ_ONLY` (validated). |
| `interface` | `string` | — | `SCSI` or `NVME` (mainly for local SSD). |
| `type` | `string` | — | `PERSISTENT` (default) or `SCRATCH`. |
| `labels` | `map(string)` | — | Labels for the created disk. |
| `provisioned_iops` | `number` | — | IOPS for extreme/hyperdisk types. |
| `provisioned_throughput` | `number` | — | MB/s throughput for hyperdisk types. |
| `resource_policies` | `list(string)` | — | Snapshot schedule policies (short name or id). |
| `source_image_encryption_key` | `object` | — | CMEK to decrypt the image: `{kms_key_self_link, kms_key_service_account}`. |
| `source_snapshot_encryption_key` | `object` | — | CMEK to decrypt the snapshot: `{kms_key_self_link, kms_key_service_account}`. |
| `disk_encryption_key` | `object` | — | CMEK to encrypt the new disk: `{kms_key_self_link, kms_key_service_account}`. |

### `network_interfaces` entry

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network` | `string` | — | Network name (same project) or self link. At least one of `network`/`subnetwork` required (validated). |
| `subnetwork` | `string` | — | Subnetwork name or self link; must be in the same region the instances run in. |
| `subnetwork_project` | `string` | — | Project of a shared-VPC subnetwork. |
| `network_ip` | `string` | — | Static internal IP. |
| `nic_type` | `string` | — | One of `GVNIC`, `VIRTIO_NET`, `MRDMA`, `IRDMA`, `IDPF` (validated). |
| `stack_type` | `string` | — | One of `IPV4_ONLY`, `IPV4_IPV6`, `IPV6_ONLY` (validated); defaults to `IPV4_ONLY`. |
| `queue_count` | `number` | — | Number of vNIC queues (total vCPUs ≥ 8). |
| `access_config` | `object` | — | External IPv4: `{nat_ip, network_tier}`; tier one of `PREMIUM`, `FIXED_STANDARD`, `STANDARD` (validated). Omit for an ephemeral address. |
| `ipv6_access_config` | `object` | — | `{network_tier}`; `PREMIUM` or `STANDARD` (validated). |
| `alias_ip_ranges` | `list(object)` | `[]` | `{ip_cidr_range, subnetwork_range_name}` secondary ranges. |

### `scheduling` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `automatic_restart` | `bool` | — | Restart on Compute-Engine-initiated termination (default `true`; preemptible VMs cannot combine it with `preemptible = true` — validated; Spot VMs should set it `false`). |
| `on_host_maintenance` | `string` | — | `MIGRATE` or `TERMINATE` (validated); `TERMINATE` required for most Spot/confidential setups. |
| `preemptible` | `bool` | — | Legacy preemptible; prefer `provisioning_model = "SPOT"`. |
| `provisioning_model` | `string` | — | `STANDARD` or `SPOT` (validated). |
| `instance_termination_action` | `string` | — | `STOP` or `DELETE`; Spot VMs only (validated). |
| `node_affinities` | `list(object)` | `[]` | `{key, operator, values}` sole-tenant affinities; operator `IN` or `NOT_IN` (validated). |

## Outputs

`template_names` — map of template key => name (auto-generated name when `name_prefix` is used).
`template_ids` — map of template key => ID (`projects/{project}/global/instanceTemplates/{name}`).
`template_self_links` — map of template key => self link.
`template_self_link_uniques` — map of template key => `self_link_unique`; preferred for
`gcp/instance-group-manager` `versions.instance_template` because it pins
the template revision (the plain self link resolves to the latest revision,
which breaks revision pinning and rolling updates).

## Example

```hcl
templates = {
  "web" = {
    name_prefix = "example-web-"
    machine_type = "e2-medium"
    disks = [
      {
        source_image = "debian-cloud/debian-12"
        boot         = true
        disk_type    = "pd-balanced"
        disk_size_gb = 20
        auto_delete  = true
      },
    ]
    network_interfaces = [
      {
        subnetwork = "projects/example-project-1234/regions/us-central1/subnetworks/example-app"
      },
    ]
    service_account = {
      email  = "example-web@example-project-1234.iam.gserviceaccount.com"
      scopes = ["cloud-platform"]
    }
  }
}
```

## Notes

- Templates are immutable in GCP — any change to the entry replaces the
  template. The module hardcodes `lifecycle { create_before_destroy = true }`:
  with a fixed `name`, a replacement then fails at apply (name conflict)
  instead of first destroying a template a managed instance group may still
  reference. For real rolling updates use `name_prefix` so each version gets
  a fresh name; the generated suffix is 24 characters for prefixes up to 37
  characters (16-char timestamp + 8-digit counter) and 9 characters for
  longer prefixes, so the full name stays ≤ 63 characters.
- At most one disk entry per template may have `boot = true`; the API
  requires the boot disk to be the first entry, so put it first.
- `region` does not localize the template (it is a global resource); it only
  disambiguates regional resources referenced by name, such as `subnetwork`.
- CMEK is supported via `kms_key_self_link` on the three encryption-key
  objects; raw customer-supplied keys (`raw_key`, `rsa_encrypted_key`) are
  deliberately out of scope to keep key material out of code.
- Spot VMs: set `scheduling.provisioning_model = "SPOT"` (implies
  `preemptible`), `automatic_restart = false` and — where wanted —
  `instance_termination_action`. `instance_termination_action` is rejected
  for non-Spot provisioning models.
- `metadata_startup_script` and a `startup-script` key in `metadata` are
  mutually exclusive; the provider rejects both at once.
- Pair with `gcp/instance-group-manager` (pass
  `template_self_link_uniques[key]` into `versions[].instance_template` via
  a Terragrunt dependency).

- Not yet in scope (future additions): `enable_display`, `maintenance_interval`,
  `graceful_shutdown`, `skip_guest_os_shutdown`, `preemption_notice_duration`,
  `partner_metadata`, `alias_ipv6_range`, `params`/`resource_manager_tags`
  (all beta-gated on the stable provider), `reservation_affinity`,
  `key_revocation_action_type`, `workload_identity_config`, `min_node_cpus`,
  `storage_pool`, `architecture`, `guest_os_features`, `network_attachment`,
  scheduling extras (`max_run_duration`, `termination_time`,
  `availability_domain`, `host_error_timeout_seconds`,
  `local_ssd_recovery_timeout`), and raw-key encryption material.

## Import

`google_compute_instance_template` ←
`projects/{project}/global/instanceTemplates/{name}` (also
`{project}/{name}` and the bare `{name}`).
