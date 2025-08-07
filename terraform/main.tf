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
  name         = "multi-port-ssh-vm"
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
    ssh-keys       = "${var.ssh_user}:${var.ssh_pub_key}"
    startup-script = <<-EOF
      #!/bin/bash

      # Define allowed SSH ports
      PORTS="22 2222 2223 2224 2225 2226"

      # Remove existing Port lines
      sed -i '/^Port /d' /etc/ssh/sshd_config

      # Add new Port lines
      for PORT in $PORTS; do
        echo "Port $PORT" >> /etc/ssh/sshd_config
      done

      # Disable password authentication
      sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
      sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

      # Restart SSH
      systemctl restart sshd
    EOF
  }
}

# ✅ Firewall rule (renamed to avoid 409 conflict)
resource "google_compute_firewall" "allow_custom_ssh_ports_v2" {
  name    = "allow-custom-ssh-ports-v2"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "2222", "2223", "2224", "2225", "2226"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

output "vm_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
