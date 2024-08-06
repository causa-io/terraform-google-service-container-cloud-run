# 🔖 Changelog

## Unreleased

## v0.14.1 (2024-08-06)

Fixes:

- Make the Cloud Run service depend on Secret Manager permissions.

## v0.14.0 (2024-08-06)

Features:

- Support `latest` as a version for secrets.
- Automatically define permissions for secrets accessed by the service.

## v0.13.0 (2024-06-25)

Features:

- Support Terraform-defined triggers using the `triggers` module variable.

## v0.12.0 (2024-05-02)

Features:

- Support `google.eventarc` triggers.

## v0.11.0 (2024-04-26)

Features:

- Forward custom request headers from the configuration or input variable to the `routes` output.

## v0.10.1 (2024-02-21)

Chores:

- Upgrade compatible `google` provider versions to support `5.*.*`.

## v0.10.0 (2024-02-06)

Features:

- Support the `google.pubSub` trigger type as a way to receive messages from Pub/Sub topics not managed by Causa.

## v0.9.0 (2023-12-21)

Breaking changes:

- The Cloud Run V2 API is now used through the `google_cloud_run_v2_service` resource. You can use an [`import` block](https://developer.hashicorp.com/terraform/language/import) to reference an existing service, and `terraform state rm` to remove the existing `google_cloud_run_service` resource.
- The `ingress` (`google.cloudRun.ingress`) and `vpc_connector_egress_settings` (`google.cloudRun.vpcAccessConnectorEgressSettings`) settings must use the enum values defined by the [V2 API](https://cloud.google.com/run/docs/reference/rest/v2/projects.locations.services).
- The maximum number of instances (`max_instances` Terraform variable and `serviceContainer.maxInstances` configuration) is now set to `100` by default (which was already the default set by the Cloud Run API).

Features:

- Support Pub/Sub subscription message filtering using the `"google.pubSub".filter` trigger attribute.

## v0.8.0 (2023-11-24)

Features:

- Allow setting a global Pub/Sub triggers backoff in the Causa configuration (`google.pubSub.[minimum|maximum]Backoff`) and the Terraform module (`pubsub_triggers_[minimum|maximum]_backoff` variables).

## v0.7.0 (2023-11-21)

Breaking changes:

- Pub/Sub triggers (push subscriptions) are now configured with [exponential backoff](https://cloud.google.com/pubsub/docs/handling-failures#exponential_backoff) by default, with the default Pub/Sub values of 10 seconds for minimum backoff, and 600 seconds for maximum backoff.

Features:

- Pub/Sub triggers exponential backoff can be configured using the `"google.pubSub".minimumBackoff` and `"google.pubSub".maximumBackoff` parameters on each trigger.

## v0.6.0 (2023-09-28)

Features:

- Define the `routes` output, which integrates with the [`api-router`](https://github.com/causa-io/terraform-google-api-router) module.

## v0.5.0 (2023-09-08)

Features:

- Add support for Cloud Tasks triggers.

Fixes:

- Ensure IAM permissions for Spanner depend on the databases (the `spanner_ddl_dependency` variable).

## v0.4.1 (2023-08-25)

Fixes:

- Simplify `pubsub_topic_ids` expression to allow Terraform to detect minimal dependencies.

## v0.4.0 (2023-08-01)

Breaking changes:

- If a `service_account_email` is provided, it should now be passed as a `service_account` object.

## v0.3.0 (2023-07-28)

Features:

- Define the `spanner_ddl_dependency` variable to facilitate expressing dependency on a Spanner database.

Fixes:

- Set missing project ID in Cloud Run permissions.

## v0.2.0 (2023-07-27)

Features:

- Set the default HTTP healthcheck to `/health` and expose the `healthcheck_endpoint` variable.

## v0.1.0 (2023-07-25)

Features:

- Implement the first version of the Cloud Run Terraform module for service container Causa projects.
