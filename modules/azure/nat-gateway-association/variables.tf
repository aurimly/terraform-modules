variable "subnet_nat_gateway_associations" {
  description = "Map of subnet-to-NAT-gateway associations keyed by an arbitrary identifier. Each entry creates one azurerm_subnet_nat_gateway_association attaching a NAT gateway to a subnet so the subnet's traffic egresses through the gateway. A subnet can carry at most one such association."
  type = map(object({
    subnet_id      = string
    nat_gateway_id = string
  }))

  validation {
    condition = alltrue([
      for a in var.subnet_nat_gateway_associations : can(regex("^/", a.subnet_id)) && can(regex("^/", a.nat_gateway_id))
    ])
    error_message = "subnet_id and nat_gateway_id must be full ARM resource IDs starting with \"/\" — feed the azure/subnet module's subnet_ids and the azure/nat-gateway module's nat_gateway_ids values."
  }

  validation {
    condition = alltrue(flatten([
      for key, a in var.subnet_nat_gateway_associations : [
        for other_key, b in var.subnet_nat_gateway_associations :
        key == other_key || lower(a.subnet_id) != lower(b.subnet_id)
      ]
    ]))
    error_message = "a subnet can only have one NAT gateway association — two entries pointing at the same subnet_id (case-insensitively) conflict at apply. Keep one entry per subnet."
  }
}
