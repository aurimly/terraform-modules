mock_provider "cloudflare" {
  mock_resource "cloudflare_email_routing_rule" {
    defaults = {
      id = "a7e6fb77-503c-41d8-a7f3-113c6918f10c"
    }
  }
  mock_resource "cloudflare_email_routing_catch_all" {
    defaults = {
      id = "b8f7fc88-614d-52e9-b804-224d8029a21d"
    }
  }
}

run "wiring" {
  command = plan

  variables {
    rules = {
      "support" = {
        zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
        matchers = [
          {
            type  = "literal"
            field = "to"
            value = "support@example.com"
          }
        ]
        actions = [
          {
            type  = "forward"
            value = ["helpdesk@example.net"]
          }
        ]
        enabled = true
        name    = "support inbox"
      }
    }

    catch_all_rules = {
      "example-com" = {
        zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
        actions = [
          {
            type  = "worker"
            value = ["mail-worker"]
          }
        ]
        enabled = true
      }
    }
  }

  assert {
    condition     = output.rule_ids["support"] == "a7e6fb77-503c-41d8-a7f3-113c6918f10c"
    error_message = "rule ID keyed by map key"
  }

  assert {
    condition     = output.catch_all_rule_ids["example-com"] == "b8f7fc88-614d-52e9-b804-224d8029a21d"
    error_message = "catch-all ID keyed by map key"
  }
}

run "forward_without_value_fails" {
  command = plan

  variables {
    catch_all_rules = {}

    rules = {
      "broken" = {
        zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
        matchers = [
          {
            type = "all"
          }
        ]
        actions = [
          {
            type = "forward"
          }
        ]
      }
    }
  }

  expect_failures = [var.rules]
}

run "duplicate_catch_all_zone_fails" {
  command = plan

  variables {
    rules = {}

    catch_all_rules = {
      "one" = {
        zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
        actions = [{ type = "drop" }]
      }
      "two" = {
        zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
        actions = [{ type = "drop" }]
      }
    }
  }

  expect_failures = [var.catch_all_rules]
}

run "wrangler_without_tag_fails" {
  command = plan

  variables {
    catch_all_rules = {}

    rules = {
      "owned" = {
        zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
        matchers = [
          {
            type = "all"
          }
        ]
        actions = [{ type = "drop" }]
        source  = "wrangler"
      }
    }
  }

  expect_failures = [var.rules]
}
