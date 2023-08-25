locals {
  # The list of all topics referenced by the configuration (topics that either trigger an endpoint, or that the service
  # publishes to).
  referenced_topics = setunion(
    local.conf_event_topics_outputs,
    [for trigger in values(local.pubsub_triggers) : trigger.topic],
  )

  # The map between event full names and Pub/Sub topic IDs.
  # This defaults to topics in the set GCP project, but can be overridden by the user (especially usefull to express the
  # dependency on the Pub/Sub topic resources).
  pubsub_topic_ids = merge(
    { for topic in local.referenced_topics : topic => "projects/${local.gcp_project_id}/topics/${topic}" },
    var.pubsub_topic_ids,
  )
}
