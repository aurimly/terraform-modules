# variables file
variable "name" {
  description = "The name of the project"
  type        = string
  default     = ""
}

variable "project_id" {
  description = "The project ID"
  type        = string
  default     = ""
}

variable "org_id" {
  description = "The organization ID"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "The folder ID"
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
  default     = ""
}

variable "auto_create_network" {
  description = "Auto create network"
  type        = bool
  default     = false
}

variable "labels" {
  description = "The labels for the project"
  type        = map(string)
  default     = {}
}

variable "deletion_policy" {
  description = "The deletion policy for the project"
  type        = string
  default     = "PREVENT"
}
