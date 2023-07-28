locals {
  secrets = {
    # Aliases are only required when the secret is stored in a different project. However one is assigned to each secret
    # to make configuration simpler.
    # The alias should start with `secret-` and its value should be the secret ID (not the version).
    for key, secret_path in local.secret_environment_variables : key => {
      alias = "secret-${random_uuid.secret_id[key].result}"
      # `id` will be used for the alias definition and `version` by the environment variable.
      secret = regex("(?P<id>projects\\/[\\w-]+\\/secrets\\/[\\w-]+)\\/versions\\/(?P<version>\\d+)", secret_path)
    }
  }
}

# The internal IDs used by each secret alias.
resource "random_uuid" "secret_id" {
  for_each = local.secret_environment_variables
}

# The Cloud Run service itself.
resource "google_cloud_run_service" "service" {
  project                    = local.gcp_project_id
  name                       = local.service_name
  location                   = local.location
  autogenerate_revision_name = true

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = local.ingress
    }
  }

  template {
    spec {
      containers {
        image = local.image

        resources {
          limits = {
            cpu    = local.cpu_limit
            memory = local.memory_limit
          }
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
            value_from {
              secret_key_ref {
                name = local.secrets[env_var.key].alias
                key  = local.secrets[env_var.key].secret.version
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

      timeout_seconds       = local.timeout
      container_concurrency = local.request_concurrency
      service_account_name  = local.service_account_email
    }

    metadata {
      annotations = merge(
        { "run.googleapis.com/cpu-throttling" = local.cpu_always_allocated ? "false" : "true" },
        local.vpc_connector_name != null ? {
          "run.googleapis.com/vpc-access-connector" = local.vpc_connector_name
          "run.googleapis.com/vpc-access-egress"    = local.vpc_connector_egress_settings
        } : {},
        local.min_instances != null ? { "autoscaling.knative.dev/minScale" = "${local.min_instances}" } : {},
        local.max_instances != null ? { "autoscaling.knative.dev/maxScale" = "${local.max_instances}" } : {},
        # Defines aliases that are then referenced by environment variables.
        length(local.secrets) > 0 ? {
          "run.googleapis.com/secrets" = join(",", [for s in values(local.secrets) : "${s.alias}:${s.secret.id}"])
        } : {}
      )
    }
  }

  lifecycle {
    # This might change outside Terraform.
    ignore_changes = [
      metadata[0].annotations["run.googleapis.com/operation-id"],
      template[0].metadata[0].labels["run.googleapis.com/startupProbeType"],
    ]
  }

  depends_on = [
    var.spanner_ddl_dependency,
    google_spanner_database_iam_member.service_spanner,
    google_pubsub_topic_iam_member.service_pubsub_publisher,
    google_project_iam_member.service_firestore_user,
  ]
}
