resource "google_cloudbuild_trigger" "trigger" {
  for_each = var.triggers

  name               = each.value.name
  description        = each.value.description
  location           = each.value.location
  project            = each.value.project_id
  service_account    = each.value.service_account
  filename           = each.value.filename
  filter             = each.value.filter
  disabled           = each.value.disabled
  include_build_logs = each.value.include_build_logs
  deletion_policy    = each.value.deletion_policy
  included_files     = each.value.included_files
  ignored_files      = each.value.ignored_files
  substitutions      = each.value.substitutions
  tags               = each.value.tags

  dynamic "build" {
    for_each = each.value.build != null ? [each.value.build] : []

    content {
      images        = build.value.images
      logs_bucket   = build.value.logs_bucket
      queue_ttl     = build.value.queue_ttl
      substitutions = build.value.substitutions
      tags          = build.value.tags
      timeout       = build.value.timeout

      dynamic "source" {
        for_each = build.value.source != null ? [build.value.source] : []

        content {
          dynamic "repo_source" {
            for_each = source.value.repo_source != null ? [source.value.repo_source] : []

            content {
              project_id    = repo_source.value.project_id
              repo_name     = repo_source.value.repo_name
              branch_name   = repo_source.value.branch_name
              tag_name      = repo_source.value.tag_name
              commit_sha    = repo_source.value.commit_sha
              dir           = repo_source.value.dir
              invert_regex  = repo_source.value.invert_regex
              substitutions = repo_source.value.substitutions
            }
          }

          dynamic "storage_source" {
            for_each = source.value.storage_source != null ? [source.value.storage_source] : []

            content {
              bucket     = storage_source.value.bucket
              object     = storage_source.value.object
              generation = storage_source.value.generation
            }
          }
        }
      }

      dynamic "step" {
        for_each = build.value.steps

        content {
          name             = step.value.name
          args             = step.value.args
          id               = step.value.id
          dir              = step.value.dir
          entrypoint       = step.value.entrypoint
          env              = step.value.env
          timeout          = step.value.timeout
          timing           = step.value.timing
          script           = step.value.script
          allow_failure    = step.value.allow_failure
          allow_exit_codes = step.value.allow_exit_codes
          secret_env       = step.value.secret_env
          wait_for         = step.value.wait_for

          dynamic "volumes" {
            for_each = step.value.volumes

            content {
              name = volumes.value.name
              path = volumes.value.path
            }
          }
        }
      }

      dynamic "options" {
        for_each = build.value.options != null ? [build.value.options] : []

        content {
          disk_size_gb            = options.value.disk_size_gb
          dynamic_substitutions   = options.value.dynamic_substitutions
          env                     = options.value.env
          log_streaming_option    = options.value.log_streaming_option
          logging                 = options.value.logging
          machine_type            = options.value.machine_type
          requested_verify_option = options.value.requested_verify_option
          secret_env              = options.value.secret_env
          source_provenance_hash  = options.value.source_provenance_hash
          substitution_option     = options.value.substitution_option
          worker_pool             = options.value.worker_pool

          dynamic "volumes" {
            for_each = options.value.volumes

            content {
              name = volumes.value.name
              path = volumes.value.path
            }
          }
        }
      }

      dynamic "available_secrets" {
        for_each = build.value.available_secrets != null ? [build.value.available_secrets] : []

        content {
          dynamic "secret_manager" {
            for_each = build.value.available_secrets.secret_manager

            content {
              env          = secret_manager.key
              version_name = secret_manager.value
            }
          }
        }
      }

      dynamic "artifacts" {
        for_each = build.value.artifacts != null ? [build.value.artifacts] : []

        content {
          images = artifacts.value.images

          dynamic "objects" {
            for_each = artifacts.value.objects != null ? [artifacts.value.objects] : []

            content {
              location = objects.value.location
              paths    = objects.value.paths
            }
          }

          dynamic "maven_artifacts" {
            for_each = artifacts.value.maven_artifacts

            content {
              repository  = maven_artifacts.value.repository
              path        = maven_artifacts.value.path
              artifact_id = maven_artifacts.value.artifact_id
              group_id    = maven_artifacts.value.group_id
              version     = maven_artifacts.value.version
            }
          }

          dynamic "python_packages" {
            for_each = artifacts.value.python_packages

            content {
              repository = python_packages.value.repository
              paths      = python_packages.value.paths
            }
          }

          dynamic "npm_packages" {
            for_each = artifacts.value.npm_packages

            content {
              repository   = npm_packages.value.repository
              package_path = npm_packages.value.package_path
            }
          }
        }
      }
    }
  }

  dynamic "trigger_template" {
    for_each = each.value.trigger_template != null ? [each.value.trigger_template] : []

    content {
      branch_name  = trigger_template.value.branch_name
      tag_name     = trigger_template.value.tag_name
      commit_sha   = trigger_template.value.commit_sha
      repo_name    = trigger_template.value.repo_name
      project_id   = trigger_template.value.project_id
      dir          = trigger_template.value.dir
      invert_regex = trigger_template.value.invert_regex
    }
  }

  dynamic "github" {
    for_each = each.value.github != null ? [each.value.github] : []

    content {
      owner                           = github.value.owner
      name                            = github.value.name
      enterprise_config_resource_name = github.value.enterprise_config_resource_name

      dynamic "push" {
        for_each = github.value.push != null ? [github.value.push] : []

        content {
          branch       = push.value.branch
          tag          = push.value.tag
          invert_regex = push.value.invert_regex
        }
      }

      dynamic "pull_request" {
        for_each = github.value.pull_request != null ? [github.value.pull_request] : []

        content {
          branch          = pull_request.value.branch
          comment_control = pull_request.value.comment_control
          invert_regex    = pull_request.value.invert_regex
        }
      }
    }
  }

  dynamic "repository_event_config" {
    for_each = each.value.repository_event_config != null ? [each.value.repository_event_config] : []

    content {
      repository = repository_event_config.value.repository

      dynamic "push" {
        for_each = repository_event_config.value.push != null ? [repository_event_config.value.push] : []

        content {
          branch       = push.value.branch
          tag          = push.value.tag
          invert_regex = push.value.invert_regex
        }
      }

      dynamic "pull_request" {
        for_each = repository_event_config.value.pull_request != null ? [repository_event_config.value.pull_request] : []

        content {
          branch          = pull_request.value.branch
          comment_control = pull_request.value.comment_control
          invert_regex    = pull_request.value.invert_regex
        }
      }
    }
  }

  dynamic "pubsub_config" {
    for_each = each.value.pubsub_config != null ? [each.value.pubsub_config] : []

    content {
      topic                 = pubsub_config.value.topic
      service_account_email = pubsub_config.value.service_account_email
    }
  }

  dynamic "webhook_config" {
    for_each = each.value.webhook_config != null ? [each.value.webhook_config] : []

    content {
      secret = webhook_config.value.secret
    }
  }

  dynamic "approval_config" {
    for_each = each.value.approval_config != null ? [each.value.approval_config] : []

    content {
      approval_required = approval_config.value.approval_required
    }
  }

  dynamic "source_to_build" {
    for_each = each.value.source_to_build != null ? [each.value.source_to_build] : []

    content {
      uri                      = source_to_build.value.uri
      repository               = source_to_build.value.repository
      ref                      = source_to_build.value.ref
      repo_type                = source_to_build.value.repo_type
      github_enterprise_config = source_to_build.value.github_enterprise_config
    }
  }

  dynamic "git_file_source" {
    for_each = each.value.git_file_source != null ? [each.value.git_file_source] : []

    content {
      path                     = git_file_source.value.path
      uri                      = git_file_source.value.uri
      repository               = git_file_source.value.repository
      revision                 = git_file_source.value.revision
      repo_type                = git_file_source.value.repo_type
      github_enterprise_config = git_file_source.value.github_enterprise_config
    }
  }
}
