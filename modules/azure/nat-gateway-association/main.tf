resource "azurerm_subnet_nat_gateway_association" "association" {
  for_each = var.subnet_nat_gateway_associations

  subnet_id      = each.value.subnet_id
  nat_gateway_id = each.value.nat_gateway_id
}
