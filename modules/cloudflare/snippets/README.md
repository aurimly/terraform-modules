# cloudflare/snippets

Map-keyed module for Cloudflare Snippets in one zone. Each entry creates one
`cloudflare_snippet`; the optional `rules` list creates the zone's single
`cloudflare_snippet_rules` resource holding the ordered rule list.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone_id` | `string` | — | Cloudflare zone ID the snippets and rules belong to. |
| `snippets` | `map(object)` | — | Map of snippets keyed by an arbitrary unique ID. |
| `rules` | `list(object)` | — | Ordered list of snippet rules. Order-preserving list — not map-keyed (see Notes). |

Plan-time validation: `snippet_name` is non-empty, contains only letters,
digits, hyphens and underscores (Cloudflare API restriction) and is unique
within the zone, case-insensitively; `files` holds at least one entry and
every entry has a non-empty name and content; `main_module`, when set,
names one of `files`; rule `expression` is non-empty and rule
`snippet_name` references a snippet managed by this module.

### `snippets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `snippet_name` | `string` | — | The snippet's identifier in the zone and its import key. |
| `files` | `list(object)` | — | JavaScript files of the snippet, each `{name, content}`. |
| `main_module` | `string` | first file | The file used as the snippet's entry point. |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `expression` | `string` | — | Cloudflare Rules language expression that triggers the snippet. |
| `snippet_name` | `string` | — | Name of a snippet managed by this module. |
| `description` | `string` | `null` | Rule description. |
| `enabled` | `bool` | `null` | Whether the rule runs. |

## Outputs

| Name | Description |
|---|---|
| `snippet_ids` | Map of key => snippet ID. Note: the import identifier is `<zone_id>/<snippet_name>`, not this generated ID. |
| `rule_ids` | Rule IDs in evaluation order, or an empty list when `rules` is empty. Positional — indexes shift when a middle rule is removed. |

## Example

```hcl
zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

snippets = {
  "hello" = {
    snippet_name = "hello-world"
    files = [
      {
        name    = "index.js"
        content = "export default { async fetch() { return new Response('Hello world'); } }"
      }
    ]
  }
}

rules = [
  {
    expression   = "http.request.uri.path eq \"/greet\""
    snippet_name = "hello-world"
    description  = "Greet on /greet"
    enabled      = true
  }
]
```

## Notes

- The module uses the `cloudflare_snippet` resource (singular). The
  plural `cloudflare_snippets` resource in the provider docs is an orphan —
  malformed `files` typing, no example, no import support — and must not
  be used.
- `rules` is an order-preserving list, a deliberate deviation from this
  repo's map-keyed convention: the upstream `cloudflare_snippet_rules`
  resource is a single ordered list per zone and rules evaluate in the
  listed order, so a map would force an invented ordering attribute. Input
  order is evaluation order.
- The rules resource replaces the zone's whole rule list on every change —
  this module owns the zone's rule list, and two consumers of the module
  for the same zone conflict. When `rules` is empty the rules resource is
  not created at all and any rules already on the zone are left untouched;
  an empty input does not clear them.
- Because of that whole-list ownership, rules may only reference snippets
  managed by this module; snippets created outside the module would be
  unmanageable here.
- `rule_ids` is positional: removing a middle rule shifts the indexes of
  every rule after it — do not treat positions as stable identifiers
  across changes.
- Snippet content lives in Terraform state; keep snippets free of secrets.
- The caller needs `Snippets Edit` on the zone (the provider's permission
  list names Snippets Read/Write).

## Import

`cloudflare_snippet` ← `<zone_id>/<snippet_name>` — by NAME, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/hello-world` (the resource's generated
`id` is a different value).

`cloudflare_snippet_rules` ← `<zone_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353` — one rules resource per zone.
