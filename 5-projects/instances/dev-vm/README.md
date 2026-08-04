# dev-vm -- Dev Spoke Validation VM

Deploys a service project + single e2-micro compute VM in the dev spoke to
validate end-to-end networking: IAP SSH, egress via NAT, DNS.

## Resources

- Service project (foundation-dev-svc-vm-01)
- Shared VPC attachment to dev host
- Custom compute service account
- e2-micro VM (vm-dev-test) on Debian 11
- IAP + OS Login IAM for operators

## Depends On

- 0-bootstrap (terraform_sa_email)
- 2-folders (folder_ids)
- 3-host-projects (project_ids)
- 4-networks (spoke_subnets)

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
| project_id | Service project ID |