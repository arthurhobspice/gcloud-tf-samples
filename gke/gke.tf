# GKE cluster
resource "google_container_cluster" "tf_sample_gke" {
  name     = "${var.gke_name_prefix}-gke"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.tf_sample_gke_network.name
  subnetwork = google_compute_subnetwork.tf_sample_gke_subnetwork.name

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_cidr_ranges["master_ipv4_cidr_block"]
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.gke_cidr_ranges["cluster_ipv4_cidr_block"]
    services_ipv4_cidr_block = var.gke_cidr_ranges["services_ipv4_cidr_block"]
  }

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.gke_cidr_ranges["master_auth_cidr_range"]
      display_name = var.gke_cidr_ranges["master_auth_cidr_range_desc"]
    }
  }

  resource_labels = merge(
    var.default_labels,
    {
      "name" = "${var.gke_name_prefix}-gke"
    }
  )
}

# Separately Managed Node Pool
resource "google_container_node_pool" "tf_sample_gke_node_pool" {
  name       = "${var.gke_name_prefix}-gke-node-pool"
  location   = var.region
  cluster    = google_container_cluster.tf_sample_gke.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = merge (
      var.default_labels,
      {
        "name" = "${var.gke_name_prefix}-gke-node-pool"
        "env"  = var.project_id
      }
    )

    #preemptible  = true
    #machine_type = "e2-standard-2"
    tags         = ["gke-node", "${var.gke_name_prefix}-gke"]
    metadata     = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = var.gke_min_node_count
    max_node_count = var.gke_max_node_count
  }
}

# Regional compute disk for persistent volumes
resource "google_compute_region_disk" "tf_sample_gke_disk" {
  name                      = "${var.gke_name_prefix}-gke-disk"
  type                      = "pd-ssd"
  region                    = var.region
  size                      = 200
  physical_block_size_bytes = 4096

  replica_zones = [var.default_zone, var.alternate_zone]

  labels = merge (
    var.default_labels,
    {
      "name" = "${var.gke_name_prefix}-gke-disk"
    }
  )

}