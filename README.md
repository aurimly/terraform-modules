# Terraform Modules

Reusable OpenTofu/Terraform modules. See `AGENTS.md` for conventions.

## Modules

| Module | Description |
|---|---|
| `modules/cloudflare/zone` | Cloudflare zones and granular zone settings. |
| `modules/cloudflare/dns-records` | Cloudflare DNS records in a single zone. |
| `modules/cloudflare/worker-domains` | Cloudflare Workers custom domains. |
| `modules/github/repository` | GitHub repository settings and branch protection. |
| `modules/gcp/project` | Google Cloud projects. |

All modules are map-keyed. Pin with `?ref=vX.Y.Z` at the consumer side.
