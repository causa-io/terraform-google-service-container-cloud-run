variable "configuration_file" {
  type        = string
  description = "The path to the configuration file for the project. It should be in JSON or YAML."
}

variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID in which resources will be placed. Defaults to the `google.project` configuration."
  default     = null
}

variable "name" {
  type        = string
  description = "The name of the Cloud Run service. Defaults to the name of the project."
  default     = null
}

variable "service_account" {
  // Using an object allows to differentiate between the default `null` value and an email that would be passed, even at
  // plan time. If the service account email references a service account resource that hasn't been created yet, the
  // `email` value is unknown, and making `google_service_account.service` depend on it for its count would fail.
  // Testing whether the object is `null` can be made at plan time, without knowing the actual value of `email`.
  type = object({
    email = string
  })
  description = "The email of the service account the container has access to. By default, a new service account is created."
  default     = null
}

variable "location" {
  type        = string
  description = "The location / region in which the Cloud Run service will be placed. Defaults to the `google.cloudRun.location` configuration."
  default     = null
}

variable "image" {
  type        = string
  description = "The URL of the Docker image to deploy. If not provided, this is inferred from the `google.cloudRun.dockerRepository` configuration, the project name, and its version."
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "A map where keys are the name of environment variables, and values are the corresponding values. This will be merged with the `serviceContainer.environmentVariables` configuration."
  default     = {}
}

variable "secret_environment_variables" {
  type        = map(string)
  description = "A map where keys are the name of environment variables, and values are secret versions IDs (e.g. `projects/*/secrets/*/versions/*`). This will be merged with the `google.cloudRun.secretEnvironmentVariables` configuration."
  default     = {}
}

variable "cpu_limit" {
  type        = string
  description = "The maximum CPU allowed to the container. Defaults to the `serviceContainer.cpuLimit` configuration or `1000m`."
  default     = null
}

variable "memory_limit" {
  type        = string
  description = "The maximum memory allowed to the container. Defaults to the `serviceContainer.memoryLimit` configuration or `512Mi`."
  default     = null
}

variable "min_instances" {
  type        = number
  description = "The minimum number of containers that should always be running. Defaults to the `serviceContainer.minInstances` configuration."
  default     = null
}

variable "max_instances" {
  type        = number
  description = "The maximum number of containers that can be deployed in response to input requests. Defaults to the `serviceContainer.maxInstances` configuration, or `100`."
  default     = null
}

variable "cpu_always_allocated" {
  type        = bool
  description = "Whether the container is running between requests and can perform background operations. Defaults to the `google.cloudRun.cpuAlwaysAllocated` configuration, or `false`."
  default     = null
}

variable "vpc_connector_name" {
  type        = string
  description = "The name of the VPC access connector through which egress traffic should be routed. This can be only the name or the full resource path. Defaults to the `google.cloudRun.vpcAccessConnector` configuration."
  default     = null
}

variable "vpc_connector_egress_settings" {
  type        = string
  description = "The setting for egress traffic that goes through the VPC access connector. Can be `ALL_TRAFFIC` or `PRIVATE_RANGES_ONLY`. Defaults to the `google.cloudRun.vpcAccessConnectorEgressSettings` configuration, or `ALL_TRAFFIC`."
  default     = null
}

variable "pubsub_triggers_minimum_backoff" {
  type        = string
  description = "The minimum backoff for Pub/Sub triggers. Defaults to the `google.pubSub.minimumBackoff` configuration, or `10s`."
  default     = null
}

variable "pubsub_triggers_maximum_backoff" {
  type        = string
  description = "The maximum backoff for Pub/Sub triggers. Defaults to the `google.pubSub.maximumBackoff` configuration, or `600s`."
  default     = null
}

variable "ingress" {
  type        = string
  description = "The type of allowed ingress that can reach the container. Can be `INGRESS_TRAFFIC_ALL`, `INGRESS_TRAFFIC_INTERNAL_ONLY`, or `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`. Defaults to the `google.cloudRun.ingress` configuration, or `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`."
  default     = null
}

variable "timeout" {
  type        = number
  description = "The maximum duration (in seconds) the service has to respond to a request. Defaults to the `google.cloudRun.timeout` configuration."
  default     = null
}

variable "request_concurrency" {
  type        = number
  description = "The maximum allowed in-flight (concurrent) requests per container. Defaults to the `google.cloudRun.requestConcurrency` configuration."
  default     = null
}

variable "healthcheck_endpoint" {
  type        = string
  description = "The endpoint to check to determine whether the container is healthy. Defaults to `/health`. Can be set to `null` to disable health checks."
  default     = "/health"
}

variable "enable_public_http_endpoints" {
  type        = bool
  description = "Whether the service should be accessible publicly (possibly behind a load balancer). This sets the output `public_http_endpoints`."
  default     = false
}

variable "pubsub_topic_ids" {
  type        = map(string)
  description = "A map where keys are event full names and values are Pub/Sub topic IDs. By default, IDs will be inferred from the GCP project ID and the event full name."
  default     = {}
}

variable "custom_request_headers" {
  type        = set(string)
  description = "A list of custom request headers that should be set by the API router. This simply sets the corresponding field in the `routes` output. Defaults to the `google.loadBalancing.customRequestHeaders` configuration."
  default     = null
}

variable "set_iam_permissions" {
  type        = bool
  description = "Whether IAM permissions should be set so that the service account can access resources defined in the service's outputs."
  default     = true
}

variable "set_pubsub_permissions" {
  type        = bool
  description = "Whether IAM permissions on Pub/Sub topics should be set so that the service account can publish to topics defined in the service's outputs. Defaults to `set_iam_permissions`."
  default     = null
}

variable "set_firestore_permissions" {
  type        = bool
  description = "Whether IAM permissions on Firestore should be set so that the service account can read and write to the database. Defaults to `set_iam_permissions`."
  default     = null
}

variable "set_spanner_permissions" {
  type        = bool
  description = "Whether IAM permissions on Spanner should be set so that the service account can read and write to the databases defined in the service's outputs. Defaults to `set_iam_permissions`."
  default     = null
}

variable "set_tasks_permissions" {
  type        = bool
  description = "Whether IAM permissions on Cloud Tasks should be set so that the service account can enqueue tasks and call itself for queues defined in the service's triggers. Defaults to `set_iam_permissions`."
  default     = null
}

variable "enable_triggers" {
  type        = bool
  description = "Whether triggers for the service should be configured."
  default     = false
}

variable "enable_pubsub_triggers" {
  type        = bool
  description = "Whether Pub/Sub triggers for the service should be configured. Defaults to `enable_triggers`."
  default     = null
}

variable "enable_tasks_triggers" {
  type        = bool
  description = "Whether Cloud Tasks triggers for the service should be configured. Defaults to `enable_triggers`."
  default     = null
}

variable "spanner_ddl_dependency" {
  type        = list(string)
  description = "The DDL for the (Spanner) database that the service depends on. This is used to ensure that the database is created and updated before the service is deployed."
  default     = []
}
