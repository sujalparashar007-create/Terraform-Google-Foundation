# ==============================================================================
# MODULE: folder — variables
# ==============================================================================

variable "parent" {
  description = "Parent resource in format 'organizations/ORG_ID' or 'folders/FOLDER_ID'"
  type        = string
}

variable "names" {
  description = "Set of folder display names to create under the parent"
  type        = set(string)
}

variable "folder_iam" {
  description = "Optional folder-level IAM bindings. Key = binding key, value = { folder_key, role, member }"
  type = map(object({
    folder_key = string # key matching one entry in var.names
    role       = string
    member     = string
  }))
  default = {}
}
