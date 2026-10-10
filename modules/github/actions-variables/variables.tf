variable "repository" {
  description = "GitHub repository name to create the variables in."
  type        = string
}

variable "variables" {
  description = "Map of Actions variables keyed by variable name. Keys are the actual variable names, so they must not contain ':'."
  type = map(object({
    value = string
  }))
}
