mock_provider "azurerm" {
  mock_resource "azurerm_web_application_firewall_policy" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/wafp-web-mock"
    }
  }
}

run "full_policies" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        policy_settings = {
          enabled                                   = true
          mode                                      = "Prevention"
          request_body_check                        = true
          max_request_body_size_in_kb               = 128
          file_upload_limit_in_mb                   = 100
          file_upload_enforcement                   = true
          request_body_enforcement                  = true
          request_body_inspect_limit_in_kb          = 128
          js_challenge_cookie_expiration_in_minutes = 30

          log_scrubbing = {
            enabled = true
            rules = {
              "auth-cookie" = {
                match_variable = "RequestCookieNames"
                selector       = "session-token"
              }
            }
          }
        }

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"

            rule_group_overrides = {
              "protocol-enforcement" = {
                rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"

                rules = {
                  "920300" = {
                    id     = "920300"
                    action = "Log"
                  }

                  "920440" = {
                    id     = "920440"
                    action = "Block"
                  }
                }
              }
            }
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }

          "geo-allow" = {
            name     = "geo-allow"
            priority = 200
            action   = "Allow"
            enabled  = true

            match_conditions = {
              "geo" = {
                operator           = "GeoMatch"
                negation_condition = true
                match_values       = ["US"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }

                transforms = ["Lowercase", "Trim"]
              }
            }
          }
        }

        tags = {
          env = "prod"
        }
      }

      "bot" = {
        name                = "wafp-bot-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "bot-manager" = {
            type    = "Microsoft_BotManagerRuleSet"
            version = "1.1"

            rule_group_overrides = {
              "bad-bots" = {
                rule_group_name = "BadBots"

                rules = {
                  "bad-bot" = {
                    id     = "020001"
                    action = "JSChallenge"
                  }
                }
              }
            }
          }
        }

        custom_rules = {
          "rate-limit-api" = {
            name                 = "rate-limit-api"
            priority             = 100
            action               = "Block"
            rule_type            = "RateLimitRule"
            rate_limit_duration  = "OneMin"
            rate_limit_threshold = 100
            group_rate_limit_by  = "ClientAddr"

            match_conditions = {
              "uri" = {
                operator     = "BeginsWith"
                match_values = ["/api/"]

                match_variables = {
                  "request-uri" = {
                    variable_name = "RequestUri"
                  }
                }
              }
            }
          }
        }
      }

      "tuning" = {
        name                = "wafp-tuning-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        policy_settings = {
          mode = "Detection"

          log_scrubbing = {
            rules = {
              "api-key" = {
                match_variable = "RequestHeaderNames"
                selector       = "x-api-key"
              }

              "client-ip" = {
                match_variable          = "RequestIPAddress"
                selector_match_operator = "EqualsAny"
              }
            }
          }
        }

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.1"
          }
        }

        exclusions = {
          "verification-token" = {
            match_variable          = "RequestArgNames"
            selector                = "__RequestVerificationToken"
            selector_match_operator = "Equals"
          }

          "legacy-cookie" = {
            match_variable          = "RequestCookieNames"
            selector                = "legacy-session"
            selector_match_operator = "EndsWith"

            excluded_rule_set = {
              type    = "OWASP"
              version = "3.2"

              rule_groups = {
                "sqli" = {
                  rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
                  excluded_rules  = ["942100"]
                }
              }
            }
          }
        }

        custom_rules = {
          "allow-health" = {
            name     = "allow-health-probes"
            priority = 10
            action   = "Allow"

            match_conditions = {
              "user-agent" = {
                operator     = "Contains"
                match_values = ["HealthProbe"]

                match_variables = {
                  "user-agent" = {
                    variable_name = "RequestHeaders"
                    selector      = "UserAgent"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

run "rejects_dot_in_policy_key" {
  command = plan

  variables {
    policies = {
      "web.a" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_dot_in_custom_rule_key" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block.a" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_dot_in_managed_rule_set_key" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp.a" = {
            type    = "OWASP"
            version = "3.2"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_empty_custom_rule_name" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = " "
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_empty_exclusion_selector" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        exclusions = {
          "token-cookie" = {
            match_variable          = "RequestCookieNames"
            selector                = ""
            selector_match_operator = "Equals"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_mode" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        policy_settings = {
          mode = "Blocking"
        }

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_custom_rule_action" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Deny"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_rule_type" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name      = "block-scanner-net"
            priority  = 100
            action    = "Block"
            rule_type = "RateLimit"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_match_rule_with_rate_limit_attributes" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "rate-limit-api" = {
            name                 = "rate-limit-api"
            priority             = 100
            action               = "Block"
            rate_limit_duration  = "OneMin"
            rate_limit_threshold = 100

            match_conditions = {
              "uri" = {
                operator     = "BeginsWith"
                match_values = ["/api/"]

                match_variables = {
                  "request-uri" = {
                    variable_name = "RequestUri"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_rate_limit_rule_without_threshold_or_duration" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "rate-limit-api" = {
            name      = "rate-limit-api"
            priority  = 100
            action    = "Block"
            rule_type = "RateLimitRule"

            match_conditions = {
              "uri" = {
                operator     = "BeginsWith"
                match_values = ["/api/"]

                match_variables = {
                  "request-uri" = {
                    variable_name = "RequestUri"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_rate_limit_rule_with_allow_action" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "rate-limit-api" = {
            name                 = "rate-limit-api"
            priority             = 100
            action               = "Allow"
            rule_type            = "RateLimitRule"
            rate_limit_duration  = "OneMin"
            rate_limit_threshold = 100

            match_conditions = {
              "uri" = {
                operator     = "BeginsWith"
                match_values = ["/api/"]

                match_variables = {
                  "request-uri" = {
                    variable_name = "RequestUri"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_operator_any_with_match_values" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "Any"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_non_any_operator_without_match_values" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator = "Contains"

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_transform" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "Contains"
                match_values = ["scanner"]
                transforms   = ["Titlecase"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_variable_name" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddress"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_duplicate_custom_rule_priority" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }

          "allow-health" = {
            name     = "allow-health-probes"
            priority = 100
            action   = "Allow"

            match_conditions = {
              "user-agent" = {
                operator     = "Contains"
                match_values = ["HealthProbe"]

                match_variables = {
                  "user-agent" = {
                    variable_name = "RequestHeaders"
                    selector      = "UserAgent"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_duplicate_custom_rule_name" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        custom_rules = {
          "block-scanner-net" = {
            name     = "block-scanner-net"
            priority = 100
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["203.0.113.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }

          "block-scanner-net-again" = {
            name     = "block-scanner-net"
            priority = 200
            action   = "Block"

            match_conditions = {
              "source" = {
                operator     = "IPMatch"
                match_values = ["198.51.100.0/24"]

                match_variables = {
                  "remote-addr" = {
                    variable_name = "RemoteAddr"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_empty_managed_rule_sets" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {}
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_unknown_rule_set_type" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "legacy" = {
            type    = "Microsoft_LegacyRuleSet"
            version = "3.2"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_rule_set_version" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.3"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_js_challenge_on_non_bot_manager_rule" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"

            rule_group_overrides = {
              "protocol-enforcement" = {
                rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"

                rules = {
                  "920300" = {
                    id     = "920300"
                    action = "JSChallenge"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_exclusion_match_variable" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        exclusions = {
          "token-cookie" = {
            match_variable          = "RequestArgSelectors"
            selector                = "auth-token"
            selector_match_operator = "Equals"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_selector_match_operator" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        exclusions = {
          "token-cookie" = {
            match_variable          = "RequestCookieNames"
            selector                = "auth-token"
            selector_match_operator = "BeginsWith"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_scrubbing_equals_without_selector" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        policy_settings = {
          log_scrubbing = {
            rules = {
              "api-key" = {
                match_variable = "RequestHeaderNames"
                selector       = ""
              }
            }
          }
        }

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_tag_limit_exceeded" {
  command = plan

  variables {
    policies = {
      "web" = {
        name                = "wafp-web-prod"
        resource_group_name = "rg-network-prod"
        location            = "westeurope"

        managed_rule_sets = {
          "owasp" = {
            type    = "OWASP"
            version = "3.2"
          }
        }

        tags = { for i in range(51) : (format("key%02d", i)) => "value" }
      }
    }
  }

  expect_failures = [var.policies]
}
