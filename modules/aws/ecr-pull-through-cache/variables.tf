variable "rules" {
  description = "Map of ECR pull-through cache rules keyed by an arbitrary identifier. Each entry creates one aws_ecr_pull_through_cache_rule."
  type = map(object({
    ecr_repository_prefix      = string
    upstream_registry_url      = string
    credential_arn             = optional(string)
    custom_role_arn            = optional(string)
    upstream_repository_prefix = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in var.rules : r.ecr_repository_prefix == "ROOT" || (length(r.ecr_repository_prefix) >= 2 && length(r.ecr_repository_prefix) <= 30 && can(regex("^([a-z0-9]+((\\.|_|__|-+)[a-z0-9]+)*(\\/[a-z0-9]+((\\.|_|__|-+)[a-z0-9]+)*)*\\/?|ROOT)$", r.ecr_repository_prefix)))
    ])
    error_message = "ecr_repository_prefix must be ROOT or 2-30 characters, lowercase alphanumerics with single . _ - separators (or __ / repeated -), optionally slash-separated path segments with a trailing slash (ECR API pattern)."
  }

  validation {
    condition     = length(var.rules) == length(distinct([for r in var.rules : r.ecr_repository_prefix]))
    error_message = "ecr_repository_prefix must be unique across entries (the prefix is the rule's unique key; duplicates fail at apply with PullThroughCacheRuleAlreadyExistsException)."
  }

  validation {
    condition = alltrue([
      for r in var.rules : r.upstream_repository_prefix == null || (length(r.upstream_repository_prefix) >= 2 && length(r.upstream_repository_prefix) <= 30 && can(regex("^([a-z0-9]+((\\.|_|__|-+)[a-z0-9]+)*(\\/[a-z0-9]+((\\.|_|__|-+)[a-z0-9]+)*)*\\/?|ROOT)$", r.upstream_repository_prefix)))
    ])
    error_message = "upstream_repository_prefix must be ROOT or 2-30 characters, lowercase alphanumerics with single . _ - separators (or __ / repeated -), optionally slash-separated path segments with a trailing slash (ECR API pattern)."
  }

  validation {
    condition = alltrue([
      for r in var.rules : r.upstream_repository_prefix == null || r.ecr_repository_prefix != "ROOT"
    ])
    error_message = "upstream_repository_prefix can only be set when ecr_repository_prefix is not ROOT (the ROOT catch-all rule always matches the upstream ROOT)."
  }

  validation {
    condition = alltrue([
      for r in var.rules : r.credential_arn == null || can(regex("^arn:aws(-[a-z0-9]+)*:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+$", r.credential_arn))
    ])
    error_message = "credential_arn must be a Secrets Manager secret ARN (arn:aws<partition>:secretsmanager:<region>:<account>:secret:<name>)."
  }

  validation {
    condition = alltrue([
      for r in var.rules : r.custom_role_arn == null || can(regex("^arn:aws(-[a-z0-9]+)*:iam::[0-9]{12}:role/.+$", r.custom_role_arn))
    ])
    error_message = "custom_role_arn must be an IAM role ARN (arn:aws<partition>:iam::<account>:role/<name>)."
  }
}
