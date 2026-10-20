# cloudflare/pages

Map-keyed module for Cloudflare Pages projects with git-source build
config, preview/production deployment configs, and optional custom
domains.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `""` | Fallback account ID used when a project omits its own. |
| `projects` | `map(object)` | — | Map of projects keyed by an arbitrary unique ID. |

### `projects` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Project name: lowercase letters, digits and hyphens (validated). Part of the identity and import ID — renaming forces project replacement and re-attaches its domains. |
| `production_branch` | `string` | — | Git branch deployed to production. |
| `account_id` | `string` | — | Per-project account ID; falls back to `var.account_id`. |
| `build_config` | `object` | — | `{build_caching, build_command, destination_dir, root_dir, web_analytics_tag, web_analytics_token}`. |
| `source` | `object` | — | Git integration: `{type, config}`; `type` one of `github`, `gitlab` (validated), `config` required. Requires an existing Pages git integration on the account. See the `source.config` object table. |
| `deployment_configs` | `object` | — | `{preview, production}`; both sides share one object shape — see the `deployment_configs` side object table. |
| `domains` | `list(string)` | `[]` | Custom domains attached to the project. Keys are the FQDNs themselves (a domain attaches to at most one project; duplicates across projects are rejected at plan time). |

### `source.config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `owner` / `owner_id` | `string` | — | Git repository owner name / id. |
| `repo_name` / `repo_id` | `string` | — | Repository name / id. |
| `production_branch` | `string` | — | Overrides the project-level production branch. |
| `pr_comments_enabled` | `bool` | — | PR commit comments by Pages. |
| `preview_deployment_setting` | `string` | — | `all`, `none` or `custom` (validated). |
| `preview_branch_includes` / `preview_branch_excludes` | `list(string)` | — | Branch patterns; only usable with `preview_deployment_setting = "custom"` (validated). |
| `path_includes` / `path_excludes` | `list(string)` | — | Path patterns filtering builds. |
| `production_deployments_enabled` | `bool` | — | Enable production deployments from the source. |

The deprecated `deployments_enabled` attribute is not exposed.

### `deployment_configs` side object (`preview` / `production`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `compatibility_date` | `string` | — | e.g. `2025-01-01`. |
| `compatibility_flags` | `list(string)` | `[]` | e.g. `nodejs_compat`. |
| `always_use_latest_compatibility_date` | `bool` | — | Ignore pinned compatibility date. |
| `env_vars` | `map(object)` | — | Keyed by variable name; `{type, value}`, both required — `type` one of `plain_text`, `secret_text` (validated). Values are sensitive in state. |
| `build_image_major_version` | `number` | — | Build image version; use `3` — version 1 is retired. |
| `fail_open` | `bool` | — | Serve responses even when the Workers runtime is down. |
| `limits` | `object` | — | `{cpu_ms}`. |
| `placement` | `object` | — | `{mode}`; e.g. `smart`. |
| `kv_namespaces` | `map(object)` | — | Keyed by binding name; `{namespace_id}` — pair with `cloudflare/workers-kv`. |
| `r2_buckets` | `map(object)` | — | Keyed by binding name; `{name, jurisdiction}`. |
| `d1_databases` | `map(object)` | — | Keyed by binding name; `{id}`. |
| `durable_object_namespaces` | `map(object)` | — | Keyed by binding name; `{namespace_id}`. |
| `hyperdrive_bindings` | `map(object)` | — | Keyed by binding name; `{id}`. |
| `queue_producers` | `map(object)` | — | Keyed by binding name; `{name}`. |
| `services` | `map(object)` | — | Keyed by binding name; `{service, entrypoint, environment}`. |
| `mtls_certificates` | `map(object)` | — | Keyed by binding name; `{certificate_id}`. |
| `analytics_engine_datasets` | `map(object)` | — | Keyed by binding name; `{dataset}`. |
| `vectorize_bindings` | `map(object)` | — | Keyed by binding name; `{index_name}`. |
| `ai_bindings` | `map(object)` | — | Keyed by binding name; `{project_id}`. |
| `browsers` | `map(object)` | — | Keyed by binding name; no attributes. |

The deprecated `usage_model` and wrangler-internal `wrangler_config_hash`
are not exposed.

## Outputs

`project_names` — map of project key => project name.
`project_subdomains` — map of project key => `<project>.pages.dev`
subdomain.
`project_domains` — map of project key => all domains serving the project.
`domain_statuses` — map of composite domain key
(`project key/domain`) => status.

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

projects = {
  "docs" = {
    name              = "example-docs"
    production_branch = "main"
    source = {
      type = "github"
      config = {
        owner     = "example-org"
        repo_name = "example-docs"
        preview_deployment_setting = "custom"
        preview_branch_includes    = ["next"]
      }
    }
    build_config = {
      build_command   = "npm run build"
      destination_dir = "dist"
    }
    deployment_configs = {
      production = {
        compatibility_date  = "2025-01-01"
        compatibility_flags = ["nodejs_compat"]
        kv_namespaces = {
          "SESSIONS" = { namespace_id = "5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d" }
        }
        env_vars = {
          "API_URL" = { type = "plain_text", value = "https://api.example.com" }
        }
      }
    }
    domains = ["docs.example.com"]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not project names.
- `source` requires a Pages git integration (Cloudflare GitHub/GitLab
  app) on the account; the module does not create it.
- `cloudflare_pages_domain` does **not** create the DNS record — pair
  with `cloudflare/dns-records` to manage the CNAME. (R2 custom domains
  behave the opposite way: they create the record automatically.)
- Import of a project fails while secret env vars exist on it — remove
  secrets, import, then re-add. Env var values are sensitive in state
  either way.
- Renaming a project forces its replacement and re-attaches its custom
  domains (their `project_name` changes).
- Keys are `project key/domain` for `domain_statuses`.

## Import

`cloudflare_pages_project` ← `<account_id>/<project_name>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/example-docs`.
`cloudflare_pages_domain` ←
`<account_id>/<project_name>/<domain>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/example-docs/docs.example.com`.
