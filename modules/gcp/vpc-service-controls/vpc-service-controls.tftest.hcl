mock_provider "google" {}

run "vpc_service_controls" {
  command = plan

  variables {
    access_policies = {
      "org" = {
        parent = "organizations/123456789"
        title  = "example-org-policy"
      }
    }

    access_levels = {
      "corp" = {
        policy_key = "org"
        name       = "corp_verified"
        title      = "Corp verified"
        basic = {
          combining_function = "AND"
          conditions = [
            {
              ip_subnetworks = ["192.0.2.0/24"]
              members        = ["user:admin@example.com"]
              regions        = ["US", "CH"]
              device_policy = {
                require_screen_lock              = true
                require_corp_owned               = true
                allowed_encryption_statuses      = ["ENCRYPTED"]
                allowed_device_management_levels = ["COMPLETE"]
                os_constraints = [
                  { os_type = "DESKTOP_CHROME_OS", minimum_version = "10.5.301", require_verified_chrome_os = true },
                  { os_type = "DESKTOP_MAC" }
                ]
              }
              vpc_network_sources = [
                { vpc_subnetwork = { network = "projects/example-prj/global/networks/example-net", vpc_ip_subnetworks = ["192.0.2.0/24"] } }
              ]
            },
            {
              regions = ["IT"]
              negate  = true
            }
          ]
        }
      }
      "cel" = {
        policy_key = "org"
        name       = "custom_cel"
        title      = "Custom CEL"
        custom = {
          expr = {
            expression  = "origin.region_code == 'US'"
            title       = "US only"
            description = "example cel level"
            location    = "example"
          }
        }
      }
    }

    service_perimeters = {
      "storage" = {
        policy_key                = "org"
        name                      = "restrict_storage"
        title                     = "Restrict Storage"
        description               = "example perimeter"
        perimeter_type            = "PERIMETER_TYPE_REGULAR"
        use_explicit_dry_run_spec = true
        status = {
          resources           = ["projects/987654321"]
          access_levels       = ["accessPolicies/123456789/accessLevels/corp_verified"]
          restricted_services = ["storage.googleapis.com"]
          vpc_accessible_services = {
            enable_restriction = true
            allowed_services   = ["storage.googleapis.com"]
          }
          ingress_policies = [
            {
              title = "example-ingress"
              ingress_from = {
                identity_type = "ANY_SERVICE_ACCOUNT"
                identities    = ["serviceAccount:cross@example-prj.iam.gserviceaccount.com"]
                sources = [
                  { access_level = "accessPolicies/123456789/accessLevels/staging_corp" },
                  { resource = "projects/1098765432" },
                  { psc_endpoint = { forwarding_rule = "//compute.googleapis.com/projects/example-prj/global/forwardingRules/example-pse" } }
                ]
              }
              ingress_to = {
                resources = ["*"]
                roles     = ["roles/storage.objectViewer"]
                operations = [
                  {
                    service_name = "storage.googleapis.com"
                    method_selectors = [
                      { method = "google.storage.objects.create" },
                      { permission = "storage.buckets.get" }
                    ]
                  }
                ]
              }
            }
          ]
          egress_policies = [
            {
              title = "example-egress"
              egress_from = {
                identity_type      = "ANY_USER_ACCOUNT"
                identities         = ["user:engineer@example.com"]
                source_restriction = "SOURCE_RESTRICTION_ENABLED"
                sources = [
                  { resource = "projects/987654321" }
                ]
              }
              egress_to = {
                resources          = ["projects/1122334455"]
                external_resources = ["s3://example-bucket/path"]
                roles              = ["roles/storage.objectCreator"]
                operations = [
                  {
                    service_name = "storage.googleapis.com"
                    method_selectors = [
                      { permission = "storage.objects.create" }
                    ]
                  }
                ]
              }
            }
          ]
        }
        spec = {
          restricted_services = ["storage.googleapis.com"]
        }
      }
      "bridge" = {
        policy_key     = "org"
        name           = "bridge_one"
        title          = "Example bridge"
        perimeter_type = "PERIMETER_TYPE_BRIDGE"
        status = {
          resources = ["projects/987654321"]
        }
      }
    }

    perimeter_resources = {
      "one" = {
        perimeter_key = "storage"
        resource      = "projects/2233445566"
      }
    }
  }
}

run "rejects_spec_without_flag" {
  command = plan

  variables {
    access_policies = {
      "org" = {
        parent = "organizations/123456789"
        title  = "example-org-policy"
      }
    }

    service_perimeters = {
      "bad" = {
        policy_key = "org"
        name       = "restrict_bad"
        title      = "Restrict Bad"
        spec = {
          restricted_services = ["storage.googleapis.com"]
        }
      }
    }
  }

  expect_failures = [var.service_perimeters]
}

run "rejects_bridge_with_services" {
  command = plan

  variables {
    access_policies = {
      "org" = {
        parent = "organizations/123456789"
        title  = "example-org-policy"
      }
    }

    service_perimeters = {
      "bad" = {
        policy_key     = "org"
        name           = "bridge_bad"
        title          = "Bridge Bad"
        perimeter_type = "PERIMETER_TYPE_BRIDGE"
        status = {
          restricted_services = ["storage.googleapis.com"]
        }
      }
    }
  }

  expect_failures = [var.service_perimeters]
}

run "rejects_bad_resource_format" {
  command = plan

  variables {
    access_policies = {
      "org" = {
        parent = "organizations/123456789"
        title  = "example-org-policy"
      }
    }

    service_perimeters = {
      "one" = {
        policy_key = "org"
        name       = "restrict_one"
        title      = "Restrict One"
      }
    }

    perimeter_resources = {
      "bad" = {
        perimeter_key = "one"
        resource      = "projects/example-prj"
      }
    }
  }

  expect_failures = [var.perimeter_resources]
}

run "rejects_bad_short_name" {
  command = plan

  variables {
    access_policies = {
      "org" = {
        parent = "organizations/123456789"
        title  = "example-org-policy"
      }
    }

    service_perimeters = {
      "bad" = {
        policy_key = "org"
        name       = "restrict bad"
        title      = "Restrict Bad"
      }
    }
  }

  expect_failures = [var.service_perimeters]
}

run "rejects_bad_identity_type" {
  command = plan

  variables {
    access_policies = {
      "org" = {
        parent = "organizations/123456789"
        title  = "example-org-policy"
      }
    }

    service_perimeters = {
      "bad" = {
        policy_key = "org"
        name       = "restrict_bad"
        title      = "Restrict Bad"
        status = {
          ingress_policies = [
            {
              ingress_from = {
                identity_type = "SOME_IDENTITY"
              }
            }
          ]
        }
      }
    }
  }

  expect_failures = [var.service_perimeters]
}

run "rejects_parent_format" {
  command = plan

  variables {
    access_policies = {
      "bad" = {
        parent = "projects/123456789"
        title  = "bad-parent"
      }
    }
  }

  expect_failures = [var.access_policies]
}
