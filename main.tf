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
  conf_timeout                       = try(local.conf_cloud_run.timeout, null)
  conf_request_concurrency           = try(local.conf_cloud_run.requestConcurrency, null)
  conf_ingress                       = try(local.conf_cloud_run.ingress, null)
  conf_vpc_connector_name            = try(local.conf_cloud_run.vpcAccessConnector, null)
  conf_vpc_connector_egress_settings = try(local.conf_cloud_run.vpcAccessConnectorEgressSettings, null)

  # Although unlikely, it is okay for this to fail if `google.cloudRun.dockerRepository` is not set, as long as
  # `var.image` is set.
  conf_image = try("${local.conf_cloud_run.dockerRepository}/${local.conf_project_name}:${local.conf_active_version}", null)

  # Configuration with variable overrides.
  gcp_project_id       = coalesce(var.gcp_project_id, local.conf_google_project)
  service_name         = coalesce(var.name, local.conf_project_name)
  location             = coalesce(var.location, local.conf_location)
  image                = coalesce(var.image, local.conf_image)
  cpu_limit            = coalesce(var.cpu_limit, local.conf_cpu_limit, "1000m")
  memory_limit         = coalesce(var.memory_limit, local.conf_memory_limit, "512Mi")
  min_instances        = try(coalesce(var.min_instances, local.conf_min_instances), null)
  max_instances        = try(coalesce(var.max_instances, local.conf_max_instances), null)
  cpu_always_allocated = coalesce(var.cpu_always_allocated, local.conf_cpu_always_allocated, false)
  timeout              = try(coalesce(var.timeout, local.conf_timeout), null)
  request_concurrency  = try(coalesce(var.request_concurrency, local.conf_request_concurrency), null)
  environment_variables = merge(
    local.pubsub_environment_variables,
    local.spanner_environment_variables,
    local.conf_environment_variables,
    var.environment_variables
  )
  secret_environment_variables  = merge(local.conf_secret_environment_variables, var.secret_environment_variables)
  ingress                       = coalesce(var.ingress, local.conf_ingress, "internal-and-cloud-load-balancing")
  vpc_connector_name            = try(coalesce(var.vpc_connector_name, local.conf_vpc_connector_name), null)
  vpc_connector_egress_settings = coalesce(var.vpc_connector_egress_settings, local.conf_vpc_connector_egress_settings, "all-traffic")

  # Permissions.
  set_firestore_permissions = coalesce(var.set_firestore_permissions, var.set_iam_permissions)
  set_pubsub_permissions    = coalesce(var.set_pubsub_permissions, var.set_iam_permissions)
  set_spanner_permissions   = coalesce(var.set_spanner_permissions, var.set_iam_permissions)

  # Triggers.
  enable_pubsub_triggers = coalesce(var.enable_pubsub_triggers, var.enable_triggers)
}

data "google_project" "project" {
  project_id = local.gcp_project_id
}
