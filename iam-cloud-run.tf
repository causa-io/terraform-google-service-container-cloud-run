# When `enable_public_http_endpoints` is `true`, the service will be configured to allow unauthenticated incoming
# requests.
# However, this is different from the `ingress` setting, which determines which requests can reach the service based on
# where the request is coming from (within the project, a GCP load balancer, or an external system).
resource "google_cloud_run_service_iam_member" "all_users" {
  count = var.enable_public_http_endpoints ? 1 : 0

  project  = local.gcp_project_id
  location = google_cloud_run_v2_service.service.location
  service  = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
