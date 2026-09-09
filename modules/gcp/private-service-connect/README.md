# gcp/private-service-connect

Map-keyed module for Google Cloud Private Services Access: allocates
`VPC_PEERING` internal ranges and establishes service networking connections to
Google producers (Filestore, Memorystore, Cloud SQL private services, NetApp, ...).

This is the service-networking peering flavor — not Private Service Connect
endpoints (`google_compute_forwarding_rule` with a target service attachment);
those are not implemented in this module.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `connections` | `map(object)` | — | Map of connections keyed by an arbitrary unique ID. One connection exists per service/network pair in GCP — give each pair its own key. |

### `connections` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network` | `string` | — | VPC network name or self link in the provider project (required). |
| `service` | `string` | `servicenetworking.googleapis.com` | Producer service to connect. |
| `reserved_peering_ranges` | `list(string)` | `[]` | Names of pre-existing peering ranges to reserve on the connection (created outside this module). |
| `deletion_policy` | `string` | — | One of `ABANDON`, `REMOVE_PEERING` (validated). `ABANDON` drops the connection from state but leaves the peering (the network stays blocked from deletion until the peering goes); `REMOVE_PEERING` is a teardown escape hatch for transitively-created peerings. |
| `allocate_ranges` | `map(object)` | `{}` | Ranges this module creates and reserves; see the `allocate_ranges` object table. |
| `routes_config` | `object` | — | Presence creates a `google_compute_network_peering_routes_config`: `{import_custom_routes, export_custom_routes, import_subnet_routes_with_public_ip, export_subnet_routes_with_public_ip}`. The two custom-routes flags are required; the public-IP subnet flags optional. |

### `allocate_ranges` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Range (global address) name; RFC1035, 1–63 chars (validated). |
| `prefix_length` | `number` | — | Range size as a mask length, 16–24 (validated). Immutable; changing forces replacement. |
| `address` | `string` | — | First address of the range (IPv4); omit to let GCP pick. |
| `project_id` | `string` | — | Project the address lives in; defaults to the provider-level project. |
| `description` | `string` | — | Range description. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |

## Outputs

`allocated_range_names` — map of composite key
(`connection key/range key`) => `{name, address, prefix_length}`.
`reserved_peering_ranges` — map of connection key => distinct list of range names
reserved on the connection (both module-allocated and pre-existing).
`connection_peerings` — map of connection key => peering resource name.

## Example

```hcl
connections = {
  "filestore" = {
    network = "projects/example-network-project/global/networks/example-vpc"

    allocate_ranges = {
      "psc" = {
        name          = "example-vpc-psc"
        address       = "10.128.0.0"
        prefix_length = 20
        description   = "Private services access range for Filestore"
      }
    }

    routes_config = {
      import_custom_routes = true
      export_custom_routes = true
    }
  }
}
```

A consumer (`gcp/filestore`) then references the range by name:

```hcl
networks = {
  network           = "example-vpc"
  modes             = ["MODE_IPV4"]
  connect_mode      = "PRIVATE_SERVICE_ACCESS"
  reserved_ip_range = "example-vpc-psc"
}
```

## Notes

- Pair with `gcp/project-services` (`servicenetworking.googleapis.com` in both the
  network project and the service project) — this module does not enable APIs itself.
- One connection per service/network pair: attempting a second connection to the same
  service and network fails at apply (the API rejects duplicates); keys only disambiguate
  different pairs.
- Range size is fixed after creation: updating `prefix_length` on an established
  connection replaces the address (fails while the connection is established — GCP does
  not resize live peering ranges; add a new larger range instead).
- Deleting a connection requires all producer service instances (Filestore instances,
  Memorystore, ...) to be deleted first. The peering itself is transitively created;
  `deletion_policy` provides the escape hatches described above.
- `address_type = "INTERNAL"` and `purpose = "VPC_PEERING"` are set by the module;
  consumers cannot create public peering ranges through it.

## Import

`google_compute_global_address` ←
`projects/{project}/global/addresses/{name}` (also `{project}/{name}` or `{name}`).
`google_service_networking_connection` ← `{peering-network}:{service}`.
`google_compute_network_peering_routes_config` ←
`{project}/{network}/{peering}` (also `{network}/{peering}`).
