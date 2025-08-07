provider "google" {
  project = "shubham-project-468314"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "vm_instance" {
  name         = "ansible-target-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      # Allocate external IP
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 ufw
    ufw allow 22
    ufw allow 2222
    ufw allow 2223
    ufw allow 2224
    ufw allow 2225
    ufw --force enable
  EOT

  tags = ["ssh-allowed"]
}

resource "google_compute_firewall" "ssh_ports" {
  name    = "allow-ssh-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "2222", "2223", "2224", "2225"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-allowed"]
}

output "external_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
