variable "grants" {
  description = "Map of privilege grants to account roles keyed by an arbitrary identifier. Each entry creates one snowflake_grant_privileges_to_account_role: a privilege set (+ optional grant option and management flags) granted to one account role on one target — the account itself, an account object, a schema(-level choice), or a schema object."
  type = map(object({
    account_role_name           = string
    privileges                  = optional(set(string))
    all_privileges              = optional(bool)
    with_grant_option           = optional(bool, false)
    always_apply                = optional(bool, false)
    strict_privilege_management = optional(bool)
    on_account                  = optional(bool)
    on_account_object = optional(object({
      object_type = optional(string)
      object_name = optional(string)
      inherited = optional(object({
        object_type_plural = string
      }))
    }))
    on_schema = optional(object({
      schema_name                = optional(string)
      all_schemas_in_database    = optional(string)
      future_schemas_in_database = optional(string)
      inherited = optional(object({
        in_account  = optional(bool)
        in_database = optional(string)
      }))
    }))
    on_schema_object = optional(object({
      object_type = optional(string)
      object_name = optional(string)
      all = optional(object({
        object_type_plural = string
        in_database        = optional(string)
        in_schema          = optional(string)
      }))
      future = optional(object({
        object_type_plural = string
        in_database        = optional(string)
        in_schema          = optional(string)
      }))
      inherited = optional(object({
        object_type_plural = string
        in_account         = optional(bool)
        in_database        = optional(string)
        in_schema          = optional(string)
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for g in var.grants : [
        (g.on_account == true ? 1 : 0) + (g.on_account_object != null ? 1 : 0) + (g.on_schema != null ? 1 : 0) + (g.on_schema_object != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "each entry must set exactly one target: on_account, on_account_object, on_schema or on_schema_object."
  }

  validation {
    condition = alltrue([
      for g in var.grants :
      (g.privileges != null) != (g.all_privileges == true ? true : false)
    ])
    error_message = "set exactly one of privileges or all_privileges per entry (module policy — the provider examples use all_privileges alone; list privileges individually otherwise)."
  }

  validation {
    condition     = alltrue([for g in var.grants : g.privileges == null || length(g.privileges) > 0 && alltrue([for p in g.privileges : p == upper(p)])])
    error_message = "privileges must be a non-empty, UPPER-CASE list (the field is case-sensitive: use only upper-case privilege names, e.g. \"SELECT\", \"CREATE TABLE\")."
  }

  validation {
    condition = alltrue([for g in var.grants : (
      g.on_account_object == null || (
        ((g.on_account_object.object_type != null && g.on_account_object.object_name != null) ? 1 : 0) + (g.on_account_object.inherited != null ? 1 : 0) == 1
        && (g.on_account_object.inherited == null || (g.on_account_object.object_type == null && g.on_account_object.object_name == null))
      )
    )])
    error_message = "within on_account_object, set either object_type together with object_name, or inherited (with its object_type_plural) alone — module policy matching the provider conflicts (object_type rejects inherited; object_name and inherited are mutually exclusive)."
  }

  validation {
    condition     = alltrue([for g in var.grants : g.strict_privilege_management != true || (g.all_privileges != true && (g.on_schema == null || g.on_schema.all_schemas_in_database == null) && (g.on_schema_object == null || g.on_schema_object.all == null))])
    error_message = "strict_privilege_management cannot be combined with all_privileges, or with all-objects targets (on_schema.all_schemas_in_database, on_schema_object.all) — module policy mirroring the provider's plan-time conflicts."
  }

  validation {
    condition = alltrue([for g in var.grants : (
      (g.with_grant_option != true || (g.on_account_object == null || g.on_account_object.inherited == null) && (g.on_schema == null || g.on_schema.inherited == null) && (g.on_schema_object == null || g.on_schema_object.inherited == null)) &&
      (g.always_apply != true || (g.on_account_object == null || g.on_account_object.inherited == null) && (g.on_schema == null || g.on_schema.inherited == null) && (g.on_schema_object == null || g.on_schema_object.inherited == null))
    )])
    error_message = "with_grant_option and always_apply cannot accompany inherited grants (module policy mirroring the provider's inherited-grants validation)."
  }

  validation {
    condition = alltrue([for g in var.grants :
      g.on_schema == null || (
        length(compact([g.on_schema.schema_name, g.on_schema.all_schemas_in_database, g.on_schema.future_schemas_in_database])) + (g.on_schema.inherited != null ? 1 : 0) == 1
      )
    ])
    error_message = "within on_schema, set exactly one of schema_name, all_schemas_in_database, future_schemas_in_database or inherited (module policy)."
  }

  validation {
    condition = alltrue([for g in var.grants :
      g.on_schema == null || g.on_schema.inherited == null ||
      ((g.on_schema.inherited.in_account == true ? 1 : 0) + (g.on_schema.inherited.in_database != null ? 1 : 0)) == 1
    ])
    error_message = "within on_schema.inherited, set exactly one of in_account or in_database (module policy mirroring the provider's exactly-one-of)."
  }

  validation {
    condition = alltrue([for g in var.grants :
      g.on_schema_object == null || (
        (g.on_schema_object.object_type != null && g.on_schema_object.object_name != null ? 1 : 0) +
        (g.on_schema_object.all != null ? 1 : 0) +
        (g.on_schema_object.future != null ? 1 : 0) +
        (g.on_schema_object.inherited != null ? 1 : 0) == 1
      )
    ])
    error_message = "within on_schema_object, set exactly one of object_type+object_name, all, future or inherited (module policy)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.grants : [
        g.on_schema_object == null || g.on_schema_object.all == null ||
        length(compact([g.on_schema_object.all.in_database, g.on_schema_object.all.in_schema])) <= 1,
        g.on_schema_object == null || g.on_schema_object.future == null ||
        length(compact([g.on_schema_object.future.in_database, g.on_schema_object.future.in_schema])) <= 1,
        g.on_schema_object == null || g.on_schema_object.inherited == null ||
        ((g.on_schema_object.inherited.in_account == true ? 1 : 0) + (g.on_schema_object.inherited.in_database != null ? 1 : 0) + (g.on_schema_object.inherited.in_schema != null ? 1 : 0)) == 1
      ]
    ]))
    error_message = "within on_schema_object all/future, set at most one scope (in_database or in_schema); within inherited, set exactly one scope (in_account, in_database or in_schema) (module policy mirroring the provider)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.grants : [
        for s in compact([
          g.account_role_name,
          g.on_account_object != null ? g.on_account_object.object_type : null,
          g.on_account_object != null ? g.on_account_object.object_name : null,
          g.on_account_object != null && g.on_account_object.inherited != null ? g.on_account_object.inherited.object_type_plural : null,
          g.on_schema != null ? g.on_schema.schema_name : null,
          g.on_schema != null ? g.on_schema.all_schemas_in_database : null,
          g.on_schema != null ? g.on_schema.future_schemas_in_database : null,
          g.on_schema != null && g.on_schema.inherited != null ? g.on_schema.inherited.in_database : null,
          g.on_schema_object != null ? g.on_schema_object.object_type : null,
          g.on_schema_object != null ? g.on_schema_object.object_name : null,
          g.on_schema_object != null && g.on_schema_object.all != null ? g.on_schema_object.all.object_type_plural : null,
          g.on_schema_object != null && g.on_schema_object.all != null ? g.on_schema_object.all.in_database : null,
          g.on_schema_object != null && g.on_schema_object.all != null ? g.on_schema_object.all.in_schema : null,
          g.on_schema_object != null && g.on_schema_object.future != null ? g.on_schema_object.future.object_type_plural : null,
          g.on_schema_object != null && g.on_schema_object.future != null ? g.on_schema_object.future.in_database : null,
          g.on_schema_object != null && g.on_schema_object.future != null ? g.on_schema_object.future.in_schema : null,
          g.on_schema_object != null && g.on_schema_object.inherited != null ? g.on_schema_object.inherited.object_type_plural : null,
          g.on_schema_object != null && g.on_schema_object.inherited != null ? g.on_schema_object.inherited.in_database : null,
          g.on_schema_object != null && g.on_schema_object.inherited != null ? g.on_schema_object.inherited.in_schema : null
        ]) : !can(regex("\\|", s)) && length(trimspace(s)) > 0
      ]
    ]))
    error_message = "all role, object, database and schema references must be non-empty and must not contain \"|\" (the import identifier separates fields with pipes). Quoted fully qualified identifiers are accepted."
  }
}
