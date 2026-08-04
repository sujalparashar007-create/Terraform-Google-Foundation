# hub-test -- Hub Validation VM

Deploys an e2-micro compute VM directly in the hub host project to validate
hub-side networking: IAP SSH, DNS resolution, connectivity.

## Resources

- e2-micro VM (vm-hub-test) in hub host project on Debian 11
- IAP + OS Login IAM for operators

## Depends On

- 0-bootstrap (terraform_sa_email)
- 3-host-projects (project_ids)
- 4-networks (hub_subnet_self_link)

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
| project_prefix | string | foundation | Prefix for project names |
| region | string | us-east1 | GCP region |
| zone | string | us-east1-b | VM zone |
| vm_operators | list(string) | [] | Users allowed to SSH via IAP |

## Outputs

| Name | Description |
|------|-------------|
| vm_name | VM instance name |
| vm_self_link | VM self-link |
| vm_internal_ip | VM internal IP |
| hub_project_id | Hub host project ID |