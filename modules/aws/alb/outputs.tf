output "lb_arns" {
  description = "Map of load balancer key => LB ARN."
  value       = { for k, lb in aws_lb.lb : k => lb.arn }
}

output "lb_ids" {
  description = "Map of load balancer key => LB ID (the ARN)."
  value       = { for k, lb in aws_lb.lb : k => lb.id }
}

output "lb_dns_names" {
  description = "Map of load balancer key => DNS name of the LB."
  value       = { for k, lb in aws_lb.lb : k => lb.dns_name }
}

output "lb_zone_ids" {
  description = "Map of load balancer key => Route 53 hosted zone ID of the LB (for alias records)."
  value       = { for k, lb in aws_lb.lb : k => lb.zone_id }
}

output "lb_listener_arns" {
  description = "Map of \"lb-key.listener-key\" => listener ARN."
  value       = { for k, l in aws_lb_listener.listener : k => l.arn }
}

output "target_group_arns" {
  description = "Map of \"lb-key.target-group-key\" => target group ARN."
  value       = { for k, tg in aws_lb_target_group.target_group : k => tg.arn }
}

output "target_group_names" {
  description = "Map of \"lb-key.target-group-key\" => target group name."
  value       = { for k, tg in aws_lb_target_group.target_group : k => tg.name }
}

output "listener_rule_arns" {
  description = "Map of \"lb-key.listener-key.rule-key\" => listener rule ARN."
  value       = { for k, r in aws_lb_listener_rule.rule : k => r.arn }
}
