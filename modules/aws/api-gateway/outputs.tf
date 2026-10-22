output "api_ids" {
  description = "Map of api key => api id."
  value       = { for k, a in aws_apigatewayv2_api.api : k => a.id }
}

output "api_endpoints" {
  description = "Map of api key => execute-api endpoint URL (present when disable_execute_api_endpoint is false)."
  value       = { for k, a in aws_apigatewayv2_api.api : k => a.api_endpoint }
}

output "api_execution_arns" {
  description = "Map of api key => execution ARN (used as e.g. a CloudWatch metrics dimension or ALB/CloudFront target)."
  value       = { for k, a in aws_apigatewayv2_api.api : k => a.execution_arn }
}

output "api_arns" {
  description = "Map of api key => api ARN."
  value       = { for k, a in aws_apigatewayv2_api.api : k => a.arn }
}

output "stage_ids" {
  description = "Map of api key => stage id (one stage per api, from the optional stage object)."
  value       = { for k, s in aws_apigatewayv2_stage.stage : k => s.id }
}

output "stage_arns" {
  description = "Map of api key => stage ARN (resource ARN usable as a WAFv2 REGIONAL association target)."
  value       = { for k, s in aws_apigatewayv2_stage.stage : k => s.arn }
}

output "stage_invoke_urls" {
  description = "Map of api key => stage invoke URL."
  value       = { for k, s in aws_apigatewayv2_stage.stage : k => s.invoke_url }
}

output "integration_ids" {
  description = "Map of \"api-key.integration-key\" => integration id."
  value       = { for k, i in aws_apigatewayv2_integration.integration : k => i.id }
}

output "route_ids" {
  description = "Map of \"api-key.route-key\" => route id."
  value       = { for k, r in aws_apigatewayv2_route.route : k => r.id }
}

output "authorizer_ids" {
  description = "Map of \"api-key.authorizer-key\" => authorizer id."
  value       = { for k, a in aws_apigatewayv2_authorizer.authorizer : k => a.id }
}

output "domain_regional_names" {
  description = "Map of domain key => regional domain name, for Route 53 alias records."
  value       = { for k, d in aws_apigatewayv2_domain_name.domain : k => d.domain_name_configuration[0].regional_domain_name }
}

output "domain_regional_zone_names" {
  description = "Map of domain key => regional hosted zone id (alias target zone for Route 53)."
  value       = { for k, d in aws_apigatewayv2_domain_name.domain : k => d.domain_name_configuration[0].hosted_zone_id }
}

output "domain_target_names" {
  description = "Map of domain key => the A/AAAA alias target domain name (matches regional_domain_name for REGIONAL endpoints; a dualstack name for EDGE endpoints)."
  value       = { for k, d in aws_apigatewayv2_domain_name.domain : k => d.domain_name_configuration[0].target_domain_name }
}

output "api_mapping_ids" {
  description = "Map of mapping key => mapping id."
  value       = { for k, m in aws_apigatewayv2_api_mapping.api_mapping : k => m.id }
}
