output "state_machine_arns" {
  description = "Map of state machine key => state machine ARN (unqualified; also the aws_sfn_state_machine import ID)."
  value       = { for k, sm in aws_sfn_state_machine.machine : k => sm.arn }
}

output "state_machine_names" {
  description = "Map of state machine key => final state machine name (provider-generated when name_prefix was used; for EventBridge targets and StartExecution)."
  value       = { for k, sm in aws_sfn_state_machine.machine : k => sm.name }
}

output "state_machine_version_arns" {
  description = "Map of state machine key => latest published version ARN; null for machines that have never published a version (stays populated after publish is reverted to false)."
  value       = { for k, sm in aws_sfn_state_machine.machine : k => sm.state_machine_version_arn }
}

output "creation_dates" {
  description = "Map of state machine key => state machine creation date (RFC3339)."
  value       = { for k, sm in aws_sfn_state_machine.machine : k => sm.creation_date }
}

output "activity_arns" {
  description = "Map of activity key => activity ARN (also the aws_sfn_activity import ID)."
  value       = { for k, a in aws_sfn_activity.activity : k => a.arn }
}

output "activity_names" {
  description = "Map of activity key => activity name."
  value       = { for k, a in aws_sfn_activity.activity : k => a.name }
}
