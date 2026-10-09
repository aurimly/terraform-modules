mock_provider "azurerm" {
  mock_resource "azurerm_firewall" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/azureFirewalls/fw-platform-mock"
    }
  }

  mock_resource "azurerm_firewall_policy" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/firewallPolicies/fwp-egress-prod"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-mock"
      ip_address = "203.0.113.10"
    }
  }
}

run "full_firewall" {
  command = plan

  variables {
    public_ips = {
      "egress" = {
        name                = "pip-fw-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
        availability_zone   = "1"
      }
    }

    firewall_policies = {
      "egress" = {
        name                     = "fwp-egress-prod"
        resource_group_name      = "rg-network-prod"
        location                 = "westeurope"
        sku                      = "Premium"
        dns                      = { proxy_enabled = true, servers = ["10.0.0.10"] }
        threat_intelligence_mode = "Deny"
        threat_intelligence_allowlist = {
          ip_addresses = ["203.0.113.0/24"]
          fqdns        = ["example.microsoft.com"]
        }
        private_ip_ranges                 = ["192.168.0.0/16"]
        auto_learn_private_ranges_enabled = false
        sql_redirect_allowed              = true
      }
      "hub" = {
        name                = "fwp-hub-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
        sku                 = "Basic"
      }
    }

    firewall_policy_rule_collection_groups = {
      "egress-base" = {
        firewall_policy_key = "egress"
        name                = "rgp-egress-base"
        priority            = 100

        application_rule_collections = {
          "allow-updates" = {
            name     = "arc-allow-updates"
            priority = 100
            action   = "Allow"

            rules = {
              "windows-update" = {
                name          = "ar-allow-updates"
                terminate_tls = true

                protocols = {
                  "update-https" = {
                    type = "Https"
                    port = 443
                  }
                }

                source_addresses      = ["192.168.1.0/24"]
                destination_fqdn_tags = ["WindowsUpdate"]
              }
            }
          }
        }

        network_rule_collections = {
          "allow-internal" = {
            name     = "nrc-allow-internal"
            priority = 200
            action   = "Allow"

            rules = {
              "internal-dns" = {
                name                  = "nr-allow-dns"
                protocols             = ["UDP"]
                destination_ports     = ["53"]
                source_addresses      = ["192.168.1.0/24"]
                destination_addresses = ["10.0.0.10"]
              }
            }
          }
        }

        nat_rule_collections = {
          "publish-vault" = {
            name     = "nrc-publish-vault"
            priority = 300
            action   = "Dnat"

            rules = {
              "vault-https" = {
                name                = "nr-vault-https"
                protocols           = ["TCP"]
                destination_address = "203.0.113.10"
                destination_ports   = ["443"]
                translated_address  = "192.168.10.110"
                translated_port     = 8200
              }
            }
          }
        }
      }
    }

    firewalls = {
      "egress" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
        sku_name            = "AZFW_VNet"
        sku_tier            = "Premium"
        firewall_policy_key = "egress"
        threat_intel_mode   = "Alert"

        dns_servers       = ["10.0.0.10"]
        dns_proxy_enabled = true

        zones = ["1", "2", "3"]

        ip_configurations = {
          "primary" = {
            name          = "ipc-primary"
            subnet_id     = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
            public_ip_key = "egress"
          }
        }

        management_ip_configuration = {
          name                 = "ipc-management"
          subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallManagementSubnet"
          public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-mgmt-prod"
        }

        tags = {
          env = "prod"
        }
      }

      "egress-hub" = {
        name                = "fw-hub-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
        sku_name            = "AZFW_Hub"
        sku_tier            = "Standard"
        firewall_policy_key = "hub"

        virtual_hub = {
          virtual_hub_id  = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualHubs/hub-platform"
          public_ip_count = 2
        }
      }
    }
  }
}

