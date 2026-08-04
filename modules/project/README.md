# project -- GCP Project Factory

Creates a GCP project and enables required APIs. Single source of truth for
project creation across all foundation stages.

## Usage

`hcl
module "project" {
  source = "../modules/project"

  name            = "prj-my-app"
  project_id      = "myco-my-app-abc123"
  org_id          = "123456789"
  billing_account = "XXXXXX-XXXXXX-XXXXXX"
  folder_id       = "987654321"
  activate_apis   = ["compute.googleapis.com", "dns.googleapis.com"]
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| name | string | required | Display name |
| project_id | string | required | Globally unique project ID |
| org_id | string | required | Numeric org ID |
| billing_account | string | required | Billing account ID |
| folder_id | string | "" | Numeric folder ID (empty = org root) |
| auto_create_network | bool | false | Auto-create default VPC |
| activate_apis | list(string) | [] | APIs to enable |
| labels | map(string) | {} | Project labels |

## Outputs

| Name | Description |
|------|-------------|
| project_id | Globally unique project ID |
| project_number | Numeric project number |
| project_name | Display name |