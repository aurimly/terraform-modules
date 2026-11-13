# cloudflare/email-routing

Map-keyed module for Cloudflare Email Routing rules. Each `rules` entry
creates one `cloudflare_email_routing_rule` in the zone named by `zone_id`;
each `catch_all_rules` entry creates the zone's single
`cloudflare_email_routing_catch_all`, whose matcher is fixed to `all` by the
API.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `rules` | `map(object)` | — | Map of routing rules keyed by an arbitrary unique ID. |
| `catch_all_rules` | `map(object)` | — | Map of per-zone catch-all rules keyed by an arbitrary unique ID. |

Plan-time validation: matcher `type` is `all`/`literal` with literal matchers
requiring field `to` and a non-empty value, action `type` is
`drop`/`forward`/`worker` with drop carrying no value and forward/worker
carrying exactly one, `source` is `api`/`wrangler` with wrangler rules
requiring `owner_worker_tag`, `zone_id` is non-empty, and catch-all entries
have unique `zone_id`s (one catch-all per zone).

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `zone_id` | `string` | — | Zone the rule belongs to (typically `dependency.zone.outputs.zone_ids["example.com"]` with the `cloudflare/zone` module). Immutable — changing it forces replacement. |
| `matchers` | `list(object)` | — | Matching patterns. Each: `type` (`all` or `literal`; literal requires `field = "to"` and the address in `value`). Fields `field` and `value` are inert on `all` matchers — the API matches every address. |
| `actions` | `list(object)` | — | Actions to take. Each: `type` (`drop`, `forward`, `worker`) and `value` — a single destination address for `forward`, a single Worker name for `worker`, nothing for `drop`. |
| `enabled` | `bool` | `null` | Routing rule status. |
| `name` | `string` | `null` | Human-readable rule name. |
| `priority` | `number` | `null` | Rule priority — rules evaluate in priority order. The provider defaults omitted values to `0`. |
| `source` | `string` | `null` | `api` (dashboard, generic API and Terraform) or `wrangler` (the rule is owned by a Worker's wrangler.jsonc). Defaults to `api` on write. |
| `owner_worker_tag` | `string` | `null` | Public tag of the owning Worker — required when `source = "wrangler"` (validated). |

### `catch_all_rules` object

Same as `rules` minus `matchers` (fixed to a single `all` matcher) and
`priority` (the catch-all always runs last).

## Outputs

| Name | Description |
|---|---|
| `rule_ids` | Map of rule key => routing rule ID. |
| `catch_all_rule_ids` | Map of catch-all key => catch-all rule ID. |

## Example

```hcl
rules = {
  "support" = {
    zone_id = dependency.zone.outputs.zone_ids["example.com"]
    matchers = [
      {
        type  = "literal"
        field = "to"
        value = "support@example.com"
      }
    ]
    actions = [
      {
        type  = "forward"
        value = ["helpdesk@example.net"]
      }
    ]
    enabled = true
    name    = "support inbox"
  }
}

catch_all_rules = {
  "example-com" = {
    zone_id = dependency.zone.outputs.zone_ids["example.com"]
    actions = [
      {
        type  = "worker"
        value = ["mail-worker"]
      }
    ]
    enabled = true
  }
}
```

## Notes

- `forward` actions can only hand mail to addresses already verified in the
  zone's destination address list — destination address management is not part
  of this module (add them in the dashboard or via the API first); the API
  rejects unknown destinations at apply.
- The catch-all is a singleton per zone: its matcher is fixed to `all`, it
  always evaluates last (after prioritized rules), and it imports by `zone_id`
  alone.
- The module floor is the repo-wide `>= 5.0.0`, but `source` and
  `owner_worker_tag` only exist from provider v5.22.0 — consumers pinned below
  that get "unsupported attribute".
  The module was researched against v5.29.0.
- Rules with `source = "wrangler"` are owned by a Worker's wrangler.jsonc —
  editing them through the API (and therefore this module) conflicts with the
  Worker's own config. Leave such rules to wrangler; this module defaults to
  `source = "api"`.
- Email routing must be enabled for the zone before rules take effect;
  enabling the service is dashboard/API-side and out of scope here.
- The caller needs `Email Routing Rules Read` and `Write` on the account.

## Import

```text
cloudflare_email_routing_rule ← <zone_id>/<rule_id>.
cloudflare_email_routing_catch_all ← <zone_id>.
```
