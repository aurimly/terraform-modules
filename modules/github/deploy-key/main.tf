terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_repository_deploy_key" "key" {
  for_each   = var.deploy_keys
  repository = var.repository
  title      = coalesce(each.value.title, each.key)
  key        = each.value.key
  read_only  = each.value.read_only
}
