resource "google_compute_instance" "tf_sample_instance" {
  name         = "tf-sample-instance"
  machine_type = "f1-micro"
  zone         = "europe-west3-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tf_sample_subnetwork.self_link
    access_config {
    }
  }

  metadata = {
    ssh-keys  = "turgon:${file("~/.ssh/tf_sample.pub")}"
  }

  metadata_startup_script = file("startup_script.sh")
}
