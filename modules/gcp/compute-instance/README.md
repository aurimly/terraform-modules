# gcp/compute-instance

Map-keyed module for Google Cloud compute instances with optional disks and IAM bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of compute instances keyed by an arbitrary unique ID; each entry creates one `google_compute_instance` plus optional additional disks and IAM bindings. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Instance name; 1–63 lowercase RFC1035 characters. Validated client-side. Changing forces replacement. |
| `zone` | `string` | — | GCP zone (e.g. `us-central1-a`). Shape-validated, not a zone list. Changing forces replacement. |
| `machine_type` | `string` | — | e.g. `e2-medium`. Changing stops and re-provisions the instance. |
| `project_id` | `string` | — | Project the instance lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `hostname` | `string` | — | Custom FQDN; must be RFC1035-compliant. |
| `can_ip_forward` | `bool` | — | Allow packet forwarding (NAT/router instances). |
| `allow_stopping_for_update` | `bool` | — | Let Terraform stop the instance to apply in-place changes; without it, such updates fail. |
| `deletion_protection` | `bool` | — | Blocks API deletes; `terraform destroy` fails until unset. |
| `min_cpu_platform` | `string` | — | Minimum CPU platform (e.g. `AMD Milan`). |
| `tags` | `list(string)` | — | Network tags for firewall rule targeting. |
| `labels` | `map(string)` | `{}` | Resource labels. |
| `metadata` | `map(string)` | — | Instance metadata. |
| `metadata_startup_script` | `string` | — | Startup script; cannot be combined with a `startup-script` key in `metadata` (validated). |
| `boot_disk` | `object` | — | Required. See the `boot_disk` table. |
| `disks` | `list(object)` | `[]` | Additional persistent disks: created (`google_compute_disk`) then attached (`google_compute_attached_disk`). See the `disks` entry table. |
| `network_interfaces` | `list(object)` | — | One or more; each must set `network` or `subnetwork` (validated). See the `network_interfaces` table. |
| `service_account` | `object` | — | `{email, scopes}`; `scopes` non-empty when set (e.g. `["cloud-platform"]`). Updating scopes requires `allow_stopping_for_update` or a stopped instance. |
| `scheduling` | `object` | — | See the `scheduling` table. |
| `shielded_instance_config` | `object` | — | `{enable_secure_boot (default false), enable_vtpm (default true), enable_integrity_monitoring (default true)}`. Requires a Shielded-VM-capable boot image. |
| `guest_accelerators` | `list(object)` | `[]` | `{type, count}` GPU entries; `count >= 1` (validated). |
| `advanced_machine_features` | `object` | — | `{enable_nested_virtualization, threads_per_core, visible_core_count}`. |
| `confidential_instance_config` | `object` | — | `{enable_confidential_compute, confidential_instance_type}`; type one of `SEV`, `SEV_SNP`, `TDX` (validated). Without `SEV` + `min_cpu_platform` `AMD Milan`/`AMD Genoa`, `on_host_maintenance` must be `TERMINATE`. |
| `network_performance_config` | `object` | — | `{total_egress_bandwidth_tier}`; one of `TIER_1`, `DEFAULT` (validated). |
| `iam_role_bindings` | `map(object)` | `{}` | Per-instance IAM: `{role, members, condition}` keyed by an arbitrary ID; `role` unique per instance (validated). `condition` is `{title, expression, description}` with `title` and `expression` required when present. |

### `boot_disk` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `image` | `string` | — | Image (name or self link) to create the boot disk from. Exactly one of `image`/`source` required (validated). Changing `image`, `size` or `type` forces instance replacement. |
| `source` | `string` | — | Existing persistent disk (name or self link) to boot from; `type`, `size` and `labels` are ignored with `source`. |
| `type` | `string` | — | Created-disk type, e.g. `pd-balanced` (derived from the image when unset). |
| `size` | `number` | — | Created-disk size in GB (derived from the image when unset). Growing later forces replacement — see Notes. |
| `labels` | `map(string)` | — | Labels for the created boot disk. |
| `auto_delete` | `bool` | `true` | Delete the boot disk when the instance is deleted. |
| `device_name` | `string` | — | Device name reflected in the guest OS. |
| `mode` | `string` | — | Must be `READ_WRITE` when set (boot disks cannot be `READ_ONLY` — validated). |

### `disks` entry

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Disk name; RFC1035-validated, distinct within the entry (validated). |
| `size` | `number` | — | Size in GB; > 0 when set (validated). Resizable in place. |
| `type` | `string` | — | e.g. `pd-ssd`, `pd-balanced`. |
| `description` | `string` | — | Human-readable description. |
| `labels` | `map(string)` | — | Resource labels. |
| `mode` | `string` | — | Attach mode: `READ_WRITE` or `READ_ONLY` (validated). |
| `device_name` | `string` | — | Device name reflected in the guest OS. |

