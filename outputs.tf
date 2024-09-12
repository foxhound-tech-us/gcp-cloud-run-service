output "id" {
  value       = google_cloud_run_service.run_service.id
  description = "An identifier for the resource with format locations/{{location}}/namespaces/{{project}}/services/{{name}}."
}

output "status" {
  value       = google_cloud_run_service.run_service.status
  description = "The current status of the Service including many other sub-attributes. See the structure on the TF Google Provider doc page for Cloud Run Service."
}
