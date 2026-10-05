variable "account_id" {
  description = "Cloudflare account ID that owns the tunnels."
  type        = string
}

variable "expose_tokens" {
  description = "Read each tunnel's connector token for the tunnel_tokens output. The token endpoint requires Write scopes and token values land in state; default false."
  type        = bool
  default     = false
}

variable "tunnels" {
  description = "Map of Cloudflare Tunnels (cloudflared) keyed by an arbitrary unique identifier. Locally-managed tunnels need tunnel_secret; remotely-managed tunnels set config_src = \"cloudflare\" and carry optional remote ingress config."
  type = map(object({
    name          = string
    tunnel_secret = optional(string)
    config_src    = optional(string, "local")
    routes = optional(map(object({
      network            = string
      comment            = optional(string)
      virtual_network_id = optional(string)
    })), {})
    config = optional(object({
      ingress = optional(list(object({
        hostname = optional(string)
        path     = optional(string)
        service  = string
        origin_request = optional(object({
          access = optional(object({
            aud_tag   = list(string)
            required  = optional(bool)
            team_name = string
          }))
          ca_pool                  = optional(string)
          connect_timeout          = optional(number)
          disable_chunked_encoding = optional(bool)
          http2_origin             = optional(bool)
          http_host_header         = optional(string)
          keep_alive_connections   = optional(number)
          keep_alive_timeout       = optional(number)
          match_sn_ito_host        = optional(bool)
          no_happy_eyeballs        = optional(bool)
          no_tls_verify            = optional(bool)
          origin_server_name       = optional(string)
          proxy_type               = optional(string)
          tcp_keep_alive           = optional(number)
          tls_timeout              = optional(number)
        }))
      })))
      origin_request = optional(object({
        access = optional(object({
          aud_tag   = list(string)
          required  = optional(bool)
          team_name = string
        }))
        ca_pool                  = optional(string)
        connect_timeout          = optional(number)
        disable_chunked_encoding = optional(bool)
        http2_origin             = optional(bool)
        http_host_header         = optional(string)
        keep_alive_connections   = optional(number)
        keep_alive_timeout       = optional(number)
        match_sn_ito_host        = optional(bool)
        no_happy_eyeballs        = optional(bool)
        no_tls_verify            = optional(bool)
        origin_server_name       = optional(string)
        proxy_type               = optional(string)
        tcp_keep_alive           = optional(number)
        tls_timeout              = optional(number)
      }))
    }))
  }))

  validation {
    condition = alltrue([
      for t in var.tunnels : t.config == null || t.config_src == "cloudflare"
    ])
    error_message = "config (remote ingress) can only be set on tunnels with config_src = \"cloudflare\"."
  }

  validation {
    condition = alltrue([
      for t in var.tunnels : t.tunnel_secret == null || can(base64decode(t.tunnel_secret))
    ])
    error_message = "tunnel_secret must be base64-encoded (build it with base64encode)."
  }
}
