locals {
  aliases = merge([
    for key_key, key in var.keys : {
      for alias_key, alias in key.aliases : "${key_key}.${alias_key}" => {
        key_key = key_key
        name    = alias.name
      }
    }
  ]...)
}

resource "aws_kms_key" "key" {
  for_each = var.keys

  description                        = each.value.description
  key_usage                          = each.value.key_usage
  customer_master_key_spec           = each.value.customer_master_key_spec
  is_enabled                         = each.value.is_enabled
  enable_key_rotation                = each.value.enable_key_rotation
  rotation_period_in_days            = each.value.rotation_period_in_days
  deletion_window_in_days            = each.value.deletion_window_in_days
  multi_region                       = each.value.multi_region
  policy                             = each.value.policy
  bypass_policy_lockout_safety_check = each.value.bypass_policy_lockout_safety_check

  tags = each.value.tags
}

resource "aws_kms_alias" "alias" {
  for_each = local.aliases

  name          = each.value.name
  target_key_id = aws_kms_key.key[each.value.key_key].key_id
}
