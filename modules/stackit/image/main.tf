terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_image" "image" {
  for_each = var.images

  project_id      = each.value.project_id
  region          = each.value.region
  name            = each.value.name
  disk_format     = each.value.disk_format
  local_file_path = each.value.local_file_path
  min_disk_size   = each.value.min_disk_size
  min_ram         = each.value.min_ram
  labels          = each.value.labels

  config = each.value.config != null ? {
    boot_menu                = each.value.config.boot_menu
    cdrom_bus                = each.value.config.cdrom_bus
    disk_bus                 = each.value.config.disk_bus
    nic_model                = each.value.config.nic_model
    operating_system         = each.value.config.operating_system
    operating_system_distro  = each.value.config.operating_system_distro
    operating_system_version = each.value.config.operating_system_version
    rescue_bus               = each.value.config.rescue_bus
    rescue_device            = each.value.config.rescue_device
    secure_boot              = each.value.config.secure_boot
    uefi                     = each.value.config.uefi
    video_model              = each.value.config.video_model
    virtio_scsi              = each.value.config.virtio_scsi
  } : null
}
