terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_membership" "membership" {
  for_each = var.members

  username             = each.value.username
  role                 = each.value.role
  downgrade_on_destroy = each.value.downgrade_on_destroy
}
