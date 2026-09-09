mock_provider "google" {}

run "policies" {
  command = plan

  variables {
    security_policies = {
      "app" = {
        name        = "example-app-policy"
        description = "example allow/deny policy"
        labels      = { "env" = "example" }

        advanced_options_config = {
          json_parsing                 = "STANDARD"
          log_level                    = "VERBOSE"
          user_ip_request_headers      = ["x-user-ip"]
          request_body_inspection_size = "16KB"

          json_custom_config = {
            content_types = ["application/json"]
          }
        }

        adaptive_protection_config = {
          layer_7_ddos_defense_config = {
            enable          = true
            rule_visibility = "PREMIUM"
          }
        }

        rules = [
          {
            action      = "allow"
            priority    = 90
            description = "allow trusted sources"
            match = {
              versioned_expr = "SRC_IPS_V1"
              config = {
                src_ip_ranges = ["192.0.2.0/24", "198.51.100.0/24"]
              }
            }
          },
          {
            action      = "throttle"
            priority    = 500
            description = "throttle suspect traffic"
            match = {
              expr = {
                expression = "evaluatePreconfiguredExpr('ssli')"
              }
            }
            rate_limit_options = {
              conform_action = "allow"
              exceed_action  = "deny(429)"
              rate_limit_threshold = {
                count        = 100
                interval_sec = 60
              }
              enforce_on_key_configs = [
                {
                  enforce_on_key_type = "HTTP_HEADER"
                  enforce_on_key_name = "x-user"
                },
              ]
            }
            preconfigured_waf_config = {
              exclusions = [
                {
                  target_rule_set = "ssli"
                  request_header = [
                    {
                      operator = "CONTAINS"
                      value    = "example-token"
                    },
                  ]
                },
              ]
            }
          },
          {
            action      = "deny(403)"
            priority    = 2147483647
            description = "default deny"
            match = {
              versioned_expr = "SRC_IPS_V1"
              config = {
                src_ip_ranges = ["*"]
              }
            }
          },
        ]
      },
      "edge" = {
        name = "example-edge-policy"
        type = "CLOUD_ARMOR_EDGE"
        rules = [
          {
            action   = "allow"
            priority = 0
            match = {
              versioned_expr = "SRC_IPS_V1"
              config = {
                src_ip_ranges = ["203.0.113.0/24"]
              }
            }
          },
        ]
      },
    }
  }
}

run "rejects_duplicate_rule_priority" {
  command = plan

  variables {
    security_policies = {
      "app" = {
        name = "example-app-policy"
        rules = [
          {
            action   = "allow"
            priority = 90
            match = {
              versioned_expr = "SRC_IPS_V1"
              config = {
                src_ip_ranges = ["192.0.2.0/24"]
              }
            }
          },
          {
            action   = "allow"
            priority = 90
            match = {
              versioned_expr = "SRC_IPS_V1"
              config = {
                src_ip_ranges = ["198.51.100.0/24"]
              }
            }
          },
        ]
      },
    }
  }

  expect_failures = [var.security_policies]
}

run "rejects_invalid_action" {
  command = plan

  variables {
    security_policies = {
      "app" = {
        name = "example-app-policy"
        rules = [
          {
            action   = "deny(429)"
            priority = 0
            match = {
              versioned_expr = "SRC_IPS_V1"
              config = {
                src_ip_ranges = ["192.0.2.0/24"]
              }
            }
          },
        ]
      },
    }
  }

  expect_failures = [var.security_policies]
}

run "rejects_throttle_without_rate_limit_options" {
  command = plan

  variables {
    security_policies = {
      "app" = {
        name = "example-app-policy"
        rules = [
          {
            action   = "throttle"
            priority = 0
            match = {
              versioned_expr = "SRC_IPS_V1"
              config = {
                src_ip_ranges = ["192.0.2.0/24"]
              }
            }
          },
        ]
      },
    }
  }

  expect_failures = [var.security_policies]
}

run "rejects_unknown_policy_type" {
  command = plan

  variables {
    security_policies = {
      "app" = {
        name = "example-app-policy"
        type = "CLOUD_ARMOR_NETWORK"
      },
    }
  }

  expect_failures = [var.security_policies]
}
