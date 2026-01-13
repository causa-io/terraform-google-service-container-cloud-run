locals {
  # The map of triggers from the `serviceContainer.triggers` configuration, filtered to keep only cron triggers with
  # a valid (HTTP) endpoint.
  cron_triggers = local.enable_cron_triggers ? {
    for key, value in local.triggers :
    key => {
      schedule             = value.schedule
      timezone             = try(value.timezone, null)
      endpoint_path        = value.endpoint.path
      retry_count          = try(value["google.scheduler"].retryCount, local.cron_triggers_retry_count)
      max_retry_duration   = try(value["google.scheduler"].maxRetryDuration, local.cron_triggers_max_retry_duration)
      min_backoff_duration = try(value["google.scheduler"].minBackoffDuration, local.cron_triggers_min_backoff_duration)
      max_backoff_duration = try(value["google.scheduler"].maxBackoffDuration, local.cron_triggers_max_backoff_duration)
      max_doublings        = try(value["google.scheduler"].maxDoublings, local.cron_triggers_max_doublings)
      attempt_deadline     = try(value["google.scheduler"].attemptDeadline, local.cron_triggers_attempt_deadline)
    }
    if contains(["cron", "google.scheduler"], try(value.type, null)) && try(value.endpoint.type, null) == "http"
  } : {}
}

# The service account used by Cloud Scheduler to invoke the Cloud Run service's triggers.
resource "google_service_account" "cron_trigger_invoker" {
  count = length(local.cron_triggers) > 0 ? 1 : 0

  project      = local.gcp_project_id
  account_id   = substr("${local.service_name}-scheduler", 0, 30)
  display_name = "${local.service_name} Cloud Scheduler triggers invoker"
  description  = "The service account used by Cloud Scheduler to invoke the Cloud Run ${local.service_name} service's triggers."
}

resource "google_cloud_run_service_iam_member" "cron_trigger_invoker" {
  count = length(local.cron_triggers) > 0 ? 1 : 0

  project  = local.gcp_project_id
  service  = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cron_trigger_invoker[0].email}"
}

# Cloud Scheduler jobs for each cron trigger defined in the configuration.
resource "google_cloud_scheduler_job" "triggers" {
  for_each = local.cron_triggers

  project     = local.gcp_project_id
  region      = google_cloud_run_v2_service.service.location
  name        = "run-${local.service_name}-${each.key}"
  description = "Cron trigger '${each.key}' for the Cloud Run ${local.service_name} service."
  schedule    = each.value.schedule
  time_zone   = each.value.timezone

  http_target {
    uri         = "${google_cloud_run_v2_service.service.uri}${each.value.endpoint_path}"
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.cron_trigger_invoker[0].email
      audience              = google_cloud_run_v2_service.service.uri
    }
  }

  retry_config {
    retry_count          = each.value.retry_count
    max_retry_duration   = each.value.max_retry_duration
    min_backoff_duration = each.value.min_backoff_duration
    max_backoff_duration = each.value.max_backoff_duration
    max_doublings        = each.value.max_doublings
  }

  attempt_deadline = each.value.attempt_deadline

  depends_on = [google_cloud_run_service_iam_member.cron_trigger_invoker]
}
