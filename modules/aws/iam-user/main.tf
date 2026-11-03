locals {
  attachments = { for pair in flatten([
    for user_key, user in var.users : [
      for arn in user.managed_policy_arns : {
        key      = "${user_key}.${arn}"
        user_key = user_key
        arn      = arn
      }
    ]
    if length(user.managed_policy_arns) > 0
  ]) : pair.key => pair }

  inline_policies = { for pair in flatten([
    for user_key, user in var.users : [
      for policy_key, policy in user.inline_policies : {
        key      = "${user_key}.${policy_key}"
        user_key = user_key
        policy   = policy
      }
    ]
    if length(user.inline_policies) > 0
  ]) : pair.key => pair }

  memberships = { for k, v in var.users : k => v if length(v.groups) > 0 }

  access_keys = { for k, v in var.users : k => v if v.access_key != null }
}

resource "aws_iam_user" "user" {
  for_each = var.users

  name                 = each.value.name
  path                 = each.value.path
  permissions_boundary = each.value.permissions_boundary
  force_destroy        = each.value.force_destroy

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_iam_user_policy_attachment" "attachment" {
  for_each = local.attachments

  user       = aws_iam_user.user[each.value.user_key].name
  policy_arn = each.value.arn
}

resource "aws_iam_user_policy" "inline" {
  for_each = local.inline_policies

  user   = aws_iam_user.user[each.value.user_key].name
  name   = each.value.policy.name
  policy = each.value.policy.policy_json
}

resource "aws_iam_user_group_membership" "membership" {
  for_each = local.memberships

  user   = aws_iam_user.user[each.key].name
  groups = each.value.groups
}

resource "aws_iam_access_key" "key" {
  for_each = local.access_keys

  user    = aws_iam_user.user[each.key].name
  pgp_key = each.value.access_key.pgp_key
  status  = each.value.access_key.status
}
