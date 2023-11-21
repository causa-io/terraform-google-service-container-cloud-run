# 🔖 Changelog

## Unreleased

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
