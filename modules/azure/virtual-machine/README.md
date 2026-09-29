# azure/virtual-machine

Map-keyed module for Azure virtual machines. Each entry creates either an
`azurerm_linux_virtual_machine` or an `azurerm_windows_virtual_machine`
depending on `os_type`, in the named resource group, in the subscription
configured on the provider. Each entry also creates the VM's managed OS disk
inline — no separate disk resources.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `virtual_machines` | `map(object)` | — | Map of virtual machines keyed by an arbitrary unique ID. |

Plan-time validation: `os_type` is `Linux`/`Windows`, (name, resource group)
pairs are unique across entries case-insensitively, `name`,
`resource_group_name` and `location` are non-empty, `size` and
`admin_username` are non-empty, Windows entries carry `admin_password` and no
SSH keys, Linux entries follow the provider's auth rules (keys by default,
password only with password authentication enabled), `os_disk` uses allowed
storage types and caching modes, exactly one of `source_image_reference` /
`source_image_id` is set, `network_interface_ids` is non-empty, ARM-format
and never shared between entries, `zone` is `1`/`2`/`3` and never combined
with `availability_set_id`, IDs are ARM-format, and tags respect the
50-entry / 512-char key / 256-char value limits.

### `virtual_machines` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `os_type` | `string` | — | `Linux` or `Windows` (case-sensitive) — picks the resource type the entry creates. |
| `name` | `string` | — | Virtual machine name. Validated loosely (non-empty) on purpose: Azure enforces its own naming rules at apply. Also the default `computer_name` — a Windows name over 15 characters fails at create unless an explicit `computer_name` is set (the provider errors, it does not truncate; the Linux counterpart validates ≤64). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the VM lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region for the VM — usually the region of its virtual network. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `size` | `string` | — | VM size, e.g. `Standard_B2s`. Resizing updates in place — the provider deallocates and reallocates automatically, so expect downtime — see Notes. |
| `admin_username` | `string` | — | Administrator account name. Immutable — changing it forces replacement. The provider plan-time-validates reserved names (admin, root, guest, ...). |
| `admin_password` | `string` | `null` | Administrator password — required for Windows (validated) and for Linux entries with `disable_password_authentication = false` (SSH keys do not satisfy the provider's check). Immutable — changing it forces replacement. The provider plan-time-validates complexity (Linux 6–72 chars, Windows 8–123, 3-of-4 character classes) and lands the password in state — see Notes. |
| `admin_ssh_keys` | `map(object)` | `{}` | SSH public keys for Linux entries (Windows entries must leave this empty — validated), keyed by an arbitrary identifier. The block's `username` is auto-set to `admin_username` — keys for other users have no useful ARM semantics. The set is immutable — see Notes. |
| `disable_password_authentication` | `bool` | `true` | Linux semantics, mirroring the provider's effective default: keys are required while `true`; `false` makes `admin_password` required. Immutable — changing it forces replacement. Not passed through for Windows entries (the Windows resource has no such attribute). |
| `computer_name` | `string` | `null` | Host name of the VM; defaults to `name`. Windows names are limited to 15 characters, Linux to 64 — set explicitly for long names. Immutable — changing it forces replacement. |
| `zone` | `string` | `null` | Availability zone: `1`, `2` or `3` (case-sensitive); unset means no zone pinning. Mutually exclusive with `availability_set_id` (validated, mirroring the provider). Immutable — changing it forces replacement. Must match the zones of attached NICs and public IPs (ARM validates at apply). |
| `availability_set_id` | `string` | `null` | Full ARM resource ID of an availability set to join. Immutable — changing it forces replacement. Azure also excludes availability sets and scale sets from combining — scale sets are out of scope for this module. |
| `network_interface_ids` | `list(string)` | — | Full ARM resource IDs of NICs to attach (typically `dependency.nic.outputs.network_interface_ids["app"]` with the `azure/network-interface` module); the first entry is the primary NIC. Required and non-empty, and a NIC may not appear in two entries (validated) — ARM attaches a NIC to one VM at a time. NOT immutable — see Notes. |
| `source_image_reference` | `object` | `null` | Marketplace image reference (`publisher`, `offer`, `sku`, `version` — all four required when set; `version` may be `latest`). Exactly one of `source_image_reference` / `source_image_id` (validated). Immutable — changing it forces replacement. |
| `source_image_id` | `string` | `null` | Full ARM resource ID of an image definition, shared gallery image version, community gallery or managed image. Immutable — changing it forces replacement. |
| `custom_data` | `string` | `null` | Base64-encoded cloud-init (Linux) or provisioning data — pass `base64encode(file("cloud-init.yaml"))`. The provider validates the encoding at plan time. Immutable — changing it forces replacement. |
| `os_disk` | `object` | — | Inline configuration of the managed OS disk the VM resource creates: `storage_account_type` (`Premium_LRS`, `Standard_LRS`, `StandardSSD_LRS`, `StandardSSD_ZRS` or `Premium_ZRS`), `caching` (`None`, `ReadOnly` or `ReadWrite`) — both required and case-sensitive — and optional `disk_size_gb`. See Notes for the disk lifecycle. |
| `boot_diagnostics` | `object` | `null` | Boot diagnostics: unset disables it; set with `storage_account_uri` null uses platform-managed storage (the provider's recommended shape); set with an `https://` URI uses that custom account. Updated in place. |
| `tags` | `map(string)` | `{}` | Tags on the VM. The tag set is authoritative — tags do not flow to NICs, disks or public IPs. |

### `admin_ssh_keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `public_key` | `string` | — | SSH public key material, e.g. `ssh-ed25519 AAAA... user@host`. The provider parses the key at plan time and only accepts valid RSA (2048+ bits) or ED25519 public keys. |

### `os_disk` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `storage_account_type` | `string` | — | `Premium_LRS`, `Standard_LRS`, `StandardSSD_LRS`, `StandardSSD_ZRS` or `Premium_ZRS` (case-sensitive). OS disks do not support Ultra SSD or PremiumV2. Immutable — changing it forces replacement. |
| `caching` | `string` | — | `None`, `ReadOnly` or `ReadWrite` (case-sensitive). Updated in place — the provider deallocates and reallocates automatically, so expect downtime, like disk growth. |
| `disk_size_gb` | `number` | `null` | OS disk size in GB; unset sizes from the image. Growing updates in place (the provider deallocates automatically); shrinking is rejected by ARM. |

## Outputs

| Name | Description |
|---|---|
| `virtual_machine_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<name>`), merged across the Linux and Windows resources — covers all input keys. |
| `virtual_machine_names` | Map of key => virtual machine name, merged across the Linux and Windows resources — covers all input keys. |

## Example

```hcl
virtual_machines = {
  "app" = {
    os_type             = "Linux"
    name                = "vm-app-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    size                = "Standard_B2s"
    admin_username      = "azureuser"
    admin_ssh_keys = {
      "deploy" = {
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9O6g2/XD0vJ0bv3EELLzkqWoBbGt3mo0MDlT8n+fnj example-placeholder"
      }
    }
    os_disk = {
      storage_account_type = "StandardSSD_LRS"
      caching              = "ReadWrite"
      disk_size_gb         = 30
    }
    source_image_reference = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }
    network_interface_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod/providers/Microsoft.Network/networkInterfaces/nic-app-prod"]
    zone = "1"
    tags = {
      env = "prod"
    }
  }
  "dc" = {
    os_type             = "Windows"
    name                = "vm-dc-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    size                = "Standard_B2s"
    admin_username      = "azureadmin"
    admin_password      = "Placeholder-Replace-Me-1"
    os_disk = {
      storage_account_type = "Premium_LRS"
      caching              = "ReadOnly"
    }
    source_image_reference = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    network_interface_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod/providers/Microsoft.Network/networkInterfaces/nic-dc-prod"]
    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- Two resource types under the hood: `os_type = "Linux"` entries land in
  `azurerm_linux_virtual_machine.linux_virtual_machine`, Windows entries in
  `azurerm_windows_virtual_machine.windows_virtual_machine`. An entry's key
  addresses whichever resource it lands in, and the outputs merge both.
- The inline `os_disk` is configuration for a managed OS disk the VM
  resource itself creates — no separate `azurerm_managed_disk` resource —
  and the disk is deleted with the VM on destroy. `disk_size_gb` grows in
   place (the provider deallocates automatically); shrinking is rejected by
   ARM. `storage_account_type` forces replacement when changed; `caching`
   updates in place with automatic deallocation.
- `network_interface_ids`: the first entry is the primary NIC; wire from
  `azure/network-interface`'s `network_interface_ids` output. A NIC attaches
  to one VM only (the module rejects sharing at plan time). NIC changes are
  not replacements — attach/detach updates in place with automatic
  shutdown + deallocation, so expect downtime, not a new VM.- Admin auth mirrors the provider's create-time checks: Linux defaults to
  password authentication disabled (SSH keys required); set
  `disable_password_authentication = false` to use a password, which then
  becomes required — SSH keys do not satisfy it. Windows requires
  `admin_password`. The provider plan-time-validates password complexity
  (Linux 6–72 chars, Windows 8–123, 3-of-4 character classes) and reserved
  admin usernames (admin, root, guest, ...) — errors surface at plan, not
  apply. Passwords land in the Terraform state; prefer SSH keys on Linux and
  keep state storage secure.
- `admin_ssh_keys`: the block's `username` is auto-set to `admin_username`
  (keys for other users have no useful ARM semantics — ARM creates no
  users). The set is immutable: SSH keys cannot be changed once provisioned,
  so key changes force replacement.
- `computer_name` defaults to `name`; the provider errors at create when a
  Windows name exceeds 15 characters without an explicit `computer_name`
  (it does not truncate; the Linux counterpart validates ≤64 the same way).
- `zone` and `availability_set_id` are mutually exclusive (validated,
  mirroring the provider's conflict rule). Scale sets are out of scope. The
  zone must match the zones of attached NICs and public IPs (ARM validates
  at apply).
- Marketplace `plan` blocks (image terms acceptance) are out of scope — for
  images requiring terms acceptance, accept them once via the CLI and use
  `source_image_id` against a stored image or gallery version.
- `custom_data`: pass base64-encoded data (e.g.
  `base64encode(file("cloud-init.yaml"))`) — the provider validates the
  encoding at plan time; changing it forces replacement.
- `boot_diagnostics`: omit the attribute entirely to leave it off; set it
  with no `storage_account_uri` for platform-managed storage; set an
  `https://` URI for a custom storage account.
- Private IPs live on NICs — read `azure/network-interface`'s
  `network_interface_private_ips` output rather than expecting VM outputs.
- The caller needs `Microsoft.Compute/virtualMachines/write` (and delete)
  on the resource group, `Microsoft.Network/networkInterfaces/join/action`
  on attached NICs, and
  `Microsoft.Network/publicIPAddresses/join/action` on public IPs carried by
  those NICs.
- Not exposed, deliberately: managed identities (identity blocks, with
  system-assigned + user-assigned maps and principal ID outputs — a natural
  backward-compatible follow-up), `os_managed_disk_id` (bring-your-own OS
  disk; the module always creates the OS disk), extensions, spot/eviction
  settings (`priority`, `eviction_policy`, `max_bid_price`), proximity
  placement groups, dedicated hosts, `license_type` (AHB/BYOS), Windows
  `patch_mode`/`timezone`, `encryption_at_host_enabled`, Trusted Launch
  (`secure_boot_enabled`/`vtpm_enabled`), CMEK OS-disk encryption
  (`disk_encryption_set_id`), and marketplace plan blocks.

## Import

`tofu import 'azurerm_linux_virtual_machine.linux_virtual_machine["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<name>"`

`tofu import 'azurerm_windows_virtual_machine.windows_virtual_machine["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<name>"`
