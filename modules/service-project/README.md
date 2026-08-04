# service-project -- Shared VPC Service Project

Creates a service project, attaches it as a Shared VPC service project to a
host project, and grants networkUser IAM on the target subnet.

## Usage

`hcl
module "service_project" {
  source = "../../../modules/service-project"

  org_id               = "123456789"
  billing_account      = "XXXXXX-XXXXXX-XXXXXX"
  folder_id            = "987654321"
  host_project_id      = "my-dev-host"
  service_project_name = "prj-dev-svc-vm"
  service_project_id   = "foundation-dev-svc-vm-01"
  subnet_self_link     = module.spoke["dev"].subnet_self_link
  region               = "us-east1"
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| org_id | string | required | Numeric org ID |
| billing_account | string | required | Billing account ID |
| folder_id | string | required | Numeric folder ID |
| host_project_id | string | required | Host project ID |
| service_project_name | string | required | Display name |
| service_project_id | string | required | Unique project ID |
| subnet_self_link | string | required | Target subnet self-link |
| region | string | us-east1 | GCP region |
| activate_apis | list(string) | [] | Additional APIs |

## Outputs

| Name | Description |
|------|-------------|
| project_id | Service project ID |
| project_number | Service project number |
| compute_sa_email | Compute engine service account email |
| subnet_self_link | Subnet self-link (passthrough) |