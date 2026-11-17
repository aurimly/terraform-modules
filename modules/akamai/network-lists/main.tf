terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 12.0.0"
    }
  }
}

resource "akamai_networklist_network_list" "list" {
  for_each = var.network_lists

  name        = each.value.name
  type        = each.value.type
  description = each.value.description
  mode        = each.value.mode
  list        = each.value.list
  contract_id = each.value.contract_id
  group_id    = each.value.group_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "akamai_networklist_activations" "activation" {
  for_each = { for k, v in var.network_lists : k => v if v.activation != null }

  network_list_id     = akamai_networklist_network_list.list[each.key].network_list_id
  sync_point          = akamai_networklist_network_list.list[each.key].sync_point
  network             = each.value.activation.network
  notes               = each.value.activation.notes
  notification_emails = each.value.activation.notification_emails
}
