resource "aws_subnet" "subnet" {
  for_each = var.subnets

  vpc_id                              = each.value.vpc_id
  cidr_block                          = each.value.cidr_block
  availability_zone                   = each.value.availability_zone
  availability_zone_id                = each.value.availability_zone_id
  map_public_ip_on_launch             = each.value.map_public_ip_on_launch
  private_dns_hostname_type_on_launch = each.value.private_dns_hostname_type_on_launch
  ipv6_cidr_block                     = each.value.ipv6_cidr_block
  assign_ipv6_address_on_creation     = each.value.assign_ipv6_address_on_creation

  tags = merge(each.value.tags, { Name = each.value.name })
}
