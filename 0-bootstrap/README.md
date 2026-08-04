# 0-bootstrap -- Foundation Bootstrapping

Creates the seed project, Terraform CI/CD service account, and GCS state bucket.
This is the **first stage** -- all downstream stages depend on it.

## Resources

- Seed project (hosts state bucket + Terraform SA)
- 8 required APIs enabled
- 	f-executor service account with org-level IAM
- GCS state bucket (versioned, uniform access)

## Prerequisites

- GCP Organization admin access
- Billing account ID
- gcloud auth application-default login for initial apply

## Usage

`ash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your org_id, billing_account
terraform init
terraform plan
terraform apply
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| org_id | string | required | Numeric org ID |
| billing_account | string | required | Billing account ID |
| region | string | us-east1 | Default region |
| project_prefix | string | foundation | Prefix for project names |
| seed_project_name | string | prj-bootstrap-seed | Seed project name |
| terraform_operators | list(string) | [] | Users allowed to impersonate TF SA |

## Outputs

| Name | Description |
|------|-------------|
| terraform_sa_email | SA impersonated by downstream stages |
| state_bucket_name | GCS bucket for all Terraform state |
| seed_project_id | Bootstrap project ID |