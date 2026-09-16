resource "google_access_context_manager_access_policy" "access_policy" {
  for_each = var.access_policies

  parent          = each.value.parent
  title           = each.value.title
  scopes          = each.value.scopes
  deletion_policy = each.value.deletion_policy
}

resource "google_access_context_manager_access_level" "access_level" {
  for_each = var.access_levels

  parent          = "accessPolicies/${google_access_context_manager_access_policy.access_policy[each.value.policy_key].name}"
  name            = "accessPolicies/${google_access_context_manager_access_policy.access_policy[each.value.policy_key].name}/accessLevels/${each.value.name}"
  title           = each.value.title
  description     = each.value.description
  deletion_policy = each.value.deletion_policy

  dynamic "basic" {
    for_each = each.value.basic != null ? [each.value.basic] : []

    content {
      combining_function = basic.value.combining_function

      dynamic "conditions" {
        for_each = basic.value.conditions

        content {
          ip_subnetworks         = conditions.value.ip_subnetworks
          required_access_levels = conditions.value.required_access_levels
          members                = conditions.value.members
          negate                 = conditions.value.negate
          regions                = conditions.value.regions

          dynamic "device_policy" {
            for_each = conditions.value.device_policy != null ? [conditions.value.device_policy] : []

            content {
              require_admin_approval = device_policy.value.require_admin_approval
              require_corp_owned     = device_policy.value.require_corp_owned
              require_screen_lock    = device_policy.value.require_screen_lock

              allowed_encryption_statuses      = device_policy.value.allowed_encryption_statuses
              allowed_device_management_levels = device_policy.value.allowed_device_management_levels

              dynamic "os_constraints" {
                for_each = conditions.value.device_policy.os_constraints

                content {
                  os_type                    = os_constraints.value.os_type
                  minimum_version            = os_constraints.value.minimum_version
                  require_verified_chrome_os = os_constraints.value.require_verified_chrome_os
                }
              }
            }
          }

          dynamic "vpc_network_sources" {
            for_each = conditions.value.vpc_network_sources

            content {
              dynamic "vpc_subnetwork" {
                for_each = vpc_network_sources.value.vpc_subnetwork != null ? [vpc_network_sources.value.vpc_subnetwork] : []

                content {
                  network            = vpc_subnetwork.value.network
                  vpc_ip_subnetworks = vpc_subnetwork.value.vpc_ip_subnetworks
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "custom" {
    for_each = each.value.custom != null ? [each.value.custom] : []

    content {
      expr {
        expression  = custom.value.expr.expression
        title       = custom.value.expr.title
        description = custom.value.expr.description
        location    = custom.value.expr.location
      }
    }
  }
}

resource "google_access_context_manager_service_perimeter" "perimeter" {
  for_each = var.service_perimeters

  parent                    = "accessPolicies/${google_access_context_manager_access_policy.access_policy[each.value.policy_key].name}"
  name                      = "accessPolicies/${google_access_context_manager_access_policy.access_policy[each.value.policy_key].name}/servicePerimeters/${each.value.name}"
  title                     = each.value.title
  description               = each.value.description
  perimeter_type            = each.value.perimeter_type
  use_explicit_dry_run_spec = each.value.use_explicit_dry_run_spec
  deletion_policy           = each.value.deletion_policy

  dynamic "status" {
    for_each = each.value.status != null ? [each.value.status] : []

    content {
      resources           = status.value.resources
      access_levels       = status.value.access_levels
      restricted_services = status.value.restricted_services

      dynamic "vpc_accessible_services" {
        for_each = status.value.vpc_accessible_services != null ? [status.value.vpc_accessible_services] : []

        content {
          enable_restriction = vpc_accessible_services.value.enable_restriction
          allowed_services   = vpc_accessible_services.value.allowed_services
        }
      }

      dynamic "ingress_policies" {
        for_each = status.value.ingress_policies

        content {
          title = ingress_policies.value.title

          dynamic "ingress_from" {
            for_each = ingress_policies.value.ingress_from != null ? [ingress_policies.value.ingress_from] : []

            content {
              identity_type = ingress_from.value.identity_type
              identities    = ingress_from.value.identities

              dynamic "sources" {
                for_each = ingress_from.value.sources

                content {
                  access_level = sources.value.access_level
                  resource     = sources.value.resource

                  dynamic "psc_endpoint" {
                    for_each = sources.value.psc_endpoint != null ? [sources.value.psc_endpoint] : []

                    content {
                      forwarding_rule = psc_endpoint.value.forwarding_rule
                    }
                  }
                }
              }
            }
          }

          dynamic "ingress_to" {
            for_each = ingress_policies.value.ingress_to != null ? [ingress_policies.value.ingress_to] : []

            content {
              resources = ingress_to.value.resources
              roles     = ingress_to.value.roles

              dynamic "operations" {
                for_each = ingress_to.value.operations

                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors

                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "egress_policies" {
        for_each = status.value.egress_policies

        content {
          title = egress_policies.value.title

          dynamic "egress_from" {
            for_each = egress_policies.value.egress_from != null ? [egress_policies.value.egress_from] : []

            content {
              identity_type      = egress_from.value.identity_type
              identities         = egress_from.value.identities
              source_restriction = egress_from.value.source_restriction

              dynamic "sources" {
                for_each = egress_from.value.sources

                content {
                  access_level = sources.value.access_level
                  resource     = sources.value.resource

                  dynamic "psc_endpoint" {
                    for_each = sources.value.psc_endpoint != null ? [sources.value.psc_endpoint] : []

                    content {
                      forwarding_rule = psc_endpoint.value.forwarding_rule
                    }
                  }
                }
              }
            }
          }

          dynamic "egress_to" {
            for_each = egress_policies.value.egress_to != null ? [egress_policies.value.egress_to] : []

            content {
              resources          = egress_to.value.resources
              external_resources = egress_to.value.external_resources
              roles              = egress_to.value.roles

              dynamic "operations" {
                for_each = egress_to.value.operations

                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors

                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
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

  dynamic "spec" {
    for_each = each.value.spec != null ? [each.value.spec] : []

    content {
      resources           = spec.value.resources
      access_levels       = spec.value.access_levels
      restricted_services = spec.value.restricted_services

      dynamic "vpc_accessible_services" {
        for_each = spec.value.vpc_accessible_services != null ? [spec.value.vpc_accessible_services] : []

        content {
          enable_restriction = vpc_accessible_services.value.enable_restriction
          allowed_services   = vpc_accessible_services.value.allowed_services
        }
      }

      dynamic "ingress_policies" {
        for_each = spec.value.ingress_policies

        content {
          title = ingress_policies.value.title

          dynamic "ingress_from" {
            for_each = ingress_policies.value.ingress_from != null ? [ingress_policies.value.ingress_from] : []

            content {
              identity_type = ingress_from.value.identity_type
              identities    = ingress_from.value.identities

              dynamic "sources" {
                for_each = ingress_from.value.sources

                content {
                  access_level = sources.value.access_level
                  resource     = sources.value.resource

                  dynamic "psc_endpoint" {
                    for_each = sources.value.psc_endpoint != null ? [sources.value.psc_endpoint] : []

                    content {
                      forwarding_rule = psc_endpoint.value.forwarding_rule
                    }
                  }
                }
              }
            }
          }

          dynamic "ingress_to" {
            for_each = ingress_policies.value.ingress_to != null ? [ingress_policies.value.ingress_to] : []

            content {
              resources = ingress_to.value.resources
              roles     = ingress_to.value.roles

              dynamic "operations" {
                for_each = ingress_to.value.operations

                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors

                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "egress_policies" {
        for_each = spec.value.egress_policies

        content {
          title = egress_policies.value.title

          dynamic "egress_from" {
            for_each = egress_policies.value.egress_from != null ? [egress_policies.value.egress_from] : []

            content {
              identity_type      = egress_from.value.identity_type
              identities         = egress_from.value.identities
              source_restriction = egress_from.value.source_restriction

              dynamic "sources" {
                for_each = egress_from.value.sources

                content {
                  access_level = sources.value.access_level
                  resource     = sources.value.resource

                  dynamic "psc_endpoint" {
                    for_each = sources.value.psc_endpoint != null ? [sources.value.psc_endpoint] : []

                    content {
                      forwarding_rule = psc_endpoint.value.forwarding_rule
                    }
                  }
                }
              }
            }
          }

          dynamic "egress_to" {
            for_each = egress_policies.value.egress_to != null ? [egress_policies.value.egress_to] : []

            content {
              resources          = egress_to.value.resources
              external_resources = egress_to.value.external_resources
              roles              = egress_to.value.roles

              dynamic "operations" {
                for_each = egress_to.value.operations

                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors

                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
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
}

resource "google_access_context_manager_service_perimeter_resource" "perimeter_resource" {
  for_each = var.perimeter_resources

  perimeter_name = google_access_context_manager_service_perimeter.perimeter[each.value.perimeter_key].name
  resource       = each.value.resource
}
