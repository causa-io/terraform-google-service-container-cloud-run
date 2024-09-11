locals {
  # The map of triggers from the `serviceContainer.triggers` configuration, filtered to keep only Cloud Tasks triggers
  # with a valid (HTTP) endpoint.
  tasks_triggers = local.enable_tasks_triggers ? {
    for key, value in local.triggers :
    key => value
    if try(value.type, null) == "google.task" && try(value.endpoint.type, null) == "http"
  } : {}

  # The set of queue names obtained from Cloud Tasks triggers.
  # See `random_string.queue_suffixes` for the reason behind suffixes.
  tasks_queues = {
    for trigger in values(local.tasks_triggers) :
    trigger.queue => trigger
  }
  tasks_queue_names = {
    for queue in keys(local.tasks_queues) :
    queue => "${queue}-${random_string.queue_suffixes[queue].result}"
  }

  # Environment variables for the Cloud Tasks queues the service can create tasks into.
  # This does not reference `google_cloud_tasks_queue.queues` on purpose to avoid future circular dependencies (see the
  # comment about the `http_request` block).
  tasks_environment_variables = {
    for queue in keys(local.tasks_queues) :
    "TASKS_QUEUE_${upper(replace(queue, "/[\\.-]{1}/", "_"))}"
    => "projects/${local.gcp_project_id}/locations/${local.location}/queues/${local.tasks_queue_names[queue]}"
  }
}

# Cloud Tasks queues cannot be quickly deleted then recreated with the same ID, which can cause problems when destroying
# and recreating an environment. Adding a suffix to queue names works around that.
resource "random_string" "queue_suffixes" {
  for_each = local.tasks_queues

  length  = 6
  special = false
  upper   = false
}

resource "google_cloud_tasks_queue" "queues" {
  for_each = local.tasks_queues

  project  = local.gcp_project_id
  location = local.location
  name     = local.tasks_queue_names[each.key]

  # This configuration avoids having to pass the service's URI to itself when creating new tasks (at runtime).
  # This is especially useful because the service's URI is not known until the service is created, which makes it hard
  # to "inject" into the service. Configuring the URI at the task level allows the service to create tasks without
  # knowing its own URI.
  http_target {
    http_method = "POST"

    uri_override {
      scheme = "HTTPS"
      host   = replace(google_cloud_run_v2_service.service.uri, "/^https:\\/\\//", "")

      path_override {
        path = each.value.endpoint.path
      }

      uri_override_enforce_mode = "ALWAYS"
    }

    oidc_token {
      service_account_email = local.service_account_email
      audience              = google_cloud_run_v2_service.service.uri
    }
  }

  retry_config {
    max_attempts       = try(each.value.retryPolicy.maxAttempts, -1)
    max_retry_duration = try(each.value.retryPolicy.maxRetryDuration, "0s")
    min_backoff        = try(each.value.retryPolicy.minBackoff, "1s")
    max_backoff        = try(each.value.retryPolicy.maxBackoff, "60s")
    max_doublings      = try(each.value.retryPolicy.maxDoublings, 16)
  }

  stackdriver_logging_config {
    sampling_ratio = 1
  }
}

# Allows the service to enqueue expiration tasks in Cloud Tasks.
resource "google_cloud_tasks_queue_iam_member" "tasks_enqueuer" {
  for_each = local.set_tasks_permissions ? google_cloud_tasks_queue.queues : {}

  project  = each.value.project
  location = each.value.location
  name     = each.value.name
  role     = "roles/cloudtasks.enqueuer"
  member   = "serviceAccount:${local.service_account_email}"
}

# Allows the service enqueuing tasks to set itself as the caller when performing the task's HTTP request.
resource "google_service_account_iam_member" "service_own_user" {
  count = local.set_tasks_permissions && length(local.tasks_triggers) > 0 ? 1 : 0

  service_account_id = "projects/-/serviceAccounts/${local.service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.service_account_email}"
}

# Allows the service to invoke itself, when performing the task's HTTP request.
resource "google_cloud_run_service_iam_member" "service_own_caller" {
  count = local.set_tasks_permissions && length(local.tasks_triggers) > 0 ? 1 : 0

  project  = google_cloud_run_v2_service.service.project
  location = google_cloud_run_v2_service.service.location
  service  = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.service_account_email}"
}
