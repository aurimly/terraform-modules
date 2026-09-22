locals {
  eip_keys = { for k, n in var.nat_gateways : k => n if n.allocation_id == null && n.connectivity_type == "public" }
}

resource "aws_eip" "nat" {
  for_each = local.eip_keys

  domain = "vpc"
  tags   = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_nat_gateway" "nat" {
  for_each = var.nat_gateways

  subnet_id                      = each.value.subnet_id
  connectivity_type              = each.value.connectivity_type
  allocation_id                  = each.value.connectivity_type != "public" ? null : coalesce(each.value.allocation_id, try(aws_eip.nat[each.key].allocation_id, null))
  private_ip                     = each.value.private_ip
  secondary_allocation_ids       = each.value.secondary_allocation_ids
  secondary_private_ip_addresses = each.value.secondary_private_ip_addresses

  tags = merge(each.value.tags, { Name = each.value.name })

  depends_on = [aws_eip.nat]
}
