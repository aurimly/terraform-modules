variable "organization" {
  description = "Organization settings; null (the default) runs the module attach-only against an org managed elsewhere (console or consumer config)."
  type = object({
    aws_service_access_principals = optional(list(string), [])
    enabled_policy_types          = optional(list(string), [])
    feature_set                   = optional(string, "ALL")
  })
  default = null

  validation {
    condition     = var.organization == null || alltrue([for p in var.organization.aws_service_access_principals : can(regex("^[a-z0-9.-]+\\.amazonaws\\.com$", p))])
    error_message = "aws_service_access_principals entries must be service principals like cloudtrail.amazonaws.com."
  }

  validation {
    condition = var.organization == null || alltrue([for t in var.organization.enabled_policy_types : contains([
      "AISERVICES_OPT_OUT_POLICY", "BACKUP_POLICY", "BEDROCK_POLICY", "CHATBOT_POLICY", "DECLARATIVE_POLICY_EC2",
      "GUARDDUTY_POLICY", "INSPECTOR_POLICY", "NETWORK_SECURITY_DIRECTOR_POLICY", "RESOURCE_CONTROL_POLICY",
      "S3_POLICY", "SECURITYHUB_POLICY", "SERVICE_CONTROL_POLICY", "TAG_POLICY", "UPGRADE_ROLLOUT_POLICY",
    ], t)])
    error_message = "enabled_policy_types entries must be valid AWS Organizations policy types (see README for the full list)."
  }

  validation {
    condition     = var.organization == null || var.organization.feature_set == null || contains(["ALL", "CONSOLIDATED_BILLING"], var.organization.feature_set)
    error_message = "feature_set must be ALL or CONSOLIDATED_BILLING."
  }

  validation {
    condition     = var.organization == null || length(var.organization.enabled_policy_types) == 0 || var.organization.feature_set == "ALL"
    error_message = "policy types require an all-features organization — set feature_set = \"ALL\" when enabling policy types (CONSOLIDATED_BILLING organizations cannot carry policies)."
  }
}

