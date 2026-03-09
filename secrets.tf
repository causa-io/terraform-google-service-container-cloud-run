locals {
  secret_refs = {
    for key, secret_ref in local.secret_environment_variables : key =>
    regex("^(?:projects\\/(?P<project>[\\w-]+)\\/secrets\\/)?(?P<secret>[\\w-]+)(?:\\/versions\\/(?P<version>latest|\\d+))?$", secret_ref)
  }

  secrets = {
    for key, matches in local.secret_refs : key => {
      id      = "projects/${coalesce(matches.project, local.gcp_project_id)}/secrets/${matches.secret}"
      version = coalesce(matches.version, "latest")
    }
  }
}

# Grants access to the service account to read the secrets defined in the service's secret environment variables.
# The secret ID should always contain the project ID, so there is no need to specify it here.
resource "google_secret_manager_secret_iam_member" "service_secrets" {
  for_each = local.set_secrets_permissions ? local.secrets : tomap({})

  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.service_account_email}"
}
