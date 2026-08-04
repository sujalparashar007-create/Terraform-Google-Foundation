# 2-folders -- Organization Folder Hierarchy

Creates two top-level folders under the organization with optional
folder-level IAM bindings.

## Resources

- ldr-network -- shared VPC host projects
- ldr-development -- dev/test sandbox projects
- Optional folder-level IAM (projectCreator, etc.)

## Depends On

- 0-bootstrap (reads terraform_sa_email)
- Can run in parallel with 1-org

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
| project_prefix | string | foundation | Prefix for project names |
| region | string | us-east1 | Default region |
| folder_iam_bindings | map(object) | {} | Folder-level IAM |

## Outputs

| Name | Description |
|------|-------------|
| folder_ids | Map of folder name to numeric ID |
| folders | Full folder resource objects |
| folder_names | Map of folder name to resource name |