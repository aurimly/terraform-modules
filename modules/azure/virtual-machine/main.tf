locals {
  linux_machines   = { for k, v in var.virtual_machines : k => v if v.os_type == "Linux" }
  windows_machines = { for k, v in var.virtual_machines : k => v if v.os_type == "Windows" }
}

resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  for_each = local.linux_machines

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  size                = each.value.size
  admin_username      = each.value.admin_username

  admin_password                  = each.value.admin_password
  disable_password_authentication = each.value.disable_password_authentication

  computer_name       = each.value.computer_name
  zone                = each.value.zone
  availability_set_id = each.value.availability_set_id

  network_interface_ids = each.value.network_interface_ids

  dynamic "admin_ssh_key" {
    for_each = each.value.admin_ssh_keys

    content {
      username   = each.value.admin_username
      public_key = admin_ssh_key.value.public_key
    }
  }

  dynamic "source_image_reference" {
    for_each = each.value.source_image_reference != null ? [1] : []

    content {
      publisher = each.value.source_image_reference.publisher
      offer     = each.value.source_image_reference.offer
      sku       = each.value.source_image_reference.sku
      version   = each.value.source_image_reference.version
    }
  }

  source_image_id = each.value.source_image_id

  custom_data = each.value.custom_data

  os_disk {
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  dynamic "boot_diagnostics" {
    for_each = each.value.boot_diagnostics != null ? [1] : []

    content {
      storage_account_uri = each.value.boot_diagnostics.storage_account_uri
    }
  }

  tags = each.value.tags
}

resource "azurerm_windows_virtual_machine" "windows_virtual_machine" {
  for_each = local.windows_machines

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  size                = each.value.size
  admin_username      = each.value.admin_username

  admin_password = each.value.admin_password

  computer_name       = each.value.computer_name
  zone                = each.value.zone
  availability_set_id = each.value.availability_set_id

  network_interface_ids = each.value.network_interface_ids

  dynamic "source_image_reference" {
    for_each = each.value.source_image_reference != null ? [1] : []

    content {
      publisher = each.value.source_image_reference.publisher
      offer     = each.value.source_image_reference.offer
      sku       = each.value.source_image_reference.sku
      version   = each.value.source_image_reference.version
    }
  }

  source_image_id = each.value.source_image_id

  custom_data = each.value.custom_data

  os_disk {
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  dynamic "boot_diagnostics" {
    for_each = each.value.boot_diagnostics != null ? [1] : []

    content {
      storage_account_uri = each.value.boot_diagnostics.storage_account_uri
    }
  }

  tags = each.value.tags
}
