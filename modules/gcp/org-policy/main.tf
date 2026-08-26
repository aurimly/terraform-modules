resource "google_org_policy_policy" "org_policy" {
  for_each = var.org_policies

  name            = each.value.name
  parent          = each.value.parent
  deletion_policy = each.value.deletion_policy

  dynamic "spec" {
    for_each = each.value.spec != null ? [each.value.spec] : []

    content {
      inherit_from_parent = spec.value.inherit_from_parent
      reset               = spec.value.reset

      dynamic "rules" {
        for_each = spec.value.rules

        content {
          allow_all  = rules.value.allow_all
          deny_all   = rules.value.deny_all
          enforce    = rules.value.enforce
          parameters = rules.value.parameters

          dynamic "condition" {
            for_each = rules.value.condition != null ? [rules.value.condition] : []

            content {
              expression  = condition.value.expression
              title       = condition.value.title
              description = condition.value.description
              location    = condition.value.location
            }
          }

          dynamic "values" {
            for_each = rules.value.values != null ? [rules.value.values] : []

            content {
              allowed_values = values.value.allowed_values
              denied_values  = values.value.denied_values
            }
          }
        }
      }
    }
  }

  dynamic "dry_run_spec" {
    for_each = each.value.dry_run_spec != null ? [each.value.dry_run_spec] : []

    content {
      inherit_from_parent = dry_run_spec.value.inherit_from_parent
      reset               = dry_run_spec.value.reset

      dynamic "rules" {
        for_each = dry_run_spec.value.rules

        content {
          allow_all  = rules.value.allow_all
          deny_all   = rules.value.deny_all
          enforce    = rules.value.enforce
          parameters = rules.value.parameters

          dynamic "condition" {
            for_each = rules.value.condition != null ? [rules.value.condition] : []

            content {
              expression  = condition.value.expression
              title       = condition.value.title
              description = condition.value.description
              location    = condition.value.location
            }
          }

          dynamic "values" {
            for_each = rules.value.values != null ? [rules.value.values] : []

            content {
              allowed_values = values.value.allowed_values
              denied_values  = values.value.denied_values
            }
          }
        }
      }
    }
  }
}
