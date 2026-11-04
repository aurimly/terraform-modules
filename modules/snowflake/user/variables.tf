variable "users" {
  description = "Map of Snowflake users keyed by an arbitrary identifier. Each entry creates one snowflake_user (human users; service users come from the separate snowflake_service_user resource — not exposed here)."
  type = map(object({
    name                           = string
    login_name                     = optional(string)
    first_name                     = optional(string)
    middle_name                    = optional(string)
    last_name                      = optional(string)
    display_name                   = optional(string)
    email                          = optional(string)
    password                       = optional(string)
    disabled                       = optional(bool)
    must_change_password           = optional(bool)
    days_to_expiry                 = optional(number)
    default_role                   = optional(string)
    default_warehouse              = optional(string)
    default_namespace              = optional(string)
    default_secondary_roles_option = optional(string)
    rsa_public_key                 = optional(string)
    rsa_public_key_2               = optional(string)
    network_policy                 = optional(string)
    log_level                      = optional(string)
    comment                        = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for u in var.users : can(regex("^[^|.\"]+$", u.name))])
    error_message = "name must not contain \"|\", \" or . (provider limitation on user identifiers; values with these characters don't survive apply and break imports). login_name is not restricted — Snowflake accepts any string there (e.g. email-style SSO logins)."
  }

  validation {
    condition = alltrue([
      for u in var.users : u.email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", u.email))
    ])
    error_message = "email must look like an email address."
  }

  validation {
    condition     = alltrue([for u in var.users : u.default_secondary_roles_option == null || contains(["DEFAULT", "NONE", "ALL"], upper(u.default_secondary_roles_option))])
    error_message = "default_secondary_roles_option must be DEFAULT, NONE or ALL (case-insensitive, matching the provider)."
  }

  validation {
    condition     = alltrue([for u in var.users : u.log_level == null || contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF"], upper(u.log_level))])
    error_message = "log_level must be one of TRACE, DEBUG, INFO, WARN, ERROR, FATAL or OFF (case-insensitive, matching the provider)."
  }

  validation {
    condition = alltrue([
      for u in var.users :
      (u.rsa_public_key == null || can(regex("^[A-Za-z0-9+/=]+$", trimspace(u.rsa_public_key)))) &&
      (u.rsa_public_key_2 == null || can(regex("^[A-Za-z0-9+/=]+$", trimspace(u.rsa_public_key_2))))
    ])
    error_message = "rsa_public_key and rsa_public_key_2 must be single-line keys without header and trailer (Snowflake requires one line; strip the BEGIN/END markers and newlines)."
  }

  validation {
    condition = alltrue(flatten([
      for key, u in var.users : [
        for other_key, n in var.users :
        key == other_key || upper(coalesce(u.login_name, u.name)) != upper(coalesce(n.login_name, n.name))
      ]
    ]))
    error_message = "login names must be unique within the account, case-insensitively (login_name defaults to name when unset) — two entries sharing a login name conflict at apply."
  }
}
