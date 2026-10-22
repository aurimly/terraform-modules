resource "aws_apigatewayv2_api" "api" {
  for_each = var.apis

  name                         = each.value.name
  protocol_type                = each.value.protocol
  description                  = each.value.description
  disable_execute_api_endpoint = each.value.disable_execute_api_endpoint
  version                      = each.value.version
  ip_address_type              = each.value.ip_address_type

  dynamic "cors_configuration" {
    for_each = each.value.cors_configuration != null ? [each.value.cors_configuration] : []
    content {
      allow_credentials = cors_configuration.value.allow_credentials
      allow_headers     = cors_configuration.value.allow_headers
      allow_methods     = cors_configuration.value.allow_methods
      allow_origins     = cors_configuration.value.allow_origins
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = each.value.route_key == null || !contains([for r in each.value.routes : r.route_key], each.value.route_key)
      error_message = "api \"${each.key}\": a quick-create route_key (\"${each.value.route_key}\") cannot also be declared in routes — remove one of the two."
    }
  }
}

resource "aws_apigatewayv2_authorizer" "authorizer" {
  for_each = local.authorizers

  api_id           = aws_apigatewayv2_api.api[each.value.api_key].id
  name             = each.value.name
  authorizer_type  = each.value.authorizer_type
  identity_sources = each.value.identity_sources

  jwt_configuration {
    audience = each.value.jwt_configuration.audience
    issuer   = each.value.jwt_configuration.issuer
  }
}

resource "aws_apigatewayv2_integration" "integration" {
  for_each = local.integrations

  api_id                    = aws_apigatewayv2_api.api[each.value.api_key].id
  integration_type          = each.value.integration_type
  integration_uri           = each.value.integration_uri
  integration_method        = each.value.integration_method
  integration_subtype       = each.value.integration_subtype
  passthrough_behavior      = each.value.passthrough_behavior
  payload_format_version    = each.value.payload_format_version
  content_handling_strategy = each.value.content_handling_strategy
  timeout_milliseconds      = each.value.timeout_milliseconds
  request_parameters        = each.value.request_parameters
  connection_id             = each.value.connection_id
  connection_type           = each.value.connection_type
  credentials_arn           = each.value.credentials_arn
  description               = each.value.description

  dynamic "tls_config" {
    for_each = each.value.tls_config != null ? [each.value.tls_config] : []
    content {
      server_name_to_verify = tls_config.value.server_name_to_verify
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.connection_type != "VPC_LINK" || each.value.connection_id != null
      error_message = "integration \"${each.key}\": connection_type VPC_LINK requires connection_id (the VPC link itself is created consumer-side)."
    }
  }
}

resource "aws_apigatewayv2_route" "route" {
  for_each = local.routes

  api_id                     = aws_apigatewayv2_api.api[each.value.api_key].id
  route_key                  = each.value.route_key
  operation_name             = each.value.operation_name
  api_key_required           = each.value.api_key_required
  request_models             = each.value.request_models
  model_selection_expression = each.value.model_selection_expression
  authorization_type         = each.value.authorization_type
  authorizer_id              = each.value.authorizer_id
  target                     = each.value.target

  depends_on = [aws_apigatewayv2_api.api]
}

resource "aws_apigatewayv2_deployment" "deployment" {
  for_each = { for k, a in var.apis : k => a if a.stage != null && !a.stage.auto_deploy }

  api_id      = aws_apigatewayv2_api.api[each.key].id
  description = "deployment for stage ${each.value.stage.name}"
  triggers    = { redeployment = sha1(jsonencode([each.value.routes, each.value.integrations, each.value.authorizers, each.value.stage])) }

  depends_on = [
    aws_apigatewayv2_route.route,
    aws_apigatewayv2_integration.integration,
    aws_apigatewayv2_api.api,
  ]
}

