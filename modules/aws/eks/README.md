# aws/eks

Map-keyed module for Amazon EKS: clusters (standard and Auto Mode), managed
node groups, add-on management, access entries and access policy
associations, and an optional OIDC provider per cluster for IRSA.

> **Provider floor** — developed against the `aws` provider v6.x; several
> attributes used here (`access_config`, the
> `resolve_conflicts_on_create`/`resolve_conflicts_on_update` split,
> `node_repair_config` counts) only stabilized through the 6.x series:
> pin v6 or newer on the consumer side.

## Destroy semantics (read before using)

- Removing a key destroys the cluster together with every child keyed under
  it. Node groups, add-ons, access entries and policy associations resolve
  their cluster name from the cluster resource, so Terraform orders children
  before the cluster on destroy. Draining Kubernetes workloads is still the
  operator's job: pod disruption budgets block node drains while node groups
  delete, and `force_update_version` only helps updates, not deletes.
- Cluster destruction takes roughly 5-15 minutes. `deletion_protection`
  blocks API deletion until it is unset (set it via the input first).
- Destroying the OIDC provider (disabling `create_oidc_provider` or
  deleting the cluster entry) breaks IRSA for every service account on
  that cluster: role trust conditions referencing the issuer stop resolving.
- Node group renames (`name`) create a new group and destroy the old one
  (new ASG, nodes recreated). `remote_access`/`launch_template` switches and
  spot-to-on-demand capacity changes are not in-place either. Version,
  scaling, label, taint and update-config changes update in place.
- Add-ons: `preserve = true` deletes only the add-on object from the EKS
  control plane and leaves its Kubernetes resources (Deployments, DaemonSets)
  on the cluster; removing an add-on key without it deletes those resources.
- Access entries and policy associations delete cleanly; deleting an entry
  revokes that principal's cluster access immediately.
- Clearing all five input maps tears down child resources while keeping any
  listed clusters — useful to hand a cluster over to another stack.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | `{}` | Map of clusters keyed by an arbitrary unique ID. |
