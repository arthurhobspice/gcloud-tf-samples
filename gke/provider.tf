provider "google" {
  project     = var.project_id
  credentials = file("~/.config/gcloud/enduring-palace-278410.json")
  region      = var.region
  zone        = var.default_zone
}

terraform {
  backend "gcs" {
    bucket      = "arthursterraformstate"
    prefix      = "gke"
    credentials = ""
  }
}
