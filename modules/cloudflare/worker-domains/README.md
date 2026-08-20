# cloudflare/worker-domains

Map-keyed module for Cloudflare Workers custom domains (hostname → Worker
service bindings). Worker scripts and assets are out of scope — they stay
on wrangler/CI.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Cloudflare account ID. |
| `zone_id` | `string` | `""` | Fallback zone ID used when a domain omits its own. |
| `domains` | `map(object)` | — | Map keyed by hostname. |

### `domains` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service` | `string` | — | Worker service name (e.g. `my-worker`). |
| `zone_id` | `string` | — | Per-domain zone ID; falls back to `var.zone_id`. |
| `zone_name` | `string` | — | Zone name. v5 populates this on read; set it when the audit returns it to avoid import drift. |

## Outputs

`domain_ids`, `domain_hostnames`, `domain_services` — all keyed by hostname.

## Notes

- `environment` is deprecated in v5 and is NOT exposed.
- Attaching a custom domain makes Cloudflare auto-manage the hostname's
  DNS records (A/AAAA). Those records are intentionally NOT part of any
  `cloudflare/dns-records` config — do not add them there, or two
  resources will fight over the same record.

## Import

`cloudflare_workers_custom_domain` ← `<account_id>/<domain_id>`
