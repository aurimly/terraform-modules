variable "subnet_route_table_associations" {
  description = "Map of subnet-to-route-table associations keyed by an arbitrary identifier. Each entry creates one azurerm_subnet_route_table_association attaching a route table to a subnet so the subnet's egress follows the table's routes. A subnet can carry at most one such association — the table it currently points at is the one in effect."
  type = map(object({
    subnet_id      = string
    route_table_id = string
  }))

  validation {
    condition = alltrue([
      for a in var.subnet_route_table_associations : can(regex("^/", a.subnet_id)) && can(regex("^/", a.route_table_id))
    ])
    error_message = "subnet_id and route_table_id must be full ARM resource IDs starting with \"/\" — feed the azure/subnet module's subnet_ids and the azure/route-table module's route_table_ids values."
  }

  validation {
    condition = alltrue(flatten([
      for key, a in var.subnet_route_table_associations : [
        for other_key, b in var.subnet_route_table_associations :
        key == other_key || lower(a.subnet_id) != lower(b.subnet_id)
      ]
    ]))
    error_message = "a subnet can only have one route table association — two entries pointing at the same subnet_id (case-insensitively) conflict at apply. Keep one entry per subnet."
  }
}