variable "ous" {
  description = "Map of organizational units keyed by an arbitrary identifier. Each entry creates one aws_organizations_organizational_unit; parents may be the managed root, a sibling key from this map (nesting), or a literal r-/ou- ID. Map keys must not contain '.' (composite attachment keys)."
  type = map(object({
    name   = string
    parent = optional(string, "root")
    tags   = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.ous) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (attachment resource addresses and composite output keys are composed from attachment and OU keys)."
  }

  validation {
    condition     = alltrue([for o in var.ous : length(o.name) >= 1 && length(o.name) <= 200])
    error_message = "name must be 1-200 characters (AWS Organizations OU naming rules)."
  }

  validation {
    condition     = alltrue([for o in var.ous : o.parent == "root" || contains(keys(var.ous), o.parent) || can(regex("^r-[0-9a-z]{4,32}$|^ou-[0-9a-z]{4,32}-[0-9a-z]{8,32}$", o.parent))])
    error_message = "parent must be \"root\" (managed root), a key of the ous map (nested OU), or a literal r-<id> or ou-<id>-<id> ID (AWS Organizations ID format)."
  }

  validation {
    condition = alltrue([
      for k, o in var.ous :
      !contains(keys(var.ous), o.parent) || !contains(keys(var.ous), var.ous[o.parent].parent)
    ])
    error_message = "OUs support two levels of managed nesting — an OU whose parent is a managed OU must itself have a non-managed parent (\"root\" or a literal r-/ou- ID). Deeper trees: manage them consumer-side; a separate module instance only works when its parent IDs are literal (known before plan)."
  }

  validation {
    condition     = alltrue([for k in keys(var.ous) : k != "root"])
    error_message = "the map key \"root\" is reserved — it collides with the parent = \"root\" sentinel and target-root attachment keys."
  }

  validation {
    condition     = alltrue([for o in var.ous : o.parent != "root" || var.organization != null])
    error_message = "parent = \"root\" requires the organization to be managed by this module (set organization) — in attach-only mode pass literal r-/ou- IDs instead."
  }
}

variable "policies" {
  description = "Map of organization policies (usually SCPs) keyed by an arbitrary identifier. Each entry creates one aws_organizations_policy from a JSON content document."
  type = map(object({
    name         = string
    content      = string
    description  = optional(string)
    type         = optional(string, "SERVICE_CONTROL_POLICY")
    skip_destroy = optional(bool, false)
    tags         = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for p in var.policies : length(p.name) >= 1 && length(p.name) <= 128])
    error_message = "name must be 1-128 characters (AWS Organizations policy naming rules)."
  }

  validation {
    condition     = alltrue([for p in var.policies : can(jsondecode(p.content))])
    error_message = "content must be a valid JSON policy document."
  }

  validation {
    condition = alltrue([for p in var.policies : contains([
      "AISERVICES_OPT_OUT_POLICY", "BACKUP_POLICY", "BEDROCK_POLICY", "CHATBOT_POLICY", "DECLARATIVE_POLICY_EC2",
      "GUARDDUTY_POLICY", "INSPECTOR_POLICY", "NETWORK_SECURITY_DIRECTOR_POLICY", "RESOURCE_CONTROL_POLICY",
      "S3_POLICY", "SECURITYHUB_POLICY", "SERVICE_CONTROL_POLICY", "TAG_POLICY", "UPGRADE_ROLLOUT_POLICY",
    ], p.type)])
    error_message = "type must be a valid AWS Organizations policy type (see README for the full list)."
  }

  validation {
    condition     = alltrue([for p in var.policies : var.organization == null || contains(var.organization.enabled_policy_types, p.type)])
    error_message = "the policy type must appear in organization.enabled_policy_types when the organization is managed by this module — policies of a type not enabled on the org are rejected by the API."
  }
}

variable "policy_attachments" {
  description = "Map of policy attachments keyed by an arbitrary identifier. Each entry resolves one policy (in-module via policy_key, or external via policy_id — exactly one) and attaches it to the configured targets. Each (policy, target) pair becomes one aws_organizations_policy_attachment."
  type = map(object({
    policy_key         = optional(string)
    policy_id          = optional(string)
    skip_destroy       = optional(bool, false)
    target_root        = optional(bool, false)
    target_ous         = optional(list(string), [])
    target_account_ids = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.policy_attachments) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (attachment resource addresses and composite output keys are composed from attachment and target keys)."
  }

  validation {
    condition     = alltrue([for a in var.policy_attachments : (a.policy_key != null) != (a.policy_id != null)])
    error_message = "exactly one of policy_key (a key of the policies map) or policy_id (a literal p- ID, e.g. an AWS-managed policy) must be set."
  }

  validation {
    condition     = alltrue([for a in var.policy_attachments : a.policy_key == null || contains(keys(var.policies), a.policy_key)])
    error_message = "policy_key must be a key of the policies map."
  }

  validation {
    condition     = alltrue([for a in var.policy_attachments : a.target_root || length(a.target_ous) > 0 || length(a.target_account_ids) > 0])
    error_message = "at least one target is required — set target_root, target_ous or target_account_ids."
  }

  validation {
    condition     = alltrue([for a in var.policy_attachments : alltrue([for o in a.target_ous : contains(keys(var.ous), o)])])
    error_message = "target_ous entries must be keys of the ous map."
  }

  validation {
    condition     = alltrue([for a in var.policy_attachments : alltrue([for i in a.target_account_ids : can(regex("^[0-9]{12}$", i))])])
    error_message = "target_account_ids entries must be 12-digit AWS account IDs."
  }

  validation {
    condition     = alltrue([for a in var.policy_attachments : !a.target_root || var.organization != null])
    error_message = "target_root = true requires the organization to be managed by this module (set organization) — in attach-only mode there is no managed root, so attach consumer-side or manage the org in this module."
  }

  validation {
    condition     = length(distinct(flatten([for akey, a in var.policy_attachments : [for t in concat(a.target_root ? ["root"] : [], formatlist("ou.%s", a.target_ous), formatlist("account.%s", a.target_account_ids)) : "${coalesce(a.policy_key, a.policy_id)}|${t}"]]))) == length(flatten([for akey, a in var.policy_attachments : [for t in concat(a.target_root ? ["root"] : [], formatlist("ou.%s", a.target_ous), formatlist("account.%s", a.target_account_ids)) : "${coalesce(a.policy_key, a.policy_id)}|${t}"]]))
    error_message = "each (policy, target) pair must be unique across attachments — duplicates would fail at apply with an attachment-already-exists error."
  }
}

variable "delegated_administrators" {
  description = "Map of delegated administrators keyed by an arbitrary identifier. Each entry registers one existing account as the delegated administrator for one service principal."
  type = map(object({
    account_id        = string
    service_principal = string
  }))
  default = {}

  validation {
    condition     = alltrue([for d in var.delegated_administrators : can(regex("^[0-9]{12}$", d.account_id))])
    error_message = "account_id must be a 12-digit AWS account ID."
  }

  validation {
    condition     = alltrue([for d in var.delegated_administrators : can(regex("^[a-z0-9.-]+\\.amazonaws\\.com$", d.service_principal))])
    error_message = "service_principal must be a service principal like guardduty.amazonaws.com."
  }
}
