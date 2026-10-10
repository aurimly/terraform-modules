terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_repository_environment" "env" {
  for_each = var.environments

  repository          = var.repository
  environment         = each.value.environment
  wait_timer          = each.value.wait_timer
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review

  dynamic "reviewers" {
    for_each = each.value.reviewers != null && length(each.value.reviewers.users) + length(each.value.reviewers.teams) > 0 ? [1] : []
    content {
      users = each.value.reviewers.users
      teams = each.value.reviewers.teams
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.deployment_branch_policy != null ? [1] : []
    content {
      protected_branches     = each.value.deployment_branch_policy.protected_branches
      custom_branch_policies = each.value.deployment_branch_policy.custom_branch_policies
    }
  }
}

resource "github_repository_environment_deployment_policy" "policy" {
  for_each = {
    for pair in flatten([
      for ek, e in var.environments : e.deployment_branch_policy != null && e.deployment_branch_policy.custom_branch_policies ? concat(
        [
          for p in e.deployment_branch_policy.branch_patterns : {
            key             = "${ek}:${p}"
            environment_key = ek
            branch_pattern  = p
            tag_pattern     = null
          }
        ],
        [
          for p in e.deployment_branch_policy.tag_patterns : {
            key             = "${ek}:${p}"
            environment_key = ek
            branch_pattern  = null
            tag_pattern     = p
          }
        ]
      ) : []
    ]) : pair.key => pair
  }

  repository     = var.repository
  environment    = github_repository_environment.env[each.value.environment_key].environment
  branch_pattern = each.value.branch_pattern
  tag_pattern    = each.value.tag_pattern
}

resource "github_actions_environment_secret" "env_secret" {
  for_each = {
    for pair in flatten([
      for ek, e in var.environments : [
        for sk, s in e.secrets : {
          key             = "${ek}:${sk}"
          environment_key = ek
          name            = sk
          value           = s.value
        }
      ]
    ]) : pair.key => pair
  }

  repository  = var.repository
  environment = github_repository_environment.env[each.value.environment_key].environment
  secret_name = each.value.name
  value       = each.value.value
}

resource "github_actions_environment_variable" "env_variable" {
  for_each = {
    for pair in flatten([
      for ek, e in var.environments : [
        for vk, v in e.variables : {
          key             = "${ek}:${vk}"
          environment_key = ek
          name            = vk
          value           = v.value
        }
      ]
    ]) : pair.key => pair
  }

  repository    = var.repository
  environment   = github_repository_environment.env[each.value.environment_key].environment
  variable_name = each.value.name
  value         = each.value.value
}
