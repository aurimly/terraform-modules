mock_provider "google" {}

run "happy_path" {
  command = plan

  variables {
    triggers = {
      "github-filename" = {
        name            = "example-github-filename"
        description     = "example push trigger"
        service_account = "projects/example-prj/serviceAccounts/example-builder@example-prj.iam.gserviceaccount.com"
        included_files  = ["src/**"]
        ignored_files   = ["docs/**"]
        tags            = ["team-example"]
        filename        = "cloudbuild.yaml"
        github = {
          owner = "example-org"
          name  = "example-repo"
          push = {
            branch = "^main$"
          }
        }
      }
      "inline-build" = {
        name     = "example-inline-build"
        location = "us-central1"
        trigger_template = {
          branch_name = "main"
          repo_name   = "example-repo"
          dir         = "apps/example"
        }
        build = {
          steps = [
            { name = "gcr.io/cloud-builders/gcloud", args = ["storage", "cp", "gs://example-bucket/remote.zip", "local.zip"] },
            { name = "example-registry.test.local/apps/builder", script = "make build", allow_failure = true, wait_for = ["-"] }
          ]
          source = {
            storage_source = {
              bucket = "example-bucket"
              object = "source_code.tar.gz"
            }
          }
          substitutions = { _FOO = "bar" }
          tags          = ["build"]
          images        = ["example-registry.test.local/example-app:$COMMIT_SHA"]
          logs_bucket   = "gs://example-bucket/logs"
          queue_ttl     = "20s"
          timeout       = "600s"
          available_secrets = {
            secret_manager = {
              EXAMPLE_SECRET = "projects/example-prj/secrets/example-secret/versions/latest"
            }
          }
          artifacts = {
            images = ["example-registry.test.local/example-app:$COMMIT_SHA"]
            objects = {
              location = "gs://example-bucket/artifacts/"
              paths    = ["dist/*"]
            }
          }
          options = {
            machine_type            = "E2_HIGHCPU_8"
            disk_size_gb            = 100
            substitution_option     = "ALLOW_LOOSE"
            dynamic_substitutions   = true
            logging                 = "CLOUD_LOGGING_ONLY"
            log_streaming_option    = "STREAM_OFF"
            requested_verify_option = "VERIFIED"
            source_provenance_hash  = ["MD5"]
            env                     = ["EXAMPLE_ENV=value"]
            volumes                 = [{ name = "cache", path = "/cache" }]
          }
        }
      }
      "pubsub" = {
        name     = "example-pubsub-trigger"
        location = "us-central1"
        pubsub_config = {
          topic = "projects/example-prj/topics/example-events"
        }
        filter = "_ACTION.matches('INSERT')"
        git_file_source = {
          path      = "cloudbuild.yaml"
          revision  = "refs/heads/main"
          repo_type = "GITHUB"
          uri       = "https://git.example.org/example-org/example-repo"
        }
        source_to_build = {
          uri       = "https://git.example.org/example-org/example-repo"
          ref       = "refs/heads/main"
          repo_type = "GITHUB"
        }
        substitutions = { _ACTION = "$(body.message.data.action)" }
      }
      "manual-approved" = {
        name        = "example-manual-approved"
        description = "manual trigger with approval"
        approval_config = {
          approval_required = true
        }
        build = {
          steps = [
            { name = "ubuntu", script = "echo hello" }
          ]
        }
      }
    }
  }
}

run "rejects_two_event_sources" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name = "example-bad"
        github = {
          owner = "example-org"
          name  = "example-repo"
          push = {
            branch = "^main$"
          }
        }
        pubsub_config = {
          topic = "projects/example-prj/topics/example-events"
        }
        filename = "cloudbuild.yaml"
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_filename_with_pubsub" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name = "example-bad"
        pubsub_config = {
          topic = "projects/example-prj/topics/example-events"
        }
        filename = "cloudbuild.yaml"
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_filter_without_pubsub" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name     = "example-bad"
        filter   = "_ACTION.matches('INSERT')"
        filename = "cloudbuild.yaml"
        trigger_template = {
          branch_name = "main"
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_two_tag_refs" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name     = "example-bad"
        filename = "cloudbuild.yaml"
        trigger_template = {
          branch_name = "main"
          tag_name    = "v1"
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_ref_without_refs" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name = "example-bad"
        source_to_build = {
          uri       = "https://git.example.org/example-org/example-repo"
          ref       = "main"
          repo_type = "GITHUB"
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_bad_include_build_logs" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name               = "example-bad"
        include_build_logs = "INLINED"
        filename           = "cloudbuild.yaml"
        github = {
          owner = "example-org"
          name  = "example-repo"
          pull_request = {
            branch = "^main$"
          }
        }
      }
    }
  }

  expect_failures = [var.triggers]
}

run "rejects_github_push_two_refs" {
  command = plan

  variables {
    triggers = {
      "bad" = {
        name     = "example-bad"
        filename = "cloudbuild.yaml"
        github = {
          owner = "example-org"
          name  = "example-repo"
          push = {
            branch = "^main$"
            tag    = "v1"
          }
        }
      }
    }
  }

  expect_failures = [var.triggers]
}
