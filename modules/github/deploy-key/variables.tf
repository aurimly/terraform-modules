variable "repository" {
  description = "GitHub repository name to add the deploy keys to."
  type        = string
}

variable "deploy_keys" {
  description = "Map of deploy keys keyed by arbitrary stable identifier. Keys must not contain ':' — the key falls back to the default <key>:<id> separator used in import IDs. Keys are not titles; the title reverts to each.map-key when none is set."
  type = map(object({
    key       = string
    title     = optional(string)
    read_only = optional(bool, true)
  }))
}
