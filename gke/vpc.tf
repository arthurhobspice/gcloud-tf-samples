# VPC
resource "google_compute_network" "tf_sample_gke_network" {
  name                    = "${var.gke_name_prefix}-gke-network"
  auto_create_subnetworks = "false"
}

# Subnets
resource "google_compute_subnetwork" "tf_sample_gke_subnetwork" {
  name                     = "${var.gke_name_prefix}-gke-subnetwork"
  region                   = var.region
  network                  = google_compute_network.tf_sample_gke_network.name
  ip_cidr_range            = var.gke_cidr_ranges["vpc_ip_cidr_range"]
  # Added by GKE cluster creation, so we have to add it here, too:
  private_ip_google_access = true
}
