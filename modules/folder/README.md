# folder -- Google Cloud Folder Factory

Creates one or more folders under a given parent (organization or folder) with
optional folder-level IAM bindings.

## Usage

`hcl
module "folders" {
  source = "../modules/folder"

  parent = "organizations/123456789"
  names  = toset(["fldr-network", "fldr-development"])

  folder_iam = {
    dev_creator = {
      folder_key = "fldr-development"
      role       = "roles/resourcemanager.projectCreator"
      member     = "group:dev-team@example.com"
    }
  }
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| parent | string | required | Parent in format organizations/NNN or folders/NNN |
| names | set(string) | required | Set of folder display names |
| folder_iam | map(object) | {} | Folder-level IAM bindings |

## Outputs

| Name | Description |
|------|-------------|
| folder_ids | Map of folder name to numeric folder ID |
| folders | Full folder resource objects |
| folder_names | Map of folder name to full resource name |