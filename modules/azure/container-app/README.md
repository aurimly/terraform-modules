# azure/container-app

> **Provider floor** — developed against the `azurerm` provider v5.x
> (v5.9.0 at build time), on the `Microsoft.App` `containerApps`
> resource; nothing is pinned in-module — pin the provider version at the
> consumer's root Terragrunt level.

Map-keyed module for Azure Container Apps (`azurerm_container_app`): one
app per entry, with (init) containers, probes, scale rules, volumes,
ingress (traffic weighting, CORS, IP restrictions), secrets, registries,
Dapr and managed identities. The environment is always external — every
app binds to it by full ARM ID (`container_app_environment_id`, typically
`dependency.cae.outputs.environment_ids[...]` from the sibling
`azure/container-app-environment` module); this module never creates the
environment.

## Destroy semantics (read before using)

- Removing an app key deletes the app, its revisions, its secrets and its
  registrations — no environment impact. Secrets are app-scoped, so a
  removed app's secret values go with it.
- Renaming an app (`name`) replaces the app: a new revision stream, a new
  FQDN under the environment's default domain, and every split-traffic
  weight referencing old revision names goes stale on the way through.
- `resource_group_name` and `container_app_environment_id` are set at
  creation only — changing either forces app replacement (and moving
  environments is almost never the thing you want; delete and re-create
  into the target environment instead).
- Everything else lives on the revision: changing templates, ingress,
  secrets or registries updates the app in place and spins a new revision
  (the service-side default keeps the revision stream, and
  `revision_suffix` makes the revision name deterministic if you want it
  so).
- Removing the ingress block removes the app's external/internal
  endpoints — the app becomes environment-only-reachable via Dapr or
  in-environment addressing, lost URLs unrecoverable from state alone
  (the FQDN output carries the last one before removal).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `container_apps` | `map(object)` | — | Map of container apps keyed by an arbitrary unique ID. |

Map keys must not contain `.` and must be non-blank at every level they
appear — keys are the identifiers of the module's outputs.

Plan-time validation: app names in the provider's ≤ 32 lowercase
format (no `--`, start/end alphanumeric), names unique across entries in
the same resource group; `name`/`resource_group_name`/
`container_app_environment_id` non-empty, the environment ID a full ARM
managed-environment ID; `revision_mode` in `Single`/`Multiple`;
`max_inactive_revisions` 0–100; identity types; secret names in the
provider's ≤ 253 rule, exactly one of `value`/`key_vault_secret_id`, the
Key Vault reference carrying `identity` both ways; registries with one
auth mechanism (`identity` XOR `username` + `password_secret_name`) and
their `password_secret_name`/system identity backed by the app's own
identity wiring; dapr app id shape and protocol; container names in the
provider's ≤ 46 rule, `cpu` ≥ 0.1, non-empty image/memory; env entries
carrying `value` or `secret_name` with `secret_name` referencing the
app's own secrets; probe transports/ports/bounds (per-kind failure
ceilings, readiness-only success, no path on TCP); scale bounds;
scale-rule names unique per app, `concurrent_requests` an integer-string
≥ 1, queue rules with ≥ 1 authentication entry, custom-rule types in the
provider's KEDA list; volumes' storage types and storage-name rules;
ingress port/transport/exposed-port/cert-mode rules, CORS origins,
IP-restriction actions aligned; traffic-weight entries summing to exactly
100 with `latest_revision` or a revision suffix each; and tags within
Azure's limits.

