# Permissions such that the service can publish to all the topics defined in the service's outputs.
resource "google_pubsub_topic_iam_member" "service_pubsub_publisher" {
  for_each = local.set_pubsub_permissions ? toset(local.conf_event_topics_outputs) : toset([])

  project = local.gcp_project_id
  topic   = local.pubsub_topic_ids[each.key]
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${local.service_account_email}"
}

locals {
  # Environment variables for the topics the service can publish to.
  pubsub_environment_variables = {
    for topic in local.conf_event_topics_outputs :
    "PUBSUB_TOPIC_${upper(replace(topic, "/[\\.-]{1}/", "_"))}" => local.pubsub_topic_ids[topic]
  }
}
