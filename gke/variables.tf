variable "region" {
  default = "europe-west3"
}

variable "default_zone" {
  default = "europe-west3-a"
}

variable "alternate_zone" {
  default ="europe-west3-b"
}

variable "project_id" {
  default = "enduring-palace-278410"
}

variable "gke_username" {
  default = ""
}

variable "gke_password" {
  default = ""
}

variable "gke_num_nodes" {
  default = 1
}

variable "gke_min_node_count" {
  default = 1
}

variable "gke_max_node_count" {
  default = 2
}

variable "gke_cidr_ranges" {
  type = map
  default = {
    "master_ipv4_cidr_block"      = "172.16.0.32/28"
    "vpc_ip_cidr_range"           = "10.10.0.0/16"
    "cluster_ipv4_cidr_block"     = "10.11.0.0/16"
    "services_ipv4_cidr_block"    = "10.12.0.0/16"
    "master_auth_cidr_range"      = "37.201.128.0/17"
    "master_auth_cidr_range_desc" = "unitymedia"
  }
}

variable "gke_name_prefix" {
  default = "tf-sample"
}

variable "default_labels" {
  type = map
  default = {
    "managed_by"      = "derbauerchristoph-gmail_com"
    "security_zone"   = "test"
    "environment"     = "test"
    "project"         = "enduring-palace-278410"
    "confidentiality" = "c1"
  }
}