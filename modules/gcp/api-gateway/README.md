# gcp/api-gateway

Map-keyed module for Google Cloud API Gateway: APIs, API configs (OpenAPI
or gRPC specs) and gateways serving them. Each entry in `apis` creates one
`google_api_gateway_api`; `api_configs` attach to APIs by key; `gateways`
serve configs by key.

The module binds to the `hashicorp/google-beta` provider — the
`google_api_gateway_*` resources are beta-only upstream and are not
registered by the GA `google` provider (validated against provider v6–v8
binaries). The consumer unit must configure a default `google-beta`
provider (or rely on its implicit configuration with Application Default
Credentials); the module itself never configures providers.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `apis` | `map(object)` | — | Map of APIs keyed by an arbitrary unique ID. |
| `api_configs` | `map(object)` | — | Map of configs keyed by an arbitrary unique ID; `api` wires each config to an API entry. |
| `gateways` | `map(object)` | — | Map of gateways keyed by an arbitrary unique ID; `api_config_key` wires each gateway to a config entry. |

Plan-time validation: `api_id`/`api_config_id`/`gateway_id` shape
(lowercase-letter start, letters/digits/hyphens); `project` shape on all
three entries; `api_configs` entries carry exactly one spec family
(`openapi_documents` XOR `grpc_services`/`managed_service_configs`, and
gRPC requires at least one `managed_service_configs`); all `contents`
fields are base64-decodable; dangling `api`/`api_config_key` references
fail at plan with a keyed message; `deletion_policy` is
`DELETE`/`ABANDON`/`PREVENT`.

### `apis` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `api_id` | `string` | — | API identifier, unique within the project. |
| `project` | `string` | `null` | Project; falls back to the provider project. |
| `display_name` | `string` | `null` | User-visible name. |
| `managed_service` | `string` | `null` | Managed service name. Immutable; a new one is generated when omitted. |
| `labels` | `map(string)` | `{}` | Non-authoritative upstream — only labels present in the configuration are managed; see the `effective_labels` output. |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON` or `PREVENT`. |

### `api_configs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `api` | `string` | — | Key of an `apis` entry. |
| `project` | `string` | `null` | Project; falls back to the provider project. |
| `api_config_id` | `string` | `null` | Fixed config identifier; mutually exclusive with `api_config_id_prefix`. With a fixed id a spec edit cannot be replaced (see Notes) — use the prefix for editable specs. |
| `api_config_id_prefix` | `string` | `null` | Prefix for a generated identifier (a random value when both are unset). |
| `display_name` | `string` | `null` | User-visible name. |
| `labels` | `map(string)` | `{}` | Non-authoritative upstream. |
| `openapi_documents` | `list(object)` | `null` | OpenAPI specs, each `{document: {path, contents}}`; excludes gRPC/managed-service documents. |
| `grpc_services` | `list(object)` | `null` | gRPC definitions, each `{file_descriptor_set: {path, contents}, source?: {path, contents}}`; requires at least one `managed_service_configs`. |
| `managed_service_configs` | `list(object)` | `null` | Service configuration files, each `{path, contents}`. |
| `gateway_config` | `object` | `null` | `{backend_config: {google_service_account}}` — the SA signing OIDC tokens for backends; immutable. Unset means OIDC via the default compute service account. |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON` or `PREVENT`. |

All `contents` fields are base64 strings — supply them with
`filebase64("spec.yaml")` or `base64encode(...)`; the module does not read
files.

### `gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `api_config_key` | `string` | — | Key of an `api_configs` entry the gateway serves. |
| `gateway_id` | `string` | — | Gateway identifier, unique within the project. |
| `project` | `string` | `null` | Project; falls back to the provider project. |
| `display_name` | `string` | `null` | User-visible name. |
| `labels` | `map(string)` | `{}` | Non-authoritative upstream. |
| `region` | `string` | `null` | Gateway region; defaults to the provider's region. |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON` or `PREVENT`. |

## Outputs

| Name | Description |
|---|---|
| `api_names` | Map of api key => resource name. |
| `api_managed_services` | Map of api key => managed service name. |
| `api_config_names` | Map of config key => resource name. |
| `api_config_service_config_ids` | Map of config key => generated service config id. |
| `gateway_names` | Map of gateway key => resource name. |
| `gateway_default_hostnames` | Map of gateway key => default hostname (the `gateway.dev` URL clients call). |
| `gateway_effective_labels` | Map of gateway key => all labels present on the resource in GCP. |

## Example

```hcl
apis = {
  "catalog" = {
    api_id       = "catalog-api"
    display_name = "Catalog API"
  }
}

api_configs = {
  "v1" = {
    api                  = "catalog"
    api_config_id_prefix = "catalog-"
    openapi_documents = [
      {
        document = {
          path     = "spec.yaml"
          contents = filebase64("spec.yaml")
        }
      }
    ]
    gateway_config = {
      backend_config = {
        google_service_account = "api-backend@example-prj.iam.gserviceaccount.com"
      }
    }
  }
}

gateways = {
  "prod" = {
    api_config_key = "v1"
    gateway_id     = "catalog-gateway"
    region         = "europe-west4"
  }
}
```

## Notes

- **Beta provider binding**: the module binds all three resources to
  `hashicorp/google-beta` (`provider = google-beta`); the consumer unit
  configures that provider. Do not set `provider` per resource from the
  consumer side — the binding is in-module.
- **API configs are immutable upstream** — editing a spec replaces the
  config. The module sets `create_before_destroy` on
  `google_api_gateway_api_config`, so the gateway keeps serving while the
  replacement config is created and repoints in-module; the old config is
  destroyed after. The provider docs require exactly this setup.
- **Config rotation needs a generated id**: with a fixed `api_config_id`,
  the replacement carries the same id and its create fails with
  `409 ALREADY_EXISTS` while the old config still exists — even with
  `create_before_destroy`. Rotate specs with `api_config_id_prefix` (or
  leave both unset for a fully generated id); a fixed id is only for
  configs that are never edited.
- The `apigateway.googleapis.com` service must be enabled in the target
  project — pair with `gcp/project-services`.
- `gateway_config` (backend authentication) is immutable; changing it
  replaces the config.
- Labels are non-authoritative upstream on all three resources: the
  module manages only the labels it is given; `effective_labels` (exposed
  for gateways) shows everything on the resource.
- `managed_service` on the API is immutable; omit it to let the API
  generate one and read it from `api_managed_services`.
- The caller needs API Gateway admin permissions and the ability to
  enable services and read the backend service account.

## Import

`google_api_gateway_api` ←
`projects/{project}/locations/global/apis/{api_id}`
(short forms `{project}/{api_id}` and `{api_id}` also work).

`google_api_gateway_api_config` ←
`projects/{project}/locations/global/apis/{api}/configs/{api_config_id}`
(short forms `{project}/{api}/{api_config_id}` and
`{api}/{api_config_id}` also work).

`google_api_gateway_gateway` ←
`projects/{project}/locations/{region}/gateways/{gateway_id}`
(short forms `{project}/{region}/{gateway_id}`,
`{region}/{gateway_id}` and `{gateway_id}` also work).
