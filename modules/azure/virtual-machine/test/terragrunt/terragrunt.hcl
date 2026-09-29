terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   virtual_machines = {
#     "app" = {
#       os_type             = "Linux"
#       name                = "vm-app-prod"
#       resource_group_name = "rg-platform-prod"
#       location            = "westeurope"
#       size                = "Standard_B2s"
#       admin_username      = "azureuser"
#       admin_ssh_keys = {
#         "deploy" = {
#           public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9O6g2/XD0vJ0bv3EELLzkqWoBbGt3mo0MDlT8n+fnj example-placeholder"
#         }
#       }
#       source_image_reference = {
#         publisher = "Canonical"
#         offer     = "ubuntu-24_04-lts"
#         sku       = "server"
#         version   = "latest"
#       }
#       network_interface_ids = [dependency.nic.outputs.network_interface_ids["app"]]
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  virtual_machines = {
    "example-linux" = {
      os_type             = "Linux"
      name                = "vm-example"
      resource_group_name = "rg-example"
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
      network_interface_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/networkInterfaces/nic-example",
      ]
    }
    "example-windows" = {
      os_type             = "Windows"
      name                = "vm-example-win"
      resource_group_name = "rg-example"
      location            = "westeurope"
      size                = "Standard_B2s"
      admin_username      = "azureuser"
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
      network_interface_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/networkInterfaces/nic-example-win",
      ]
    }
  }
}
