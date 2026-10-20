mock_provider "cloudflare" {
  mock_resource "cloudflare_pages_project" {
    defaults = {
      subdomain = "example-docs.pages.dev"
      domains   = ["docs.example.com"]
    }
  }
}

run "project_with_git_source_and_bindings" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    projects = {
      "docs" = {
        name              = "example-docs"
        production_branch = "main"
        build_config = {
          build_command   = "npm run build"
          destination_dir = "dist"
          build_caching   = true
        }
        source = {
          type = "github"
          config = {
            owner                          = "example-org"
            repo_name                      = "example-docs"
            production_branch              = "main"
            pr_comments_enabled            = true
            preview_deployment_setting     = "custom"
            preview_branch_includes        = ["next"]
            path_includes                  = ["docs/"]
            production_deployments_enabled = true
          }
        }
        deployment_configs = {
          preview = {
            compatibility_date  = "2025-01-01"
            compatibility_flags = ["nodejs_compat"]
            env_vars = {
              "API_URL" = { type = "plain_text", value = "https://api.example.com" }
              "SECRET"  = { type = "secret_text", value = "hunter2" }
            }
            build_image_major_version = 3
            limits                    = { cpu_ms = 50 }
            placement                 = { mode = "smart" }
            kv_namespaces             = { "SESSIONS" = { namespace_id = "5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d" } }
            r2_buckets                = { "ASSETS" = { name = "example-assets", jurisdiction = "eu" } }
            d1_databases              = { "DB" = { id = "d1-id" } }
            durable_object_namespaces = { "DO" = { namespace_id = "do-id" } }
            hyperdrive_bindings       = { "HG" = { id = "hg-id" } }
            queue_producers           = { "QUEUE" = { name = "example-queue" } }
            services                  = { "SRV" = { service = "example-worker", entrypoint = "fetch", environment = "production" } }
            mtls_certificates         = { "MTLS" = { certificate_id = "mtls-id" } }
            analytics_engine_datasets = { "AE" = { dataset = "example" } }
            vectorize_bindings        = { "VEC" = { index_name = "example-index" } }
            ai_bindings               = { "AI" = { project_id = "example-prj" } }
            browsers                  = { "BROWSER" = {} }
          }
          production = {
            compatibility_date                   = "2025-01-01"
            compatibility_flags                  = ["nodejs_compat"]
            always_use_latest_compatibility_date = false
            fail_open                            = true
            env_vars = {
              "API_URL" = { type = "plain_text", value = "https://api.example.com" }
            }
          }
        }
        domains = ["docs.example.com"]
      }
      "app" = {
        name              = "example-app"
        production_branch = "main"
        domains           = ["app.example.com", "www.example.com"]
      }
    }
  }

  assert {
    condition     = output.project_names["docs"] == "example-docs"
    error_message = "project name keyed by map key"
  }

  assert {
    condition     = output.project_subdomains["docs"] == "example-docs.pages.dev"
    error_message = "pages.dev subdomain output"
  }

  assert {
    condition     = length(cloudflare_pages_domain.domain) == 3
    error_message = "three custom domain resources created"
  }
}

run "rejects_duplicate_domains" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    projects = {
      "a" = {
        name              = "example-a"
        production_branch = "main"
        domains           = ["shared.example.com"]
      }
      "b" = {
        name              = "example-b"
        production_branch = "main"
        domains           = ["shared.example.com"]
      }
    }
  }

  expect_failures = [var.projects]
}

run "rejects_branch_includes_without_custom" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    projects = {
      "a" = {
        name              = "example-a"
        production_branch = "main"
        source = {
          type = "github"
          config = {
            owner                   = "example-org"
            repo_name               = "example"
            preview_branch_includes = ["next"]
          }
        }
      }
    }
  }

  expect_failures = [var.projects]
}

run "rejects_bad_source_type" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    projects = {
      "a" = {
        name              = "example-a"
        production_branch = "main"
        source = {
          type   = "bitbucket"
          config = { owner = "example-org", repo_name = "example" }
        }
      }
    }
  }

  expect_failures = [var.projects]
}

run "rejects_bad_env_var_type" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    projects = {
      "a" = {
        name              = "example-a"
        production_branch = "main"
        deployment_configs = {
          production = {
            env_vars = {
              "A" = { type = "encrypted", value = "x" }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.projects]
}

run "rejects_bad_preview_deployment_setting" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    projects = {
      "a" = {
        name              = "example-a"
        production_branch = "main"
        source = {
          type = "github"
          config = {
            owner                      = "example-org"
            repo_name                  = "example"
            preview_deployment_setting = "sometimes"
          }
        }
      }
    }
  }

  expect_failures = [var.projects]
}

run "side_without_env_vars" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    projects = {
      "a" = {
        name              = "example-a"
        production_branch = "main"
        deployment_configs = {
          production = {
            compatibility_date = "2025-01-01"
            kv_namespaces = {
              "SESSIONS" = { namespace_id = "5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d" }
            }
          }
          preview = {
            compatibility_date = "2025-01-01"
          }
        }
      }
    }
  }
}
