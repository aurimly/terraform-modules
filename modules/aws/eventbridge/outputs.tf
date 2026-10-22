output "bus_arns" {
  description = "Map of event bus key => bus ARN."
  value       = { for k, b in aws_cloudwatch_event_bus.bus : k => b.arn }
}

output "bus_names" {
  description = "Map of event bus key => bus name."
  value       = { for k, b in aws_cloudwatch_event_bus.bus : k => b.name }
}

output "rule_arns" {
  description = "Map of rule key => rule ARN."
  value       = { for k, r in aws_cloudwatch_event_rule.rule : k => r.arn }
}

output "rule_names" {
  description = "Map of rule key => rule name."
  value       = { for k, r in aws_cloudwatch_event_rule.rule : k => r.name }
}

output "target_ids" {
  description = "Map of \"rule-key.target-key\" => target id (provider-generated when the target input omits target_id; part of the import address)."
  value       = { for k, t in aws_cloudwatch_event_target.target : k => t.target_id }
}

output "target_arns" {
  description = "Map of \"rule-key.target-key\" => target resource ARN (the input `arn` echoed back; targets carry no AWS-issued id)."
  value       = { for k, t in aws_cloudwatch_event_target.target : k => t.arn }
}

output "archive_arns" {
  description = "Map of \"bus-key.archive-key\" => archive ARN."
  value       = { for k, a in aws_cloudwatch_event_archive.archive : k => a.arn }
}

output "schedule_arns" {
  description = "Map of schedule key => schedule ARN."
  value       = { for k, s in aws_scheduler_schedule.schedule : k => s.arn }
}

output "schedule_group_arns" {
  description = "Map of schedule group key => group ARN."
  value       = { for k, g in aws_scheduler_schedule_group.schedule_group : k => g.arn }
}
