locals {
  # The list of all topics referenced by the configuration (topics that either trigger an endpoint, or that the service
  # publishes to).
  referenced_topics = setunion(
    local.conf_event_topics_outputs,
    [for trigger in values(local.pubsub_triggers) : trigger.topic],
  )

  # The map between event full names and Pub/Sub topic IDs, only for referenced topics.
  # This defaults to topics in the set GCP project, but can be overridden by the user.
  pubsub_topic_ids = {
    for topic in local.referenced_topics :
    topic => coalesce(
      try(var.pubsub_topic_ids[topic], null),
      "projects/${local.gcp_project_id}/topics/${topic}"
    )
  }
}
