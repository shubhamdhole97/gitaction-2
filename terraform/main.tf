variable "ssh_user" {
  type = string
}

variable "ssh_pub_key" {
  type = string
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "shubham-project-468314"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "vm_instance" {
  name         = "defaualt-ssh-vm"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network       = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_pub_key}"
  }
}

resource "google_compute_firewall" "allow_default_ssh" {
  name    = "allow-default-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}