| `node_groups` | `map(object)` | `{}` | Map of managed node groups keyed by an arbitrary unique ID; each entry references its cluster by `cluster_key`. |
| `addons` | `map(object)` | `{}` | Map of add-ons keyed by an arbitrary unique ID; each entry references its cluster by `cluster_key`. |
| `access_entries` | `map(object)` | `{}` | Map of access entries keyed by an arbitrary unique ID; each entry references its cluster by `cluster_key`. |
| `access_policy_associations` | `map(object)` | `{}` | Map of access policy associations keyed by an arbitrary unique ID; each entry references its cluster by `cluster_key`. |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cluster name, 1-100 characters, letter/digit start (validated). |
| `role_arn` | `string` | — | ARN of the cluster role. Needs `AmazonEKSClusterPolicy` attached — pair with the `aws/iam-role` module (trust policy `Service = eks.amazonaws.com`). |
| `version` | `string` | — | Desired Kubernetes version; omit for the latest available, set to upgrade (no EKS-internal downgrades). |
| `enabled_cluster_log_types` | `list(string)` | `[]` | Control plane log types, from `api`, `audit`, `authenticator`, `controllerManager`, `scheduler` (validated). Log groups live in the `aws/cloudwatch` module — without them logs are dropped. |
| `deletion_protection` | `bool` | — | Blocks API deletion until disabled. |
| `force_update_version` | `bool` | — | Override upgrade-blocking readiness checks on version updates. |
| `bootstrap_self_managed_addons` | `bool` | `true` | Install the default unmanaged add-ons (`aws-cni`, `kube-proxy`, CoreDNS) at creation. Changing this forces a new cluster. Auto Mode requires `false`. |
| `create_oidc_provider` | `bool` | `false` | Also create one `aws_iam_openid_connect_provider` for the cluster's issuer URL — required for IRSA and for `service_account_role_arn` on add-ons. |
| `oidc_client_id_list` | `list(string)` | `["sts.amazonaws.com"]` | Audiences on the OIDC provider. |
| `oidc_thumbprint_list` | `list(string)` | — | Explicit thumbprints to pin; omit unless the account is a private PKI edge case (AWS serves trusted roots). |
| `access_config` | `object` | — | `{authentication_mode, bootstrap_cluster_creator_admin_permissions}`. Mode is `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP` (validated). Access entries/policy associations in this module require `API` or `API_AND_CONFIG_MAP`. |
| `encryption_config` | `object` | — | `{resources, key_arn}` — envelope encryption of secrets resource(s); every `resources` entry must be `secrets` (validated). Key must be a symmetric KMS CMK in the same region (pair with `aws/kms`). |
| `kubernetes_network_config` | `object` | — | `{ip_family, service_ipv4_cidr, elastic_load_balancing}`. `ip_family` is `ipv4`/`ipv6` (validated, settable only at creation); `service_ipv4_cidr` is settable only at creation; `elastic_load_balancing` is `{enabled}` — an Auto Mode capability. |
| `compute_config` | `object` | — | EKS Auto Mode: `{enabled, node_pools, node_role_arn}`. See the Auto Mode notes below; `node_pools` and `node_role_arn` must be set together (validated). |
| `storage_config` | `object` | — | Auto Mode capability block: `{block_storage: {enabled}}`. |
| `upgrade_policy` | `object` | — | `{support_type}` — `EXTENDED` or `STANDARD` (validated). |
| `zonal_shift_config` | `object` | — | `{enabled}` — Route 53 ARC zonal shift. |
| `vpc_config` | `object` | — | `{subnet_ids, security_group_ids, endpoint_private_access, endpoint_public_access, public_access_cidrs}`. At least two subnets (validated); the API requires the subnets to span different AZs. Pairs with the `aws/subnet` module. Defaults: public access on, private off — set both explicitly for private-only clusters. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `node_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_key` | `string` | — | Key of the cluster entry this node group belongs to (checked at plan/apply; a wrong key errors before any resource is created). |
| `name` | `string` | — | Node group name, 63 characters max, letter/digit start (validated), unique per cluster. |
| `node_role_arn` | `string` | — | ARN of the node group role. Needs `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly` — pair with the `aws/iam-role` module (trust `Service = ec2.amazonaws.com`). |
| `subnet_ids` | `list(string)` | — | Subnets for the group's nodes. |
| `instance_types` | `list(string)` | — | EC2 instance types; defaults to `t3.medium`. |
| `ami_type` | `string` | — | AMI type (`AL2023_x86_64_STANDARD`, `AL2023_ARM_64_STANDARD`, etc.) — the list drifts with Kubernetes releases, see the AWS docs. |
| `capacity_type` | `string` | — | `ON_DEMAND` or `SPOT` (validated, settable only at creation). |
| `disk_size` | `number` | — | Root EBS size; 20 GiB default (50 for Windows AMIs). |
| `labels` | `map(string)` | `{}` | Kubernetes labels applied through the EKS API. |
| `version` | `string` | — | Kubernetes version; defaults to the cluster version. |
| `release_version` | `string` | — | AMI release version. Setting it with `version` is the documented AMI-tracking pattern (SSM parameter pairing), not a conflict. |
| `force_update_version` | `bool` | — | Force node replacement past blocking PDBs during updates. |
| `scaling_config` | `object` | — | `{desired_size, min_size, max_size}` — all required, `min <= desired <= max` (validated). Desired size supports external autoscaling per the provider docs (`lifecycle` `ignore_changes` on `scaling_config[0].desired_size` consumer-side when an autoscaler manages the count). |
| `taints` | `list(object)` | `[]` | `{key, value, effect}` — effect is `NO_SCHEDULE`, `NO_EXECUTE` or `PREFER_NO_SCHEDULE` (validated); up to 50 per group. |
| `remote_access` | `object` | — | `{ec2_ssh_key, source_security_group_ids}`. Conflicts with `launch_template` (validated). Omitting `source_security_group_ids` with an SSH key opens port 22 to the internet. |
| `launch_template` | `object` | — | `{id, name, version}` — exactly one of `id`/`name` (validated), `version` always (use the template's `latest_version`/`default_version`; `$Latest` flips on read). |
| `update_config` | `object` | — | `{max_unavailable, max_unavailable_percentage, update_strategy}` — exactly one of count/percentage (validated). |
| `node_repair_config` | `object` | — | `{enabled, max_parallel_nodes_repaired_count, max_parallel_nodes_repaired_percentage, max_unhealthy_node_threshold_count, max_unhealthy_node_threshold_percentage}` — each pair is count XOR percentage (validated). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `addons` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_key` | `string` | — | Key of the cluster entry the add-on belongs to. |
| `addon_name` | `string` | — | Add-on name as listed by `eks describe-addon-versions`, unique per cluster (validated). |
| `addon_version` | `string` | — | Add-on version as listed by `describe-addon-versions`; omit for default. |
| `resolve_conflicts_on_create` | `string` | — | `NONE` or `OVERWRITE` — conflict handling when migrating a self-managed add-on. |
| `resolve_conflicts_on_update` | `string` | — | `NONE`, `OVERWRITE` or `PRESERVE` — conflict handling when a value diverges from the EKS default. |
| `service_account_role_arn` | `string` | — | IAM role bound to the add-on service account; requires the cluster OIDC provider (`create_oidc_provider = true`, or consumer-managed). |
| `preserve` | `bool` | — | Keep the Kubernetes resources when the add-on is destroyed. |
| `configuration_values` | `string` | — | JSON string of add-on configuration (pass `jsonencode({...})`). |
| `pod_identity_association` | `list(object)` | `[]` | `{role_arn, service_account}` pairs created as EKS Pod Identity associations along with the add-on. |
| `tags` | `map(string)` | `{}` | Tags passed through as set (no natural name to merge). |

### `access_entries` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_key` | `string` | — | Key of the cluster entry the access entry belongs to. |
| `principal_arn` | `string` | — | IAM principal allowed access, unique per cluster (validated). |
| `type` | `string` | `STANDARD` | `STANDARD`, `EC2_LINUX`, `EC2_WINDOWS` or `FARGATE_LINUX` (validated). |
| `user_name` | `string` | — | Kubernetes username; defaults to the principal ARN (or assume-role/session name). |
| `kubernetes_groups` | `list(string)` | `[]` | RBAC groups for the entry. |
| `tags` | `map(string)` | `{}` | Tags passed through as set. |

### `access_policy_associations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_key` | `string` | — | Key of the cluster entry the association belongs to. |
| `principal_arn` | `string` | — | Principal granted the policy (usually also present in `access_entries`). |
| `policy_arn` | `string` | — | Cluster access policy ARN, e.g. `arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy`. |
| `access_scope` | `object` | — | `{type, namespaces}` — type `cluster` or `namespace` (validated); `namespace` requires a non-empty `namespaces` list (validated). |

## Outputs

`cluster_names`, `cluster_arns` — maps of cluster key => name/ARN.
`cluster_endpoints`, `cluster_certificate_authorities` — maps of cluster key => API endpoint / base64 CA data.
`cluster_versions`, `cluster_platform_versions`, `cluster_statuses` — maps of cluster key => resolved version/platform/status.
`cluster_oidc_issuer_urls` — map of cluster key => issuer URL (present for every cluster).
`oidc_provider_arns` — map of cluster key => provider ARN, only where `create_oidc_provider = true`.
`node_group_names`, `node_group_arns`, `node_group_statuses` — maps of `"clusterKey.groupKey"` key => name/ARN/status.
`node_group_asg_names` — map of `"clusterKey.groupKey"` key => list of Auto Scaling Group names.
`addon_arns`, `addon_ids` — maps of `"clusterKey.addonKey"` key => ARN / `cluster:addon` ID.
`access_entry_arns` — map of `"clusterKey.entryKey"` key => ARN.
`access_policy_association_ids` — map of `"clusterKey.assocKey"` key => `cluster#principal#policy` ID.

## Example

```hcl
clusters = {
  "main" = {
    name     = "example-main"
    role_arn = dependency.iam_roles.outputs.arns["cluster"]
    version  = "1.34"

    enabled_cluster_log_types = ["api", "audit"]

    access_config = {
      authentication_mode                         = "API"
      bootstrap_cluster_creator_admin_permissions = true
    }

    create_oidc_provider = true

    vpc_config = {
      subnet_ids              = dependency.network.outputs.private_subnet_ids
      endpoint_private_access = true
      endpoint_public_access  = true
      public_access_cidrs     = ["10.0.0.0/8"]
    }

    tags = {
      Environment = "example"
    }
  },
  "auto" = {
    name       = "example-auto"
    role_arn   = dependency.iam_roles.outputs.arns["auto-cluster"]
    version    = "1.34"

    bootstrap_self_managed_addons = false

    compute_config = {
      enabled       = true
      node_pools    = ["general-purpose"]
      node_role_arn = dependency.iam_roles.outputs.arns["auto-node"]
    }

    kubernetes_network_config = {
      elastic_load_balancing = { enabled = true }
    }

    storage_config = {
      block_storage = { enabled = true }
    }

    access_config = {
      authentication_mode = "API"
    }

    vpc_config = {
      subnet_ids              = dependency.network.outputs.private_subnet_ids
      endpoint_private_access = true
    }
  },
}

node_groups = {
  "system" = {
    cluster_key   = "main"
    name          = "example-system"
    node_role_arn = dependency.iam_roles.outputs.arns["worker"]
    subnet_ids    = dependency.network.outputs.private_subnet_ids

    instance_types = ["m6i.large"]
    capacity_type  = "ON_DEMAND"

    scaling_config = {
      desired_size = 2
      min_size     = 1
      max_size     = 3
    }

    labels = { "workload" = "examples" }

    taints = [
      { key = "examples", value = "true", effect = "NO_SCHEDULE" }
    ]

    update_config = {
      max_unavailable_percentage = 33
    }
  },
}

addons = {
  "vpc-cni" = {
    cluster_key = "main"
    addon_name  = "vpc-cni"

    resolve_conflicts_on_update = "OVERWRITE"
  },
  "coredns" = {
    cluster_key = "main"
    addon_name  = "coredns"

    service_account_role_arn = dependency.iam_roles.outputs.arns["coredns"]

    resolve_conflicts_on_update = "OVERWRITE"
  },
}

access_entries = {
  "admins" = {
    cluster_key   = "main"
    principal_arn = dependency.iam_roles.outputs.arns["admin-role"]
  },
}

access_policy_associations = {
  "admins" = {
    cluster_key   = "main"
    principal_arn = dependency.iam_roles.outputs.arns["admin-role"]
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope = {
      type = "cluster"
    }
  },
  "viewers" = {
    cluster_key   = "main"
    principal_arn = dependency.iam_roles.outputs.arns["viewer-role"]
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

    access_scope = {
      type       = "namespace"
      namespaces = ["examples"]
    }
  },
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names. Child maps use
  composite `"clusterKey.groupKey"`-style keys (the dot is reserved — map
  keys containing it are rejected at plan time).
- IRSA: for each cluster, use `cluster_oidc_issuer_urls` and
  `oidc_provider_arns` with the `aws/iam-role` module trust condition
  (`StringEquals` on the issuer host of the cluster URL with the value
  `system:serviceaccount:namespace:name`),
  and `service_account_role_arn` on add-ons only where an OIDC provider exists.
- Auto Mode: the cluster role needs `AmazonEKSClusterPolicy` plus
  `AmazonEKSComputePolicy`, `AmazonEKSBlockStoragePolicy`,
  `AmazonEKSLoadBalancingPolicy`, `AmazonEKSNetworkingPolicy`; the Auto Mode
  node role (needed only when `node_pools` is non-empty) needs
  `AmazonEKSWorkerNodeMinimalPolicy` + `AmazonEC2ContainerRegistryPullOnly`.
  `compute_config.node_role_arn` cannot change after compute is enabled.
- Auto Mode manages `vpc-cni`, `kube-proxy`, `coredns` and `aws-ebs-csi-driver`
  itself and pre-installs `eks-pod-identity-agent` — do not add those via
  `addons` (it would duplicate Auto Mode's management). `bootstrap_self_managed_addons = false` only stops the
  bootstrap of self-managed add-ons, not Auto Mode's own management. A cluster
  with an empty `node_pools` list disables both built-in pools (custom
  NodePools are Karpenter-managed) and needs no node role.
- Managed node groups can coexist with Auto Mode — two node-management paths
  on one cluster, consumer choice; nothing in the module forces either way.
- Access entries of type `EC2_LINUX`, `EC2_WINDOWS`, `FARGATE_LINUX` cannot
  carry `user_name`/`kubernetes_groups` (validated) and cannot be the target
  of policy associations — keep those `STANDARD`.
- Policy-association uniqueness in the API is the `(principal_arn, policy_arn)`
  pair per cluster.
- The OIDC provider resource is account-level (one provider per issuer URL in
  the account); this module creates one entry per cluster only where
  `create_oidc_provider = true`.
- `cluster_id` is Outpost-only and never populated for cloud clusters — it is
  intentionally not exposed; use `cluster_names` (which is what the cluster
  resource's `id` contains).
- Provider default timeouts, where consumer CI wraps applies: cluster create
  30m / update 60m / delete 15m; node group and add-on operations run 60m and
  20m-40m respectively.

## Import

`aws_eks_cluster` ← cluster name.
`aws_eks_node_group` ← `cluster_name:node_group_name`.
`aws_eks_addon` ← `cluster_name:addon_name`.
`aws_eks_access_entry` ← `cluster_name:principal_arn`.
`aws_eks_access_policy_association` ← `cluster_name#principal_arn#policy_arn`.
`aws_iam_openid_connect_provider` ← provider ARN.