run "rejects_dot_in_firewall_key" {
  command = plan

  variables {
    firewalls = {
      "egress.a" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        ip_configurations = {
          "primary" = {
            name                 = "ipc-primary"
            subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-egress-prod"
          }
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_hub_with_ip_configurations" {
  command = plan

  variables {
    firewalls = {
      "egress-hub" = {
        name                = "fw-hub-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
        sku_name            = "AZFW_Hub"

        ip_configurations = {
          "primary" = {
            name                 = "ipc-primary"
            subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-egress-prod"
          }
        }

        virtual_hub = {
          virtual_hub_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualHubs/hub-platform"
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_ip_configuration_without_public_ip" {
  command = plan

  variables {
    firewalls = {
      "egress" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        ip_configurations = {
          "primary" = {
            name      = "ipc-primary"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
          }
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_ip_configuration_with_both_public_ip_ways" {
  command = plan

  variables {
    public_ips = {
      "egress" = {
        name                = "pip-fw-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
      }
    }

    firewalls = {
      "egress" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        ip_configurations = {
          "primary" = {
            name                 = "ipc-primary"
            subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
            public_ip_key        = "egress"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-egress-prod"
          }
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_unknown_public_ip_key" {
  command = plan

  variables {
    firewalls = {
      "egress" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        ip_configurations = {
          "primary" = {
            name          = "ipc-primary"
            subnet_id     = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
            public_ip_key = "other"
          }
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_wrong_firewall_subnet_name" {
  command = plan

  variables {
    firewalls = {
      "egress" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        ip_configurations = {
          "primary" = {
            name                 = "ipc-primary"
            subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/workload"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-egress-prod"
          }
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_management_name_collision" {
  command = plan

  variables {
    firewalls = {
      "egress" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        ip_configurations = {
          "primary" = {
            name                 = "ipc-primary"
            subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-egress-prod"
          }
        }

        management_ip_configuration = {
          name                 = "ipc-primary"
          subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallManagementSubnet"
          public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-mgmt-prod"
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_dns_proxy_without_servers" {
  command = plan

  variables {
    firewalls = {
      "egress" = {
        name                = "fw-platform-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        dns_proxy_enabled = true

        ip_configurations = {
          "primary" = {
            name                 = "ipc-primary"
            subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/publicIPAddresses/pip-fw-egress-prod"
          }
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_bad_policy_sku" {
  command = plan

  variables {
    firewalls = {}

    firewall_policies = {
      "egress" = {
        name                = "fwp-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
        sku                 = "Free"
      }
    }
  }

  expect_failures = [var.firewall_policies]
}

run "rejects_empty_threat_allowlist" {
  command = plan

  variables {
    firewalls = {}

    firewall_policies = {
      "egress" = {
        name                = "fwp-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        threat_intelligence_allowlist = {
          ip_addresses = []
          fqdns        = []
        }
      }
    }
  }

  expect_failures = [var.firewall_policies]
}

run "rejects_rcg_unknown_policy_key" {
  command = plan

  variables {
    firewalls = {}

    firewall_policies = {
      "egress" = {
        name                = "fwp-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
      }
    }

    firewall_policy_rule_collection_groups = {
      "base" = {
        firewall_policy_key = "other"
        name                = "rgp-base"
        priority            = 100
      }
    }
  }

  expect_failures = [var.firewall_policy_rule_collection_groups]
}

run "rejects_nat_action_not_dnat" {
  command = plan

  variables {
    firewalls = {}

    firewall_policies = {
      "egress" = {
        name                = "fwp-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
      }
    }

    firewall_policy_rule_collection_groups = {
      "base" = {
        firewall_policy_key = "egress"
        name                = "rgp-base"
        priority            = 100

        nat_rule_collections = {
          "publish" = {
            name     = "nrc-publish"
            priority = 100
            action   = "Allow"

            rules = {
              "web" = {
                name                = "nr-web"
                protocols           = ["TCP"]
                destination_address = "203.0.113.10"
                translated_address  = "192.168.10.110"
                translated_port     = 80
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.firewall_policy_rule_collection_groups]
}

run "rejects_nat_rule_with_two_destination_ports" {
  command = plan

  variables {
    firewalls = {}

    firewall_policies = {
      "egress" = {
        name                = "fwp-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
      }
    }

    firewall_policy_rule_collection_groups = {
      "base" = {
        firewall_policy_key = "egress"
        name                = "rgp-base"
        priority            = 100

        nat_rule_collections = {
          "publish" = {
            name     = "nrc-publish"
            priority = 100
            action   = "Dnat"

            rules = {
              "web" = {
                name                = "nr-web"
                protocols           = ["TCP"]
                destination_address = "203.0.113.10"
                destination_ports   = ["80", "443"]
                translated_address  = "192.168.10.110"
                translated_port     = 80
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.firewall_policy_rule_collection_groups]
}

run "rejects_nat_rule_with_both_translations" {
  command = plan

  variables {
    firewalls = {}

    firewall_policies = {
      "egress" = {
        name                = "fwp-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
      }
    }

    firewall_policy_rule_collection_groups = {
      "base" = {
        firewall_policy_key = "egress"
        name                = "rgp-base"
        priority            = 100

        nat_rule_collections = {
          "publish" = {
            name     = "nrc-publish"
            priority = 100
            action   = "Dnat"

            rules = {
              "web" = {
                name                = "nr-web"
                protocols           = ["TCP"]
                destination_address = "203.0.113.10"
                translated_address  = "192.168.10.110"
                translated_fqdn     = "web.internal.example.com"
                translated_port     = 80
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.firewall_policy_rule_collection_groups]
}

run "rejects_duplicate_collection_priority" {
  command = plan

  variables {
    firewalls = {}

    firewall_policies = {
      "egress" = {
        name                = "fwp-egress-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"
      }
    }

    firewall_policy_rule_collection_groups = {
      "base" = {
        firewall_policy_key = "egress"
        name                = "rgp-base"
        priority            = 100

        network_rule_collections = {
          "first" = {
            name     = "nrc-first"
            priority = 100
            action   = "Allow"

            rules = {
              "a" = {
                name                  = "nr-a"
                protocols             = ["TCP"]
                destination_addresses = ["203.0.113.10"]
              }
            }
          }
          "second" = {
            name     = "nrc-second"
            priority = 100
            action   = "Allow"

            rules = {
              "a" = {
                name                  = "nr-a"
                protocols             = ["TCP"]
                destination_addresses = ["203.0.113.10"]
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.firewall_policy_rule_collection_groups]
}
