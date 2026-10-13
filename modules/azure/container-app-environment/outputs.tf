output "environment_ids" {
  description = "Map of environment key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.App/managedEnvironments/<name>\")."
  value       = { for key, environment in azurerm_container_app_environment.environment : key => environment.id }
}

output "environment_names" {
  description = "Map of environment key => environment name (2–60 alphanumeric/hyphen characters — the module input name)."
  value       = { for key, environment in azurerm_container_app_environment.environment : key => environment.name }
}

output "environment_default_domains" {
  description = "Map of environment key => the service-generated default domain (\"<name>-<hash>.<region>.azurecontainerapps.io\") — globally unique; apps in the environment get FQDNs under it."
  value       = { for key, environment in azurerm_container_app_environment.environment : key => environment.default_domain }
}

output "environment_static_ip_addresses" {
  description = "Map of environment key => the static IP of the environment — its public inbound IP, or the ILB subnet IP when internal_load_balancer_enabled is true."
  value       = { for key, environment in azurerm_container_app_environment.environment : key => environment.static_ip_address }
}

output "environment_custom_domain_verification_ids" {
  description = "Map of environment key => the custom-domain verification ID of the environment — the value for the `asuid.<custom-domain>` TXT record when binding a domain to the environment's own DNS suffix. Sensitive: the provider marks the source attribute sensitive; it lands in state and anyone with state access can read it."
  value       = { for key, environment in azurerm_container_app_environment.environment : key => environment.custom_domain_verification_id }
  sensitive   = true
}

output "environment_identity_principal_ids" {
  description = "Map of environment key => the system-assigned principal ID of the environment's identity — null when the environment has no identity or a user-assigned only one."
  value = {
    for key, environment in azurerm_container_app_environment.environment :
    key => try(environment.identity[0].principal_id, null)
  }
}

output "environment_docker_bridge_cidrs" {
  description = "Map of environment key => the docker-bridge CIDR of the environment — populated only with infrastructure_subnet_id (VNet-injected environments); null otherwise."
  value = {
    for key, environment in azurerm_container_app_environment.environment :
    key => try(environment.docker_bridge_cidr, null)
  }
}

output "environment_platform_reserved_cidrs" {
  description = "Map of environment key => the platform-reserved CIDR of the environment — populated only with infrastructure_subnet_id (VNet-injected environments); null otherwise."
  value = {
    for key, environment in azurerm_container_app_environment.environment :
    key => try(environment.platform_reserved_cidr, null)
  }
}

output "environment_platform_reserved_dns_ip_addresses" {
  description = "Map of environment key => the platform-reserved internal DNS IP of the environment — populated only with infrastructure_subnet_id (VNet-injected environments); null otherwise."
  value = {
    for key, environment in azurerm_container_app_environment.environment :
    key => try(environment.platform_reserved_dns_ip_address, null)
  }
}
