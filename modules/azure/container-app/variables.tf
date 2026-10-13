variable "container_apps" {
  description = "Map of Azure Container Apps keyed by an arbitrary identifier. Each entry creates one azurerm_container_app in the named resource group. Apps always bind to an externally managed environment by full ARM ID (container_app_environment_id — typically dependency.cae.outputs.environment_ids[...] from the azure/container-app-environment module); this module never creates the environment."
  type = map(object({
    name                         = string
    resource_group_name          = string
    container_app_environment_id = string
    revision_mode                = string
    workload_profile_name        = optional(string)
    max_inactive_revisions       = optional(number)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    secret = optional(map(object({
      name                = string
      value               = optional(string)
      key_vault_secret_id = optional(string)
      identity            = optional(string)
    })), {})

    registry = optional(map(object({
      server               = string
      identity             = optional(string)
      username             = optional(string)
      password_secret_name = optional(string)
    })), {})

    dapr = optional(object({
      app_id       = string
      app_port     = optional(number)
      app_protocol = optional(string, "http")
    }))

    template = object({
      container = map(object({
        name    = string
        image   = string
        cpu     = number
        memory  = string
        args    = optional(list(string))
        command = optional(list(string))
        env     = optional(map(object({ value = optional(string), secret_name = optional(string) })), {})
        liveness_probe = optional(map(object({
          transport               = string
          port                    = number
          host                    = optional(string)
          path                    = optional(string)
          header                  = optional(map(object({ name = string, value = string })), {})
          initial_delay           = optional(number)
          interval_seconds        = optional(number)
          timeout                 = optional(number)
          failure_count_threshold = optional(number)
        })), {})
        readiness_probe = optional(map(object({
          transport               = string
          port                    = number
          host                    = optional(string)
          path                    = optional(string)
          header                  = optional(map(object({ name = string, value = string })), {})
          initial_delay           = optional(number)
          interval_seconds        = optional(number)
          timeout                 = optional(number)
          failure_count_threshold = optional(number)
          success_count_threshold = optional(number)
        })), {})
        startup_probe = optional(map(object({
          transport               = string
          port                    = number
          host                    = optional(string)
          path                    = optional(string)
          header                  = optional(map(object({ name = string, value = string })), {})
          initial_delay           = optional(number)
          interval_seconds        = optional(number)
          timeout                 = optional(number)
          failure_count_threshold = optional(number)
        })), {})
        volume_mounts = optional(map(object({ path = string, sub_path = optional(string) })), {})
      }))

      init_container = optional(map(object({
        name          = string
        image         = string
        cpu           = number
        memory        = string
        args          = optional(list(string))
        command       = optional(list(string))
        env           = optional(map(object({ value = optional(string), secret_name = optional(string) })), {})
        volume_mounts = optional(map(object({ path = string, sub_path = optional(string) })), {})
      })), {})

      min_replicas                     = optional(number, 0)
      max_replicas                     = optional(number, 10)
      cooldown_period_in_seconds       = optional(number, 300)
      polling_interval_in_seconds      = optional(number, 30)
      termination_grace_period_seconds = optional(number, 0)
      revision_suffix                  = optional(string)

      http_scale_rule = optional(map(object({
        concurrent_requests = string
        authentication      = optional(map(object({ secret_name = string, trigger_parameter = optional(string) })), {})
      })), {})

      tcp_scale_rule = optional(map(object({
        concurrent_requests = string
        authentication      = optional(map(object({ secret_name = string, trigger_parameter = optional(string) })), {})
      })), {})

      azure_queue_scale_rule = optional(map(object({
        queue_name     = string
        queue_length   = number
        authentication = map(object({ secret_name = string, trigger_parameter = string }))
      })), {})

      custom_scale_rule = optional(map(object({
        custom_rule_type = string
        metadata         = map(string)
        authentication   = optional(map(object({ secret_name = string, trigger_parameter = string })), {})
        identity_id      = optional(string)
      })), {})

      volume = optional(map(object({
        storage_name  = optional(string)
        storage_type  = optional(string, "EmptyDir")
        mount_options = optional(string)
      })), {})
    })

    ingress = optional(object({
      target_port                = number
      exposed_port               = optional(number)
      transport                  = optional(string, "auto")
      external_enabled           = optional(bool, false)
      allow_insecure_connections = optional(bool)
      client_certificate_mode    = optional(string)
      cors = optional(object({
        allowed_origins           = list(string)
        allow_credentials_enabled = optional(bool, false)
        allowed_headers           = optional(list(string))
        allowed_methods           = optional(list(string))
        exposed_headers           = optional(list(string))
        max_age_in_seconds        = optional(number)
      }))
      ip_security_restriction = optional(map(object({
        name             = string
        action           = string
        ip_address_range = string
        description      = optional(string)
      })), {})
      traffic_weight = map(object({
        label           = optional(string)
        latest_revision = optional(bool, false)
        revision_suffix = optional(string)
        percentage      = number
      }))
    }))

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for app_key in keys(var.container_apps) : length(trimspace(app_key)) > 0 && !can(regex("\\.", app_key))
    ])
    error_message = "map keys of container_apps must be non-empty and must not contain \".\" — keys are the identifiers referenced in the module's outputs (app_ids and friends); dots would make Terragrunt dependency lookups ambiguous."
  }

  validation {
    condition = alltrue([
      for app_key, app in var.container_apps :
      can(regex("^[a-z]([a-z0-9.-]{0,30}[a-z0-9])?$", app.name)) && !can(regex("--", app.name))
    ])
    error_message = "name must be lowercase alphanumeric with periods and hyphens allowed in the middle, at most 32 characters, starting and ending alphanumeric, without \"--\" (the provider's own container-app name rule). Immutable — changing it forces app replacement."
  }

  validation {
    condition = alltrue([
      for app in var.container_apps : length(trimspace(app.name)) > 0 && length(trimspace(app.resource_group_name)) > 0 && length(trimspace(app.container_app_environment_id)) > 0
    ])
    error_message = "name, resource_group_name and container_app_environment_id must not be empty."
  }

  validation {
    condition = alltrue(flatten([
      for app_key, app in var.container_apps : [
        for other_key, other in var.container_apps :
        app_key == other_key || lower(app.resource_group_name) != lower(other.resource_group_name) || lower(app.name) != lower(other.name)
      ]
    ]))
    error_message = "two entries may not carry the same app name inside the same resource group, case-insensitively — the Azure API rejects the duplicate. Names are resource-group scoped, so the same name in different resource groups is fine."
  }

  validation {
    condition = alltrue([
      for app in var.container_apps : can(regex("^/", app.container_app_environment_id))
    ])
    error_message = "container_app_environment_id must be a full ARM managed-environment ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.App/managedEnvironments/<name>\" — typically dependency.cae.outputs.environment_ids[...] from the azure/container-app-environment module). Set at app creation only: changing it forces app replacement."
  }

  validation {
    condition = alltrue([
      for app in var.container_apps : contains(["Single", "Multiple"], app.revision_mode)
    ])
    error_message = "revision_mode must be \"Single\" or \"Multiple\" (case-sensitive) — Single auto-deactivates older revisions and forbids traffic splitting; Multiple keeps revisions and lets ingress.traffic_weight split among them."
  }

  validation {
    condition = alltrue([
      for app in var.container_apps : app.max_inactive_revisions == null || (app.max_inactive_revisions >= 0 && app.max_inactive_revisions <= 100)
    ])
    error_message = "max_inactive_revisions must be between 0 and 100 — the cap on deactivated revisions the app keeps; pair it with revision_mode = \"Multiple\" in blue-green set-ups."
  }

  validation {
    condition = alltrue([
      for app in var.container_apps : app.workload_profile_name == null || length(trimspace(app.workload_profile_name)) > 0
    ])
    error_message = "workload_profile_name, when set, must be a non-empty profile name matching a workload_profile defined on the (external) environment — leave it unset for the environment's default Consumption profile. This module cannot check the name against the environment; a mismatch fails at the Azure API."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : app.identity == null ? [] : [
        contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], app.identity.type),
        !can(regex("UserAssigned", app.identity.type)) || length(app.identity.identity_ids) > 0
      ]
    ]))
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (case-sensitive as written), and identity_ids must carry at least one user-assigned identity ARM ID when the type contains \"UserAssigned\"."
  }

  validation {
    condition = alltrue(flatten(concat(
      [for app_key in keys(var.container_apps) : true],
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.secret) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.registry) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.template.container) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.template.init_container) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.template.volume) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.template.http_scale_rule) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.template.tcp_scale_rule) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.template.azure_queue_scale_rule) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : [
          for key in keys(app.template.custom_scale_rule) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : app.ingress == null ? [] : [
          for key in keys(app.ingress.ip_security_restriction) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ]),
      flatten([
        for app_key, app in var.container_apps : app.ingress == null ? [] : [
          for key in keys(app.ingress.traffic_weight) : length(trimspace(key)) > 0 && !can(regex("\\.", key))
        ]
      ])
    )))
    error_message = "map keys of secret, registry, template.container, template.init_container, template.volume, the four scale-rule maps, ingress.ip_security_restriction, ingress.traffic_weight (and the nested env/volume_mount/probe/header maps below) must be non-empty and must not contain \".\" — keys are local or self-descriptive identifiers in the module's inputs and outputs."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for secret_key, secret in app.secret : [
          can(regex("^[a-z0-9]([a-z0-9-]{0,251}[a-z0-9])?$", secret.name)) && !can(regex("-$", secret.name)),
          (secret.value != null) != (secret.key_vault_secret_id != null),
          (secret.key_vault_secret_id != null) == (secret.identity != null)
        ]
      ]
    ]))
    error_message = "each secret needs a name of lowercase alphanumeric/hyphen characters up to 253, not ending with a hyphen (the provider's own rule); exactly one of value or key_vault_secret_id (plain values land in state in plaintext — see Notes); and, when the Key Vault route is used, identity must be set and vice versa — identity is \"System\" or a user-assigned identity ARM ID the vault is readable with."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for secret_key, secret in app.secret :
        secret.key_vault_secret_id == null || can(regex("^https://.+/secrets/.+", secret.key_vault_secret_id))
      ]
    ]))
    error_message = "secret key_vault_secret_id, when set, must be a full Key Vault secret ID (\"https://<vault>.vault.azure.net/secrets/<name>\" — versioned or versionless). Changing the ID on an existing secret is not picked up; rotate by updating the secret inside the vault."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        length(distinct([for secret_key, secret in app.secret : lower(secret.name)])) == length(app.secret)
      ]
    ]))
    error_message = "secret names must be unique within the app, case-insensitively — the Azure API rejects the duplicate."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for registry_key, registry in app.registry : [
          length(trimspace(registry.server)) > 0,
          (registry.identity != null) != (registry.username != null || registry.password_secret_name != null),
          (registry.username != null) == (registry.password_secret_name != null),
          registry.identity == null || can(regex("(?i)^system$", registry.identity)) || can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/.+$", registry.identity))
        ]
      ]
    ]))
    error_message = "each registry needs a non-empty server and exactly one auth mechanism: identity (\"system\" — case-insensitive — or a user-assigned identity ARM ID) OR the pair username + password_secret_name; the two mechanisms are mutually exclusive and the username/password pair is all-or-nothing (the provider enforces the same three rules)."
  }

  validation {
    condition = alltrue(flatten(concat(
      [for app in var.container_apps : true],
      flatten([
        for app in var.container_apps : [
          for registry_key, registry in app.registry :
          registry.password_secret_name == null || contains([for secret_key, secret in app.secret : lower(secret.name)], lower(registry.password_secret_name))
        ]
      ]),
      flatten([
        for app in var.container_apps : [
          for registry_key, registry in app.registry :
          registry.identity == null || !can(regex("^system", lower(registry.identity))) || app.identity != null
        ]
      ])
    )))
    error_message = "each registry's password_secret_name must reference one of the app's own secret definitions (registry credentials are app-level secrets, not module inputs), and registry identity = system requires the app itself to carry an identity block; a user-assigned registry identity should be listed in the app's identity.identity_ids."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : app.dapr == null ? [] : [
        length(trimspace(app.dapr.app_id)) > 0,
        can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", app.dapr.app_id)),
        contains(["http", "grpc"], app.dapr.app_protocol)
      ]
    ]))
    error_message = "dapr.app_id, when the dapr block is set, must be a non-empty Dapr Application Identifier — lowercase alphanumeric with hyphens, no dots; app_protocol must be \"http\" or \"grpc\" (case-sensitive) — the protocol the Dapr sidecar speaks to the app with, defaulting to http."
  }

  validation {
    condition = alltrue([
      for app in var.container_apps : length(app.template.container) > 0
    ])
    error_message = "template.container must carry at least one container — the Azure API rejects a revision with nothing in it."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : concat(
        [
          for container_key, container in app.template.container : [
            can(regex("(^[a-z0-9]$)|(^([a-z0-9])([a-z0-9.-]{0,44}[a-z0-9])$)", container.name)),
            length(trimspace(container.image)) > 0,
            container.cpu >= 0.1,
            length(trimspace(container.memory)) > 0
          ]
        ],
        [
          for init_key, init_container in app.template.init_container : [
            can(regex("(^[a-z0-9]$)|(^([a-z0-9])([a-z0-9.-]{0,44}[a-z0-9])$)", init_container.name)),
            length(trimspace(init_container.image)) > 0,
            init_container.cpu >= 0.1,
            length(trimspace(init_container.memory)) > 0
          ]
        ]
      )
    ]))
    error_message = "every (init) container needs a name of lowercase alphanumeric, period or dash characters, at most 46 characters, starting and ending alphanumeric (the provider's own rule), a non-empty image reference (\"<registry-server>/<image>:<tag>\"), cpu of at least 0.1 and a non-empty memory string (e.g. \"0.5Gi\"; see Notes for the Consumption-profile allocation combos Azure enforces)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : concat(
        [
          for container_key, container in app.template.container : [
            for env_key in keys(container.env) : length(trimspace(env_key)) > 0 && !can(regex("\\.", env_key))
          ]
        ],
        [
          for init_key, init_container in app.template.init_container : [
            for env_key in keys(init_container.env) : length(trimspace(env_key)) > 0 && !can(regex("\\.", env_key))
          ]
        ]
      )
    ]))
    error_message = "env map keys must be non-empty and must not contain \".\" — the env key is the exact environment-variable name the container sees."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : concat(
        [
          for container_key, container in app.template.container : [
            for env_key, env_value in container.env : (env_value.value != null || env_value.secret_name != null)
          ]
        ],
        [
          for init_key, init_container in app.template.init_container : [
            for env_key, env_value in init_container.env : (env_value.value != null || env_value.secret_name != null)
          ]
        ]
      )
    ]))
    error_message = "each env entry must set value or secret_name — an env var with neither is rejected by the Azure API. When both are set, secret_name wins and value is silently dropped (the service's own precedence) — pick one."
  }

  validation {
    condition = alltrue(flatten(concat(
      [for app in var.container_apps : true],
      flatten([
        for app in var.container_apps : [
          for container_key, container in app.template.container : [
            for env_key, env_value in container.env :
            env_value.secret_name == null || contains([for secret_key, secret in app.secret : lower(secret.name)], lower(env_value.secret_name))
          ]
        ]
      ]),
      flatten([
        for app in var.container_apps : [
          for init_key, init_container in app.template.init_container : [
            for env_key, env_value in init_container.env :
            env_value.secret_name == null || contains([for secret_key, secret in app.secret : lower(secret.name)], lower(env_value.secret_name))
          ]
        ]
      ])
    )))
    error_message = "every env secret_name must reference one of the app's own secret definitions (env.secret_name is a pointer into the app-level secret list, and a dangling reference fails at the Azure API)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for container_key, container in app.template.container : concat(
          [for probe_key in keys(container.liveness_probe) : length(trimspace(probe_key)) > 0 && !can(regex("\\.", probe_key))],
          [for probe_key in keys(container.readiness_probe) : length(trimspace(probe_key)) > 0 && !can(regex("\\.", probe_key))],
          [for probe_key in keys(container.startup_probe) : length(trimspace(probe_key)) > 0 && !can(regex("\\.", probe_key))],
          [for probe in concat(values(container.liveness_probe), values(container.readiness_probe), values(container.startup_probe)) : [
            contains(["TCP", "HTTP", "HTTPS"], upper(probe.transport)),
            probe.port >= 1 && probe.port <= 65535,
            probe.initial_delay == null || (probe.initial_delay >= 0 && probe.initial_delay <= 60),
            probe.interval_seconds == null || (probe.interval_seconds >= 1 && probe.interval_seconds <= 240),
            probe.timeout == null || (probe.timeout >= 1 && probe.timeout <= 240),
            probe.transport != "TCP" || probe.path == null
          ]]
        )
      ]
    ]))
    error_message = "probe transport must be TCP, HTTP or HTTPS (case-insensitive — normalized to upper) with port 1–65535; delay spans 0–60 (defaults 1/0/0 across kinds), interval and timeout span 1–240 (defaults 10 and 1) — the provider's own bounds; a TCP probe cannot carry a path (it would be silently dropped); omit attributes to stay at the defaults."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for container_key, container in app.template.container : concat(
          [for probe in values(container.liveness_probe) :
          probe.failure_count_threshold == null || (probe.failure_count_threshold >= 1 && probe.failure_count_threshold <= 30)],
          [for probe in values(container.readiness_probe) : [
            probe.failure_count_threshold == null || (probe.failure_count_threshold >= 1 && probe.failure_count_threshold <= 48),
            probe.success_count_threshold == null || (probe.success_count_threshold >= 1 && probe.success_count_threshold <= 10)
          ]],
          [for probe in values(container.startup_probe) :
          probe.failure_count_threshold == null || (probe.failure_count_threshold >= 1 && probe.failure_count_threshold <= 240)]
        )
      ]
    ]))
    error_message = "probe failure_count_threshold respects the per-kind ceilings (liveness 1–30, readiness 1–48, startup 1–240; default 3) and success_count_threshold (readiness only) spans 1–10 (default 3)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for container_key, container in app.template.container : concat(
          [for probe in concat(values(container.liveness_probe), values(container.readiness_probe), values(container.startup_probe)) :
          [for header_key in keys(probe.header) : length(trimspace(header_key)) > 0 && !can(regex("\\.", header_key))]],
          [for probe in concat(values(container.liveness_probe), values(container.readiness_probe), values(container.startup_probe)) :
          [for header in values(probe.header) : length(trimspace(header.name)) > 0]]
        )
      ]
    ]))
    error_message = "probe header map keys must be non-empty and must not contain \".\", and each header entry must carry a non-empty name — an unnamed header is dropped by the API."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for container_key, container in app.template.container : concat(
          [for mount_key in keys(container.volume_mounts) : length(trimspace(mount_key)) > 0 && !can(regex("\\.", mount_key))],
          [for mount in values(container.volume_mounts) : length(trimspace(mount.path)) > 0],
          [for init_key, init_container in app.template.init_container : concat(
            [for mount_key in keys(init_container.volume_mounts) : length(trimspace(mount_key)) > 0 && !can(regex("\\.", mount_key))],
            [for mount in values(init_container.volume_mounts) : length(trimspace(mount.path)) > 0]
          )]
        )
      ]
    ]))
    error_message = "volume_mounts keys must be non-empty and must not contain \".\" — the key must equal one of the app's template.volume entries (the mount is wired by that name); mount paths must be non-empty."
  }

  validation {
    condition = alltrue(flatten(concat(
      [for app in var.container_apps : true],
      flatten([
        for app in var.container_apps : [
          for container_key, container in app.template.container : [
            for mount_key in keys(container.volume_mounts) : contains(keys(app.template.volume), mount_key)
          ]
        ]
      ]),
      flatten([
        for app in var.container_apps : [
          for init_key, init_container in app.template.init_container : [
            for mount_key in keys(init_container.volume_mounts) : contains(keys(app.template.volume), mount_key)
          ]
        ]
      ])
    )))
    error_message = "every volume_mounts key must reference a template.volume entry by its key — the Azure API rejects mounts that name a volume not declared on the app's template."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for rule_key, rule in app.template.http_scale_rule : [
          can(regex("^[1-9][0-9]*$", rule.concurrent_requests)),
          alltrue([for auth_key, auth in rule.authentication : length(trimspace(auth.secret_name)) > 0 && (auth.trigger_parameter == null || length(trimspace(auth.trigger_parameter)) > 0)])
        ]
      ]
    ]))
    error_message = "each http_scale_rule needs a map key that reads as the rule's name (see the scale-rule key rule), concurrent_requests as a string representation of an integer ≥ 1 (the provider's own type and rule — it is a string, not a number), and authentication entries (when present) with a non-blank secret_name and a non-blank optional trigger_parameter."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for rule_key, rule in app.template.tcp_scale_rule : [
          can(regex("^[1-9][0-9]*$", rule.concurrent_requests)),
          alltrue([for auth_key, auth in rule.authentication : length(trimspace(auth.secret_name)) > 0 && (auth.trigger_parameter == null || length(trimspace(auth.trigger_parameter)) > 0)])
        ]
      ]
    ]))
    error_message = "each tcp_scale_rule needs a map key that reads as the rule's name (see the scale-rule key rule), concurrent_requests as a string representation of an integer ≥ 1 (the provider's own type and rule — it is a string, not a number), and authentication entries (when present) with a non-blank secret_name and a non-blank optional trigger_parameter."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for rule_key, rule in app.template.azure_queue_scale_rule : [
          length(trimspace(rule.queue_name)) > 0,
          rule.queue_length >= 1,
          length(rule.authentication) > 0,
          alltrue([for auth_key, auth in rule.authentication : length(trimspace(auth.secret_name)) > 0 && length(trimspace(auth.trigger_parameter)) > 0])
        ]
      ]
    ]))
    error_message = "each azure_queue_scale_rule needs a map key that reads as the rule's name (see the scale-rule key rule), a non-empty queue_name, queue_length ≥ 1 and at least one authentication entry with non-blank secret_name and trigger_parameter — the provider marks authentication required for queue rules. queue_name is the raw Azure Storage queue name, not this module's key space."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for rule_key, rule in app.template.custom_scale_rule : [
          can(regex("(^[a-z0-9]$)|(^[a-z0-9][a-z0-9-]{0,29}[a-z0-9]$)", rule_key)) && !can(regex("--", rule_key)),
          length(rule.metadata) > 0,
          alltrue([for meta_key, meta_value in rule.metadata : length(trimspace(meta_key)) > 0 && length(trimspace(meta_value)) > 0]),
          alltrue([for auth_key, auth in rule.authentication : length(trimspace(auth.secret_name)) > 0 && length(trimspace(auth.trigger_parameter)) > 0]),
          rule.identity_id == null || can(regex("(?i)^system$", rule.identity_id)) || can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/.+$", rule.identity_id))
        ]
      ]
    ]))
    error_message = "each custom_scale_rule needs a non-empty metadata map (all keys/values non-blank — the service rejects malformed metadata), authentication entries (when present) with non-blank secret_name and trigger_parameter (required for custom rules), identity_id of \"System\" or a full user-assigned identity ARM ID, and the rule name (the map key) in lowercase alphanumeric/dash, ≤ 31 characters, without \"--\"."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for rule_key, rule in app.template.custom_scale_rule : contains(
          ["activemq", "artemis-queue", "kafka", "pulsar", "aws-cloudwatch", "aws-dynamodb", "aws-dynamodb-streams", "aws-kinesis-stream", "aws-sqs-queue", "azure-app-insights", "azure-blob", "azure-data-explorer", "azure-eventhub", "azure-log-analytics", "azure-monitor", "azure-pipelines", "azure-servicebus", "azure-queue", "cassandra", "cpu", "cron", "datadog", "elasticsearch", "external", "external-push", "gcp-stackdriver", "gcp-storage", "gcp-pubsub", "graphite", "http", "huawei-cloudeye", "ibmmq", "influxdb", "kubernetes-workload", "liiklus", "memory", "metrics-api", "mongodb", "mssql", "mysql", "nats-jetstream", "stan", "tcp", "new-relic", "openstack-metric", "openstack-swift", "postgresql", "predictkube", "prometheus", "rabbitmq", "redis", "redis-cluster", "redis-sentinel", "redis-streams", "redis-cluster-streams", "redis-sentinel-streams", "selenium-grid", "solace-event-queue", "github-runner"],
          rule.custom_rule_type
        )
      ]
    ]))
    error_message = "custom_rule_type must be one of the KEDA-compatible types the provider lists (activemq, artemis-queue, kafka, pulsar, aws-*, azure-*, gcp-*, http, tcp, prometheus, rabbitmq, redis*, postgresql, github-runner and the rest — see the Inputs table) — the provider enforces this exact list, so the module mirrors it at plan."
  }

  validation {
    condition = alltrue(flatten(concat(
      [for app in var.container_apps : true],
      flatten([
        for app in var.container_apps : [
          for rule_key in keys(app.template.http_scale_rule) : [
            for auth_key, auth in app.template.http_scale_rule[rule_key].authentication : contains([for secret_key, secret in app.secret : lower(secret.name)], lower(auth.secret_name))
          ]
        ]
      ]),
      flatten([
        for app in var.container_apps : [
          for rule_key in keys(app.template.tcp_scale_rule) : [
            for auth_key, auth in app.template.tcp_scale_rule[rule_key].authentication : contains([for secret_key, secret in app.secret : lower(secret.name)], lower(auth.secret_name))
          ]
        ]
      ]),
      flatten([
        for app in var.container_apps : [
          for rule_key in keys(app.template.azure_queue_scale_rule) : [
            for auth_key, auth in app.template.azure_queue_scale_rule[rule_key].authentication : contains([for secret_key, secret in app.secret : lower(secret.name)], lower(auth.secret_name))
          ]
        ]
      ]),
      flatten([
        for app in var.container_apps : [
          for rule_key in keys(app.template.custom_scale_rule) : [
            for auth_key, auth in app.template.custom_scale_rule[rule_key].authentication : contains([for secret_key, secret in app.secret : lower(secret.name)], lower(auth.secret_name))
          ]
        ]
      ])
    )))
    error_message = "every scale-rule authentication secret_name must reference one of the app's own secret definitions (auth secrets are app-level secrets, not module inputs) — a dangling reference fails at the Azure API."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        length(distinct([for rule_key in concat(
          keys(app.template.http_scale_rule),
          keys(app.template.tcp_scale_rule),
          keys(app.template.azure_queue_scale_rule),
          keys(app.template.custom_scale_rule)
          ) : lower(rule_key)])) == length(concat(
          keys(app.template.http_scale_rule),
          keys(app.template.tcp_scale_rule),
          keys(app.template.azure_queue_scale_rule),
          keys(app.template.custom_scale_rule)
        ))
      ]
    ]))
    error_message = "scale-rule names (the map keys) must be unique within the app, case-insensitively — KEDA triggers are configured per-name and the API rejects duplicates."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : [
        for volume_key, volume in app.template.volume : [
          contains(["AzureFile", "EmptyDir", "NfsAzureFile", "Secret"], coalesce(volume.storage_type, "EmptyDir")),
          volume.storage_name == null || (length(trimspace(volume.storage_name)) > 0 && can(regex("^[a-z]([a-z0-9-]{0,30}[a-z0-9])?$", volume.storage_name)) && !can(regex("--", volume.storage_name))),
          volume.mount_options == null || length(trimspace(volume.mount_options)) > 0,
          volume.storage_name != null || contains(["EmptyDir", "Secret"], coalesce(volume.storage_type, "EmptyDir")),
          volume.storage_name == null || contains(["AzureFile", "NfsAzureFile"], coalesce(volume.storage_type, "EmptyDir"))
        ]
      ]
    ]))
    error_message = "each volume needs a map key that reads as the volume's name (see the volume key rule), storage_type in AzureFile/EmptyDir/NfsAzureFile/Secret (the provider's own list; defaults to EmptyDir), non-empty storage_name/mount_options when set, storage_name (the environment-storage resource name) in the provider's lowercase alphanumeric/dash shape ≤ 32 without \"--\" — and storage_name set exactly for AzureFile/NfsAzureFile volumes (an EmptyDir volume has no backing to name and a Secret volume has none at all)."
  }

  validation {
    condition = alltrue([
      for app in var.container_apps :
      app.template.min_replicas >= 0 && app.template.min_replicas <= 300 &&
      app.template.max_replicas >= 1 && app.template.max_replicas <= 300 &&
      app.template.min_replicas <= app.template.max_replicas &&
      app.template.cooldown_period_in_seconds >= 1 &&
      app.template.polling_interval_in_seconds >= 1 &&
      app.template.termination_grace_period_seconds >= 0 && app.template.termination_grace_period_seconds <= 600
    ])
    error_message = "scale bounds: min_replicas 0–300, max_replicas 1–300, min_replicas ≤ max_replicas (defaults 0 scale-to-zero and 10); cooldown_period_in_seconds and polling_interval_in_seconds ≥ 1 (defaults 300 and 30); termination_grace_period_seconds 0–600 (default 0)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : app.ingress == null ? [] : [
        app.ingress.target_port >= 1 && app.ingress.target_port <= 65535,
        contains(["auto", "http", "http2", "tcp"], app.ingress.transport),
        app.ingress.exposed_port == null || (app.ingress.transport == "tcp" && app.ingress.exposed_port >= 1 && app.ingress.exposed_port <= 65535),
        app.ingress.client_certificate_mode == null || contains(["ignore", "accept", "require"], app.ingress.client_certificate_mode),
        app.ingress.cors == null || (length(app.ingress.cors.allowed_origins) > 0 && (app.ingress.cors.max_age_in_seconds == null || app.ingress.cors.max_age_in_seconds >= 0)),
        length(app.ingress.traffic_weight) > 0,
        sum([for weight_key, weight in app.ingress.traffic_weight : weight.percentage]) == 100
      ]
    ]))
    error_message = "ingress, when set: target_port spans 1–65535 (the container port receiving traffic); transport is auto/http/http2/tcp (default auto); exposed_port only rides transport = \"tcp\" (1–65535 when set); client_certificate_mode is ignore/accept/require; cors.allowed_origins carries at least one origin and max_age_in_seconds ≥ 0 when set; traffic_weight carries at least one entry whose percentages sum to exactly 100 — the service rejects any other total (the canonical single-revision weight is { latest_revision = true, percentage = 100 })."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : app.ingress == null ? [] : [
        for weight_key, weight in app.ingress.traffic_weight : [
          weight.label == null || length(trimspace(weight.label)) > 0,
          weight.revision_suffix == null || length(trimspace(weight.revision_suffix)) > 0,
          weight.percentage >= 0 && weight.percentage <= 100,
          weight.latest_revision || (weight.revision_suffix != null && length(trimspace(weight.revision_suffix)) > 0)
        ]
      ]
    ]))
    error_message = "each ingress.traffic_weight entry needs label/revision_suffix non-blank when set, percentage 0–100, and either latest_revision = true or a non-empty revision_suffix (the provider enforces the same rule — a weight with neither has nowhere to route)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : app.ingress == null ? [] : [
        for restriction_key, restriction in app.ingress.ip_security_restriction : [
          length(trimspace(restriction.name)) > 0,
          contains(["Allow", "Deny"], restriction.action),
          can(cidrhost(restriction.ip_address_range, 0)) || can(cidrhost("${restriction.ip_address_range}/32", 0)) || can(cidrhost("${restriction.ip_address_range}/128", 0))
        ]
      ]
    ]))
    error_message = "each ingress.ip_security_restriction entry needs a non-empty name, action of Allow or Deny (case-sensitive), and ip_address_range as a single IP address or CIDR block (in either IP version) — all entries of one ingress must share the same action (next rule)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.container_apps : app.ingress == null ? [] : [
        length(distinct([for restriction_key, restriction in app.ingress.ip_security_restriction : restriction.action])) <= 1
      ]
    ]))
    error_message = "an ingress's ip_security_restriction entries must share one action — mixing Allow and Deny rules in the same app is not supported by the service."
  }

  validation {
    condition = alltrue([
      for app_key, app in var.container_apps :
      length(app.tags) <= 50 && alltrue([for tag_key, tag_value in app.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (Azure-enforced limits)."
  }
}
