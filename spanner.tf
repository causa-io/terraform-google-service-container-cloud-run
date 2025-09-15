# Grants the service write access to all databases defined in the service's outputs.
# The format of the output is `<instance>.<database>`.
resource "google_spanner_database_iam_member" "service_spanner" {
  for_each = local.set_spanner_permissions ? {
    for _, o in local.spanner_outputs :
    "${o.instance}.${o.database}" => o
  } : tomap({})

  project  = local.gcp_project_id
  instance = each.value.instance
  database = each.value.database
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${local.service_account_email}"

  depends_on = [
    var.spanner_ddl_dependency,
  ]
}

# If the service uses a Spanner client, it needs to be able to write metrics to Cloud Monitoring.
# Although the permissions are included in the `roles/spanner.databaseUser` role, they are not granted at the project
# level, which makes them useless.
# See https://cloud.google.com/spanner/docs/view-manage-client-side-metrics#access-client-side-metrics.
resource "google_project_iam_member" "service_monitoring_metric_writer" {
  count = length(resource.google_spanner_database_iam_member.service_spanner) > 0 ? 1 : 0

  project = local.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${local.service_account_email}"
}

locals {
  # The parsed outputs for the Spanner databases defined in the service's outputs.
  spanner_outputs = [
    for output in local.conf_spanner_outputs :
    {
      instance = split(".", output)[0]
      database = split(".", output)[1]
    }
  ]

  # Environment variables for the first Spanner database defined in the service's outputs.
  # A single database is supported for now.
  spanner_environment_variables = length(local.spanner_outputs) > 0 ? {
    SPANNER_INSTANCE = local.spanner_outputs[0].instance
    SPANNER_DATABASE = local.spanner_outputs[0].database
  } : {}
}
