locals {
  # Project configuration from the JSON file.
  configuration = yamldecode(file(var.configuration_file))

  conf_project_name   = local.configuration.project.name
  conf_active_version = local.configuration.project.activeVersion

  conf_service_container = try(local.configuration.serviceContainer, tomap({}))

  conf_endpoints      = try(local.conf_service_container.endpoints, tomap({}))
  conf_http_endpoints = try(local.conf_endpoints.http, [])

  conf_triggers = try(local.conf_service_container.triggers, tomap({}))

  conf_environment_variables = try(local.conf_service_container.environmentVariables, tomap({}))
  conf_cpu_limit             = try(local.conf_service_container.cpuLimit, null)
  conf_memory_limit          = try(local.conf_service_container.memoryLimit, null)
  conf_min_instances         = try(local.conf_service_container.minInstances, null)
  conf_max_instances         = try(local.conf_service_container.maxInstances, null)

  conf_outputs              = try(local.conf_service_container.outputs, tomap({}))
  conf_event_topics_outputs = try(local.conf_outputs.eventTopics, [])
  conf_firestore_outputs    = try(local.conf_outputs["google.firestore"], [])
  conf_spanner_outputs      = try(local.conf_outputs["google.spanner"], [])

  conf_google                        = try(local.configuration.google, tomap({}))
  conf_google_project                = try(local.conf_google.project, null)
  conf_cloud_run                     = try(local.conf_google.cloudRun, tomap({}))
  conf_location                      = try(local.conf_cloud_run.location, null)
  conf_secret_environment_variables  = try(local.conf_cloud_run.secretEnvironmentVariables, tomap({}))
  conf_cpu_always_allocated          = try(local.conf_cloud_run.cpuAlwaysAllocated, null)
  conf_startup_cpu_boost             = try(local.conf_cloud_run.startupCpuBoost, null)
  conf_timeout                       = try(local.conf_cloud_run.timeout, null)
  conf_request_concurrency           = try(local.conf_cloud_run.requestConcurrency, null)
  conf_ingress                       = try(local.conf_cloud_run.ingress, null)
  conf_vpc_connector_name            = try(local.conf_cloud_run.vpcAccessConnector, null)
  conf_vpc_connector_egress_settings = try(local.conf_cloud_run.vpcAccessConnectorEgressSettings, null)
  conf_pubsub                        = try(local.conf_google.pubSub, tomap({}))
  conf_pubsub_minimum_backoff        = try(local.conf_pubsub.minimumBackoff, null)
  conf_pubsub_maximum_backoff        = try(local.conf_pubsub.maximumBackoff, null)
  conf_scheduler                     = try(local.conf_google.scheduler, tomap({}))
  conf_scheduler_retry_count         = try(local.conf_scheduler.retryCount, null)
  conf_scheduler_max_retry_duration  = try(local.conf_scheduler.maxRetryDuration, null)
  conf_scheduler_min_backoff         = try(local.conf_scheduler.minBackoffDuration, null)
  conf_scheduler_max_backoff         = try(local.conf_scheduler.maxBackoffDuration, null)
  conf_scheduler_max_doublings       = try(local.conf_scheduler.maxDoublings, null)
  conf_scheduler_attempt_deadline    = try(local.conf_scheduler.attemptDeadline, null)
  conf_google_load_balancing         = try(local.conf_google.loadBalancing, tomap({}))
  conf_custom_request_headers        = try(local.conf_google_load_balancing.customRequestHeaders, toset([]))

  # Although unlikely, it is okay for this to fail if `google.cloudRun.dockerRepository` is not set, as long as
  # `var.image` is set.
  # The local `active_version` is used, to allow a possible override by the `active_version` variable, even when the
  # full image URL is obtained from the configuration.
  conf_image = try("${local.conf_cloud_run.dockerRepository}/${local.conf_project_name}:${local.active_version}", null)

  # Configuration with variable overrides.
  gcp_project_id         = coalesce(var.gcp_project_id, local.conf_google_project)
  service_name           = coalesce(var.name, local.conf_project_name)
  active_version         = coalesce(var.active_version, local.conf_active_version)
  location               = coalesce(var.location, local.conf_location)
  image                  = coalesce(var.image, local.conf_image)
  cpu_limit              = coalesce(var.cpu_limit, local.conf_cpu_limit, "1000m")
  memory_limit           = coalesce(var.memory_limit, local.conf_memory_limit, "512Mi")
  min_instances          = try(coalesce(var.min_instances, local.conf_min_instances), null)
  max_instances          = try(coalesce(var.max_instances, local.conf_max_instances), 100)
  custom_request_headers = coalesce(var.custom_request_headers, local.conf_custom_request_headers, toset([]))
  cpu_always_allocated   = coalesce(var.cpu_always_allocated, local.conf_cpu_always_allocated, false)
  startup_cpu_boost      = coalesce(var.startup_cpu_boost, local.conf_startup_cpu_boost, false)
  timeout                = try(coalesce(var.timeout, local.conf_timeout), null)
  request_concurrency    = try(coalesce(var.request_concurrency, local.conf_request_concurrency), null)
  healthcheck_endpoint   = var.healthcheck_endpoint
  environment_variables = merge(
    local.pubsub_environment_variables,
    local.spanner_environment_variables,
    local.tasks_environment_variables,
    local.conf_environment_variables,
    var.environment_variables
  )
  secret_environment_variables       = merge(local.conf_secret_environment_variables, var.secret_environment_variables)
  ingress                            = coalesce(var.ingress, local.conf_ingress, "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER")
  vpc_connector_name                 = try(coalesce(var.vpc_connector_name, local.conf_vpc_connector_name), null)
  vpc_connector_egress_settings      = coalesce(var.vpc_connector_egress_settings, local.conf_vpc_connector_egress_settings, "ALL_TRAFFIC")
  pubsub_triggers_minimum_backoff    = coalesce(var.pubsub_triggers_minimum_backoff, local.conf_pubsub_minimum_backoff, "10s")
  pubsub_triggers_maximum_backoff    = coalesce(var.pubsub_triggers_maximum_backoff, local.conf_pubsub_maximum_backoff, "600s")
  cron_triggers_retry_count          = try(coalesce(var.cron_triggers_retry_count, local.conf_scheduler_retry_count), 0)
  cron_triggers_max_retry_duration   = coalesce(var.cron_triggers_max_retry_duration, local.conf_scheduler_max_retry_duration, "0s")
  cron_triggers_min_backoff_duration = coalesce(var.cron_triggers_min_backoff_duration, local.conf_scheduler_min_backoff, "5s")
  cron_triggers_max_backoff_duration = coalesce(var.cron_triggers_max_backoff_duration, local.conf_scheduler_max_backoff, "3600s")
  cron_triggers_max_doublings        = try(coalesce(var.cron_triggers_max_doublings, local.conf_scheduler_max_doublings), 5)
  cron_triggers_attempt_deadline     = try(coalesce(var.cron_triggers_attempt_deadline, local.conf_scheduler_attempt_deadline), null)
  triggers                           = merge(local.conf_triggers, var.triggers)

  # Permissions.
  set_firestore_permissions = coalesce(var.set_firestore_permissions, var.set_iam_permissions)
  set_pubsub_permissions    = coalesce(var.set_pubsub_permissions, var.set_iam_permissions)
  set_spanner_permissions   = coalesce(var.set_spanner_permissions, var.set_iam_permissions)
  set_tasks_permissions     = coalesce(var.set_tasks_permissions, var.set_iam_permissions)
  set_secrets_permissions   = coalesce(var.set_secrets_permissions, var.set_iam_permissions)

  # Triggers.
  enable_pubsub_triggers   = coalesce(var.enable_pubsub_triggers, var.enable_triggers)
  enable_tasks_triggers    = coalesce(var.enable_tasks_triggers, var.enable_triggers)
  enable_eventarc_triggers = coalesce(var.enable_eventarc_triggers, var.enable_triggers)
  enable_cron_triggers     = coalesce(var.enable_cron_triggers, var.enable_triggers)
}

data "google_project" "project" {
  project_id = local.gcp_project_id
}
