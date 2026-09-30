output "record_fqdns" {
  description = "Map of \"<zone_key>.<record_key>\" => record FQDN with the trailing dot the Azure API applies (e.g. \"www.example.com.\")."
  value = merge(
    { for key, record in azurerm_dns_a_record.a : key => record.fqdn },
    { for key, record in azurerm_dns_a_record.a_alias : key => record.fqdn },
    { for key, record in azurerm_dns_aaaa_record.aaaa : key => record.fqdn },
    { for key, record in azurerm_dns_aaaa_record.aaaa_alias : key => record.fqdn },
    { for key, record in azurerm_dns_caa_record.caa : key => record.fqdn },
    { for key, record in azurerm_dns_cname_record.cname : key => record.fqdn },
    { for key, record in azurerm_dns_cname_record.cname_alias : key => record.fqdn },
    { for key, record in azurerm_dns_mx_record.mx : key => record.fqdn },
    { for key, record in azurerm_dns_ns_record.ns : key => record.fqdn },
    { for key, record in azurerm_dns_ptr_record.ptr : key => record.fqdn },
    { for key, record in azurerm_dns_srv_record.srv : key => record.fqdn },
    { for key, record in azurerm_dns_txt_record.txt : key => record.fqdn },
    { for key, record in azurerm_private_dns_a_record.private_a : key => record.fqdn },
    { for key, record in azurerm_private_dns_aaaa_record.private_aaaa : key => record.fqdn },
    { for key, record in azurerm_private_dns_cname_record.private_cname : key => record.fqdn },
    { for key, record in azurerm_private_dns_mx_record.private_mx : key => record.fqdn },
    { for key, record in azurerm_private_dns_ptr_record.private_ptr : key => record.fqdn },
    { for key, record in azurerm_private_dns_srv_record.private_srv : key => record.fqdn },
    { for key, record in azurerm_private_dns_txt_record.private_txt : key => record.fqdn },
  )
}
