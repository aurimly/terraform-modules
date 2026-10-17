terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_repository_webhook" "repository_webhook" {
  for_each = var.repository_webhooks

  repository = each.value.repository
  active     = each.value.active
  events     = each.value.events

  dynamic "configuration" {
    for_each = [each.value.configuration]

    content {
      url          = configuration.value.url
      content_type = configuration.value.content_type
      secret       = configuration.value.secret
      insecure_ssl = configuration.value.insecure_ssl
    }
  }
}

resource "github_organization_webhook" "organization_webhook" {
  for_each = var.organization_webhooks

  active = each.value.active
  events = each.value.events

  dynamic "configuration" {
    for_each = [each.value.configuration]

    content {
      url          = configuration.value.url
      content_type = configuration.value.content_type
      secret       = configuration.value.secret
      insecure_ssl = configuration.value.insecure_ssl
    }
  }
}
