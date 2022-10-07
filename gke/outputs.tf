output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "tf_sample_gke_cluster_name" {
  value       = google_container_cluster.tf_sample_gke.name
  description = "GKE Cluster Name"
}

output "tf_sample_gke_cluster_endpoint" {
  value       = google_container_cluster.tf_sample_gke.endpoint
  description = "GKE Cluster Endpoint (Host)"
}
