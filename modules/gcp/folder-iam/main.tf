locals {
  member_grants = {
    for g in flatten([
      for key, entry in var.members : [
        for role in entry.roles : {
          key       = key
          role      = role
          member    = entry.member
          condition = entry.condition
        }
      ]
    ]) : g.condition != null ? "${g.key}/${g.role}/${g.condition.title}" : "${g.key}/${g.role}" => g
  }
}

resource "google_folder_iam_member" "member" {
  for_each = var.mode == "member" ? local.member_grants : {}

  folder = "folders/${var.folder_id}"
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

resource "google_folder_iam_binding" "binding" {
  for_each = var.mode == "binding" ? var.bindings : {}

  folder  = "folders/${var.folder_id}"
  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

resource "google_folder_iam_policy" "policy" {
  count = var.mode == "policy" && var.policy_data != null ? 1 : 0

  folder      = "folders/${var.folder_id}"
  policy_data = var.policy_data
}

resource "google_folder_iam_audit_config" "audit_config" {
  for_each = var.audit_config_enabled ? var.audit_configs : {}

  folder  = "folders/${var.folder_id}"
  service = each.value.service

  dynamic "audit_log_config" {
    for_each = each.value.audit_log_configs

    content {
      log_type         = audit_log_config.value.log_type
      exempted_members = audit_log_config.value.exempted_members
    }
  }
}
