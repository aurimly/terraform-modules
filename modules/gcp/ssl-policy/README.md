# gcp/ssl-policy

Map-keyed module for SSL policies — TLS profile and version selection for
load balancer target HTTPS proxies. Policies created here attach to load
balancers created by `gcp/load-balancer` (see Outputs).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `ssl_policies` | `map(object)` | — | Map of SSL policies keyed by an arbitrary unique ID. |

### `ssl_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name, RFC1035 (validated). Immutable. |
| `project_id` | `string` | — | Project the policy lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Free-text description. |
| `profile` | `string` | `COMPATIBLE` | One of `COMPATIBLE`, `MODERN`, `RESTRICTED`, `CUSTOM`, `FIPS_202205` (validated). `CUSTOM` requires `custom_features` (validated); `FIPS_202205` requires `min_tls_version = "TLS_1_2"` (validated). |
| `min_tls_version` | `string` | `TLS_1_0` | One of `TLS_1_0`, `TLS_1_1`, `TLS_1_2`, `TLS_1_3` (validated). `TLS_1_3` requires profile `RESTRICTED` (validated). |
| `post_quantum_key_exchange` | `string` | — | One of `DEFAULT`, `ENABLED`, `DEFERRED`. |
| `custom_features` | `list(string)` | — | Explicit cipher list, only with profile `CUSTOM` (validated). |

## Outputs

`policy_ids` — map of policy key => policy id.
`policy_self_links` — map of policy key => self link. Pass to
`gcp/load-balancer` `https_proxies[].ssl_policy`.
`policy_profiles` — map of policy key => profile.
`policy_enabled_features` — map of policy key => the features the policy
enables (computed from profile or `custom_features`).

## Example

```hcl
ssl_policies = {
  "global" = {
    name            = "example-global-tls12"
    profile         = "RESTRICTED"
    min_tls_version = "TLS_1_2"
  },
}
```

Wired into `gcp/load-balancer`:

```hcl
https_proxies = {
  "app" = {
    name       = "example-app-https-proxy"
    ssl_policy = module.sslpol.policy_self_links["global"]
    ...
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- See the Google Cloud SSL policies reference for the cipher list behind each
  profile (`COMPATIBLE` > `MODERN` > `RESTRICTED` in strictness).
- Regional SSL policies (`google_compute_region_ssl_policy`, for regional
  external ALB proxies) are intentionally out of scope — file an issue if you
  need them.
- Pair with `gcp/project-services` (`compute.googleapis.com`) when the target
  project does not have the Compute Engine API enabled yet; this module does
  not enable APIs itself.

## Import

`google_compute_ssl_policy` ←
`projects/{project}/global/sslPolicies/{name}`.
