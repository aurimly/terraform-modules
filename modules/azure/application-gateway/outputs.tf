output "gateway_ids" {
  description = "Map of gateway key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/applicationGateways/<name>\")."
  value       = { for key, gateway in azurerm_application_gateway.gateway : key => gateway.id }
}

output "gateway_names" {
  description = "Map of gateway key => gateway name."
  value       = { for key, gateway in azurerm_application_gateway.gateway : key => gateway.name }
}

output "gateway_private_ip_addresses" {
  description = "Map of gateway key => list of private frontend IP addresses (public IPs belong to the azure/public-ip module — wire public_ip_address_id)."
  value = {
    for key, gateway in azurerm_application_gateway.gateway : key => [
      for frontend in gateway.frontend_ip_configuration : frontend.private_ip_address
      if frontend.private_ip_address != null
    ]
  }
}

output "backend_address_pool_ids" {
  description = "Map of \"<gateway_key>:backend_address_pools:<name>\" => backend-address-pool ARM ID (this is what azurerm_network_interface_application_gateway_backend_address_pool_association and the VMSS/VM association resources need)."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for pool in gateway.backend_address_pool : "${gateway_key}:backend_address_pools:${pool.name}" => pool.id
    }
  ])...)
}

output "backend_http_settings_ids" {
  description = "Map of \"<gateway_key>:backend_http_settings:<name>\" => backend-settings ARM ID."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for settings in gateway.backend_http_settings : "${gateway_key}:backend_http_settings:${settings.name}" => settings.id
    }
  ])...)
}

output "http_listener_ids" {
  description = "Map of \"<gateway_key>:http_listeners:<name>\" => listener ARM ID."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for listener in gateway.http_listener : "${gateway_key}:http_listeners:${listener.name}" => listener.id
    }
  ])...)
}

output "request_routing_rule_ids" {
  description = "Map of \"<gateway_key>:request_routing_rules:<name>\" => routing-rule ARM ID."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for rule in gateway.request_routing_rule : "${gateway_key}:request_routing_rules:${rule.name}" => rule.id
    }
  ])...)
}

output "url_path_map_ids" {
  description = "Map of \"<gateway_key>:url_path_maps:<name>\" => path-map ARM ID."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for url_map in gateway.url_path_map : "${gateway_key}:url_path_maps:${url_map.name}" => url_map.id
    }
  ])...)
}

output "probe_ids" {
  description = "Map of \"<gateway_key>:probes:<name>\" => probe ARM ID."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for probe in gateway.probe : "${gateway_key}:probes:${probe.name}" => probe.id
    }
  ])...)
}

output "frontend_port_ids" {
  description = "Map of \"<gateway_key>:frontend_ports:<name>\" => frontend-port ARM ID."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for port in gateway.frontend_port : "${gateway_key}:frontend_ports:${port.name}" => port.id
    }
  ])...)
}

output "ssl_certificate_public_cert_datas" {
  description = "Map of \"<gateway_key>:ssl_certificates:<name>\" => the public certificate data surfaced by the gateway (public_cert_data)."
  value = merge(flatten([
    for gateway_key, gateway in azurerm_application_gateway.gateway : {
      for certificate in gateway.ssl_certificate : "${gateway_key}:ssl_certificates:${certificate.name}" => certificate.public_cert_data
    }
  ])...)
  sensitive = true
}
