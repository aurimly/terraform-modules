# aws/api-gateway

Map-keyed module for API Gateway HTTP APIs (v2): APIs with CORS
configuration, JWT authorizers, integrations (Lambda proxies, HTTP
proxies, mocks, service subtypes), routes bounded to integrations, one
optional stage per API (with a managed deployment for non-auto-deploy
stages), and custom domain names with API mappings.

REST API (v1) is a separate module — see the Notes.

## Destroy semantics (read before using)

- Removing an api key destroys the API and everything attached to it
  (authorizers, integrations, routes, stage, deployment). Traffic
  through the execute-api endpoint and any mapped domains stops
  immediately.
- Removing the `stage` object destroys the stage (deployed routes stop
  serving; the execute-api URL routes 404 without it) — API calls
  bound to that stage break until a replacement stage exists.
- Removing an integration key breaks every route referencing it — the
  route resource keeps its id but plan fails resolving
  `integration_key`; remove routes first.
- Removing a domain key destroys the domain and drops all its API
  mappings (DNS records pointing at it must follow; the certificate is
  consumer-managed and not destroyed).
- `stage.access_log_settings.destination_arn` must point at a log group
  created elsewhere (pair with `aws/cloudwatch`) that allows API
  Gateway's service principal delivery.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `apis` | `map(object)` | `{}` | HTTP APIs keyed by an arbitrary unique ID; nested `authorizers`, `integrations`, `routes`, `stage`. |
| `domain_names` | `map(object)` | `{}` | Custom domain names keyed by an arbitrary unique ID. |
| `api_mappings` | `map(object)` | `{}` | Paths of the domains above mapped onto APIs. |

### `apis` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | API name. |
| `protocol` | `string` | `HTTP` | `HTTP` or `WEBSOCKET` (validated) — the API Gateway v2 `protocol_type` values. WebSocket-only behavior (route responses) is out of scope; routes carrying API keys (`api_key_required`), `request_models` and `model_selection_expression` are WebSocket-only on the API side. |
| `description` | `string` | — | API description. |
| `disable_execute_api_endpoint` | `bool` | `false` | Turn off the default execute-api endpoint (domains only). |
| `version` | `string` | — | Free-form version label. |
| `ip_address_type` | `string` | — | `ipv4` or `dualstack` (validated). |
| `route_key` | `string` | — | Quick-create route key (`$default`); cannot also appear in `routes` (precondition). |
| `cors_configuration` | `object` | — | `{allow_credentials, allow_headers, allow_methods, allow_origins, expose_headers, max_age}`. |
| `authorizers` | `map(object)` | `{}` | JWT authorizers; `{name, authorizer_type (= "JWT"), identity_sources (typically `$request.header.Authorization`), jwt_configuration {audience, issuer}}`. |
| `integrations` | `map(object)` | `{}` | Integrations keyed per api; see the fields on the route table source: `{integration_type (AWS\_PROXY for Lambda, HTTP_PROXY, ...), integration_uri, integration_method, integration_subtype, payload_format_version, timeout_milliseconds (50–30000, validated), request_parameters, connection_type + connection_id (VPC link consumer-side), credentials_arn, tls_config, description}`. |
| `routes` | `map(object)` | `{}` | Routes; `{route_key ("POST /orders"), integration_key (same api), authorization_type, authorizer_key (same api), api_key_required, request_models, model_selection_expression, operation_name}`. |
| `stage` | `object` | — | Single stage per api; `{name, auto_deploy (default true), description, client_certificate_id, stage_variables, access_log_settings {destination_arn, format}, default_route_settings {throttling_burst_limit, throttling_rate_limit, detailed_metrics_enabled, data_trace_enabled, logging_level (OFF/INFO/ERROR, validated)}}`. With `auto_deploy = false` a `deployment` resource is created and redeployed on route/stage changes. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `domain_names` object

`{domain_name, certificate_arn, endpoint_type (REGIONAL/EDGE,
validated), security_policy (TLS_1_0/TLS_1_2/TLS_1_3, validated),
ip_address_type (ipv4/dualstack, validated — belongs to the domain
configuration),
ownership_verification_certificate_arn,
mutual_tls_authentication {truststore_uri, truststore_version}, tags}`.
The certificate is not created here (pair with `aws/acm`).

### `api_mappings` object

`{api_key (precondition: a key of apis), domain_key (a key of
domain_names), api_mapping_key (path prefix; "" is the root mapping),
stage_name (defaults to the api's stage name, else `$default`)}`.
`domain_key + api_mapping_key` pairs are unique (validated).

## Outputs

`api_ids`, `api_arns`, `api_endpoints` (execute-api URL), `api_execution_arns`.
`stage_ids`, `stage_arns` (usable as a WAFv2 REGIONAL association target),
`stage_invoke_urls`.
`integration_ids`, `route_ids`, `authorizer_ids` — maps of
`"api-key.sub-key"` => id.
`domain_regional_names` — regional domain name per domain key (Route 53
alias target).
`domain_regional_zone_names` — regional hosted zone id (alias zone).
`domain_target_names` — A/AAAA alias target name.
`api_mapping_ids`.

## Example

```hcl
apis = {
  "orders" = {
    name = "example-orders"
    cors_configuration = {
      allow_origins = ["https://example.example"]
      allow_methods = ["GET", "POST"]
    }
    authorizers = {
      "cognito" = {
        name             = "example-cognito"
        identity_sources = ["$request.header.Authorization"]
        jwt_configuration = {
          issuer   = "https://cognito-idp.eu-central-1.amazonaws.com/example"
          audience = ["example-client-id"]
        }
      }
    }
    integrations = {
      "create-order" = {
        integration_type       = "AWS_PROXY"
        integration_uri        = "arn:aws:lambda:eu-central-1:111111111111:function:example-create-order"
        payload_format_version = "2.0"
      }
    }
    routes = {
      "post-orders" = {
        route_key       = "POST /orders"
        integration_key = "create-order"
      }
    }
    stage = {
      name        = "v1"
      auto_deploy = true
    }
  }
}
domain_names = {
  "orders" = {
    domain_name     = "orders.example.example"
    certificate_arn = "arn:aws:acm:eu-central-1:111111111111:certificate/00000000-0000-0000-0000-000000000000"
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}
api_mappings = {
  "orders" = {
    api_key         = "orders"
    domain_key      = "orders"
    api_mapping_key = ""
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — two APIs
  may share a name; the key disambiguates.
- REST API (v1) is a different API generation (resources/methods,
  models, usage plans, API keys, Lambda/REQUEST authorizers) and lives
  in its own module; this one covers HTTP and WebSocket (v2).
- Integrations through a VPC link expect `connection_id` from a VPC
  link created consumer-side. Service integrations use
  `integration_type = "AWS"` with an `aws-api.*` subtype.
- Access-log destinations must pre-allow the API Gateway service
  principal (log group resource policy; pair with `aws/cloudwatch`).
- The provider version floor for the resources used is `>= 6.0.0`.

## Import

`aws_apigatewayv2_api` ← api id.
`aws_apigatewayv2_authorizer` ← `<api-id>/<authorizer-id>`.
`aws_apigatewayv2_integration` ← `<api-id>/<integration-id>`.
`aws_apigatewayv2_route` ← `<api-id>/<route-id>`.
`aws_apigatewayv2_stage` ← `<api-id>/<stage-name>`.
`aws_apigatewayv2_deployment` ← deployment id.
`aws_apigatewayv2_domain_name` ← domain name.
`aws_apigatewayv2_api_mapping` ← `<api-mapping-id>/<domain-name>`.
