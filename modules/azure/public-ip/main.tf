resource "azurerm_public_ip" "public_ip" {
  for_each = var.public_ips

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  allocation_method = each.value.allocation_method
  sku               = each.value.sku
  sku_tier          = each.value.sku_tier
  ip_version        = each.value.ip_version

  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  domain_name_label       = each.value.domain_name_label

  zones = each.value.availability_zone != null ? [each.value.availability_zone] : null

  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id

  tags = each.value.tags
}
