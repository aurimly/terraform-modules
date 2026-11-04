terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_user" "user" {
  for_each = var.users

  name                           = each.value.name
  login_name                     = each.value.login_name
  first_name                     = each.value.first_name
  middle_name                    = each.value.middle_name
  last_name                      = each.value.last_name
  display_name                   = each.value.display_name
  email                          = each.value.email
  password                       = each.value.password
  disabled                       = each.value.disabled != null ? tostring(each.value.disabled) : null
  must_change_password           = each.value.must_change_password != null ? tostring(each.value.must_change_password) : null
  days_to_expiry                 = each.value.days_to_expiry
  default_role                   = each.value.default_role
  default_warehouse              = each.value.default_warehouse
  default_namespace              = each.value.default_namespace
  default_secondary_roles_option = each.value.default_secondary_roles_option
  rsa_public_key                 = each.value.rsa_public_key
  rsa_public_key_2               = each.value.rsa_public_key_2
  network_policy                 = each.value.network_policy
  log_level                      = each.value.log_level
  comment                        = each.value.comment
}
