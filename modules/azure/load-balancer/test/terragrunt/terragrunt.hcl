terraform {
  source = "../../"
}

# Example inputs (commented). To plan against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   public_ips = {
#     "edge" = {
#       name                = "pip-lb-web-prod"
#       resource_group_name = "rg-web-prod"
#       location            = "westeurope"
#       availability_zone   = "1"
#       domain_name_label   = "web-prod"
#       tags = {
#         env = "prod"
#       }
#     }
#   }
#
#   load_balancers = {
#     "web" = {
#       name                = "lb-web-prod"
#       resource_group_name = "rg-web-prod"
#       location            = "westeurope"
#       sku_tier            = "Regional"
#
#       frontend_ip_configurations = {
#         "public" = {
#           name          = "web-frontend-public"
#           public_ip_key = "edge"
#           zones         = ["1", "2", "3"]
#         }
#         "private" = {
#           name                          = "web-frontend-internal"
#           subnet_id                     = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>"
#           private_ip_address            = "10.20.1.10"
#           private_ip_address_allocation = "Static"
#         }
#       }
#
#       backend_address_pools = {
#         "vms" = {
#           name = "web-backend-vms"
#           addresses = {
#             "vm1" = {
#               name               = "vm1"
#               ip_address         = "10.20.1.21"
#               virtual_network_id = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>"
#             }
#           }
#           nic_associations = {
#             "vm2" = {
#               network_interface_id  = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/networkInterfaces/<nic>"
#               ip_configuration_name = "ipconfig1"
#             }
#           }
#         }
#       }
#
#       probes = {
#         "http" = {
#           name                = "probe-http"
#           protocol            = "Http"
#           port                = 8080
#           request_path        = "/health"
#           interval_in_seconds = 15
#           number_of_probes    = 2
#         }
#       }
#
#       rules = {
#         "http" = {
#           name                          = "rule-http"
#           frontend_ip_configuration_key = "public"
#           backend_address_pool_key      = "vms"
#           probe_key                     = "http"
#           protocol                      = "Tcp"
#           frontend_port                 = 80
#           backend_port                  = 8080
#         }
#       }
#
#       nat_rules = {
#         "ssh" = {
#           name                          = "nat-ssh"
#           frontend_ip_configuration_key = "public"
#           protocol                      = "Tcp"
#           frontend_port                 = 2201
#           backend_port                  = 22
#         }
#       }
#
#       outbound_rules = {
#         "out" = {
#           name                           = "outbound-all"
#           backend_address_pool_key       = "vms"
#           frontend_ip_configuration_keys = ["public"]
#           protocol                       = "All"
#         }
#       }
#
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  load_balancers = {}
}
