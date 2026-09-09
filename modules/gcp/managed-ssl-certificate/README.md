# gcp/managed-ssl-certificate

Map-keyed module for Google-managed SSL certificates. Certificates created
here attach to load balancers created by `gcp/load-balancer` (see Outputs).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `certificates` | `map(object)` | — | Map of certificates keyed by an arbitrary unique ID. |

### `certificates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Certificate name, RFC1035 (validated). Immutable. |
| `project_id` | `string` | — | Project the certificate lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Free-text description. |
| `managed` | `object` | — | `{domains}` — 1–100 domains (validated). Changing `domains` forces replacement. |

## Outputs

`certificate_ids` — map of certificate key => certificate id.
`certificate_self_links` — map of certificate key => self link. Pass to
`gcp/load-balancer` `https_proxies[].ssl_certificates`.
`certificate_names` — map of certificate key => certificate name.
`certificate_domains` — map of certificate key => managed domains list.
`certificate_expire_time` — map of certificate key => expire time (RFC3339) of
the most recently generated certificate — what consumers alert on.
`certificate_subject_alternative_names` — map of certificate key => subject
alternative names of the most recently generated certificate.

## Example

```hcl
certificates = {
  "app" = {
    name        = "example-app-cert"
    description = "managed certificate for example.example.com"
    managed = {
      domains = ["example.example.com"]
    }
  },
}
```

Wired into `gcp/load-balancer`:

```hcl
https_proxies = {
  "app" = {
    name            = "example-app-https-proxy"
    ssl_certificates = [module.cert.certificate_self_links["app"]]
    ...
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- A managed certificate only finishes provisioning once it is attached to a
  target HTTPS proxy and the domains resolve (via DNS) to the load balancer's
  IP; until then its status stays PROVISIONING.
- Rotating domains forces certificate replacement (names are immutable). The
  provider-recommended pattern is a second certificate + a proxy update, i.e.
  `lifecycle { create_before_destroy = true }` on the certificate resource in
  the consumer, switching the proxy to the new certificate before the old one
  is destroyed.
- Self-managed certificates (the `certificate` block, private key in state)
  are intentionally out of scope — file an issue if you need them.
- Pair with `gcp/project-services` (`compute.googleapis.com`) when the target
  project does not have the Compute Engine API enabled yet; this module does
  not enable APIs itself.

## Import

`google_compute_managed_ssl_certificate` ←
`projects/{project}/global/sslCertificates/{name}`.
