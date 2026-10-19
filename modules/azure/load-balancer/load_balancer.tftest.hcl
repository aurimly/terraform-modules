mock_provider "azurerm" {
  # azurerm 5.x parses referenced resource IDs at plan time — the mock's
  # synthetic IDs must be real ARM IDs.
  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
    }
  }

  mock_resource "azurerm_lb" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb"
    }
  }

  mock_resource "azurerm_lb_backend_address_pool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/backendAddressPools/pool"
    }
  }

  mock_resource "azurerm_lb_backend_address_pool_address" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/backendAddressPools/pool/addresses/addr"
    }
  }

  mock_resource "azurerm_network_interface_backend_address_pool_association" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkInterfaces/nic/ipConfigurations/ipc|/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/backendAddressPools/pool"
    }
  }

  mock_resource "azurerm_lb_probe" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/probes/probe"
    }
  }

  mock_resource "azurerm_lb_rule" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/loadBalancingRules/rule"
    }
  }

  mock_resource "azurerm_lb_nat_rule" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/inboundNatRules/rule"
    }
  }

  mock_resource "azurerm_lb_nat_pool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/inboundNatPools/pool"
    }
  }

  mock_resource "azurerm_lb_outbound_rule" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/loadBalancers/lb/outboundRules/rule"
    }
  }
}

run "full_load_balancer" {
  command = plan

  variables {
    public_ips = {
      "edge" = {
        name                = "pip-lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        availability_zone   = "1"
        domain_name_label   = "web-prod"
        tags = {
          env = "prod"
        }
      }
    }

    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        sku_tier            = "Regional"

        frontend_ip_configurations = {
          "public" = {
            name          = "web-frontend-public"
            public_ip_key = "edge"
            zones         = ["1", "2", "3"]
          }
          "private" = {
            name                          = "web-frontend-internal"
            subnet_id                     = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod/subnets/snet-web"
            private_ip_address            = "10.20.1.10"
            private_ip_address_allocation = "Static"
          }
        }

        backend_address_pools = {
          "vms" = {
            name = "web-backend-vms"
            addresses = {
              "vm1" = {
                name               = "vm1"
                ip_address         = "10.20.1.21"
                virtual_network_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod"
              }
            }
            nic_associations = {
              "vm2" = {
                network_interface_id  = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/networkInterfaces/nic-vm2"
                ip_configuration_name = "ipconfig1"
              }
            }
          }
        }

        probes = {
          "http" = {
            name                = "probe-http"
            protocol            = "Http"
            port                = 8080
            request_path        = "/health"
            interval_in_seconds = 15
            number_of_probes    = 2
          }
        }

        rules = {
          "http" = {
            name                          = "rule-http"
            frontend_ip_configuration_key = "public"
            backend_address_pool_key      = "vms"
            probe_key                     = "http"
            protocol                      = "Tcp"
            frontend_port                 = 80
            backend_port                  = 8080
          }
        }

        nat_rules = {
          "ssh" = {
            name                          = "nat-ssh"
            frontend_ip_configuration_key = "public"
            protocol                      = "Tcp"
            frontend_port                 = 2201
            backend_port                  = 22
          }
        }

        outbound_rules = {
          "out" = {
            name                           = "outbound-all"
            backend_address_pool_key       = "vms"
            frontend_ip_configuration_keys = ["public"]
            protocol                       = "All"
          }
        }

        tags = {
          env = "prod"
        }
      }

      "cross-region" = {
        name                = "lb-global-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        sku_tier            = "Global"

        frontend_ip_configurations = {
          "public" = {
            name                 = "global-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-global"
          }
        }

        backend_address_pools = {
          "regionals" = {
            name = "global-backend"
            addresses = {
              "r1" = {
                name                                = "r1"
                backend_address_ip_configuration_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/loadBalancers/lb-web-prod/frontendIPConfigurations/web-frontend-public"
              }
            }
          }
        }

        rules = {
          "http" = {
            name                          = "rule-http"
            frontend_ip_configuration_key = "public"
            backend_address_pool_key      = "regionals"
            protocol                      = "Tcp"
            frontend_port                 = 80
            backend_port                  = 80
          }
        }
      }
    }
  }
}

run "rejects_missing_pool_key" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "public" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
          }
        }
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
          }
        }
        rules = {
          "http" = {
            name                          = "rule-http"
            frontend_ip_configuration_key = "public"
            backend_address_pool_key      = "missing"
            protocol                      = "Tcp"
            frontend_port                 = 80
            backend_port                  = 80
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_public_and_private_frontend" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "mixed" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
            subnet_id            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod/subnets/snet-web"
          }
        }
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_no_frontend" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                       = "lb-web-prod"
        resource_group_name        = "rg-web-prod"
        location                   = "westeurope"
        frontend_ip_configurations = {}
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_tcp_probe_with_request_path" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "public" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
          }
        }
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
          }
        }
        probes = {
          "tcp" = {
            name         = "probe-tcp"
            protocol     = "Tcp"
            port         = 443
            request_path = "/health"
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_synchronous_mode_without_virtual_network" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "public" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
          }
        }
        backend_address_pools = {
          "vms" = {
            name             = "web-backend"
            synchronous_mode = "Automatic"
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_rule_port_out_of_range" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "public" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
          }
        }
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
          }
        }
        rules = {
          "http" = {
            name                          = "rule-http"
            frontend_ip_configuration_key = "public"
            backend_address_pool_key      = "vms"
            protocol                      = "Tcp"
            frontend_port                 = 80
            backend_port                  = 70000
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_mixed_nat_rule_forms" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "public" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
          }
        }
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
          }
        }
        nat_rules = {
          "ssh" = {
            name                          = "nat-ssh"
            frontend_ip_configuration_key = "public"
            protocol                      = "Tcp"
            frontend_port                 = 2201
            backend_port                  = 22
            frontend_port_start           = 2201
            frontend_port_end             = 2210
            backend_address_pool_key      = "vms"
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_address_without_form" {
  command = plan

  variables {
    load_balancers = {
      "web" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "public" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
          }
        }
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
            addresses = {
              "vm1" = {
                name       = "vm1"
                ip_address = "10.20.1.21"
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}

run "rejects_dot_in_keys" {
  command = plan

  variables {
    load_balancers = {
      "web.1" = {
        name                = "lb-web-prod"
        resource_group_name = "rg-web-prod"
        location            = "westeurope"
        frontend_ip_configurations = {
          "public" = {
            name                 = "web-frontend"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-web-prod/providers/Microsoft.Network/publicIPAddresses/pip-lb"
          }
        }
        backend_address_pools = {
          "vms" = {
            name = "web-backend"
          }
        }
      }
    }
  }

  expect_failures = [var.load_balancers]
}
