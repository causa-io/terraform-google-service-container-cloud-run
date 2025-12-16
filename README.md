# Terraform module for Causa service container projects deployed on Cloud Run

This module manages a Causa service container project deployed as a Cloud Run service. It handles the configuration of the Cloud Run service resource, but can also handle IAM permissions and Pub/Sub push subscriptions pointing to the service, based on the `causa.yaml` file for the project.

## ➕ Requirements

This module depends on the [google Terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest).

## 🎉 Installation

Copy the following in your Terraform configuration, and run `terraform init`:

```terraform
module "my_service" {
  source  = "causa-io/service-container-cloud-run/google"
  version = "<insert the most recent version number here>"

  # The path to the generated configuration file for the service container project.
  configuration_file = "${local.project_configurations_directory}/my-service.json"
}
```

## ✨ Features

The only required parameter is the `configuration_file`, which should point to a JSON or YAML file containing the Causa project configuration. The full configuration for each project can be generated using the [`ProjectWriteConfigurations` infrastructure processor](https://github.com/causa-io/workspace-module-core#projectwriteconfigurations). The recommended way of configuring this module is through the `causa.yaml` project file. Terraform module variables should only be used to override the configuration when no other way is possible.

### Cloud Run service

The main resource managed by this module is the Cloud Run service itself, for which many parameters can be configured. See the [variables descriptions](./variables.tf) for more details about available configuration and defaults.

By default, the Cloud Run service cannot be accessed publicly. To allow unauthenticated requests (as in, not using IAM) to the service, set `enable_public_http_endpoints` to `true`. This will also populate the `public_http_endpoints` output, which will contain the `serviceContainer.endpoints.http` configuration from `causa.yaml` and can be used as input for setting up a load balancer.

### IAM permissions

Based on the `causa.yaml` configuration, this module can also manage required permissions for the service. This includes:

- Read and write access to Firestore (if at least one collection is listed in `serviceContainer.outputs.['google.firestore']`).
- Publisher permissions to Pub/Sub topics listed in `serviceContainer.outputs.eventTopics`.
- Read and write access to Spanner databases listed in `serviceContainer.outputs.['google.spanner']`.
- Permissions for managed Cloud Tasks queues, based on the triggers for the service (see the corresponding section).
- Read access to secrets referenced in `google.cloudRun.secretEnvironmentVariables`.

Automatic definition of IAM permissions can be disabled by setting the `set_*_permissions` variables to `false`.

### Pub/Sub triggers

This module can also create and configure Pub/Sub push subscriptions for all event triggers defined in `serviceContainer.triggers`. For this, set the `enable_[pubsub_]triggers` variable to `true`.

For each trigger with `type: event` or `type: google.pubSub`, a Pub/Sub subscription for the `topic` with the push endpoint set to `endpoint.path` will be created. Pub/Sub will be configured such that calls to the service are authenticated using a dedicated service account. The exponential backoff for the retry policy can also be configured per trigger. For example, the service configuration could look something like:

```yaml
serviceContainer:
  triggers:
    myTrigger:
      type: event
      topic: my-pubsub-topic
      endpoint:
        type: http
        path: /service/http/route
      google.pubSub:
        minimumBackoff: 1s
        maximumBackoff: 100s
        # Optional message filtering.
        filter: attributes.eventName = "someEvent"

# Default values for all triggers.
google:
  pubSub:
    minimumBackoff: 10s
    maximumBackoff: 600s
```

> 💡 The `google.pubSub` type can be used in place of the `event` type for topics that are not managed by Causa. This allows defining triggers that will not be included in the rest of Causa event-related tooling (e.g. code generation).

### Cloud Tasks triggers (queues)

Similarly to Pub/Sub triggers, this module can also manage Cloud Tasks queues for corresponding triggers. The `enable_[tasks_]triggers` variable should be set to `true`.

For each trigger with `type: google.task`, a Cloud Tasks queue will be created with the name of the `queue` attribute for the trigger (plus a suffix). The `endpoint` configuration is identical to Pub/Sub, and must reference an HTTP endpoint for the service. The endpoint is used to configured queue-level HTTP requests.

If `set_[iam|tasks]_permissions` is `true`, the IAM permissions will be configured such that the service can:

- Create tasks in the queues.
- Set the service account for the service as the `OIDC token` in tasks.
- Allow the service account to invoke the Cloud Run service itself.

This allows creating tasks from the Cloud Run service which call back the trigger endpoint on the service itself.

Finally, the tasks queue IDs (needed by the Cloud Tasks client) are made available as environment variables in the service as `TASKS_QUEUE_<NAME_IN_UPPERCASE>`. For example, the ID of the queue `my-queue` will be made available in the variable `TASKS_QUEUE_MY_QUEUE`.

### Eventarc triggers

This module can also manage Eventarc triggers pushing events to the service. The `enable_[eventarc_]triggers` variable should be set to `true`. Here is an example of how to configure such a trigger:

```yaml
serviceContainer:
  triggers:
    myEventarcTrigger:
      type: google.eventarc
      endpoint:
        type: http
        path: /path/to/trigger
      google.eventarc:
        location: europe-west1 # Defaults to the location of the Cloud Run service.
        contentType: application/json # Required as all events do not support the same content types.
        filters: # Required...
          # ...because at least the `type` should be filtered.
          - attribute: type
            value: google.cloud.firestore.document.v1.written
          - attribute: database
            value: (default)
          - attribute: document
            operator: match-path-pattern # The operator can optionally be set as well.
            value: myCollection/{documentId=*}
```

### Cron triggers (Cloud Scheduler)

This module can manage Cloud Scheduler jobs that periodically call HTTP endpoints on the service. The `enable_[cron_]triggers` variable should be set to `true`.

For each trigger with `type: cron` or `type: google.scheduler`, a Cloud Scheduler job will be created. The job will make authenticated HTTP POST requests to the configured endpoint. Here is an example configuration:

```yaml
serviceContainer:
  triggers:
    myCronJob:
      type: cron
      schedule: 0 * * * * # Required.
      timezone: America/New_York # Optional. Defaults to UTC.
      endpoint:
        type: http
        path: /cron/my-job
      google.scheduler:
        # All retry parameters are optional.
        retryCount: 3
        maxRetryDuration: 0s
        minBackoffDuration: 5s
        maxBackoffDuration: 3600s
        maxDoublings: 5
        attemptDeadline: 180s

# Default values for all cron triggers.
google:
  scheduler:
    retryCount: 0
    maxRetryDuration: 0s
    minBackoffDuration: 5s
    maxBackoffDuration: 3600s
    maxDoublings: 5
    attemptDeadline: 180s
```
