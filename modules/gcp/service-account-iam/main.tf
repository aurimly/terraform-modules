locals {
  member_grants = {
    for g in flatten([
      for key, entry in var.members : [
        for role in entry.roles : {
          key             = key
          role            = role
          member          = entry.member
          condition       = entry.condition
          service_account = entry.service_account
        }
      ]
    ]) : g.condition != null ? "${g.key}/${g.role}/${g.condition.title}" : "${g.key}/${g.role}" => g
  }
}

resource "google_service_account_iam_member" "member" {
  for_each = var.mode == "member" ? local.member_grants : {}

  service_account_id = var.service_accounts[each.value.service_account]
  role               = each.value.role
  member             = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

resource "google_service_account_iam_binding" "binding" {
  for_each = var.mode == "binding" ? var.bindings : {}

  service_account_id = var.service_accounts[each.value.service_account]
  role               = each.value.role
  members            = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

resource "google_service_account_iam_policy" "policy" {
  for_each = var.mode == "policy" ? var.policies : {}

  service_account_id = var.service_accounts[each.key]
  policy_data        = each.value.policy_data
}
