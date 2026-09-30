locals {
  keys = merge([
    for vault_key, vault in var.key_vaults : {
      for key_key, key in vault.keys : "${vault_key}.${key_key}" => merge(key, {
        vault_key    = vault_key
        key_vault_id = azurerm_key_vault.key_vault[vault_key].id
      })
    }
  ]...)

  secrets = merge([
    for vault_key, vault in var.key_vaults : {
      for secret_key, secret in vault.secrets : "${vault_key}.${secret_key}" => merge(secret, {
        vault_key    = vault_key
        key_vault_id = azurerm_key_vault.key_vault[vault_key].id
      })
    }
  ]...)

  certificates = merge([
    for vault_key, vault in var.key_vaults : {
      for certificate_key, certificate in vault.certificates : "${vault_key}.${certificate_key}" => merge(certificate, {
        vault_key    = vault_key
        key_vault_id = azurerm_key_vault.key_vault[vault_key].id
      })
    }
  ]...)
}

resource "azurerm_key_vault" "key_vault" {
  for_each = var.key_vaults

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tenant_id           = each.value.tenant_id
  sku_name            = each.value.sku_name

  soft_delete_retention_days      = each.value.soft_delete_retention_days
  purge_protection_enabled        = each.value.purge_protection_enabled
  rbac_authorization_enabled      = each.value.rbac_authorization_enabled
  public_network_access_enabled   = each.value.public_network_access_enabled
  enabled_for_deployment          = each.value.enabled_for_deployment
  enabled_for_disk_encryption     = each.value.enabled_for_disk_encryption
  enabled_for_template_deployment = each.value.enabled_for_template_deployment

  dynamic "network_acls" {
    for_each = each.value.network_acls != null ? [each.value.network_acls] : []
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  dynamic "access_policy" {
    for_each = each.value.access_policies
    content {
      tenant_id               = access_policy.value.tenant_id
      object_id               = access_policy.value.object_id
      application_id          = access_policy.value.application_id
      certificate_permissions = access_policy.value.certificate_permissions
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      storage_permissions     = access_policy.value.storage_permissions
    }
  }

  tags = each.value.tags
}

resource "azurerm_key_vault_key" "key" {
  for_each = local.keys

  name         = each.value.name
  key_vault_id = each.value.key_vault_id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  curve        = each.value.curve
  key_opts     = each.value.key_opts

  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date
  tags            = each.value.tags

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []
    content {
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry

      dynamic "automatic" {
        for_each = rotation_policy.value.automatic != null ? [rotation_policy.value.automatic] : []
        content {
          time_after_creation = automatic.value.time_after_creation
          time_before_expiry  = automatic.value.time_before_expiry
        }
      }
    }
  }
}

resource "azurerm_key_vault_secret" "secret" {
  for_each = local.secrets

  name         = each.value.name
  key_vault_id = each.value.key_vault_id
  value        = each.value.value
  value_wo     = each.value.value_wo

  value_wo_version = each.value.value_wo_version
  content_type     = each.value.content_type

  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date
  tags            = each.value.tags
}

resource "azurerm_key_vault_certificate" "certificate" {
  for_each = local.certificates

  name         = each.value.name
  key_vault_id = each.value.key_vault_id
  tags         = each.value.tags

  dynamic "certificate" {
    for_each = each.value.certificate != null ? [each.value.certificate] : []
    content {
      contents = certificate.value.contents
      password = certificate.value.password
    }
  }

  dynamic "certificate_policy" {
    for_each = each.value.certificate_policy != null ? [each.value.certificate_policy] : []
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_parameters.name
      }

      key_properties {
        exportable = certificate_policy.value.key_properties.exportable
        key_type   = certificate_policy.value.key_properties.key_type
        key_size   = certificate_policy.value.key_properties.key_size
        curve      = certificate_policy.value.key_properties.curve
        reuse_key  = certificate_policy.value.key_properties.reuse_key
      }

      dynamic "lifetime_action" {
        for_each = certificate_policy.value.lifetime_action
        content {
          dynamic "action" {
            for_each = lifetime_action.value.action != null ? [lifetime_action.value.action] : []
            content {
              action_type = action.value.action_type
            }
          }

          dynamic "trigger" {
            for_each = lifetime_action.value.trigger != null ? [lifetime_action.value.trigger] : []
            content {
              days_before_expiry  = trigger.value.days_before_expiry
              lifetime_percentage = trigger.value.lifetime_percentage
            }
          }
        }
      }

      secret_properties {
        content_type = certificate_policy.value.secret_properties.content_type
      }

      dynamic "x509_certificate_properties" {
        for_each = certificate_policy.value.x509_certificate_properties != null ? [certificate_policy.value.x509_certificate_properties] : []
        content {
          extended_key_usage = x509_certificate_properties.value.extended_key_usage
          key_usage          = x509_certificate_properties.value.key_usage
          subject            = x509_certificate_properties.value.subject
          validity_in_months = x509_certificate_properties.value.validity_in_months

          dynamic "subject_alternative_names" {
            for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []
            content {
              dns_names = subject_alternative_names.value.dns_names
              emails    = subject_alternative_names.value.emails
              upns      = subject_alternative_names.value.upns
            }
          }
        }
      }
    }
  }
}
