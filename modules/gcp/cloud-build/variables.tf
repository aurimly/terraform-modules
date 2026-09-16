variable "triggers" {
  description = "Map of Cloud Build triggers keyed by an arbitrary identifier. Each entry creates one google_cloudbuild_trigger; either an inline build or a filename template is required."
  type = map(object({
    name               = string
    location           = optional(string, "global")
    project_id         = optional(string)
    description        = optional(string)
    disabled           = optional(bool, false)
    service_account    = optional(string)
    filename           = optional(string)
    filter             = optional(string)
    include_build_logs = optional(string)
    deletion_policy    = optional(string)
    included_files     = optional(list(string))
    ignored_files      = optional(list(string))
    substitutions      = optional(map(string))
    tags               = optional(list(string))
    build = optional(object({
      images        = optional(list(string))
      logs_bucket   = optional(string)
      queue_ttl     = optional(string)
      substitutions = optional(map(string))
      tags          = optional(list(string))
      timeout       = optional(string)
      source = optional(object({
        repo_source = optional(object({
          project_id    = optional(string)
          repo_name     = string
          branch_name   = optional(string)
          tag_name      = optional(string)
          commit_sha    = optional(string)
          dir           = optional(string)
          invert_regex  = optional(bool)
          substitutions = optional(map(string))
        }))
        storage_source = optional(object({
          bucket     = string
          object     = string
          generation = optional(string)
        }))
      }))
      steps = list(object({
        name             = string
        args             = optional(list(string))
        id               = optional(string)
        dir              = optional(string)
        entrypoint       = optional(string)
        env              = optional(list(string))
        timeout          = optional(string)
        timing           = optional(string)
        script           = optional(string)
        allow_failure    = optional(bool)
        allow_exit_codes = optional(list(number))
        secret_env       = optional(list(string))
        wait_for         = optional(list(string))
        volumes = optional(list(object({
          name = string
          path = string
        })), [])
      }))
      options = optional(object({
        disk_size_gb            = optional(number)
        dynamic_substitutions   = optional(bool)
        env                     = optional(list(string))
        log_streaming_option    = optional(string)
        logging                 = optional(string)
        machine_type            = optional(string)
        requested_verify_option = optional(string)
        secret_env              = optional(list(string))
        source_provenance_hash  = optional(list(string))
        substitution_option     = optional(string)
        worker_pool             = optional(string)
        volumes = optional(list(object({
          name = string
          path = string
        })), [])
      }))
      available_secrets = optional(object({
        secret_manager = map(string)
      }))
      artifacts = optional(object({
        images = optional(list(string))
        objects = optional(object({
          location = optional(string)
          paths    = optional(list(string))
        }))
        maven_artifacts = optional(map(object({
          repository  = string
          path        = optional(string)
          artifact_id = optional(string)
          group_id    = optional(string)
          version     = optional(string)
        })), {})
        python_packages = optional(map(object({
          repository = string
          paths      = optional(list(string))
        })), {})
        npm_packages = optional(map(object({
          repository   = string
          package_path = optional(string)
        })), {})
      }))
    }))
    trigger_template = optional(object({
      branch_name  = optional(string)
      tag_name     = optional(string)
      commit_sha   = optional(string)
      repo_name    = optional(string)
      project_id   = optional(string)
      dir          = optional(string)
      invert_regex = optional(bool)
    }))
    github = optional(object({
      owner                           = optional(string)
      name                            = optional(string)
      enterprise_config_resource_name = optional(string)
      push = optional(object({
        branch       = optional(string)
        tag          = optional(string)
        invert_regex = optional(bool)
      }))
      pull_request = optional(object({
        branch          = string
        comment_control = optional(string)
        invert_regex    = optional(bool)
      }))
    }))
    repository_event_config = optional(object({
      repository = string
      push = optional(object({
        branch       = optional(string)
        tag          = optional(string)
        invert_regex = optional(bool)
      }))
      pull_request = optional(object({
        branch          = optional(string)
        comment_control = optional(string)
        invert_regex    = optional(bool)
      }))
    }))
    pubsub_config = optional(object({
      topic                 = string
      service_account_email = optional(string)
    }))
    webhook_config = optional(object({
      secret = string
    }))
    approval_config = optional(object({
      approval_required = optional(bool, true)
    }))
    source_to_build = optional(object({
      repo_type                = string
      ref                      = string
      repository               = optional(string)
      uri                      = optional(string)
      github_enterprise_config = optional(string)
    }))
    git_file_source = optional(object({
      path                     = string
      repo_type                = string
      revision                 = optional(string)
      repository               = optional(string)
      uri                      = optional(string)
      github_enterprise_config = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for t in var.triggers : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.~+]{0,99}$", t.name))])
    error_message = "name must be 1 to 100 characters, start with an alphanumeric character and contain only alphanumerics, hyphens, underscores, periods, tildes and plus signs."
  }

  validation {
    condition     = alltrue([for t in var.triggers : can(regex("^[a-z0-9-]+$", t.location))])
    error_message = "location must look like a GCP region or the value global (e.g. us-central1); it is a shape check, not a list of valid locations."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", t.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : length([
        for k in ["trigger_template", "github", "repository_event_config", "pubsub_config", "webhook_config"] : k
        if try(t[k], null) != null
      ]) <= 1
    ])
    error_message = "use at most one event source: trigger_template, github, repository_event_config, pubsub_config or webhook_config; a trigger without one is manual-only."
  }

  validation {
    condition     = alltrue([for t in var.triggers : (t.build != null && t.filename == null) || (t.build == null && t.filename != null) || (t.build == null && t.filename == null)])
    error_message = "use exactly one of build (inline build template) or filename (build defined in the repo); a manual trigger may omit both by using git_file_source."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.build == null ? true : length(t.build.steps) > 0
    ])
    error_message = "build.steps must be non-empty when an inline build is set (the API requires at least one step)."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.filename == null || anytrue([t.trigger_template != null, t.github != null])])
    error_message = "filename is only valid with trigger_template or github triggers (for pubsub, webhook and manual triggers set the file path via git_file_source)."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.filter == null || anytrue([t.pubsub_config != null, t.webhook_config != null])])
    error_message = "filter is only valid with pubsub_config or webhook_config triggers."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.trigger_template == null || length([for v in [t.trigger_template.branch_name, t.trigger_template.tag_name, t.trigger_template.commit_sha] : v if v != null]) == 1])
    error_message = "trigger_template needs exactly one of branch_name, tag_name or commit_sha."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.github == null || (t.github.push != null) != (t.github.pull_request != null)])
    error_message = "github needs exactly one of push or pull_request."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.github == null || t.github.push == null || (t.github.push.branch != null) != (t.github.push.tag != null)])
    error_message = "github.push needs exactly one of branch or tag."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.repository_event_config == null || (t.repository_event_config.push != null) != (t.repository_event_config.pull_request != null)])
    error_message = "repository_event_config needs at most one of push or pull_request."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.source_to_build == null || can(regex("^refs/", t.source_to_build.ref))
    ])
    error_message = "source_to_build.ref must start with refs/ (e.g. refs/heads/main)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.triggers : [
        for src in [t.source_to_build, t.git_file_source] : src == null || contains(["UNKNOWN", "CLOUD_SOURCE_REPOSITORIES", "GITHUB", "BITBUCKET_SERVER"], src.repo_type)
      ]
    ]))
    error_message = "repo_type must be one of UNKNOWN, CLOUD_SOURCE_REPOSITORIES, GITHUB or BITBUCKET_SERVER."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.include_build_logs == null || contains(["INCLUDE_BUILD_LOGS_UNSPECIFIED", "INCLUDE_BUILD_LOGS_WITH_STATUS"], t.include_build_logs)])
    error_message = "include_build_logs must be INCLUDE_BUILD_LOGS_UNSPECIFIED or INCLUDE_BUILD_LOGS_WITH_STATUS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.deletion_policy == null || contains(["DELETE", "ABANDON"], t.deletion_policy)])
    error_message = "deletion_policy must be DELETE or ABANDON (case-sensitive). Defaults to DELETE when unset."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.build == null || t.build.options == null || contains(["ALLOW_LOOSE", "ALLOW_UNSUBSTITUTED"], try(t.build.options.substitution_option, "ALLOW_LOOSE"))
    ])
    error_message = "build.options.substitution_option must be ALLOW_LOOSE or ALLOW_UNSUBSTITUTED."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.build == null || t.build.options == null || contains(["LOGGING_UNSPECIFIED", "LEGACY", "GCS_ONLY", "CLOUD_LOGGING_ONLY", "NONE"], try(t.build.options.logging, "LOGGING_UNSPECIFIED"))
    ])
    error_message = "build.options.logging must be one of LOGGING_UNSPECIFIED, LEGACY, GCS_ONLY, CLOUD_LOGGING_ONLY or NONE."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.build == null || t.build.options == null || contains(["STREAM_DEFAULT", "STREAM_ON", "STREAM_OFF"], try(t.build.options.log_streaming_option, "STREAM_DEFAULT"))
    ])
    error_message = "build.options.log_streaming_option must be STREAM_DEFAULT, STREAM_ON or STREAM_OFF."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.build == null || t.build.options == null || alltrue([
        for h in try(t.build.options.source_provenance_hash, []) : contains(["NONE", "MD5", "SHA256"], h)
      ])
    ])
    error_message = "build.options.source_provenance_hash must contain only NONE, MD5 or SHA256."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.build == null || t.build.options == null || contains(["NOT_VERIFIED", "VERIFIED"], try(t.build.options.requested_verify_option, "NOT_VERIFIED"))
    ])
    error_message = "build.options.requested_verify_option must be NOT_VERIFIED or VERIFIED."
  }
}
