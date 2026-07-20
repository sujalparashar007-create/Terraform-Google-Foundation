terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # No backend block — bootstrap creates the GCS state bucket.
  # After `terraform apply`, uncomment the block below and run
  # `terraform init -migrate-state` to move state into the bucket:

  backend "gcs" {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "0-bootstrap"
  }
}
