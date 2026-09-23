locals {
  ssm_ami_keys = { for k, v in var.instances : k => v.ami_ssm_parameter if v.ami_ssm_parameter != null }
}

data "aws_ssm_parameter" "ami" {
  for_each = local.ssm_ami_keys

  name = each.value
}

resource "aws_instance" "instance" {
  for_each = var.instances

  ami                         = each.value.ami != null ? each.value.ami : data.aws_ssm_parameter.ami[each.key].value
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  associate_public_ip_address = each.value.associate_public_ip_address
  key_name                    = each.value.key_name
  vpc_security_group_ids      = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null
  iam_instance_profile        = each.value.iam_instance_profile
  user_data                   = each.value.user_data
  user_data_replace_on_change = each.value.user_data_replace_on_change
  private_ip                  = each.value.private_ip

  dynamic "root_block_device" {
    for_each = each.value.root_block_device != null ? [each.value.root_block_device] : []

    content {
      volume_size           = root_block_device.value.volume_size
      volume_type           = root_block_device.value.volume_type
      iops                  = root_block_device.value.iops
      throughput            = root_block_device.value.throughput
      encrypted             = root_block_device.value.encrypted
      kms_key_id            = root_block_device.value.kms_key_id
      delete_on_termination = root_block_device.value.delete_on_termination
    }
  }

  dynamic "ebs_block_device" {
    for_each = each.value.ebs_block_devices

    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      volume_type           = ebs_block_device.value.volume_type
      iops                  = ebs_block_device.value.iops
      throughput            = ebs_block_device.value.throughput
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = ebs_block_device.value.kms_key_id
      snapshot_id           = ebs_block_device.value.snapshot_id
      delete_on_termination = ebs_block_device.value.delete_on_termination
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}
