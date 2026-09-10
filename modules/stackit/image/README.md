# stackit/image

Map-keyed module for STACKIT images uploaded from local image files.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `images` | `map(object)` | — | Map of images keyed by an arbitrary unique ID. |

### `images` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Image name. Changing it replaces the image. |
| `project_id` | `string` | — | STACKIT project UUID the image is uploaded to. |
| `disk_format` | `string` | — | Disk format: one of `ami`, `ari`, `aki`, `qcow2`, `raw`, `vdi`, `vpc`, `vmdk`. Changing it replaces the image. |
| `local_file_path` | `string` | — | Path to the local image file, resolved on the machine running OpenTofu/Terraform. Must exist at plan time (the provider checks this). Changing it replaces the image. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the image. |
| `min_disk_size` | `number` | `null` | Minimum disk size in GB required to boot the image. |
| `min_ram` | `number` | `null` | Minimum RAM in MB required to boot the image. |
| `config` | `object` | `null` | Optional hardware/scheduling configuration, see sub-table. |
| `labels` | `map(string)` | `{}` | Labels attached to the image. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. |

### `config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `boot_menu` | `bool` | `null` | Enable the boot menu. |
| `cdrom_bus` | `string` | `null` | Bus type for CD-ROM devices. |
| `disk_bus` | `string` | `null` | Bus type for disk devices (e.g. `virtio`). |
| `nic_model` | `string` | `null` | Network interface model. |
| `operating_system` | `string` | `null` | Operating system name. |
| `operating_system_distro` | `string` | `null` | Operating system distribution. |
| `operating_system_version` | `string` | `null` | Operating system version. |
| `rescue_bus` | `string` | `null` | Bus type for the rescue device. |
| `rescue_device` | `string` | `null` | Rescue device. |
| `secure_boot` | `bool` | `null` | Enable secure boot. |
| `uefi` | `bool` | `null` | Boot via UEFI. |
| `video_model` | `string` | `null` | Video device model. |
| `virtio_scsi` | `bool` | `null` | Enable virtio-scsi controller. |

## Outputs

`images` — map of image key => object:

| Attribute | Description |
|---|---|
| `image_id` | Image UUID. Feed into a server's `image_id` or a volume's `source.id`. |
| `checksum_algorithm` | Checksum algorithm of the uploaded image. |
| `checksum_digest` | Checksum digest of the uploaded image. |
| `protected` | Whether the image is protected from deletion. |
| `scope` | Image scope. |
| `id` | `"{project_id},{region},{image_id}"` — the import ID. |

## Example

```hcl
images = {
  "ubuntu" = {
    project_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region          = "eu01"
    name            = "ubuntu-2404-custom"
    disk_format     = "qcow2"
    local_file_path = "/path/to/ubuntu-24.04.qcow2"
    min_disk_size   = 10
    min_ram         = 512
    config = {
      disk_bus    = "virtio"
      virtio_scsi = true
    }
    labels = {
      "env" = "prod"
    }
  }
}
```

## Notes

- The IaaS (Compute Engine) service must be enabled on the STACKIT
  project before images can be uploaded — unlike some other STACKIT
  services, creating IaaS resources does not auto-enable it.
- `local_file_path` is resolved on the machine running OpenTofu/Terraform
  and must exist there at plan time; for remote-state CI runs the file
  must be present on the runner.
- Uploads are one-way: any change to an input replaces the image (a new
  upload). There is no in-place update.
- Image deletion may fail while the image is still referenced by servers
  or volumes; detach or delete dependents first.
- The resulting `image_id` is what the `modules/stackit/server` and
  `modules/stackit/volume` modules consume.
- Plan-time validation of `disk_format` only rejects formats the Glance
  API would reject anyway; the provider itself has no enum check.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_image` ← `{project_id},{region},{image_id}`

`local_file_path` is not fetched from the API, so an imported image also
needs it set plus `lifecycle { ignore_changes = [local_file_path] }` —
otherwise the first apply after import replaces the image.
