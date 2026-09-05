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
| `modules/gcp/folder-iam` | Google Cloud folder IAM: members, bindings, policy, and audit configs. |
| `modules/gcp/project` | Google Cloud projects. |
| `modules/gcp/project-iam` | Google Cloud project IAM: members, bindings, policy, and audit configs. |
| `modules/gcp/org-policy` | Google Cloud organization policies (org, folder, or project level). |
| `modules/gcp/organization-iam` | Google Cloud organization IAM: members, bindings, policy, and audit configs. |
| `modules/gcp/service-account` | Google Cloud service accounts. |
| `modules/gcp/service-account-iam` | Google Cloud service account IAM: members, bindings, and policies. |
| `modules/gcp/firewall` | Google Cloud firewall rules (allow/deny) in a VPC network. |
| `modules/gcp/nat` | Google Cloud Router and Cloud NAT gateways. |
| `modules/gcp/static_ip` | Google Cloud regional and global static IP addresses. |
| `modules/gcp/subnet` | Google Cloud subnetworks in a VPC network. |
| `modules/gcp/vpc` | Google Cloud VPC networks. |
| `modules/stackit/folder` | STACKIT Resource Manager folders under an organization or parent folder. |
| `modules/stackit/project` | STACKIT Resource Manager projects under an organization or folder. |
| `modules/stackit/organization_role_assignment` | STACKIT authorization role assignments on an organization. |
| `modules/stackit/folder_role_assignment` | STACKIT authorization role assignments on a folder. |
| `modules/stackit/project_role_assignment` | STACKIT authorization role assignments on a project. |
| `modules/stackit/service_account_role_assignment` | STACKIT authorization 'Act-As' role assignments on a service account. |
| `modules/stackit/service_account` | STACKIT service accounts in a project (email and service account ID). |

All modules are map-keyed. Pin with `?ref=vX.Y.Z` at the consumer side.

## Support

These modules are open source and free to use. For help architecting or
managing Terraform infrastructure at scale, [xtralinux.com](https://xtralinux.com)
offers consulting and managed IaC — [get in touch](https://xtralinux.com).
