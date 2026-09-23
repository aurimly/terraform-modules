variable "instances" {
  description = "Map of EC2 instances keyed by an arbitrary identifier. Each entry creates one aws_instance."
  type = map(object({
    name                        = string
    instance_type               = string
    subnet_id                   = string
    ami                         = optional(string)
    ami_ssm_parameter           = optional(string)
    associate_public_ip_address = optional(bool)
    key_name                    = optional(string)
    security_group_ids          = optional(list(string), [])
    iam_instance_profile        = optional(string)
    user_data                   = optional(string)
    user_data_replace_on_change = optional(bool, false)
    private_ip                  = optional(string)
    root_block_device = optional(object({
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
      iops                  = optional(number)
      throughput            = optional(number)
      encrypted             = optional(bool)
      kms_key_id            = optional(string)
      delete_on_termination = optional(bool, true)
    }))
    ebs_block_devices = optional(map(object({
      device_name           = string
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
      iops                  = optional(number)
      throughput            = optional(number)
      encrypted             = optional(bool)
      kms_key_id            = optional(string)
      snapshot_id           = optional(string)
      delete_on_termination = optional(bool, true)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for v in var.instances : (v.ami == null) != (v.ami_ssm_parameter == null)])
    error_message = "set exactly one of ami or ami_ssm_parameter (the AMI must come from one of the two)."
  }

  validation {
    condition     = alltrue([for v in var.instances : length(v.name) <= 255])
    error_message = "name must be at most 255 characters (AWS tag-value limit applied to Name)."
  }

  validation {
    condition     = alltrue([for v in var.instances : v.root_block_device == null || contains(["standard", "gp2", "gp3", "io1", "io2", "st1", "sc1"], v.root_block_device.volume_type)])
    error_message = "root_block_device volume_type must be one of standard, gp2, gp3, io1, io2, st1 or sc1 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for v in var.instances : alltrue([for e in v.ebs_block_devices : contains(["standard", "gp2", "gp3", "io1", "io2", "st1", "sc1"], e.volume_type)])])
    error_message = "ebs_block_devices volume_type must be one of standard, gp2, gp3, io1, io2, st1 or sc1 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for v in var.instances : v.root_block_device == null || v.root_block_device.kms_key_id == null || v.root_block_device.encrypted == true])
    error_message = "root_block_device kms_key_id can only be set with encrypted = true (AWS rejects unencrypted volumes with a KMS key)."
  }

  validation {
    condition     = alltrue([for v in var.instances : alltrue([for e in v.ebs_block_devices : e.kms_key_id == null || e.encrypted == true])])
    error_message = "ebs_block_devices kms_key_id can only be set with encrypted = true (AWS rejects unencrypted volumes with a KMS key)."
  }

  validation {
    condition     = alltrue([for v in var.instances : alltrue([for e in v.ebs_block_devices : e.snapshot_id == null || (e.encrypted == null && e.kms_key_id == null)])])
    error_message = "ebs_block_devices snapshot_id cannot be combined with encrypted or kms_key_id (the volume inherits the snapshot's encryption)."
  }

  validation {
    condition     = alltrue([for v in var.instances : v.root_block_device == null || v.root_block_device.throughput == null || v.root_block_device.volume_type == "gp3"])
    error_message = "root_block_device throughput is only valid with volume_type = \"gp3\"."
  }

  validation {
    condition     = alltrue([for v in var.instances : alltrue([for e in v.ebs_block_devices : e.throughput == null || e.volume_type == "gp3"])])
    error_message = "ebs_block_devices throughput is only valid with volume_type = \"gp3\"."
  }
}
