provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_instance" "app" {
  count        = "${var.num_of_apps}"
  name         = "reddit-app${count.index}"
  machine_type = "g1-small"
  zone         = "${var.app_zone}"
  tags         = ["reddit-app"]

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"

    #ssh-keys = "appuser1:${file(var.public_key_path)}"
    #
    #ssh-keys = "appuser2:${file(var.public_key_path)}"
    #
    #ssh-keys = "appuser3:${file(var.public_key_path)}"
    #
    #ssh-keys = "appuser4:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}