output "name" {
  value       = google_cloud_run_service.service.name
  description = "The name of the Cloud Run service."
}

output "url" {
  value       = google_cloud_run_service.service.status[0].url
  description = "The URL to make requests to the Cloud Run service."
}

output "public_http_endpoints" {
  description = "The list of public HTTP endpoints (routes) for the service."
  value       = var.enable_public_http_endpoints ? local.conf_http_endpoints : []
}
