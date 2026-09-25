locals {
  lifecycle_policy_json = {
    for k, r in var.repositories : k => r.lifecycle_policy == null ? null : jsonencode({
      rules = [
        for rule in r.lifecycle_policy.rules : {
          for key, value in {
            rulePriority = rule.rule_priority
            description  = rule.description
            selection = {
              for s_key, s_value in merge(
                { tagStatus = rule.selection.tag_status },
                rule.selection.tag_status == "tagged" && length(coalesce(rule.selection.tag_pattern_list, [])) > 0 ? { tagPatternList = rule.selection.tag_pattern_list } : {},
                rule.selection.tag_status == "tagged" && length(coalesce(rule.selection.tag_prefix_list, [])) > 0 ? { tagPrefixList = rule.selection.tag_prefix_list } : {},
                rule.selection.storage_class != null ? { storageClass = rule.selection.storage_class } : {},
                { countType = rule.selection.count_type },
                rule.selection.count_unit != null ? { countUnit = rule.selection.count_unit } : {},
                { countNumber = rule.selection.count_number }
              ) : s_key => s_value
            }
            action = {
              for a_key, a_value in merge(
                { type = rule.action.type },
                rule.action.target_storage_class != null ? { targetStorageClass = rule.action.target_storage_class } : {}
              ) : a_key => a_value
            }
          } : key => value if value != null
        }
      ]
    })
  }
}

resource "aws_ecr_repository" "repository" {
  for_each = var.repositories

  name                 = each.value.name
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete
  tags                 = merge(each.value.tags, { Name = each.value.name })

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption != null ? each.value.encryption.type : "AES256"
    kms_key         = each.value.encryption != null ? each.value.encryption.kms_key : null
  }

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = each.value.image_tag_mutability_exclusion_filters

    content {
      filter      = image_tag_mutability_exclusion_filter.value.filter
      filter_type = image_tag_mutability_exclusion_filter.value.filter_type
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []

    content {
      delete = timeouts.value.delete
    }
  }
}

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each = { for k, r in var.repositories : k => r if r.lifecycle_policy != null }

  repository = aws_ecr_repository.repository[each.key].name
  policy     = local.lifecycle_policy_json[each.key]
}

resource "aws_ecr_repository_policy" "policy" {
  for_each = { for k, r in var.repositories : k => r if r.repository_policy != null }

  repository = aws_ecr_repository.repository[each.key].name
  policy     = each.value.repository_policy.policy
}
