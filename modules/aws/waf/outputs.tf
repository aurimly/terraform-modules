output "ip_set_arns" {
  description = "Map of ip set key => IP set ARN."
  value       = { for k, s in aws_wafv2_ip_set.ip_set : k => s.arn }
}

output "web_acl_arns" {
  description = "Map of web ACL key => web ACL ARN."
  value       = { for k, a in aws_wafv2_web_acl.web_acl : k => a.arn }
}

output "web_acl_ids" {
  description = "Map of web ACL key => web ACL id (what a CloudFront distribution's web_acl_id expects for a CLOUDFRONT-scope ACL)."
  value       = { for k, a in aws_wafv2_web_acl.web_acl : k => a.id }
}

output "rule_group_arns" {
  description = "Map of rule group key => rule group ARN."
  value       = { for k, g in aws_wafv2_rule_group.rule_group : k => g.arn }
}

output "association_ids" {
  description = "Map of association key => association id."
  value       = { for k, a in aws_wafv2_web_acl_association.association : k => a.id }
}
