locals {
  # The map of triggers from the `serviceContainer.triggers` configuration, filtered to keep only Eventarc triggers with
  # a valid (HTTP) endpoint.
  eventarc_triggers = local.enable_eventarc_triggers ? {
    for key, value in local.triggers :
    key => {
      endpoint_path = value.endpoint.path
      content_type  = value["google.eventarc"].contentType
      location      = try(value["google.eventarc"].location, google_cloud_run_v2_service.service.location)
      filters = [
        for filter in value["google.eventarc"].filters :
        {
          attribute = filter.attribute
          value     = filter.value
          operator  = try(filter.operator, null)
        }
      ]
    }
    if try(value.type, null) == "google.eventarc" && try(value.endpoint.type, null) == "http"
  } : {}

  # The set of GCS buckets referenced by Eventarc triggers. Used to configure IAM permissions.
  eventarc_triggers_storage_buckets = toset(flatten([
    for _, trigger in local.eventarc_triggers :
    [for filter in trigger.filters : filter.value if filter.attribute == "bucket"]
    if anytrue([
      for filter in trigger.filters :
      filter.attribute == "type" && startswith(filter.value, "google.cloud.storage.")
    ])
  ]))
}

# The service account used by Eventarc to invoke the Cloud Run service's triggers.
resource "google_service_account" "eventarc_trigger_invoker" {
  count = length(local.eventarc_triggers) > 0 ? 1 : 0

  project      = local.gcp_project_id
  account_id   = substr("${local.service_name}-eventarc", 0, 30)
  display_name = "${local.service_name} Eventarc triggers invoker"
  description  = "The service account used by Eventarc to invoke the Cloud Run ${local.service_name} service's triggers."
}

resource "google_eventarc_trigger" "triggers" {
  for_each = local.eventarc_triggers

  project = local.gcp_project_id

  # Names must be lowercase and cannot contain underscores.
  # This transformation could cause conflicts in extreme edge cases.
  name     = replace(lower("run-${local.service_name}-${each.key}"), "_", "-")
  location = each.value.location

  service_account         = google_service_account.eventarc_trigger_invoker[0].email
  event_data_content_type = each.value.content_type

  destination {
    cloud_run_service {
      region  = google_cloud_run_v2_service.service.location
      service = google_cloud_run_v2_service.service.name
      path    = each.value.endpoint_path
    }
  }

  dynamic "matching_criteria" {
    for_each = each.value.filters
    iterator = filter

    content {
      attribute = filter.value.attribute
      value     = filter.value.value
      operator  = filter.value.operator
    }
  }

  depends_on = [
    google_cloud_run_service_iam_member.eventarc_trigger_invoker,
    google_project_iam_member.eventarc_eventreceiver,
    google_storage_bucket_iam_member.eventarc_notifications,
  ]
}

# Allows the service account used by Eventarc to receive events.
resource "google_project_iam_member" "eventarc_eventreceiver" {
  count = length(local.eventarc_triggers) > 0 ? 1 : 0

  project = local.gcp_project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc_trigger_invoker[0].email}"
}

# Allows the service account used by Eventarc to invoke the Cloud Run service.
resource "google_cloud_run_service_iam_member" "eventarc_trigger_invoker" {
  count = length(local.eventarc_triggers) > 0 ? 1 : 0

  project  = local.gcp_project_id
  service  = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.eventarc_trigger_invoker[0].email}"
}

# Grants Eventarc the necessary permissions to configure Cloud Storage bucket notifications.
resource "google_storage_bucket_iam_member" "eventarc_notifications" {
  for_each = local.eventarc_triggers_storage_buckets

  bucket = each.key
  role   = "roles/storage.bucketViewer"
  member = "serviceAccount:${google_service_account.eventarc_trigger_invoker[0].email}"
}
