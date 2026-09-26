output "log_group_names" {
  description = "Map of log group key => log group name (also the aws_cloudwatch_log_group import ID)."
  value       = { for k, g in aws_cloudwatch_log_group.log_group : k => g.name }
}

output "log_group_arns" {
  description = "Map of log group key => log group ARN."
  value       = { for k, g in aws_cloudwatch_log_group.log_group : k => g.arn }
}

output "alarm_names" {
  description = "Map of alarm key => alarm name (also the aws_cloudwatch_metric_alarm import ID)."
  value       = { for k, a in aws_cloudwatch_metric_alarm.alarm : k => a.alarm_name }
}

output "alarm_arns" {
  description = "Map of alarm key => alarm ARN."
  value       = { for k, a in aws_cloudwatch_metric_alarm.alarm : k => a.arn }
}

output "dashboard_names" {
  description = "Map of dashboard key => dashboard name (also the aws_cloudwatch_dashboard import ID)."
  value       = { for k, d in aws_cloudwatch_dashboard.dashboard : k => d.dashboard_name }
}

output "dashboard_arns" {
  description = "Map of dashboard key => dashboard ARN."
  value       = { for k, d in aws_cloudwatch_dashboard.dashboard : k => d.dashboard_arn }
}
