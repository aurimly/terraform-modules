resource "aws_route53_zone" "zone" {
  for_each = var.zones

  name              = each.value.name
  comment           = each.value.comment
  delegation_set_id = each.value.delegation_set_id
  force_destroy     = each.value.force_destroy

  dynamic "vpc" {
    for_each = each.value.vpc_ids

    content {
      vpc_id = vpc.value
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.private || length(each.value.vpc_ids) == 0
      error_message = "zone \"${each.key}\": vpc_ids only apply to private zones (public zones cannot associate VPCs)."
    }

    precondition {
      condition     = !each.value.private || length(each.value.vpc_ids) > 0
      error_message = "zone \"${each.key}\" is private: at least one vpc_id is required (a private hosted zone is meaningless without an associated VPC)."
    }
  }

  tags = each.value.tags
}

resource "aws_route53_delegation_set" "delegation_set" {
  for_each = { for k, z in var.zones : k => z if z.create_delegation_set }

  reference_name = each.key
}
