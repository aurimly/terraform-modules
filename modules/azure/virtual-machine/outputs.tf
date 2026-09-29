output "virtual_machine_ids" {
  description = "Map of virtual machine key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<name>\"), merged across the Linux and Windows resources — covers all input keys."
  value       = merge({ for k, v in azurerm_linux_virtual_machine.linux_virtual_machine : k => v.id }, { for k, v in azurerm_windows_virtual_machine.windows_virtual_machine : k => v.id })
}

output "virtual_machine_names" {
  description = "Map of virtual machine key => virtual machine name, merged across the Linux and Windows resources — covers all input keys."
  value       = merge({ for k, v in azurerm_linux_virtual_machine.linux_virtual_machine : k => v.name }, { for k, v in azurerm_windows_virtual_machine.windows_virtual_machine : k => v.name })
}
