locals {
  trust_doc_keys = { for k, v in var.roles : k => v.trust if v.trust != null }

  attachments = { for pair in flatten([
    for role_key, role in var.roles : [
      for arn in role.managed_policy_arns : {
        key      = "${role_key}.${arn}"
        role_key = role_key
        arn      = arn
      }
    ]
    if length(role.managed_policy_arns) > 0
  ]) : pair.key => pair }

  inline_policies = { for pair in flatten([
    for role_key, role in var.roles : [
      for policy_key, policy in role.inline_policies : {
        key      = "${role_key}.${policy_key}"
        role_key = role_key
        policy   = policy
      }
    ]
    if length(role.inline_policies) > 0
  ]) : pair.key => pair }

  profile_keys = { for k, v in var.roles : k => v.create_instance_profile if v.create_instance_profile }
}

data "aws_iam_policy_document" "trust" {
  for_each = local.trust_doc_keys

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = each.value.principal_type
      identifiers = each.value.identifiers
    }

    dynamic "condition" {
      for_each = each.value.conditions

      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "role" {
  for_each = var.roles

  name                  = each.value.name
  path                  = each.value.path
  description           = each.value.description
  max_session_duration  = each.value.max_session_duration
  permissions_boundary  = each.value.permissions_boundary
  force_detach_policies = each.value.force_detach_policies
  assume_role_policy    = each.value.trust_policy_json != null ? each.value.trust_policy_json : data.aws_iam_policy_document.trust[each.key].json

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  for_each = local.attachments

  role       = aws_iam_role.role[each.value.role_key].name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy" "inline" {
  for_each = local.inline_policies

  role   = aws_iam_role.role[each.value.role_key].name
  name   = each.value.policy.name
  policy = each.value.policy.policy_json
}

resource "aws_iam_instance_profile" "profile" {
  for_each = local.profile_keys

  name = aws_iam_role.role[each.key].name
  role = aws_iam_role.role[each.key].name
  path = var.roles[each.key].path

  tags = merge(var.roles[each.key].tags, { Name = var.roles[each.key].name })
}
