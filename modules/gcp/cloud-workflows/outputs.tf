output "workflow_ids" {
  description = "Map of workflow key => workflow id."
  value       = { for k, w in google_workflows_workflow.workflow : k => w.id }
}

output "workflow_names" {
  description = "Map of workflow key => workflow name."
  value       = { for k, w in google_workflows_workflow.workflow : k => w.name }
}

output "workflow_states" {
  description = "Map of workflow key => workflow state."
  value       = { for k, w in google_workflows_workflow.workflow : k => w.state }
}

output "workflow_revision_ids" {
  description = "Map of workflow key => current revision id."
  value       = { for k, w in google_workflows_workflow.workflow : k => w.revision_id }
}
