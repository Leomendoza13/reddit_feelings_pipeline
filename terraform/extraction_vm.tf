resource "google_compute_instance" "extraction_vm" {
  name         = "extraction-instance"
  machine_type = "e2-standard-2"
  zone         = "europe-west1-b"
  tags         = ["extraction-vm"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id

    access_config {
    }
  }

  service_account {
    email  = google_service_account.extraction_vm_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }

  metadata_startup_script = file("${path.module}/scripts/extraction_vm_script.sh")
}

resource "null_resource" "extraction" {
  depends_on = [google_compute_instance.extraction_vm]

  provisioner "file" {
    source      = "../utils/extraction/"
    destination = "."

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(replace(var.ssh_pub_key_path, ".pub", ""))
      host        = google_compute_instance.extraction_vm.network_interface[0].access_config[0].nat_ip
    }
  }   
}