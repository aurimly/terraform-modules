terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 12.0.0"
    }
  }
}

resource "akamai_clientlist_list" "list" {
  for_each = var.client_lists

  name        = each.value.name
  type        = each.value.type
  contract_id = each.value.contract_id
  group_id    = each.value.group_id
  notes       = each.value.notes
  tags        = each.value.tags

  dynamic "items" {
    for_each = each.value.items

    content {
      value           = items.value.value
      key             = items.value.key
      values          = items.value.values
      description     = items.value.description
      tags            = items.value.tags
      expiration_date = items.value.expiration_date
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "akamai_clientlist_activation" "activation" {
  for_each = { for k, v in var.client_lists : k => v if v.activation != null }

  list_id                 = akamai_clientlist_list.list[each.key].list_id
  version                 = akamai_clientlist_list.list[each.key].version
  network                 = each.value.activation.network
  comments                = each.value.activation.comments
  notification_recipients = each.value.activation.notification_recipients
}
