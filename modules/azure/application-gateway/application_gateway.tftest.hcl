mock_provider "azurerm" {}

run "full_gateway" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"

        autoscale_configuration = {
          min_capacity = 2
          max_capacity = 10
        }
        zones         = ["1", "2", "3"]
        http2_enabled = true

        identity = {
          type         = "UserAssigned"
          identity_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-appgw-eu"]
        }

        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }

        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
          "private" = {
            name                          = "fip-private"
            subnet_id                     = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
            private_ip_address_allocation = "Dynamic"
          }
        }

        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
          "http"  = { name = "port-80", port = 80 }
        }

        ssl_certificates = {
          "wildcard" = {
            name                = "store-eu-cert"
            key_vault_secret_id = "https://kv-store-eu.vault.azure.net/secrets/store-eu-cert"
          }
        }

        probes = {
          "default" = {
            name                                      = "probe-default"
            protocol                                  = "Https"
            interval                                  = 30
            timeout                                   = 15
            unhealthy_threshold                       = 3
            path                                      = "/healthz"
            pick_host_name_from_backend_http_settings = true
          }
        }

        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net", "api2.internal.example.net"]
          }
        }

        backend_http_settings = {
          "api" = {
            name                                = "settings-api"
            port                                = 443
            protocol                            = "Https"
            request_timeout                     = 60
            pick_host_name_from_backend_address = true
            probe_key                           = "default"
            connection_draining = {
              enabled           = true
              drain_timeout_sec = 60
            }
          }
        }

        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Https"
            ssl_certificate_key           = "wildcard"
            require_sni                   = true
          }
          "http" = {
            name                          = "listener-http"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }

        request_routing_rules = {
          "https" = {
            name                      = "rule-https"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
          "http" = {
            name                      = "rule-http"
            priority                  = 200
            rule_type                 = "Basic"
            http_listener_key         = "http"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }

        url_path_maps = {
          "api-paths" = {
            name                              = "map-api"
            default_backend_address_pool_key  = "api"
            default_backend_http_settings_key = "api"
            path_rules = {
              "v2" = {
                name                      = "rule-v2"
                paths                     = ["/v2/*"]
                backend_address_pool_key  = "api"
                backend_http_settings_key = "api"
              }
            }
          }
        }
      }
    }
  }
}

run "rejects_v1_sku" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        sku_name            = "Standard_Large"
        capacity            = 2
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 443
            protocol = "Https"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }
        request_routing_rules = {
          "https" = {
            name                      = "rule-https"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}

run "rejects_capacity_with_autoscale" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        capacity            = 2
        autoscale_configuration = {
          min_capacity = 2
          max_capacity = 10
        }
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 443
            protocol = "Http"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }
        request_routing_rules = {
          "https" = {
            name                      = "rule-https"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}

run "rejects_https_listener_without_cert" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        capacity            = 2
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 443
            protocol = "Http"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Https"
          }
        }
        request_routing_rules = {
          "https" = {
            name                      = "rule-https"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}

run "rejects_probe_timeout_above_interval" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        capacity            = 2
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        probes = {
          "default" = {
            name                = "probe-default"
            protocol            = "Http"
            interval            = 10
            timeout             = 20
            unhealthy_threshold = 3
            path                = "/healthz"
            host                = "127.0.0.1"
          }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 80
            protocol = "Http"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }
        request_routing_rules = {
          "https" = {
            name                      = "rule-https"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}

run "rejects_unknown_listener_key" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        capacity            = 2
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 443
            protocol = "Http"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }
        request_routing_rules = {
          "botched" = {
            name                      = "rule-botched"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "does-not-exist"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}

run "rejects_priority_out_of_range" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        capacity            = 2
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 443
            protocol = "Http"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }
        request_routing_rules = {
          "bad" = {
            name                      = "rule-bad"
            priority                  = 25000
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}

run "rejects_kv_cert_without_identity" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        capacity            = 2
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        ssl_certificates = {
          "wildcard" = {
            name                = "store-eu-cert"
            key_vault_secret_id = "https://kv-store-eu.vault.azure.net/secrets/store-eu-cert"
          }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 443
            protocol = "Http"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }
        request_routing_rules = {
          "https" = {
            name                      = "rule-https"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}

run "rejects_ssl_policy_conflicts" {
  command = plan

  variables {
    application_gateways = {
      "store-eu" = {
        name                = "appgw-store-eu-01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        capacity            = 2
        gateway_ip_configurations = {
          "primary" = {
            name      = "gw-ip"
            subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-store/subnets/appgw"
          }
        }
        frontend_ip_configurations = {
          "public" = {
            name                 = "fip-public"
            public_ip_address_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.Network/publicIPAddresses/pip-edge-eu"
          }
        }
        frontend_ports = {
          "https" = { name = "port-443", port = 443 }
        }
        backend_address_pools = {
          "api" = {
            name  = "pool-api"
            fqdns = ["api1.internal.example.net"]
          }
        }
        backend_http_settings = {
          "api" = {
            name     = "settings-api"
            port     = 443
            protocol = "Http"
          }
        }
        http_listeners = {
          "https" = {
            name                          = "listener-https"
            frontend_ip_configuration_key = "public"
            frontend_port_key             = "https"
            protocol                      = "Http"
          }
        }
        request_routing_rules = {
          "https" = {
            name                      = "rule-https"
            priority                  = 100
            rule_type                 = "Basic"
            http_listener_key         = "https"
            backend_address_pool_key  = "api"
            backend_http_settings_key = "api"
          }
        }
        ssl_policy = {
          disabled_protocols = ["TLSv1_0"]
          policy_type        = "Predefined"
          policy_name        = "AppGwSslPolicy20170401S"
        }
      }
    }
  }

  expect_failures = [var.application_gateways]
}
