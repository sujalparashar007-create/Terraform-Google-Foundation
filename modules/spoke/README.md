# spoke -- Spoke VPC + Subnet

Creates a spoke VPC with a primary subnet and optional GKE secondary IP ranges.
Supports vm, gke, and mixed workload types.

## Usage

`hcl
module "spoke" {
  source = "../modules/spoke"

  project_id    = "my-dev-host"
  region        = "us-east1"
  env_name      = "dev"
  spoke_cidr    = "10.16.0.0/16"
  vpc_name      = "vpc-dev-spoke"
  subnet_name   = "sb-dev-vm-us-east1"
  subnet_cidr   = "10.16.0.0/22"
  workload_type = "vm"
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| project_id | string | required | GCP project ID |
| region | string | required | GCP region |
| env_name | string | required | Environment name |
| spoke_cidr | string | required | CIDR for spoke |
| vpc_name | string | required | VPC name |
| subnet_name | string | required | Subnet name |
| subnet_cidr | string | required | Subnet CIDR |
| workload_type | string | vm | vm / gke / mixed |
| pod_cidr | string | "" | GKE pod CIDR |
| svc_cidr | string | "" | GKE services CIDR |

## Outputs

| Name | Description |
|------|-------------|
| vpc_self_link | Spoke VPC self-link |
| vpc_id | Spoke VPC ID |
| vpc_name | Spoke VPC name |
| subnet_self_link | Primary subnet self-link |
| subnet_name | Primary subnet name |
| subnet_cidr | Primary subnet CIDR |
| pod_range_name | GKE pod range name (vm = "") |
| svc_range_name | GKE services range name (vm = "") |