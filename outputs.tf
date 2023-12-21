output "name" {
  value       = google_cloud_run_v2_service.service.name
  description = "The name of the Cloud Run service."
}

output "location" {
  value       = google_cloud_run_v2_service.service.location
  description = "The location of the Cloud Run service."
}

output "project" {
  value       = google_cloud_run_v2_service.service.project
  description = "The project of the Cloud Run service."
}

output "url" {
  value       = google_cloud_run_v2_service.service.uri
  description = "The URL to make requests to the Cloud Run service."
}

output "public_http_endpoints" {
  description = "The list of public HTTP endpoints (routes) for the service."
  value       = var.enable_public_http_endpoints ? local.conf_http_endpoints : []
}

output "tasks_queues" {
  description = "The IDs of Cloud Tasks queues created by the module for triggers defined in the configuration."
  value       = { for name, queue in google_cloud_tasks_queue.queues : name => queue.id }
}

output "routes" {
  value = {
    paths   = var.enable_public_http_endpoints ? local.conf_http_endpoints : []
    type    = "google.cloudRun"
    region  = google_cloud_run_v2_service.service.location
    service = google_cloud_run_v2_service.service.name
  }
  description = "The configuration that can be passed to the `api-router` module. Only relevant if the service exposes public HTTP endpoints."
}
