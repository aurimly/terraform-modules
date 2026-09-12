terraform {
  required_providers {
    ns1 = {
      source  = "ns1-terraform/ns1"
      version = ">= 2.0.0"
    }
  }
}

resource "ns1_record" "record" {
  for_each = var.records

  zone                     = each.value.zone
  domain                   = each.value.domain != null ? each.value.domain : "${each.key}.${each.value.zone}"
  type                     = each.value.type
  ttl                      = each.value.ttl
  override_ttl             = each.value.override_ttl
  link                     = each.value.link
  use_client_subnet        = each.value.use_client_subnet
  meta                     = each.value.meta
  tags                     = each.value.tags
  blocked_tags             = each.value.blocked_tags
  override_address_records = each.value.override_address_records

  lifecycle {
    precondition {
      condition     = each.value.link == null || length(each.value.answers) == 0
      error_message = "record \"${each.key}\" must not set both link and answers."
    }
  }

  dynamic "filters" {
    for_each = each.value.filters

    content {
      filter   = filters.value.filter
      disabled = filters.value.disabled
      config   = filters.value.config
    }
  }

  dynamic "regions" {
    for_each = each.value.regions

    content {
      name = regions.value.name
      meta = regions.value.meta
    }
  }

  dynamic "answers" {
    for_each = each.value.answers

    content {
      answer       = answers.value.answer
      answer_parts = answers.value.answer_parts
      region       = answers.value.region
      meta         = answers.value.meta
    }
  }
}
