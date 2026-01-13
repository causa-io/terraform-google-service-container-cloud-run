locals {
  service_account_email = var.service_account != null ? var.service_account.email : google_service_account.service[0].email
}

# The automatically-created service account for the Cloud Run service.
resource "google_service_account" "service" {
  count = var.service_account != null ? 0 : 1

  project      = local.gcp_project_id
  account_id   = substr(local.service_name, 0, 30)
  display_name = "${local.service_name} Cloud Run service"
  description  = "The service account used by Cloud Run for the ${local.service_name} service."
}
