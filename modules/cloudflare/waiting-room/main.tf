terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

locals {
  events = {
    for event_key, event in var.events : "${event.room_key}.${event_key}" => {
      room_key = event.room_key
      event    = event
    }
  }
}

resource "cloudflare_waiting_room" "waiting_room" {
  for_each = var.waiting_rooms

  zone_id              = var.zone_id
  host                 = each.value.host
  name                 = each.value.name
  new_users_per_minute = each.value.new_users_per_minute
  total_active_users   = each.value.total_active_users

  path                      = each.value.path
  description               = each.value.description
  queue_all                 = each.value.queue_all
  queueing_method           = each.value.queueing_method
  queueing_status_code      = each.value.queueing_status_code
  session_duration          = each.value.session_duration
  suspended                 = each.value.suspended
  disable_session_renewal   = each.value.disable_session_renewal
  custom_page_html          = each.value.custom_page_html
  default_template_language = each.value.default_template_language
  cookie_suffix             = each.value.cookie_suffix
  json_response_enabled     = each.value.json_response_enabled
  turnstile_mode            = each.value.turnstile_mode
  turnstile_action          = each.value.turnstile_action
  enabled_origin_commands   = each.value.enabled_origin_commands

  cookie_attributes = each.value.cookie_attributes == null ? null : {
    samesite = each.value.cookie_attributes.samesite
    secure   = each.value.cookie_attributes.secure
  }

  additional_routes = each.value.additional_routes == null ? null : [
    for route in each.value.additional_routes : {
      host = route.host
      path = route.path
    }
  ]
}

resource "cloudflare_waiting_room_event" "event" {
  for_each = local.events

  zone_id         = var.zone_id
  waiting_room_id = cloudflare_waiting_room.waiting_room[each.value.room_key].id

  name             = each.value.event.name
  event_start_time = each.value.event.event_start_time
  event_end_time   = each.value.event.event_end_time

  prequeue_start_time     = each.value.event.prequeue_start_time
  description             = each.value.event.description
  new_users_per_minute    = each.value.event.new_users_per_minute
  total_active_users      = each.value.event.total_active_users
  queueing_method         = each.value.event.queueing_method
  session_duration        = each.value.event.session_duration
  suspended               = each.value.event.suspended
  disable_session_renewal = each.value.event.disable_session_renewal
  custom_page_html        = each.value.event.custom_page_html
  shuffle_at_event_start  = each.value.event.shuffle_at_event_start
  turnstile_mode          = each.value.event.turnstile_mode
  turnstile_action        = each.value.event.turnstile_action
}