### `network_interfaces` entry

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network` | `string` | — | Network name (same project) or self link. At least one of `network`/`subnetwork` required (validated). |
| `subnetwork` | `string` | — | Subnetwork name or self link; must be in the instance's region. |
| `subnetwork_project` | `string` | — | Project of a shared-VPC subnetwork. |
| `network_ip` | `string` | — | Static internal IP. |
| `nic_type` | `string` | — | One of `GVNIC`, `VIRTIO_NET`, `MRDMA`, `IRDMA`, `IDPF` (validated). |
| `stack_type` | `string` | — | One of `IPV4_ONLY`, `IPV4_IPV6`, `IPV6_ONLY` (validated); defaults to `IPV4_ONLY`. |
| `queue_count` | `number` | — | Number of vNIC queues (total vCPUs ≥ 8). |
| `access_config` | `object` | — | External IPv4: `{nat_ip, network_tier}`; tier one of `PREMIUM`, `FIXED_STANDARD`, `STANDARD` (validated). Omit for an ephemeral address; pair `nat_ip` with `gcp/static_ip`. |
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

`instance_names` — map of instance key => name.
`instance_self_links` — map of instance key => self link.
`instance_ids` — map of instance key => ID (`projects/{project}/zones/{zone}/instances/{name}`).
`internal_ips` — map of instance key => list of internal IPs (one per interface).
`external_ips` — map of instance key => list of external IPv4 addresses from `access_config`.
`disk_names` — map of instance key => list of created additional-disk names.

## Example

```hcl
instances = {
  "web" = {
    name         = "example-web-1"
    zone         = "us-central1-a"
    machine_type = "e2-medium"
    tags         = ["example-web"]
    boot_disk = {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-balanced"
    }
    disks = [
      {
        name = "example-web-1-data"
        size = 100
        type = "pd-ssd"
      },
    ]
    network_interfaces = [
      {
        subnetwork = "projects/example-project-1234/regions/us-central1/subnetworks/example-app"
        access_config = {}
      },
    ]
    service_account = {
      email  = "example-web@example-project-1234.iam.gserviceaccount.com"
      scopes = ["cloud-platform"]
    }
    iam_role_bindings = {
      "logs" = {
        role    = "roles/logging.logWriter"
        members = ["serviceAccount:example-web@example-project-1234.iam.gserviceaccount.com"]
      }
    }
  }
  "bouncer" = {
    name         = "example-bouncer"
    zone         = "us-central1-a"
    machine_type = "e2-small"
    can_ip_forward = true
    boot_disk = {
      source = "projects/example-project-1234/zones/us-central1-a/disks/example-bouncer-boot"
    }
    network_interfaces = [
      {
        subnetwork = "projects/example-project-1234/regions/us-central1/subnetworks/example-edge"
        access_config = {
          nat_ip = "projects/example-project-1234/regions/us-central1/addresses/example-edge-ip"
        }
      },
    ]
  }
}
```

## Notes

- One map entry = one instance. A map key is an arbitrary unique identifier,
  not a resource name — several entries may share a `name` in different
  zones/projects.
- The boot disk is created inline via `boot_disk.initialize_params`
  (`image`, `type`, `size`, `labels`), not as a separate
  `google_compute_disk` resource. Consequence: growing the boot disk
  later replaces the instance — size the boot disk up front, or create and
  manage the disk outside this module and boot via `boot_disk.source`.
  Additional disks (`disks`) keep the create-then-attach pattern, so they
  can be resized and attached/detached without touching the instance.
- The instance sets `lifecycle { ignore_changes = [attached_disk] }`
  (provider requirement when using `google_compute_attached_disk` — the two
  resources otherwise fight over the attached disk block).
- Created `disks` entries are not auto-deleted with the instance: deleting
  the instance leaves the disk, which stays module-managed until the entry
  is removed from `disks`.
- Spot VMs: set `scheduling.provisioning_model = "SPOT"` (implies
  `preemptible`), `automatic_restart = false` and — where wanted —
  `instance_termination_action`. `instance_termination_action` is rejected
  for non-Spot provisioning models.
- `metadata_startup_script` and a `startup-script` key in `metadata` are
  mutually exclusive; the provider rejects both at once.
- `deletion_protection = true` blocks API deletes; `allow_stopping_for_update`
  gates in-place changes that require a stop (e.g. service account scopes).
- Confidential VMs require `on_host_maintenance = "TERMINATE"` unless the
  type is `SEV` with `min_cpu_platform` `AMD Milan`/`AMD Genoa` (API-enforced).
- Pair with `gcp/vpc` (`network` names/self links), `gcp/subnet`
  (`subnetwork` self links), `gcp/static_ip` (`access_config.nat_ip`), and
  `gcp/firewall` (`tags` targeting).

- Not yet in scope (future additions): `scratch_disk` (local SSD), attach-only
  `attached_disk` (existing disks), `reservation_affinity`,
  `key_revocation_action_type`, `resource_manager_tags`, `params`,
  `min_node_cpus`, `workload_identity_config`, `network_attachment`, `vlan`,
  `igmp_query`, `enable_display`, instance/disk CMEK keys, scheduling extras
  (`max_run_duration`, `termination_time`, `availability_domain`,
  `host_error_timeout_seconds`, `local_ssd_recovery_timeout`),
  `desired_status`.

## Import

`google_compute_instance` ←
`projects/{project}/zones/{zone}/instances/{name}` (also
`{project}/{zone}/{name}` and the bare `{name}` within the provider's default
zone).

`google_compute_disk` ←
`projects/{project}/zones/{zone}/disks/{name}` (also shorter forms).

`google_compute_attached_disk` ←
`projects/{project}/zones/{zone}/instances/{instance}/{disk}`.

`google_compute_instance_iam_binding` ←
`projects/{project}/zones/{zone}/instances/{instance} roles/{role}` — note the
space separator and the fully qualified `roles/...` name.
