mock_provider "cloudflare" {
  mock_resource "cloudflare_waiting_room" {
    defaults = {
      id = "a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d"
    }
  }
  mock_resource "cloudflare_waiting_room_event" {
    defaults = {
      id = "b2c3d4e5-6f7a-8b9c-0d1e-2f3a4b5c6d7e"
    }
  }
}

run "wiring" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    waiting_rooms = {
      "shop" = {
        host                 = "shop.example.com"
        name                 = "launch"
        new_users_per_minute = 200
        total_active_users   = 200
        path                 = "/checkout"
        cookie_suffix        = "shop"
        cookie_attributes = {
          samesite = "auto"
          secure   = "auto"
        }
      }
    }

    events = {
      "release" = {
        room_key             = "shop"
        name                 = "black-friday"
        event_start_time     = "2026-11-27T00:00:00Z"
        event_end_time       = "2026-11-27T23:59:59Z"
        prequeue_start_time  = "2026-11-26T22:00:00Z"
        total_active_users   = 500
        new_users_per_minute = 250
      }
    }
  }

  assert {
    condition     = output.waiting_room_ids["shop"] == "a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d"
    error_message = "waiting room ID keyed by map key"
  }

  assert {
    condition     = output.event_ids["shop.release"] == "b2c3d4e5-6f7a-8b9c-0d1e-2f3a4b5c6d7e"
    error_message = "event ID keyed by composed room.event address"
  }
}

run "dangling_room_key_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    waiting_rooms = {
      "shop" = {
        host                 = "shop.example.com"
        name                 = "launch"
        new_users_per_minute = 200
        total_active_users   = 200
      }
    }

    events = {
      "orphan" = {
        room_key         = "missing"
        name             = "black-friday"
        event_start_time = "2026-11-27T00:00:00Z"
        event_end_time   = "2026-11-27T23:59:59Z"
      }
    }
  }

  expect_failures = [var.events]
}

run "override_pair_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    waiting_rooms = {
      "shop" = {
        host                 = "shop.example.com"
        name                 = "launch"
        new_users_per_minute = 200
        total_active_users   = 200
      }
    }

    events = {
      "release" = {
        room_key           = "shop"
        name               = "black-friday"
        event_start_time   = "2026-11-27T00:00:00Z"
        event_end_time     = "2026-11-27T23:59:59Z"
        total_active_users = 500
      }
    }
  }

  expect_failures = [var.events]
}

run "bad_queueing_method_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    events = {}

    waiting_rooms = {
      "shop" = {
        host                 = "shop.example.com"
        name                 = "launch"
        new_users_per_minute = 200
        total_active_users   = 200
        queueing_method      = "sorted"
      }
    }
  }

  expect_failures = [var.waiting_rooms]
}

run "host_path_conflict_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    events = {}

    waiting_rooms = {
      "first" = {
        host                 = "shop.example.com"
        name                 = "launch"
        new_users_per_minute = 200
        total_active_users   = 200
        path                 = "/checkout"
      }
      "second" = {
        host                 = "SHOP.example.com"
        name                 = "sale"
        new_users_per_minute = 200
        total_active_users   = 200
        path                 = "/checkout"
      }
    }
  }

  expect_failures = [var.waiting_rooms]
}

run "routes_without_suffix_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    events = {}

    waiting_rooms = {
      "shop" = {
        host                 = "shop.example.com"
        name                 = "launch"
        new_users_per_minute = 200
        total_active_users   = 200
        additional_routes = [
          {
            host = "shop2.example.com"
            path = "/checkout"
          }
        ]
      }
    }
  }

  expect_failures = [var.waiting_rooms]
}

run "shuffle_without_prequeue_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    waiting_rooms = {
      "shop" = {
        host                 = "shop.example.com"
        name                 = "launch"
        new_users_per_minute = 200
        total_active_users   = 200
      }
    }

    events = {
      "release" = {
        room_key               = "shop"
        name                   = "black-friday"
        event_start_time       = "2026-11-27T00:00:00Z"
        event_end_time         = "2026-11-27T23:59:59Z"
        shuffle_at_event_start = true
      }
    }
  }

  expect_failures = [var.events]
}
