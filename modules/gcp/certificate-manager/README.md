# gcp/certificate-manager

Map-keyed module for Certificate Manager objects: DNS authorizations
(`google_certificate_manager_dns_authorization`), certificates
(`google_certificate_manager_certificate`), certificate maps
(`google_certificate_manager_certificate_map`), and map entries
(`google_certificate_manager_certificate_map_entry`).

Use this module for regional certificates (classic managed certs are
global-only), Cloud Run domain mappings, Media CDN (`EDGE_CACHE` scope), mTLS
`CLIENT_AUTH` scope, self-managed cert uploads, and certificate maps for SNI
routing. Classic `google_compute_managed_ssl_certificate` setups stay in
`gcp/managed-ssl-certificate`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `dns_authorizations` | `map(object)` | `{}` | Map of DNS authorizations keyed by an arbitrary unique ID. |
| `certificates` | `map(object)` | `{}` | Map of certificates keyed by an arbitrary unique ID. |
| `certificate_maps` | `map(object)` | `{}` | Map of certificate maps keyed by an arbitrary unique ID. |
| `certificate_map_entries` | `map(object)` | `{}` | Map of certificate map entries keyed by an arbitrary unique ID. |

### `dns_authorizations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1–64 chars, starts with a letter (validated). Unique per location. |
| `domain` | `string` | — | Domain to authorize, hostname or `*.service.example.com` (shape-validated). Immutable. |
| `location` | `string` | `global` | Certificate Manager location (shape-validated); must match the certificate's. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `description` | `string` | — | Free-text description. |
| `labels` | `map(string)` | `{}` | Labels. |
| `type` | `string` | — | `FIXED_RECORD` or `PER_PROJECT_RECORD` (validated; fixed defaults by location). `PER_PROJECT_RECORD` allows cross-project Google-managed certs. Immutable. |
| `deletion_policy` | `string` | DELETE | `DELETE`, `ABANDON` or `PREVENT` (validated). |

### `certificates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1–64 chars, starts with a letter (validated). Globally unique. |
| `location` | `string` | `global` | Certificate Manager location; must match the DNS authorizations'. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `description` | `string` | — | Free-text description. |
| `labels` | `map(string)` | `{}` | Labels. |
| `scope` | `string` | DEFAULT | `DEFAULT`, `EDGE_CACHE`, `ALL_REGIONS` (global certs only) or `CLIENT_AUTH` (validated). Immutable. |
| `deletion_policy` | `string` | DELETE | `DELETE`, `ABANDON` or `PREVENT` (validated). |
| `managed` | `object` | — | Google-managed: `{domains, dns_authorizations?, issuance_config?}`; exactly one of the last two (validated). |
| `self_managed` | `object` | — | `{pem_certificate, pem_private_key}`; contents live in state as plain text. Both are updated in place. |

`managed.domains` takes 1–100 hostnames (wildcards allowed, validated).
`dns_authorizations` entries are keys into the `dns_authorizations` map.
`issuance_config` is **bring-your-own**: pass the full resource id
(`projects/{project}/locations/{location}/certificateIssuanceConfigs/{name}`);
this module does not create issuance configs because they require a Private CA
CA pool (`google_privateca_ca_pool`) that lives outside this module. Exactly one
of the two is allowed (validated).

### `certificate_maps` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1–64 chars, starts with a letter (validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `description` | `string` | — | Free-text description. |
| `labels` | `map(string)` | `{}` | Labels. |

### `certificate_map_entries` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `map_key` | `string` | — | Key into `certificate_maps` (plan-fail if missing). |
| `name` | `string` | — | 1–64 chars, starts with a letter (validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `description` | `string` | — | Free-text description. |
| `hostname` | `string` | — | FQDN or wildcard (`*.service.example.com`) selecting entries by SNI; must not be combined with `matcher = PRIMARY` (validated). |
| `matcher` | `string` | — | `PRIMARY` only (validated); at most one `PRIMARY` entry per map across the whole input (validated). |
| `labels` | `map(string)` | `{}` | Labels. |
| `certificates` | `list(string)` | — | 1–15 keys into the `certificates` map (validated, resolved to ids). |

## Outputs

| Name | Description |
|---|---|
| `dns_authorization_ids` | Map of DNS authorization key => id. |
| `dns_resource_records` | Map of DNS authorization key => list of `{name, type, data}` records to publish in the zone. |
| `certificate_ids` | Map of certificate key => id. |
| `certificate_map_ids` | Map of certificate map key => id. |
| `certificate_map_entry_ids` | Map of entry key => id. |

## Example

DNS-authorized Google-managed certificate wired to a target SSL proxy through a
certificate map:

```hcl
module "certs" {
  source = "git::ssh://git@github.com/<org>/terraform-modules.git//modules/gcp/certificate-manager?ref=v1.25.0"

  dns_authorizations = {
    "a" = {
      name   = "example-dns-auth"
      domain = "service.example.com"
    }
  }

  certificates = {
    "edge" = {
      name  = "example-edge-cert"
      scope = "DEFAULT"
      managed = {
        domains            = ["service.example.com"]
        dns_authorizations = ["a"]
      }
    }
  }

  certificate_maps = {
    "lb" = {
      name = "example-lb-cert-map"
    }
  }

  certificate_map_entries = {
    "sni" = {
      map_key      = "lb"
      name         = "example-sni-entry"
      hostname     = "service.example.com"
      certificates = ["edge"]
    }
  }
}
```

Publish the `dns_resource_records` output records in the zone (e.g. via
`gcp/dns-record-sets`), then wire the map into a target proxy — `gcp/target-proxies`
ssl_proxies take `certificate_map = "//certificatemanager.googleapis.com/${module.certs.certificate_map_ids["lb"]}"`,
`gcp/load-balancer` target HTTPS proxies accept the same format in
`certificate_manager_certificates`.

## When to use which (vs `gcp/managed-ssl-certificate`)

- `gcp/managed-ssl-certificate`: classic global Google-managed certs for target
  HTTPS proxies; no DNS authorization managed for you, no regional/self-managed.
- `gcp/certificate-manager`: DNS-authorized managed certs with DNS publishing
  control, regional certs, self-managed uploads, `EDGE_CACHE`/`CLIENT_AUTH`
  scopes, and certificate maps for SNI multiplexing on target proxies.

## Import

- `google_certificate_manager_dns_authorization` ← `projects/{project}/locations/{location}/dnsAuthorizations/{name}`
- `google_certificate_manager_certificate` ← `projects/{project}/locations/{location}/certificates/{name}`
- `google_certificate_manager_certificate_map` ← `projects/{project}/locations/global/certificateMaps/{name}`
- `google_certificate_manager_certificate_map_entry` ← `projects/{project}/locations/global/certificateMaps/{map}/certificateMapEntries/{name}`

## Notes

- Enable `certificatemanager.googleapis.com` via `project-services`.
- `self_managed` PEM data (including the private key) is stored in state as
  plain text; keep the key material in a secret source you accept the state
  implications for, and never commit it.
