terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

locals {
  domains = {
    for d in flatten([
      for key, project in var.projects : [
        for domain in project.domains : {
          project_key = key
          name        = project.name
          account_id  = project.account_id
          domain      = domain
        }
      ]
    ]) : "${d.project_key}/${d.domain}" => d
  }
}

resource "cloudflare_pages_project" "project" {
  for_each = var.projects

  account_id         = coalesce(each.value.account_id, var.account_id)
  name               = each.value.name
  production_branch  = each.value.production_branch
  build_config       = each.value.build_config
  source             = each.value.source
  deployment_configs = each.value.deployment_configs

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "project \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }
  }
}

resource "cloudflare_pages_domain" "domain" {
  for_each = local.domains

  account_id   = coalesce(each.value.account_id, var.account_id)
  name         = each.value.domain
  project_name = each.value.name

  depends_on = [cloudflare_pages_project.project]
}
