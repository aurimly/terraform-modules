# aws/ec2-instance

Map-keyed module for AWS EC2 instances. The AMI comes either as an explicit
ID or as the name of an SSM parameter (typically a public AMI alias under
`/aws/service/ami-amazon-linux-latest/...` or a consumer-managed parameter).
The IAM instance profile is a pass-through attribute — profile creation lives
in the `aws/iam-role` module.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | `{}` | Map of instances keyed by an arbitrary unique identifier; each entry also carries its `ebs_block_devices` map. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name tag of the instance; at most 255 characters. Validated client-side. |
| `instance_type` | `string` | — | Instance type, e.g. `t3.micro`. Changing it stops and starts the instance (no replacement; a change crossing CPU architectures forces replacement). |
| `subnet_id` | `string` | — | Subnet to launch into (typically `dependency.subnet.outputs.subnet_ids["main"]` with the `aws/subnet` module). Immutable; changing forces replacement. |
| `ami` | `string` | — | Explicit AMI ID. Exactly one of `ami` or `ami_ssm_parameter` per instance (validated client-side). Immutable; changing forces replacement. |
| `ami_ssm_parameter` | `string` | — | SSM parameter name holding the AMI ID, resolved via the `aws_ssm_parameter` data source. Exactly one of `ami` or `ami_ssm_parameter` per instance (validated client-side). |
| `associate_public_ip_address` | `bool` | — | Assign a public IPv4 address. When unset, the subnet's map-public-IP setting decides. Immutable; changing forces replacement. |
| `key_name` | `string` | — | SSH key pair name. Immutable; changing forces replacement. |
| `security_group_ids` | `list(string)` | `[]` | VPC security group IDs to attach. With none set, the instance falls back to the VPC's default security group. Updates in place. |
| `iam_instance_profile` | `string` | — | Instance profile name or ARN, e.g. `dependency.iam_role.outputs.instance_profile_arns["app"]` with the `aws/iam-role` module. Changing it updates the profile association in place. |
| `user_data` | `string` | — | User data script/cloud-init. Changes stop and start the instance by default (applied without replacement, effective after reboot). |
| `user_data_replace_on_change` | `bool` | `false` | Opt in: make `user_data` changes force replacement instead of stop/start. |
| `private_ip` | `string` | — | Private IPv4 within the subnet. Immutable; changing forces replacement. |
| `root_block_device` | `object` | — | Root EBS volume config — see table below. Omitted: root volume sizing follows the AMI. |
| `ebs_block_devices` | `map(object)` | `{}` | Secondary EBS volumes keyed by an arbitrary identifier — see table below. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `root_block_device` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `volume_size` | `number` | — | Size in GiB. Omitted: AMI default. Updates in place when growing. |
| `volume_type` | `string` | `gp3` | One of `standard`, `gp2`, `gp3`, `io1`, `io2`, `st1`, `sc1` (case-sensitive). Validated client-side. The `gp3` default overrides the provider's AMI-following default. |
| `iops` | `number` | — | Provisioned IOPS (`io1`/`io2` and `gp3`). |
| `throughput` | `number` | — | Provisioned throughput MiB/s, `gp3` only. Validated client-side. |
| `encrypted` | `bool` | — | Encrypt the root volume. Changing it (or `kms_key_id`) forces replacement. |
| `kms_key_id` | `string` | — | KMS key ARN/ID; requires `encrypted = true` (validated client-side). Changing it forces replacement. |
| `delete_on_termination` | `bool` | `true` | Delete the root volume when the instance terminates. |

### `ebs_block_devices` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `device_name` | `string` | — | Device name, e.g. `/dev/sdf`. |
| `volume_size` | `number` | — | Size in GiB. Omitted: snapshot default. |
| `volume_type` | `string` | `gp3` | Same set as the root volume. The `gp3` default overrides the provider's `gp2` default. |
| `iops` | `number` | — | Provisioned IOPS (`io1`/`io2` and `gp3`). |
| `throughput` | `number` | — | Provisioned throughput MiB/s, `gp3` only. Validated client-side. |
| `encrypted` | `bool` | — | Encrypt the volume. Cannot be combined with `snapshot_id` (validated client-side). |
| `kms_key_id` | `string` | — | KMS key ARN/ID; requires `encrypted = true` (validated client-side). Cannot be combined with `snapshot_id`. |
| `snapshot_id` | `string` | — | Snapshot to create the volume from; the volume inherits the snapshot's encryption. |
| `delete_on_termination` | `bool` | `true` | Delete the volume when the instance terminates. |

## Outputs

`instance_ids` — map of instance key => instance ID (`i-...`).
`instance_arns` — map of instance key => instance ARN.
`instance_private_ips` — map of instance key => private IPv4 address.
`instance_public_ips` — map of instance key => public IPv4 address, `null` for instances without one. Covers all instance keys.
`instance_security_group_ids` — map of instance key => security group IDs on the instance's network interface.

## Example

```hcl
instances = {
  "app" = {
    name                 = "example-app"
    instance_type        = "t3.micro"
    subnet_id            = dependency.subnet.outputs.subnet_ids["app"]
    ami_ssm_parameter    = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    security_group_ids   = [dependency.sg.outputs.security_group_ids["app"]]
    iam_instance_profile = dependency.iam_role.outputs.instance_profile_arns["ec2-app"]
    root_block_device = {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
    ebs_block_devices = {
      "data" = {
        device_name = "/dev/sdf"
        volume_size = 50
        volume_type = "gp3"
      }
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Map keys are arbitrary unique identifiers, not resource names — the key
  disambiguates entries that would otherwise share a `name`.
- AMI validity is enforced by the EC2 API at apply time: a stale AMI ID or
  a parameter pointing at a deleted AMI fails there, not at plan time. The
  resolved AMI shows as `(sensitive value)` in plan output (the SSM data
  source marks parameter values sensitive) — cosmetic, nothing sensitive
  about AMI IDs.
- Force replacement if changed: `ami`, `subnet_id`, `key_name`,
  `associate_public_ip_address`, `private_ip`, root volume
  `encrypted`/`kms_key_id`, and `user_data` when
  `user_data_replace_on_change` is `true`.
  Stop/start without replacement: `instance_type` (unless the change
  crosses CPU architectures) and (by default) `user_data`.
- `instance_public_ips` reflects the assigned public IPv4. If the consumer
  attaches an Elastic IP out-of-band, read the address from the EIP
  resource instead — the instance's public IP no longer tracks it.
- The module takes over management of the full set of non-root EBS volumes
  through `ebs_block_device`: the provider cannot automatically detect
  changes to these blocks, devices present on the instance but absent from
  the config are treated as drift, and the block cannot be mixed with
  separate `aws_ebs_volume`/`aws_volume_attachment` resources. Treat the
  `ebs_block_devices` map as the complete device set — every attribute of
  an entry forces instance replacement when changed, since inline EBS
  blocks are never updated in place.
- Removing `root_block_device` from the config after creation does not
  destroy the root volume — the block is optional/computed, so the
  provider keeps the values recorded in state; manage the root volume
  through the same block rather than removing it.
- Attaching security groups is done by ID (the provider's
  `vpc_security_group_ids` argument); never mix with security-group-name
  form (`security_groups`), which only applies to EC2-Classic.

## Import

`aws_instance` — instance ID only: `i-xxxxx`.
