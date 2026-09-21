terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = ">= 5.0.0"
    }
  }
}

resource "equinix_fabric_cloud_router" "cloud_router" {
  for_each = var.cloud_routers

  name        = each.value.name
  type        = each.value.type
  description = each.value.description

  location {
    metro_code = each.value.location.metro_code
    ibx        = each.value.location.ibx
    metro_name = each.value.location.metro_name
    region     = each.value.location.region
  }

  package {
    code = each.value.package.code
  }

  project {
    project_id = each.value.project.project_id
    href       = each.value.project.href
  }

  dynamic "notifications" {
    for_each = each.value.notifications

    content {
      type          = notifications.value.type
      emails        = notifications.value.emails
      send_interval = notifications.value.send_interval
    }
  }

  dynamic "account" {
    for_each = each.value.account != null ? [each.value.account] : []

    content {
      account_number = account.value.account_number
    }
  }

  dynamic "order" {
    for_each = each.value.order != null ? [each.value.order] : []

    content {
      purchase_order_number = order.value.purchase_order_number
      order_number          = order.value.order_number
      order_id              = order.value.order_id
      billing_tier          = order.value.billing_tier
      term_length           = order.value.term_length
    }
  }

  dynamic "marketplace_subscription" {
    for_each = each.value.marketplace_subscription != null ? [each.value.marketplace_subscription] : []

    content {
      uuid = marketplace_subscription.value.uuid
      type = marketplace_subscription.value.type
    }
  }
}