resource "aws_apigatewayv2_stage" "stage" {
  for_each = { for k, a in var.apis : k => a if a.stage != null }

  api_id                = aws_apigatewayv2_api.api[each.key].id
  name                  = each.value.stage.name
  description           = each.value.stage.description
  auto_deploy           = each.value.stage.auto_deploy
  deployment_id         = !each.value.stage.auto_deploy ? aws_apigatewayv2_deployment.deployment[each.key].id : null
  stage_variables       = each.value.stage.stage_variables
  client_certificate_id = each.value.stage.client_certificate_id

  dynamic "access_log_settings" {
    for_each = each.value.stage.access_log_settings != null ? [each.value.stage.access_log_settings] : []
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }

  dynamic "default_route_settings" {
    for_each = each.value.stage.default_route_settings != null ? [each.value.stage.default_route_settings] : []
    content {
      data_trace_enabled       = default_route_settings.value.data_trace_enabled
      detailed_metrics_enabled = default_route_settings.value.detailed_metrics_enabled
      logging_level            = default_route_settings.value.logging_level
      throttling_burst_limit   = default_route_settings.value.throttling_burst_limit
      throttling_rate_limit    = default_route_settings.value.throttling_rate_limit
    }
  }

  tags = merge(each.value.tags, { Name = "${each.value.name}-${each.value.stage.name}" })
}

resource "aws_apigatewayv2_domain_name" "domain" {
  for_each = var.domain_names

  domain_name = each.value.domain_name

  domain_name_configuration {
    certificate_arn                        = each.value.certificate_arn
    endpoint_type                          = each.value.endpoint_type
    security_policy                        = each.value.security_policy
    ip_address_type                        = each.value.ip_address_type
    ownership_verification_certificate_arn = each.value.ownership_verification_certificate_arn
  }

  dynamic "mutual_tls_authentication" {
    for_each = each.value.mutual_tls_authentication != null ? [each.value.mutual_tls_authentication] : []
    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = mutual_tls_authentication.value.truststore_version
    }
  }

  tags = merge(each.value.tags, { Name = each.value.domain_name })
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  for_each = local.api_mappings

  api_id          = aws_apigatewayv2_api.api[each.value.api_key].id
  domain_name     = var.domain_names[each.value.domain_key].domain_name
  stage           = each.value.stage_name
  api_mapping_key = each.value.api_mapping_key

  lifecycle {
    precondition {
      condition     = contains(keys(var.apis), each.value.api_key)
      error_message = "api_mapping \"${each.key}\": api_key \"${each.value.api_key}\" must be a key of var.apis."
    }

    precondition {
      condition     = contains(keys(var.domain_names), each.value.domain_key)
      error_message = "api_mapping \"${each.key}\": domain_key \"${each.value.domain_key}\" must be a key of var.domain_names."
    }
  }
}

locals {
  authorizers = merge([
    for api_key, api in var.apis : {
      for auth_key, auth in api.authorizers : "${api_key}.${auth_key}" => {
        api_key           = api_key
        name              = auth.name
        authorizer_type   = auth.authorizer_type
        identity_sources  = auth.identity_sources
        jwt_configuration = auth.jwt_configuration
      }
    }
  ]...)

  integrations = merge([
    for api_key, api in var.apis : {
      for integration_key, integration in api.integrations : "${api_key}.${integration_key}" => merge(integration, {
        api_key = api_key
      })
    }
  ]...)

  routes = merge([
    for api_key, api in var.apis : {
      for route_key, route in api.routes : "${api_key}.${route_key}" => merge(route, {
        api_key            = api_key
        authorization_type = route.authorizer_key != null ? "JWT" : coalesce(route.authorization_type, "NONE")
        authorizer_id      = route.authorizer_key != null ? aws_apigatewayv2_authorizer.authorizer["${api_key}.${route.authorizer_key}"].id : null
        target             = route.integration_key != null ? "integrations/${aws_apigatewayv2_integration.integration["${api_key}.${route.integration_key}"].id}" : null
      })
    }
  ]...)

  api_mappings = {
    for mapping_key, mapping in var.api_mappings : mapping_key => merge(mapping, {
      stage_name = mapping.stage_name != null ? mapping.stage_name : try(var.apis[mapping.api_key].stage.name, "$default")
    })
  }
}
