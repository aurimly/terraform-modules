mock_provider "cloudflare" {
  mock_resource "cloudflare_queue" {
    defaults = {
      id       = "023e105f-4eef-8ad9-ca31-a8372d0c3530"
      queue_id = "023e105f-4eef-8ad9-ca31-a8372d0c3530"
    }
  }
  mock_resource "cloudflare_queue_consumer" {
    defaults = {
      consumer_id = "5ebe363c-0f2b-4e0d-8f8c-3a3b0a1b2c3d"
    }
  }
}

run "wiring" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    queues = {
      "orders" = {
        queue_name = "orders-queue"
        settings = {
          delivery_delay = 5
        }
      }
      "orders-dlq" = {
        queue_name = "orders-dlq"
      }
    }

    consumers = {
      "orders-worker" = {
        queue_key         = "orders"
        type              = "worker"
        script_name       = "order-processor"
        dead_letter_queue = "orders-dlq"
        settings = {
          batch_size       = 50
          max_retries      = 3
          max_wait_time_ms = 5000
        }
      }
    }
  }

  assert {
    condition     = output.queue_names["orders"] == "orders-queue"
    error_message = "queue name keyed by map key"
  }

  assert {
    condition     = output.consumer_ids["orders.orders-worker"] == "5ebe363c-0f2b-4e0d-8f8c-3a3b0a1b2c3d"
    error_message = "consumer ID keyed by composed queue.consumer address"
  }
}

run "worker_without_script_fails" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    queues = {
      "orders" = {
        queue_name = "orders-queue"
      }
    }

    consumers = {
      "broken" = {
        queue_key = "orders"
        type      = "worker"
      }
    }
  }

  expect_failures = [var.consumers]
}

run "dangling_queue_key_fails" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    queues = {
      "orders" = {
        queue_name = "orders-queue"
      }
    }

    consumers = {
      "orphan" = {
        queue_key = "missing"
        type      = "http_pull"
      }
    }
  }

  expect_failures = [var.consumers]
}

run "missing_account_fails" {
  command = plan

  variables {
    consumers = {}

    queues = {
      "orders" = {
        queue_name = "orders-queue"
      }
    }
  }

  expect_failures = [resource.cloudflare_queue.queue["orders"]]
}
