provider "google" {
  project                     = "foundation-bootstrap-seed"
  billing_project             = "foundation-bootstrap-seed"
  region                      = "us-east1"
  impersonate_service_account = "tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}
