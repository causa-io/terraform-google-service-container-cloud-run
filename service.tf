locals {
  # This module supports passing either the name of the connector (e.g. `my-connector`) or its full path (e.g.
  # `projects/my-project/locations/my-location/connectors/my-connector`).
  # If only the name is passed, the full name is inferred from the configured project ID and location.
  vpc_connector_full_name = (
    local.vpc_connector_name != null
    ? try(regex("^projects\\/[\\w-]+\\/locations\\/[\\w-]+\\/connectors\\/[\\w-]+$", local.vpc_connector_name), null) != null
    ? local.vpc_connector_name
    : "projects/${local.gcp_project_id}/locations/${local.location}/connectors/${local.vpc_connector_name}"
    : null
  )
}

# The Cloud Run service itself.
resource "google_cloud_run_v2_service" "service" {
  project  = local.gcp_project_id
  name     = local.service_name
  location = local.location

  ingress = local.ingress

  scaling {
    min_instance_count = local.min_instances
    max_instance_count = local.max_instances
    scaling_mode       = "AUTOMATIC"
  }

  template {
    containers {
      image = local.image

      resources {
        limits = {
          cpu    = local.cpu_limit
          memory = local.memory_limit
        }

        cpu_idle          = !local.cpu_always_allocated
        startup_cpu_boost = local.startup_cpu_boost
      }

      dynamic "env" {
        for_each = local.environment_variables
        iterator = env_var

        content {
          name  = env_var.key
          value = env_var.value
        }
      }

      dynamic "env" {
        for_each = local.secret_environment_variables
        iterator = env_var

        content {
          name = env_var.key
          value_source {
            secret_key_ref {
              secret  = local.secrets[env_var.key].id
              version = local.secrets[env_var.key].version
            }
          }
        }
      }

      dynamic "startup_probe" {
        for_each = local.healthcheck_endpoint != null ? ["probe"] : []
        iterator = probe

        content {
          http_get {
            path = local.healthcheck_endpoint
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = local.healthcheck_endpoint != null ? ["probe"] : []
        iterator = probe

        content {
          http_get {
            path = local.healthcheck_endpoint
          }
        }
      }
    }

    timeout                          = local.timeout
    max_instance_request_concurrency = local.request_concurrency
    service_account                  = local.service_account_email

    dynamic "vpc_access" {
      for_each = local.vpc_connector_full_name != null ? ["access"] : []
      iterator = access

      content {
        connector = local.vpc_connector_full_name
        egress    = local.vpc_connector_egress_settings
      }
    }
  }

  depends_on = [
    var.spanner_ddl_dependency,
    google_spanner_database_iam_member.service_spanner,
    google_pubsub_topic_iam_member.service_pubsub_publisher,
    google_project_iam_member.service_firestore_user,
    google_secret_manager_secret_iam_member.service_secrets,
    google_project_iam_member.service_monitoring_metric_writer,
  ]
}
