# cloudflare/turnstile

Map-keyed module for Cloudflare Turnstile widgets. Each entry creates one
`cloudflare_turnstile_widget` in the account resolved from the entry's
`account_id` or the module-level fallback. Widget names are not unique at
Cloudflare — the map key is the disambiguator.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `""` | Fallback account ID for widgets that omit `account_id`. |
| `widgets` | `map(object)` | — | Map of widgets keyed by an arbitrary unique ID. |

Plan-time validation: `name` is non-empty, `domains` entries are non-empty
hostnames (the list itself may be empty for off-web use), `mode` is
`managed`/`non-interactive`/`invisible`, `clearance_level` is one of
`no_clearance`/`jschallenge`/`managed`/`interactive`, and `region` is
`world`/`china`. A missing `account_id` on both levels fails the lifecycle
precondition with a keyed message.

### `widgets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Human-readable widget name; not unique by design — name one per usage site. |
| `domains` | `list(string)` | — | Hostnames the widget may run on. May be empty for widgets verified off-web (mobile apps). Updated in place. |
| `mode` | `string` | — | `managed` (interactive challenge only when needed), `non-interactive` (never shows a challenge) or `invisible` (never shows, no interactive fallback). Creation-time at the API — a change attempts an in-place update and may be rejected at apply. |
| `account_id` | `string` | `null` | Account for this widget; falls back to the module-level `account_id` when omitted. |
| `bot_fight_mode` | `bool` | `null` | Computationally expensive challenges for malicious bots (Enterprise only). |
| `clearance_level` | `string` | `null` | Challenge clearance granted when the widget runs on a Cloudflare-proxied site: `no_clearance`, `jschallenge`, `managed` or `interactive`. |
| `ephemeral_id` | `bool` | `null` | Return the Ephemeral ID from `/siteverify` (Enterprise only). |
| `offlabel` | `bool` | `null` | Hide Cloudflare branding on the widget (Enterprise only). |
| `region` | `string` | `null` | `world` or `china`. Immutable — cannot be changed after creation. |

## Outputs

| Name | Description |
|---|---|
| `widget_sitekeys` | Map of key => sitekey (public identifier; the widget's ID equals the sitekey upstream, so this is also the import identifier). |
| `widget_secret_keys` | Map of key => secret key (sensitive output). |

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

widgets = {
  "login-form" = {
    name    = "login form"
    domains = ["blog.example.com", "www.example.com"]
    mode    = "managed"
  }
  "app-check" = {
    name    = "mobile app check"
    domains = []
    mode    = "non-interactive"
    region  = "world"
  }
}
```

## Notes

- The secret key is exposed as a sensitive output so wiring (e.g. seeding a
  secret manager) is possible in-module-chain; it is persisted in state like
  any output. For environments where state storage is not trusted, fetch the
  secret via the API instead of outputting it.
- `region` is set at creation and immutable; switching a widget to the `china`
  region means replacing it.
- `bot_fight_mode`, `ephemeral_id` and `offlabel` are Enterprise-only flags —
  the module passes them through, and plans on other plans still validate.
- The sitekey is safe to embed publicly; the secret key belongs server-side
  (used with `/siteverify`).
- The caller needs `Turnstile Sites Read`/`Write` (and `Account Settings
  Read`/`Write` per the provider's permission list).

## Import

`cloudflare_turnstile_widget` ← `<account_id>/<sitekey>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/0x4AAAaAaAAAAaAAaAAaAAaAAaAAaAAaAa`.
