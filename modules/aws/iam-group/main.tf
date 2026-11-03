locals {
  attachments = { for pair in flatten([
    for group_key, group in var.groups : [
      for arn in group.managed_policy_arns : {
        key       = "${group_key}.${arn}"
        group_key = group_key
        arn       = arn
      }
    ]
    if length(group.managed_policy_arns) > 0
  ]) : pair.key => pair }

  inline_policies = { for pair in flatten([
    for group_key, group in var.groups : [
      for policy_key, policy in group.inline_policies : {
        key       = "${group_key}.${policy_key}"
        group_key = group_key
        policy    = policy
      }
    ]
    if length(group.inline_policies) > 0
  ]) : pair.key => pair }
}

resource "aws_iam_group" "group" {
  for_each = var.groups

  name = each.value.name
  path = each.value.path
}

resource "aws_iam_group_policy_attachment" "attachment" {
  for_each = local.attachments

  group      = aws_iam_group.group[each.value.group_key].name
  policy_arn = each.value.arn
}

resource "aws_iam_group_policy" "inline" {
  for_each = local.inline_policies

  group  = aws_iam_group.group[each.value.group_key].name
  name   = each.value.policy.name
  policy = each.value.policy.policy_json
}
