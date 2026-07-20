# ── Bootstrap provider — uses the human operator's credentials (gcloud auth ADC).
# There is no SA to impersonate yet — that SA is created BY this stage.
# All downstream stages will impersonate the Terraform SA this stage outputs.

provider "google" {
  region = var.region
}
