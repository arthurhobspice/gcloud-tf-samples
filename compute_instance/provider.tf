provider "google" {
  project     = "enduring-palace-278410"
  credentials = file("~/.config/gcloud/enduring-palace-278410.json")
  region      = "europe-west3"
  zone        = "europe-west3-a"
}

terraform {
  backend "gcs" {
    bucket      = "arthursterraformstate"
    prefix      = "compute"
    credentials = ""
  }
}
