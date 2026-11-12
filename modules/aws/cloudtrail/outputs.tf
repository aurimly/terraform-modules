output "trail_arns" {
  description = "Map of trail key => trail ARN (also the aws_cloudtrail import ID — id and ARN are the same for this resource)."
  value       = { for k, t in aws_cloudtrail.trail : k => t.arn }
}

output "trail_home_regions" {
  description = "Map of trail key => home region (the region the trail was created in; multi-region trails are managed from there)."
  value       = { for k, t in aws_cloudtrail.trail : k => t.home_region }
}
