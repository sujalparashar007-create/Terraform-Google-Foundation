variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "Billing Account ID"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for project names"
  type        = string
  default     = "foundation"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east1-b"
}

variable "vm_operators" {
  description = "Users who can SSH into the VM via IAP"
  type        = list(string)
  default     = ["sujalparashar007@gmail.com"]
}
