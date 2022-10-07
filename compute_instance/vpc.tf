resource "google_compute_network" "tf_sample_network" {
  name                    = "tf-sample-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "tf_sample_subnetwork" {
  name          = "tf-sample-subnetwork"
  ip_cidr_range = "10.128.0.0/16"
  region        = "europe-west3"
  network       = google_compute_network.tf_sample_network.id
  secondary_ip_range {
    # Primary IP of compute instance must belong to primary range
    # Secondary IP can also belong to secondary range (optional)
    range_name    = "tf-sample-subnetwork-secondary"
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_compute_firewall" "tf_sample_network_firewall" {
  name    = "tf-sample-network-firewall"
  network = google_compute_network.tf_sample_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
