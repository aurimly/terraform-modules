# cloudflare/workers_script

Map-keyed module for Cloudflare Worker records. This module manages the
Worker record only — it drives the v5 `cloudflare_worker` resource, which
carries no script content, versions, bindings, or deployments. Script
content, versions, bindings and deployments stay with wrangler/CI, matching
the posture of `cloudflare/worker-domains`.

## What this module owns vs wrangler

Terraform owns: observability settings, the `*.workers.dev` subdomain
settings, tags, logpush, and tail consumers.

Wrangler owns: code, versions, bindings, deployments.

Every knob declared below is Terraform-owned: omitted fields are sent as
their defaults (e.g. `logpush = false`, empty tags), so importing a
wrangler-managed Worker and planning will reset any of these knobs wrangler
previously set. Do not manage these knobs in wrangler.toml too — choose one
owner per knob.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Cloudflare account ID. |
| `workers` | `map(object)` | — | Map of Workers keyed by an arbitrary unique ID. |

### `workers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Worker service name (the name wrangler deploys under). |
| `logpush` | `bool` | `false` | Whether logpush is enabled for the Worker. |
| `tags` | `set(string)` | `[]` | Tags associated with the Worker. |
| `subdomain` | `object` | `null` | `*.workers.dev` subdomain settings: `enabled`, `previews_enabled` (both optional `bool`). |
| `tail_consumers` | `set(string)` | `[]` | Names of other Workers that consume this Worker's logs. |
| `observability` | `object` | computed | Observability settings, see below. |

### `observability` object

All fields optional; the API computes unset values.

| Attribute | Type | Description |
|---|---|---|
| `enabled` | `bool` | Whether observability is enabled. |
| `head_sampling_rate` | `number` | Sampling rate, 0 to 1. |
| `logs` | `object` | `enabled`, `head_sampling_rate`, `destinations` (list), `invocation_logs`, `persist`. |
| `traces` | `object` | `enabled`, `head_sampling_rate`, `destinations` (list), `persist`, `propagation_policy`. |

## Outputs

`worker_ids`, `worker_names`, `worker_deployed_ons` — all keyed by worker
key. `worker_deployed_ons` is `null` until wrangler's first deploy — a
clean "this Worker record exists but serves nothing yet" signal.

## Notes

- This module uses Cloudflare's beta Workers API. The resource is recent —
  `required_providers` keeps the repo-wide `>= 5.0.0` floor, but consumers
  far below v5.24 get "invalid resource type"; the module was researched
  against 5.24.0.
- Until wrangler's first deploy the Worker record exists but serves no
  traffic; `worker_deployed_ons` will read `null`.
- Wrangler deploys can reset record-level settings (observability,
  subdomain, tags) if the same knobs are configured in wrangler.toml.
  Choose one owner per knob.

## Example

```hcl
workers = {
  "api-worker" = {
    name = "example-api-worker"
    observability = {
      enabled            = true
      head_sampling_rate = 0.1
    }
    subdomain = {
      enabled = true
    }
  }
  "log-sink" = {
    name           = "example-log-sink"
    tail_consumers = ["example-api-worker"]
  }
}
```

## Import

`cloudflare_worker` ← `<account_id>/<worker_id>` — the immutable Worker ID,
not the name; take it from this module's `worker_ids` output or the
dashboard.
