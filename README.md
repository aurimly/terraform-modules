# Terraform Modules

Reusable OpenTofu/Terraform modules maintained and offered by [xtralinux.com](https://xtralinux.com).

## Modules

| Module | Description |
|---|---|
| `modules/cloudflare/zone` | Cloudflare zones and granular zone settings. |
| `modules/cloudflare/dns-records` | Cloudflare DNS records in a single zone. |
| `modules/cloudflare/worker-domains` | Cloudflare Workers custom domains. |
| `modules/github/repository` | GitHub repository settings and branch protection. |
| `modules/gcp/folder` | Google Cloud folders under an organization or parent folder. |
| `modules/gcp/project` | Google Cloud projects. |

All modules are map-keyed. Pin with `?ref=vX.Y.Z` at the consumer side.

## Support

These modules are open source and free to use. For help architecting or
managing Terraform infrastructure at scale, [xtralinux.com](https://xtralinux.com)
offers consulting and managed IaC — [get in touch](https://xtralinux.com).
