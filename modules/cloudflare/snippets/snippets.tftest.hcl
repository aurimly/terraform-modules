mock_provider "cloudflare" {
  mock_resource "cloudflare_snippet" {
    defaults = {
      id = "0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
    }
  }
  mock_resource "cloudflare_snippet_rules" {
    defaults = {
      id = "023e105f4ecef8ad9ca31a8372d0c353"
    }
  }
}

run "wiring" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    snippets = {
      "hello" = {
        snippet_name = "hello-world"
        files = [
          {
            name    = "index.js"
            content = "export default { async fetch() { return new Response('Hello world'); } }"
          }
        ]
      }
    }

    rules = [
      {
        expression   = "http.request.uri.path eq \"/greet\""
        snippet_name = "hello-world"
        enabled      = true
      },
      {
        expression   = "http.request.uri.path eq \"/goodbye\""
        snippet_name = "hello-world"
      }
    ]
  }

  assert {
    condition     = output.snippet_ids["hello"] == "0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
    error_message = "snippet ID keyed by map key"
  }

  assert {
    condition     = length(output.rule_ids) == 2
    error_message = "rule IDs exported in evaluation order"
  }
}

run "dangling_rule_snippet_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    snippets = {
      "hello" = {
        snippet_name = "hello-world"
        files = [
          {
            name    = "index.js"
            content = "export default { async fetch() { return new Response('Hello world'); } }"
          }
        ]
      }
    }

    rules = [
      {
        expression   = "http.request.uri.path eq \"/greet\""
        snippet_name = "unmanaged-snippet"
      }
    ]
  }

  expect_failures = [var.rules]
}

run "bad_snippet_name_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    rules = []

    snippets = {
      "broken" = {
        snippet_name = "hello world!"
        files = [
          {
            name    = "index.js"
            content = "export default { async fetch() { return new Response('Hello world'); } }"
          }
        ]
      }
    }
  }

  expect_failures = [var.snippets]
}

run "empty_files_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    rules = []

    snippets = {
      "broken" = {
        snippet_name = "hello-world"
        files        = []
      }
    }
  }

  expect_failures = [var.snippets]
}

run "main_module_mismatch_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    rules = []

    snippets = {
      "broken" = {
        snippet_name = "hello-world"
        main_module  = "missing.js"
        files = [
          {
            name    = "index.js"
            content = "export default { async fetch() { return new Response('Hello world'); } }"
          }
        ]
      }
    }
  }

  expect_failures = [var.snippets]
}

run "no_rules_omits_rules_resource" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    snippets = {
      "hello" = {
        snippet_name = "hello-world"
        files = [
          {
            name    = "index.js"
            content = "export default { async fetch() { return new Response('Hello world'); } }"
          }
        ]
      }
    }

    rules = []
  }

  assert {
    condition     = length(output.rule_ids) == 0
    error_message = "rule_ids empty when no rules configured"
  }
}
