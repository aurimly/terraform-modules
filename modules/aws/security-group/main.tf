locals {
  ingress_rules = { for pair in flatten([
    for group_key, group in var.security_groups : [
      for rule_key, rule in group.ingress : {
        key       = "${group_key}.${rule_key}.ingress"
        group_key = group_key
        rule      = rule
      }
    ]
    if length(group.ingress) > 0
  ]) : pair.key => pair }

  egress_rules = { for pair in flatten([
    for group_key, group in var.security_groups : [
      for rule_key, rule in group.egress : {
        key       = "${group_key}.${rule_key}.egress"
        group_key = group_key
        rule      = rule
      }
    ]
    if length(group.egress) > 0
  ]) : pair.key => pair }
}

resource "aws_security_group" "sg" {
  for_each = var.security_groups

  name                   = each.value.name
  description            = each.value.description
  vpc_id                 = each.value.vpc_id
  revoke_rules_on_delete = each.value.revoke_rules_on_delete

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each = local.ingress_rules

  security_group_id            = aws_security_group.sg[each.value.group_key].id
  description                  = each.value.rule.description
  cidr_ipv4                    = each.value.rule.cidr_ipv4
  cidr_ipv6                    = each.value.rule.cidr_ipv6
  prefix_list_id               = each.value.rule.prefix_list_id
  referenced_security_group_id = each.value.rule.referenced_security_group_id
  from_port                    = each.value.rule.from_port
  to_port                      = each.value.rule.to_port
  ip_protocol                  = each.value.rule.protocol
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  for_each = local.egress_rules

  security_group_id            = aws_security_group.sg[each.value.group_key].id
  description                  = each.value.rule.description
  cidr_ipv4                    = each.value.rule.cidr_ipv4
  cidr_ipv6                    = each.value.rule.cidr_ipv6
  prefix_list_id               = each.value.rule.prefix_list_id
  referenced_security_group_id = each.value.rule.referenced_security_group_id
  from_port                    = each.value.rule.from_port
  to_port                      = each.value.rule.to_port
  ip_protocol                  = each.value.rule.protocol
}
