# cloudflare/workers_route

Map-keyed module for Cloudflare Workers routes, binding a URL pattern in a
zone to a Worker script (or to nothing).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone_id` | `string` | `""` | Fallback zone ID used when a route omits its own. |
| `routes` | `map(object)` | — | Map of routes keyed by an arbitrary unique ID. |

### `routes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `pattern` | `string` | — | URL pattern, e.g. `example.com/about/*`. Changing the pattern is an in-place update, not a replacement. |
| `script` | `string` | — | Worker script name. Omit for a route with no Worker attached. |
| `zone_id` | `string` | — | Per-route zone ID; falls back to `var.zone_id`. |

## Outputs

`route_ids`, `route_patterns`, `route_scripts` — all keyed by route key.
`route_scripts` values are `null` for unattached routes.

## Notes

- In v5 `script` is optional and not deprecated (the v4 idiom
  `script_name = ""` is gone) — omit the attribute to create an unattached
  route, which is a first-class object.
- Attaching a Worker via `worker-domains` auto-manages DNS records for the
  custom domain; routes only gate requests to already-proxied hostnames and
  do not create DNS records.
- Keys are arbitrary unique identifiers, not patterns — two entries can
  target overlapping or identical patterns in different zones.

## Example

```hcl
routes = {
  "api-v2" = {
    pattern = "example.com/api/v2/*"
    script  = "example-api-worker"
  }
  "parked-preview" = {
    pattern = "preview.example.com/*"
  }
}
```

## Import

`cloudflare_workers_route` ← `<zone_id>/<route_id>`
