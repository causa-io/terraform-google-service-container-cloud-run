# Firestore permissions are set at the project level because there is a single default database per project.
# The `roles/datastore.user` grants read and write access to the database.
# Permissions are set if at least one collection is defined in the service's outputs.
resource "google_project_iam_member" "service_firestore_user" {
  count = local.set_firestore_permissions && length(local.conf_firestore_outputs) > 0 ? 1 : 0

  project = local.gcp_project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${local.service_account_email}"
}
