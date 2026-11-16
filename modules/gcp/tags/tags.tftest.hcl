mock_provider "google" {}

run "keys_and_values" {
  command = plan

  variables {
    tag_keys = {
      "env" = {
        parent     = "organizations/123456789012"
        short_name = "environment"
      }
      "network" = {
        parent       = "organizations/123456789012"
        short_name   = "network"
        purpose      = "GCE_FIREWALL"
        purpose_data = { network = "example-prj/example-vpc" }
      }
      "cost" = {
        parent     = "projects/example-prj"
        short_name = "cost-center"
      }
    }

    tag_values = {
      "prod" = {
        key        = "env"
        short_name = "production"
      }
      "staging" = {
        key        = "env"
        short_name = "staging"
      }
    }
  }
}

run "bad_short_name_fails" {
  command = plan

  variables {
    tag_keys = {
      "broken" = {
        parent     = "organizations/123456789012"
        short_name = "has/slash"
      }
    }
    tag_values = {}
  }

  expect_failures = [var.tag_keys]
}

run "purpose_data_without_purpose_fails" {
  command = plan

  variables {
    tag_keys = {
      "broken" = {
        parent       = "organizations/123456789012"
        short_name   = "network"
        purpose_data = { network = "example-prj/example-vpc" }
      }
    }
    tag_values = {}
  }

  expect_failures = [var.tag_keys]
}

run "duplicate_short_name_same_parent_fails" {
  command = plan

  variables {
    tag_keys = {
      "first" = {
        parent     = "organizations/123456789012"
        short_name = "environment"
      }
      "second" = {
        parent     = "organizations/123456789012"
        short_name = "environment"
      }
    }
    tag_values = {}
  }

  expect_failures = [var.tag_keys]
}

run "dangling_value_key_fails" {
  command = plan

  variables {
    tag_keys = {
      "env" = {
        parent     = "organizations/123456789012"
        short_name = "environment"
      }
    }
    tag_values = {
      "orphan" = {
        key        = "missing"
        short_name = "production"
      }
    }
  }

  expect_failures = [var.tag_values]
}
