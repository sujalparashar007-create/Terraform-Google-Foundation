# 3-host-projects -- Shared VPC Host Projects

Creates host projects for hub and dev environments under their respective
folders.

## Resources

- oundation-hub-host-01 -- under fldr-network
- oundation-dev-host-01 -- under fldr-development
- Default APIs: compute, dns, iap

## Depends On

- 0-bootstrap (terraform_sa_email)
- 2-folders (folder_ids)

## Usage

`ash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| org_id | string | required | Numeric org ID |
| billing_account | string | required | Billing account ID |
| project_prefix | string | foundation | Prefix for project IDs |
| region | string | us-east1 | Default region |
| host_project_apis | map(list(string)) | {} | Per-host API overrides |

## Outputs

| Name | Description |
|------|-------------|
| project_ids | Map of host key to project ID |
| project_numbers | Map of host key to project number |