# gcp/shared-vpc

Map-keyed module for Shared VPC host enablement and service project
attachment. This module only flips the host flag and attaches service
projects — subnet-level IAM (`compute.networkUser` for the service projects'
agents on selected subnets) is not done here; pair with `gcp/project-iam` or
`gcp/subnet`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `host_projects` | `map(object)` | — | Map of host projects keyed by an arbitrary unique ID. |

### `host_projects` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | The subject project — the project that becomes/hosts Shared VPC. There is no provider-project default: this is the resource's subject, not a location override (format validated). |
| `service_projects` | `list(string)` | `[]` | Project IDs to attach to this host (format validated, globally unique across all entries — a project can attach to at most one host, validated; a host cannot attach itself, validated). |
| `host_deletion_policy` | `string` | `DELETE` | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `service_deletion_policy` | `string` | — | `ABANDON` (validated — `ABANDON` is the only accepted value for service project attachments; unset leaves the provider default `DELETE`-and-remove behavior). |

## Outputs

`host_project_ids` — map of host key => host project id.
`attached_service_projects` — map of composite key (`host key/service project
id`) => attached service project id.
`service_project_hosts` — map of composite key => host project id the service
project is attached to.

## Example

```hcl
host_projects = {
  "prd" = {
    project_id       = "example-host-prd"
    service_projects = ["example-svc-a", "example-svc-b"]
  },
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- IAM context required outside this module: `roles/compute.xpnAdmin` at the
  org or folder level to enable the host, and `roles/compute.networkUser`
  (or `compute.networkAdmin`) wiring so the service projects' agents can use
  host subnets.
- Detaching a service project out-of-band and re-applying repairs cleanly
  with `service_deletion_policy = "ABANDON"` — without it, Terraform tries to
  remove the attachment it no longer sees.
- Service project attachments always detach before the host flag is disabled:
  the service resources reference the host resource, so Terraform's destroy
  ordering gives the dependency ordering for free.

## Import

`google_compute_shared_vpc_host_project` ← the bare project id
(`{project_id}`).
`google_compute_shared_vpc_service_project` ←
`{host_project_id}/{service_project_id}`.
