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
| `modules/gcp/bucket` | Google Cloud Storage buckets with optional IAM bindings. |
| `modules/gcp/billing-budget` | Google Cloud billing budgets with threshold and notification rules. |
| `modules/gcp/project-services` | Google Cloud project API (service) enablement. |
| `modules/gcp/compute-instance` | Google Cloud compute instances with optional disks and IAM bindings. |
| `modules/gcp/instance-group-manager` | Google Cloud zonal managed instance groups with optional autoscaling. |
| `modules/gcp/instance-template` | Google Cloud instance templates for managed instance groups. |
| `modules/gcp/firewall` | Google Cloud firewall rules (allow/deny) in a VPC network. |
| `modules/gcp/nat` | Google Cloud Router and Cloud NAT gateways. |
| `modules/gcp/static-ip` | Google Cloud regional and global static IP addresses. |
| `modules/gcp/subnet` | Google Cloud subnetworks in a VPC network. |
| `modules/gcp/vpc` | Google Cloud VPC networks. |
| `modules/gcp/gke` | Google Kubernetes Engine clusters with node pools and backup plans. |
| `modules/gcp/load-balancer` | Google Cloud load balancing: health checks, backend services/buckets, URL maps, target proxies, and forwarding rules. |
| `modules/gcp/kms` | Google Cloud KMS key rings, crypto keys, and IAM bindings. |
| `modules/gcp/private-service-connect` | Google Cloud Private Services Access: VPC peering ranges and service networking connections. |
| `modules/gcp/filestore` | Google Cloud Filestore instances with optional backups. |
| `modules/gcp/artifact-registry` | Google Cloud Artifact Registry repositories with optional IAM bindings. |
| `modules/gcp/cloud-armor` | Google Cloud Armor security policies: IP rules, preconfigured WAF rules, rate limiting, redirects, and adaptive protection. |
| `modules/gcp/managed-ssl-certificate` | Google-managed SSL certificates for load balancer target proxies. |
| `modules/gcp/ssl-policy` | Google Cloud SSL policies for target HTTPS proxies. |
| `modules/gcp/shared-vpc` | Google Cloud Shared VPC host enablement and service project attachment. |
| `modules/gcp/psc-endpoint` | Google Cloud Private Service Connect consumer endpoints: internal IPs and forwarding rules targeting service attachments. |
| `modules/gcp/logging` | Google Cloud log sinks to Cloud Storage, Pub/Sub, BigQuery, or Cloud Logging with filters and exclusions. |
| `modules/gcp/iam-custom-role` | Google Cloud custom IAM roles at organization or project level. |
| `modules/gcp/cloud-sql` | Google Cloud SQL PostgreSQL/MySQL instances with optional read replicas. |
| `modules/gcp/memorystore` | Google Cloud Memorystore Redis/Valkey instances. |
| `modules/gcp/dns-zone` | Google Cloud DNS managed zones: public, private, forwarding, and peering zones. |
| `modules/gcp/dns-record-sets` | Google Cloud DNS resource record sets in a single managed zone, with weighted/geo/primary-backup routing policies. |
| `modules/gcp/cloud-run` | Google Cloud Run services with optional IAM bindings. |
| `modules/gcp/monitoring` | Google Cloud Monitoring dashboards and alert policies. |
| `modules/gcp/secret-manager` | Google Secret Manager secrets with optional versions, replication, rotation, and IAM bindings. |
| `modules/gcp/pubsub` | Google Pub/Sub topics with nested subscriptions (push/pull/BigQuery/Cloud Storage) and IAM bindings. |
| `modules/gcp/workload-identity-federation` | Google Workload Identity Federation pools, providers (OIDC/SAML/AWS/X.509), and service account token-creator grants. |
| `modules/stackit/folder` | STACKIT Resource Manager folders under an organization or parent folder. |
| `modules/stackit/project` | STACKIT Resource Manager projects under an organization or folder. |
| `modules/stackit/organization_role_assignment` | STACKIT authorization role assignments on an organization. |
| `modules/stackit/folder_role_assignment` | STACKIT authorization role assignments on a folder. |
| `modules/stackit/project_role_assignment` | STACKIT authorization role assignments on a project. |
| `modules/stackit/service_account_role_assignment` | STACKIT authorization 'Act-As' role assignments on a service account. |
| `modules/stackit/service_account` | STACKIT service accounts in a project (email and service account ID). |
| `modules/stackit/network` | STACKIT virtual networks with IPv4/IPv6 prefixes, gateways, nameservers, and DHCP. |
| `modules/stackit/security_group` | STACKIT security groups with optional inline security group rules. |
| `modules/stackit/public_ip` | STACKIT public IP addresses, optionally associated with a network interface. |
| `modules/stackit/load_balancer` | STACKIT load balancers with listeners, target pools, and targets. |
| `modules/stackit/object_storage` | STACKIT Object Storage buckets, credentials groups, and credentials. |
| `modules/stackit/ske` | STACKIT Kubernetes Engine clusters with node pools and optional kubeconfigs. |
| `modules/stackit/server` | STACKIT servers (virtual machines) booting from an image or boot volume. |
| `modules/stackit/volume` | STACKIT block-storage volumes, optionally created from an image/snapshot source. |
| `modules/stackit/image` | STACKIT images uploaded from local image files. |
| `modules/stackit/key_pair` | STACKIT SSH key pairs for server authentication. |
| `modules/stackit/dns_zone` | STACKIT DNS zones (primary/secondary) with SOA tuning and reverse-zone support. |
| `modules/stackit/dns_record_set` | STACKIT DNS record sets (A, AAAA, CNAME, MX, TXT, ...) inside a DNS zone. |
| `modules/stackit/secrets_manager` | STACKIT Secrets Manager instances with ACLs and optional KMS encryption. |
| `modules/stackit/postgresflex_instance` | STACKIT PostgreSQL Flex instances with storage, flavor, network ACL, and backup schedule. |
| `modules/stackit/postgresflex_database` | STACKIT PostgreSQL Flex databases inside an existing instance. |
| `modules/stackit/postgresflex_user` | STACKIT PostgreSQL Flex database users with roles and API-generated passwords. |
| `modules/stackit/secrets_manager_user` | STACKIT Secrets Manager users with auto-generated credentials. |

All modules are map-keyed. Pin with `?ref=vX.Y.Z` at the consumer side.

## Support

These modules are open source and free to use. For help architecting or
managing Terraform infrastructure at scale, [xtralinux.com](https://xtralinux.com)
offers consulting and managed IaC — [get in touch](https://xtralinux.com).

## License

These modules are released under the MIT License — see [LICENSE](LICENSE).
