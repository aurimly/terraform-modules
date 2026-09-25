variable "repositories" {
  description = "Map of ECR repositories keyed by an arbitrary identifier. Each entry creates one aws_ecr_repository plus an optional lifecycle policy and repository policy."
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string, "MUTABLE")
    image_tag_mutability_exclusion_filters = optional(list(object({
      filter      = string
      filter_type = optional(string, "WILDCARD")
    })), [])
    scan_on_push = optional(bool, false)
    encryption = optional(object({
      type    = optional(string, "AES256")
      kms_key = optional(string)
    }))
    force_delete = optional(bool)
    timeouts = optional(object({
      delete = optional(string)
    }))
    lifecycle_policy = optional(object({
      rules = list(object({
        rule_priority = number
        description   = optional(string)
        selection = object({
          tag_status       = string
          tag_pattern_list = optional(list(string))
          tag_prefix_list  = optional(list(string))
          storage_class    = optional(string)
          count_type       = string
          count_unit       = optional(string)
          count_number     = number
        })
        action = optional(object({
          type                 = string
          target_storage_class = optional(string)
        }), { type = "expire" })
      }))
    }))
    repository_policy = optional(object({
      policy = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.repositories : length(r.name) >= 2 && length(r.name) <= 256 && can(regex("^(?:[a-z0-9]+(?:[._-][a-z0-9]+)*/)?[a-z0-9]+(?:[._-][a-z0-9]+)*$", r.name))])
    error_message = "name must be 2 to 256 characters, lowercase alphanumerics with single . _ - separators and at most one namespace segment terminated by / (ECR pattern: (?:[a-z0-9]+(?:[._-][a-z0-9]+)*/)?[a-z0-9]+(?:[._-][a-z0-9]+)*)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : contains(["MUTABLE", "IMMUTABLE", "MUTABLE_WITH_EXCLUSION", "IMMUTABLE_WITH_EXCLUSION"], r.image_tag_mutability)])
    error_message = "image_tag_mutability must be one of MUTABLE, IMMUTABLE, MUTABLE_WITH_EXCLUSION or IMMUTABLE_WITH_EXCLUSION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : alltrue([for f in r.image_tag_mutability_exclusion_filters : f.filter_type == "WILDCARD"])])
    error_message = "image_tag_mutability_exclusion_filters.filter_type must be WILDCARD (the only filter type the API accepts for tag-mutability exclusions)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : length(r.image_tag_mutability_exclusion_filters) == 0 || !can(regex("^MUTABLE$|^IMMUTABLE$", r.image_tag_mutability))])
    error_message = "image_tag_mutability_exclusion_filters requires image_tag_mutability MUTABLE_WITH_EXCLUSION or IMMUTABLE_WITH_EXCLUSION (the plain options reject exclusion filters)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : r.encryption == null || contains(["AES256", "KMS"], r.encryption.type)])
    error_message = "encryption.type must be one of AES256 or KMS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : r.encryption == null || r.encryption.type != "AES256" || r.encryption.kms_key == null])
    error_message = "encryption.kms_key must not be set when encryption.type is AES256 (AES256 uses ECR-managed AES encryption)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for i, rule in r.lifecycle_policy.rules : rule.rule_priority > 0
      ])
    ])
    error_message = "lifecycle_policy.rules.rule_priority must be a positive integer (ECR evaluates rules starting at 1; the rule matching first wins)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || length(r.lifecycle_policy.rules) == length(distinct([for rule in r.lifecycle_policy.rules : rule.rule_priority]))
    ])
    error_message = "lifecycle_policy.rules.rule_priority must be unique within one policy (duplicate priorities are rejected when the policy is applied)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for i in range(max(length(r.lifecycle_policy.rules) - 1, 0)) :
        r.lifecycle_policy.rules[i].rule_priority < r.lifecycle_policy.rules[i + 1].rule_priority
      ])
    ])
    error_message = "lifecycle_policy.rules must be listed in ascending rule_priority order (ECR reorders by priority; a shuffled list shows a perpetual diff)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : contains(["tagged", "untagged", "any"], rule.selection.tag_status)
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.tag_status must be one of tagged, untagged or any (lowercase, case-sensitive)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : (length(coalesce(rule.selection.tag_pattern_list, [])) == 0) || (length(coalesce(rule.selection.tag_prefix_list, [])) == 0)
      ])
    ])
    error_message = "lifecycle_policy.rules.selection: use either tag_pattern_list or tag_prefix_list, not both (the API rejects both in one rule)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.selection.tag_status != "tagged" || length(coalesce(rule.selection.tag_pattern_list, [])) > 0 || length(coalesce(rule.selection.tag_prefix_list, [])) > 0
      ])
    ])
    error_message = "lifecycle_policy.rules.selection requires one of tag_pattern_list or tag_prefix_list when tag_status is tagged (the API rejects a tagged rule without either)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.selection.tag_status == "tagged" || (length(coalesce(rule.selection.tag_pattern_list, [])) == 0 && length(coalesce(rule.selection.tag_prefix_list, [])) == 0)
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.tag_pattern_list/tag_prefix_list only apply when tag_status is tagged (the API rejects them otherwise)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || length(r.lifecycle_policy.rules) > 0
    ])
    error_message = "lifecycle_policy.rules must contain at least one rule (the API rejects an empty policy)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : contains(["imageCountMoreThan", "sinceImagePushed", "sinceImagePulled", "sinceImageTransitioned"], rule.selection.count_type)
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.count_type must be one of imageCountMoreThan, sinceImagePushed, sinceImagePulled or sinceImageTransitioned (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.selection.count_number > 0
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.count_number must be a positive integer."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.selection.count_type == "imageCountMoreThan" || rule.selection.count_type == "anyOf" || rule.selection.count_unit == "days"
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.count_unit must be days for sinceImagePushed, sinceImagePulled and sinceImageTransitioned count types."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.selection.count_type == "sinceImagePushed" || rule.selection.count_type == "sinceImagePulled" || rule.selection.count_type == "sinceImageTransitioned" || rule.selection.count_unit == null
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.count_unit is only valid with sinceImagePushed, sinceImagePulled or sinceImageTransitioned count types (the API rejects it otherwise)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.selection.count_type != "sinceImageTransitioned" || rule.selection.storage_class == "archive"
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.storage_class must be archive when count_type is sinceImageTransitioned (the API rejects anything else)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.selection.storage_class == null || rule.selection.count_type == "sinceImageTransitioned" || rule.selection.count_type == "imageCountMoreThan" || rule.selection.count_type == "sinceImagePushed" || rule.selection.count_type == "sinceImagePulled"
      ])
    ])
    error_message = "lifecycle_policy.rules.selection.storage_class is only valid with count_type sinceImageTransitioned (archive) or imageCountMoreThan/sinceImagePushed/sinceImagePulled (standard); the API rejects it otherwise."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for i, rule in r.lifecycle_policy.rules : rule.selection.tag_status != "any" || i == length(r.lifecycle_policy.rules) - 1
      ])
    ])
    error_message = "lifecycle_policy.rules with tag_status any must have the highest rule_priority, i.e. be listed last (ECR evaluates rules in order and stops at the first match)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : contains(["expire", "transition"], rule.action.type)
      ])
    ])
    error_message = "lifecycle_policy.rules.action.type must be one of expire or transition (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.action.type != "transition" || rule.action.target_storage_class == "archive"
      ])
    ])
    error_message = "lifecycle_policy.rules.action.target_storage_class must be archive when action.type is transition (the API rejects anything else)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : r.lifecycle_policy == null || alltrue([
        for rule in r.lifecycle_policy.rules : rule.action.type != "expire" || rule.action.target_storage_class == null
      ])
    ])
    error_message = "lifecycle_policy.rules.action.target_storage_class is only valid with action.type transition (the API rejects it otherwise)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : r.repository_policy == null || length(r.repository_policy.policy) > 0 && can(jsondecode(r.repository_policy.policy))])
    error_message = "repository_policy.policy must be a non-empty JSON document (e.g. an aws_iam_policy_document data source rendered with jsonencode)."
  }
}
