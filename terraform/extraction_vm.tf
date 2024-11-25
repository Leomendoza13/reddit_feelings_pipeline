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
    network_ip = "10.0.0.5"

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

resource "null_resource" "setup" {
  depends_on = [null_resource.extraction]
  
  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip",
      "python3 -m venv venv",
      "source venv/bin/activate",
      "pip install -r requirements.txt",
      "python3 main.py"
    ]
    
    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(replace(var.ssh_pub_key_path, ".pub", ""))
      host        = google_compute_instance.extraction_vm.network_interface[0].access_config[0].nat_ip
    }
  }
}