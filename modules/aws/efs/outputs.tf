output "file_system_ids" {
  description = "Map of file system key => file system ID (fs-...)."
  value       = { for k, t in aws_efs_file_system.fs : k => t.id }
}

output "file_system_arns" {
  description = "Map of file system key => file system ARN."
  value       = { for k, t in aws_efs_file_system.fs : k => t.arn }
}

output "file_system_dns_names" {
  description = "Map of file system key => DNS name of the file system (the mount address, e.g. fs-xxxx.efs.region.amazonaws.com)."
  value       = { for k, t in aws_efs_file_system.fs : k => t.dns_name }
}

output "mount_target_ids" {
  description = "Map of composite \"fsKey.mtKey\" key => mount target ID (fsmt-...)."
  value       = { for k, m in aws_efs_mount_target.mount_target : k => m.id }
}

output "mount_target_ip_addresses" {
  description = "Map of composite \"fsKey.mtKey\" key => mount target IP address."
  value       = { for k, m in aws_efs_mount_target.mount_target : k => m.ip_address }
}

output "mount_target_network_interface_ids" {
  description = "Map of composite \"fsKey.mtKey\" key => ENI ID created for the mount target."
  value       = { for k, m in aws_efs_mount_target.mount_target : k => m.network_interface_id }
}

output "access_point_ids" {
  description = "Map of composite \"fsKey.apKey\" key => access point ID (fsap-...)."
  value       = { for k, a in aws_efs_access_point.access_point : k => a.id }
}

output "access_point_arns" {
  description = "Map of composite \"fsKey.apKey\" key => access point ARN (use in IAM/POSIX client policies)."
  value       = { for k, a in aws_efs_access_point.access_point : k => a.arn }
}
