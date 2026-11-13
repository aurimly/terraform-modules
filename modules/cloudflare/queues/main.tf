terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

locals {
  consumers = {
    for consumer_key, consumer in var.consumers : "${consumer.queue_key}.${consumer_key}" => {
      queue_key = consumer.queue_key
      consumer  = consumer
    }
  }
}

resource "cloudflare_queue" "queue" {
  for_each = var.queues

  account_id   = coalesce(each.value.account_id, var.account_id)
  queue_name   = each.value.queue_name
  jurisdiction = each.value.jurisdiction
  settings     = each.value.settings

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "queue \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }
  }
}

resource "cloudflare_queue_consumer" "consumer" {
  for_each = local.consumers

  account_id = coalesce(var.queues[each.value.queue_key].account_id, var.account_id)
  queue_id   = cloudflare_queue.queue[each.value.queue_key].id

  type              = each.value.consumer.type
  script_name       = each.value.consumer.script_name
  dead_letter_queue = each.value.consumer.dead_letter_queue

  settings = each.value.consumer.settings == null ? null : {
    batch_size            = each.value.consumer.settings.batch_size
    max_concurrency       = each.value.consumer.settings.max_concurrency
    max_retries           = each.value.consumer.settings.max_retries
    max_wait_time_ms      = each.value.consumer.settings.max_wait_time_ms
    retry_delay           = each.value.consumer.settings.retry_delay
    visibility_timeout_ms = each.value.consumer.settings.visibility_timeout_ms
    email                 = [for address in each.value.consumer.settings.email_destinations : { id = address }]
    pagerduty             = [for id in each.value.consumer.settings.pagerduty_destinations : { id = id }]
    webhooks              = [for id in each.value.consumer.settings.webhook_destinations : { id = id }]
  }
}