### `container_apps` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | App name: ≤ 32 characters, lowercase alphanumeric with hyphens/periods in the middle, no `--`, start/end alphanumeric (validated — the provider's own rule). Immutable — changing it forces app replacement. |
| `resource_group_name` | `string` | — | Resource group the app lives in (typically `dependency.rg.outputs.resource_group_names["platform"]`). Immutable — changing it forces app replacement. |
| `container_app_environment_id` | `string` | — | Full ARM managed-environment ID the app binds to (typically `dependency.cae.outputs.environment_ids["platform"]`). Immutable — changing it forces app replacement. The environment stays external to this module — see Notes. |
| `revision_mode` | `string` | — | `Single` (old revisions auto-deactivate, no split weights) or `Multiple` (revisions persist, split traffic gears up; validated). Updated in place. |
| `workload_profile_name` | `string` | `null` | Name of a workload profile on the external environment to run this app on (`D4` and friends). Omitted = the environment's default Consumption profile. Since the environment is external, the module cannot check the name — a mismatch fails at the Azure API. Updated in place. |
| `max_inactive_revisions` | `number` | `null` | Cap of deactivated revisions retained (0–100, validated) — pair with `revision_mode = "Multiple"` for blue-green set-ups. Updated in place. |
| `identity` | `object` | `null` | Optional managed-identity block — see the object table. |
| `secret` | `map(object)` | `{}` | App-level secrets keyed by an arbitrary unique ID — see the object table. These are the secrets env vars/registries/scale-rule auth reference by `secret_name`. |
| `registry` | `map(object)` | `{}` | Private container registries keyed by an arbitrary unique ID — see the object table. |
| `dapr` | `object` | `null` | Optional single Dapr block — see the object table. |
| `template` | `object` | — | The running template — see the `template` object table. Template changes are in-place and spin a new revision. |
| `ingress` | `object` | `null` | Optional single ingress block (what the app serves on the environment's FQDN and from where) — see the `ingress` object table. |
| `tags` | `map(string)` | `{}` | Tags on the app. The tag set is authoritative — see Notes. |

### `identity` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `SystemAssigned`, `UserAssigned` or `SystemAssigned, UserAssigned` (case-sensitive; validated). |
| `identity_ids` | `list(string)` | `[]` | Full ARM resource IDs of the user-assigned identities (at least one when the type contains `UserAssigned` — validated). Registry identities beyond `system` and custom-rule executor identities must be in this list. |

### `secret` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Secret name (lowercase alphanumeric/hyphen up to 253, no trailing hyphen — validated; the API rejects duplicates case-insensitively — validated). Unique across the whole set. |
| `value` | `string` | `null` | Plain secret value — exactly one of this or `key_vault_secret_id` (validated). Lands in state in plaintext (see Notes); prefer the Key Vault route. |
| `key_vault_secret_id` | `string` | `null` | Full Key Vault secret ID (versioned or versionless, validated). Changing the ID on an existing secret is not picked up; rotate inside the vault instead. Pairs exactly with `identity` (validated both ways). |
| `identity` | `string` | `null` | `System` (the system-assigned identity reads the vault) or a user-assigned identity ARM ID — with the vault granted Key Vault Secrets User to it. Only together with `key_vault_secret_id` (validated). |

### `registry` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `server` | `string` | — | Registry hostname (e.g. `crplatformprod.azurecr.io`). |
| `username` | `string` | `null` | Registry username — paired exactly with `password_secret_name` (validated) and mutually exclusive with `identity` (validated). |
| `password_secret_name` | `string` | `null` | Name of one of the app's own `secret` entries holding the registry password (validated — the registry credential is an app-level secret, and a dangling reference fails at the API). |
| `identity` | `string` | `null` | `system` (case-insensitive, requires the app to carry an identity — validated) or a user-assigned identity ARM ID (listed in `identity.identity_ids`) authorized to pull — mutually exclusive with the username/password pair (validated). |

### `dapr` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `app_id` | `string` | — | Dapr Application Identifier — lowercase alphanumeric with hyphens, no dots (validated); how other services reach the app under this identifier depends on Dapr's service invocation. |
| `app_port` | `number` | `null` | Port the app listens on for Dapr traffic (typically `ingress.target_port`). |
| `app_protocol` | `string` | `http` | `http` or `grpc` (case-sensitive; validated) — the protocol the Dapr sidecar speaks to the app with. |

### `template` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `container` | `map(object)` | — | At least one container keyed by an arbitrary unique ID — see the `container` object table. |
| `init_container` | `map(object)` | `{}` | Init containers keyed by an arbitrary unique ID — same shape as `container` minus the probe blocks. |
| `min_replicas` | `number` | `0` | Scale floor (0–300, validated; 0 = scale-to-zero). |
| `max_replicas` | `number` | `10` | Scale ceiling (1–300, validated, not below `min_replicas` — validated). |
| `cooldown_period_in_seconds` | `number` | `300` | Seconds before scaling down again (≥ 1, validated). |
| `polling_interval_in_seconds` | `number` | `30` | Interval between KEDA polls (≥ 1, validated). |
| `termination_grace_period_seconds` | `number` | `0` | Seconds between SIGTERM and the kill (0–600, validated). |
| `revision_suffix` | `string` | `null` | Suffix for the next revision name — must be unique for the app's lifetime (non-blank when set, validated); the service hash-generates one when omitted. The service may re-use an old suffix name — docs suggest timestamp/hash-style suffixes. |
| `http_scale_rule` | `map(object)` | `{}` | HTTP scale rules keyed by the rule NAME (the identifier logs/KEDA know) — see the scale-rule section. Rule names are unique across all four rule maps per app (validated). |
| `tcp_scale_rule` | `map(object)` | `{}` | TCP scale rules keyed by the rule NAME — same shape as `http_scale_rule`. |
| `azure_queue_scale_rule` | `map(object)` | `{}` | Azure Storage queue scale rules keyed by the rule NAME — see the scale-rule section. |
| `custom_scale_rule` | `map(object)` | `{}` | Custom (KEDA) scale rules keyed by the rule NAME — see the scale-rule section. |
| `volume` | `map(object)` | `{}` | Volumes keyed by the volume NAME (containers reference mounts by it) — see the `volume` object table. |

### `container` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Container name: ≤ 46 characters, lowercase alphanumeric/dot/dash, start/end alphanumeric (validated — the provider's own rule). |
| `image` | `string` | — | Image reference `<registry-server>/<repository>:<tag>` (non-empty, validated). |
| `cpu` | `number` | — | vCPU fraction (≥ 0.1, validated). On Consumption profiles, Azure enforces the supported cpu/memory combos at apply (see Notes). |
| `memory` | `string` | — | Memory string, e.g. `0.5Gi`, `1.0Gi`, `2Gi` (non-empty, validated). |
| `args` | `list(string)` | `null` | Arguments to the container's entrypoint. |
| `command` | `list(string)` | `null` | Command overriding the image default, pre-tokenized. |
| `env` | `map(object)` | `{}` | Environment variables keyed by the variable NAME (the key is what the container sees) — see the `env` object table below. |
| `liveness_probe` | `map(object)` | `{}` | Liveness probes keyed by an arbitrary unique ID — see the `probe` shape below. |
| `readiness_probe` | `map(object)` | `{}` | Readiness probes keyed by an arbitrary unique ID — same shape, plus `success_count_threshold`. |
| `startup_probe` | `map(object)` | `{}` | Startup probes keyed by an arbitrary unique ID — same shape as liveness with a wider failure ceiling. |
| `volume_mounts` | `map(object)` | `{}` | Mounts of the app's volumes into this container, keyed by the volume NAME (`template.volume` keys — validated: a mount of an undeclared volume fails at the API) — see the `volume_mounts` object table. |

### `env` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | `null` | Literal value for the variable — either this or `secret_name` (at least one, validated). |
| `secret_name` | `string` | `null` | Name of one of the app's own `secret` entries (validated) whose value becomes the variable's. When both are set, the secret wins and the value is silently dropped (the service's own precedence) — set exactly one. |

### Probe shape (`liveness_probe`/`readiness_probe`/`startup_probe` entries)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `transport` | `string` | — | `TCP`, `HTTP` or `HTTPS` (case-insensitive, normalized to upper). |
| `port` | `number` | — | Probe port (1–65535, validated). |
| `host` | `string` | `null` | Probe hostname (defaults to the pod IP; the `Host` in headers overrides for HTTP/HTTPS). |
| `path` | `string` | `null` | Probe path — HTTP/HTTPS only (rejected on TCP, validated). |
| `header` | `map(object)` | `{}` | Probe request headers keyed by an arbitrary unique ID; entries carry `name` and `value` (name non-empty — validated). |
| `initial_delay` | `number` | `null` | Seconds after start before probing (0–60 — defaults 1/0/0 kinds; validated). |
| `interval_seconds` | `number` | `null` | Seconds between probes (1–240, default 10; validated). |
| `timeout` | `number` | `null` | Seconds before the probe times out (1–240, default 1; validated). |
| `failure_count_threshold` | `number` | `null` | Consecutive failures before the probe trips (default 3) — liveness 1–30, readiness 1–48, startup 1–240 (validated per kind). |
| `success_count_threshold` | `number` | `null` | Consecutive successes before the probe trips (1–10, default 3; validated) — readiness probes only; the input type keeps it off liveness/startup, where the service never reads it. |

### Scale rules

Rules live under `template.<kind>_scale_rule` maps, keyed by the rule
NAME (unique across all kinds within an app, case-insensitively —
validated; KEDA logs and UI speak the name — the key must read as that
name, since the module renders it into the scale rule). For custom rules
the key additionally follows lowercase alphanumeric/dash, ≤ 31 chars,
no `--` (validated). The rules' `authentication`
entries point at the app's own `secret` names (validated), like
`secret` blocks do for env vars.

`http_scale_rule`/`tcp_scale_rule` entries:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `concurrent_requests` | `string` | — | String representation of an integer ≥ 1 (validated — the provider's own type and rule; it is a string, not a number). |
| `authentication` | `map(object)` | `{}` | Optional auth entries keyed arbitrarily; each carries `secret_name` (non-blank; one of the app's own secrets — validated) and `trigger_parameter` (non-blank when set). |

`azure_queue_scale_rule` entries:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `queue_name` | `string` | — | Azure Storage queue name, non-blank (validated). |
| `queue_length` | `number` | — | Target length per replica (≥ 1, validated). |
| `authentication` | `map(object)` | — | Required (≥ 1 entry, validated — the provider enforces): `secret_name` and `trigger_parameter` both non-blank. The storage-agent identity must have rights on the queue (consumer-side RBAC). |

`custom_scale_rule` entries:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `custom_rule_type` | `string` | — | One KEDA type in the provider's list (validated): `activemq`, `artemis-queue`, `kafka`, `pulsar`, `aws-cloudwatch`, `aws-dynamodb`, `aws-dynamodb-streams`, `aws-kinesis-stream`, `aws-sqs-queue`, `azure-app-insights`, `azure-blob`, `azure-data-explorer`, `azure-eventhub`, `azure-log-analytics`, `azure-monitor`, `azure-pipelines`, `azure-servicebus`, `azure-queue`, `cassandra`, `cpu`, `cron`, `datadog`, `elasticsearch`, `external`, `external-push`, `gcp-stackdriver`, `gcp-storage`, `gcp-pubsub`, `graphite`, `http`, `huawei-cloudeye`, `ibmmq`, `influxdb`, `kubernetes-workload`, `liiklus`, `memory`, `metrics-api`, `mongodb`, `mssql`, `mysql`, `nats-jetstream`, `stan`, `tcp`, `new-relic`, `openstack-metric`, `openstack-swift`, `postgresql`, `predictkube`, `prometheus`, `rabbitmq`, `redis`, `redis-cluster`, `redis-sentinel`, `redis-streams`, `redis-cluster-streams`, `redis-sentinel-streams`, `selenium-grid`, `solace-event-queue`, `github-runner`. |
| `metadata` | `map(string)` | — | KEDA trigger parameters — non-empty, all keys/values non-blank (validated; malformed metadata fails at the API). |
| `authentication` | `map(object)` | `{}` | Optional (≥ 1 entry if set — the provider enforces): `secret_name` (one of the app's own secrets — validated) and `trigger_parameter` (required, non-blank — validated). |
| `identity_id` | `string` | `null` | `System` (the provider's spelling) or a user-assigned identity ARM ID — the identity executing the rule. A user-assigned one should be in the app's `identity.identity_ids`. |

### `volume` object

The map key is the volume name (containers reference it in `volume_mounts`,
validated as lowercase alphanumeric/dash ≤ 32, start letter, end
alphanumeric).

| Attribute | Type | Default | Description |
|---|---|---|---|
| `storage_name` | `string` | `null` | Name of the backing `azurerm_container_app_environment_storage` resource (managed elsewhere — see Notes) — required exactly for `AzureFile` and `NfsAzureFile` volumes (validated), never on `EmptyDir`/`Secret` (validated). Lowercase alphanumeric/dash shape ≤ 32, no `--` (validated — the provider's own rule). |
| `storage_type` | `string` | `EmptyDir` | `AzureFile`, `EmptyDir`, `NfsAzureFile` or `Secret` (validated — the provider's own list). |
| `mount_options` | `string` | `null` | Comma-separated mount options — meaningful with `AzureFile` only (documented, not rejected: set with other types it is silently ignored by the service); non-blank when set (validated). |

### `volume_mounts` object (entries)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `path` | `string` | — | Absolute path under the container's filesystem (non-empty, validated). |
| `sub_path` | `string` | `null` | Sub-path inside the volume to mount instead of the root. |

### `ingress` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `target_port` | `number` | — | Container port receiving traffic (1–65535, validated). |
| `exposed_port` | `number` | `null` | Service-side port with `transport = "tcp"` only (1–65535; rejected with other transports — validated). |
| `transport` | `string` | `auto` | `auto`, `http`, `http2` or `tcp` (case-sensitive; validated). |
| `external_enabled` | `bool` | `false` | Public reachability — `true` gives the app an FQDN for the environment's default domain, `false` restricts to in-environment addressing. |
| `allow_insecure_connections` | `bool` | `null` | Permit HTTP traffic to the app's revision. |
| `client_certificate_mode` | `string` | `null` | `ignore` (drop the client cert on forwarding), `accept` (forward it without requiring one) or `require` (demand one; validated). |
| `cors` | `object` | `null` | Optional single CORS block — see the object table. |
| `ip_security_restriction` | `map(object)` | `{}` | IP restrictions keyed by an arbitrary unique ID — see the object table. All entries of one ingress must share one action (validated — mixing is not supported by the service). |
| `traffic_weight` | `map(object)` | — | Traffic weights keyed by an arbitrary unique ID — see the object table. Percentages across entries must sum to exactly 100 (validated — the service rejects any other total). |

### `ingress.traffic_weight` entries

| Attribute | Type | Default | Description |
|---|---|---|---|
| `label` | `string` | `null` | Name prefix for the revision's routing host — gives the entry its own sub-FQDN (e.g. `nightly.app-env-domain`). Non-blank when set (validated). |
| `latest_revision` | `bool` | `false` | The weight targets the app's latest stable revision. |
| `revision_suffix` | `string` | `null` | Target revision by its suffix (non-blank when set, validated) — with `latest_revision = false`, one of the two is required per entry (validated — the provider enforces the same rule). |
| `percentage` | `number` | — | Weighted share 0–100 (validated); all entries sum to exactly 100 (validated). The canonical single-revision weight is `{ latest_revision = true, percentage = 100 }`. |

### `ingress.ip_security_restriction` entries

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Restriction name (non-empty, validated). |
| `action` | `string` | — | `Allow` or `Deny` (case-sensitive; validated) — all entries must share the same action (validated). |
| `ip_address_range` | `string` | — | A single IP address (IPv4 or IPv6) or CIDR block (validated — the provider accepts either). |
| `description` | `string` | `null` | Free-text description of the rule. |

### `ingress.cors` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `allowed_origins` | `list(string)` | — | Origin allow-list, exact scheme+host (at least one; validated). Use `"*"` intentionally — it opens every origin. |
| `allow_credentials_enabled` | `bool` | `false` | Whether the browser may send credentials cross-origin. |
| `allowed_headers` | `list(string)` | `null` | Request headers accepted cross-origin. |
| `allowed_methods` | `list(string)` | `null` | HTTP methods accepted cross-origin (e.g. `GET`, `POST`). |
| `exposed_headers` | `list(string)` | `null` | Response headers the browser may expose to scripts. |
| `max_age_in_seconds` | `number` | `null` | Preflight cache hop (≥ 0, validated). |

## Outputs

| Name | Description |
|---|---|
| `app_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.App/containerApps/<name>`). |
| `app_names` | Map of key => app name. |
| `app_latest_revision_fqdns` | Map of key => the latest revision's FQDN — the URL to hit when `external_enabled = true` (apps without ingress return an empty string). |
| `app_latest_revision_names` | Map of key => the latest revision's name — useful for finding revision-specific logs and split traffic targets. |
| `app_outbound_ip_addresses` | Map of key => the egress IP list downstream services must allow-list. |
| `app_custom_domain_verification_ids` | Map of key => the app's custom-domain verification ID — the `asuid.<custom-domain>` TXT record value (wire it via `azure/dns-records`). Sensitive — see Notes. |
| `app_identity_principal_ids` | Map of key => the system-assigned principal ID (null when there is no identity or a user-assigned-only one) — the value RBAC grants for this app carry. |

## Example

```hcl
container_apps = {
  "api" = {
    name                         = "api-prod"
    resource_group_name          = "rg-platform-prod"
    container_app_environment_id = dependency.cae.outputs.environment_ids["platform"]
    revision_mode                = "Multiple"

    identity = {
      type         = "UserAssigned"
      identity_ids = [dependency.mid.outputs.managed_identity_ids["api-registry"]]
    }
    secret = {
      "db-password" = {
        name  = "db-password"
        value = "example-placeholder"
      }
      "app-connection" = {
        name                = "app-connection"
        key_vault_secret_id = dependency.kv.outputs.secret_ids["app-connection"]
        identity            = "System"
      }
    }
    registry = {
      "primary" = {
        server   = "crplatformprod.azurecr.io"
        identity = dependency.mid.outputs.managed_identity_ids["api-registry"]
      }
    }
    dapr = {
      app_id   = "api"
      app_port = 3000
    }

    template = {
      min_replicas = 1
      max_replicas = 20

      container = {
        "api" = {
          name   = "api"
          image  = "crplatformprod.azurecr.io/api:v1.2.3"
          cpu    = 0.5
          memory = "1.0Gi"
          env = {
            "APP_MODE" = { value = "prod" }
            "DB_PASSWORD" = { secret_name = "db-password" }
          }
          readiness_probe = {
            "http" = {
              transport = "HTTP"
              port      = 3000
              path      = "/ready"
            }
          }
        }
      }

      http_scale_rule = {
        "load" = {
          name                = "http-load"
          concurrent_requests = "100"
        }
      }
    }

    ingress = {
      target_port      = 3000
      external_enabled = true
      traffic_weight = {
        "latest" = {
          latest_revision = true
          percentage      = 100
        }
      }
    }
    tags = {
      app = "api"
    }
  }
  "invoice-processor" = {
    name                         = "invoice-processor-prod"
    resource_group_name          = "rg-platform-prod"
    container_app_environment_id = dependency.cae.outputs.environment_ids["platform"]
    revision_mode                = "Single"

    secret = {
      "kv-identity" = {
        name  = "kv-identity"
        value = "example-placeholder"
      }
    }

    template = {
      container = {
        "processor" = {
          name   = "processor"
          image  = "crplatformprod.azurecr.io/invoice-processor:v3"
          cpu    = 0.25
          memory = "0.5Gi"
        }
      }
      azure_queue_scale_rule = {
        "invoice-queue" = {
          name         = "invoice-queue"
          queue_name   = "invoice-orders"
          queue_length = 5
          authentication = {
            "storage" = {
              secret_name       = "kv-identity"
              trigger_parameter = "identity"
            }
          }
        }
      }
    }
    tags = {
      app = "invoice-processor"
    }
  }
}
```

A downstream unit wires like:

```hcl
dependency "apps" {
  config_path = "../apps"

  mock_outputs = {
    app_latest_revision_fqdns = {
      "api" = "api-prod.example.northeurope.azurecontainerapps.io"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "output"]
}
```

and consumes `dependency.apps.outputs.app_latest_revision_fqdns["api"]`.

## Notes

- **The environment is always external.** This module never creates the
  `azurerm_container_app_environment` — bind via
  `container_app_environment_id` (see `azure/container-app-environment`).
  Every environment change therefore stays in its own unit: apps plan and
  apply without touching env-side force-replacement land mines. The
  corollary: `workload_profile_name` cannot be validated here (it must
  name a profile the external environment defines), and a wrong name
  fails at the Azure API.
- Revision semantics: template/ingress/secret/registry/dapr/identity
  changes are in-place spins of a new revision; `Single` mode tears the
  previous revision down automatically, `Multiple` keeps it alive and
  routeable. `traffic_weight` is required even in `Single` mode (the
  provider marks the block required whenever ingress is set); the
  canonical single-revision weight is `{ latest_revision = true,
  percentage = 100 }`.
- Consumption profile resource ceilings: on Consumption profiles, Azure
  only accepts known cpu/memory combos (0.1/0.5Gi as the minimum,
  0.25/0.5Gi, 0.5/1.0Gi, 1/2Gi, 2/4Gi and so on up to 16/32Gi) — enforced
  at apply, so the module does not guess the table. Dedicated profiles
  scale to the instance counts set in the environment.
- Secrets: plain `value`s land in state in plaintext (they are
  provider-sensitive, and state is the leak vector). Real credentials
  belong behind `key_vault_secret_id` + identity — the identity wire
  (`System` or the ARM ID) and the vault grant (Key Vault Secrets User)
  are consumer IAM work. Secret changes spin a new revision;
  Key Vault-referenced secrets rotate inside the vault without touching
  the app.
- Identity chain: a registry identity (beyond `system`), a scale-rule
  executor identity and a Key Vault-reading secret identity must be
  granted their access downstream — identity wiring here is the list,
  the RBAC grants are consumer IAM work.
- `workload_profile_name` must match the external environment's profile
  name (validated there, not here).
- IP restrictions: `ip_address_range` takes a single IP address OR a
  CIDR block, in either IP version (the provider accepts both shapes) —
  single host IPs behind the scenes become /32 (or /128) rules.
- `container_app_environment_storage` (Azure File/NFS shares) is
  deliberately out of scope: volumes here reference the backing share by
  `storage_name`, and the environment-storage resource belongs to the
  environment unit. Create it consumer-side (or in the environment unit)
  and reference it by name (see also the pass-through list above).
- Not exposed, deliberately (pass-through candidates for a later minor):
  the app-scoped custom-domain certificate binding
  (`azurerm_container_app_custom_domain` — the ingress `custom_domain`
  attribute is now read-only; it is a dedicated resource), Dapr
  components, container jobs (`azurerm_container_app_job`), and identity
  settings (`identitySettings` blocks not yet surfaced by the provider).
- RBAC the caller needs: `Microsoft.App/containerApps/write` (and
  delete) on the resource group.
- The `app_custom_domain_verification_ids` output is sensitive (the
  provider marks the source attribute sensitive); it lands in state and
  anyone with state access can read it.

## Import

```text
tofu import 'azurerm_container_app.container_app["<app_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.App/containerApps/<name>"
```
