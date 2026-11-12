locals {
  # one() over an empty list yields null without an index error, and the
  # for-expression keeps the org → OU/attachment dependency edge intact when
  # the module runs attach-only (organization = null).
  root_id = one([for o in aws_organizations_organization.org : o.roots[0].id])

  attachment_target_lists = {
    for akey, att in var.policy_attachments : akey =>
    concat(
      att.target_root ? ["root"] : [],
      formatlist("ou.%s", att.target_ous),
      formatlist("account.%s", att.target_account_ids),
    )
  }

  attachments = merge([
    for akey, att in var.policy_attachments : {
      for tkey in local.attachment_target_lists[akey] : "${akey}.${tkey}" => {
        attachment_key = akey
        target_key     = tkey
        policy_id      = att.policy_key != null ? aws_organizations_policy.policy[att.policy_key].id : att.policy_id
        skip_destroy   = att.skip_destroy
      }
    }
  ]...)

  attachment_target_ids = {
    for ckey, att in local.attachments : ckey =>
    att.target_key == "root" ? local.root_id :
    startswith(att.target_key, "ou.") ? local.ou_ids[substr(att.target_key, 3, length(att.target_key))] :
    substr(att.target_key, 8, length(att.target_key))
  }

  ou_ids = merge(
    { for k, o in aws_organizations_organizational_unit.ou : k => o.id },
    { for k, o in aws_organizations_organizational_unit.nested_ou : k => o.id },
  )

  ou_arns = merge(
    { for k, o in aws_organizations_organizational_unit.ou : k => o.arn },
    { for k, o in aws_organizations_organizational_unit.nested_ou : k => o.arn },
  )
}

resource "aws_organizations_organization" "org" {
  count = var.organization != null ? 1 : 0

  aws_service_access_principals = var.organization.aws_service_access_principals
  enabled_policy_types          = var.organization.enabled_policy_types
  feature_set                   = var.organization.feature_set
}

# OUs split into two resources because a resource block cannot reference
# itself (Terraform rejects self-referential blocks even when the for_each
# membership keeps the reference out of reach): entries whose parent is not
# a managed sibling (root or a literal r-/ou- ID) live in `ou`; entries
# whose parent is a managed sibling live in `nested_ou` — two levels of
# managed nesting (validated).
resource "aws_organizations_organizational_unit" "ou" {
  for_each = { for k, o in var.ous : k => o if !contains(keys(var.ous), o.parent) }

  name      = each.value.name
  parent_id = each.value.parent == "root" ? local.root_id : each.value.parent
  tags      = each.value.tags
}

resource "aws_organizations_organizational_unit" "nested_ou" {
  for_each = { for k, o in var.ous : k => o if contains(keys(var.ous), o.parent) }

  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.ou[each.value.parent].id
  tags      = each.value.tags
}

resource "aws_organizations_policy" "policy" {
  for_each = var.policies

  name         = each.value.name
  description  = each.value.description
  content      = each.value.content
  type         = each.value.type
  skip_destroy = each.value.skip_destroy
  tags         = each.value.tags
}

resource "aws_organizations_policy_attachment" "attachment" {
  for_each = local.attachments

  policy_id    = each.value.policy_id
  target_id    = local.attachment_target_ids[each.key]
  skip_destroy = each.value.skip_destroy
}

resource "aws_organizations_delegated_administrator" "delegated" {
  for_each = var.delegated_administrators

  account_id        = each.value.account_id
  service_principal = each.value.service_principal
}
