resource "google_compute_instance" "airflow_vm" {
  name         = "airflow-instance"
  machine_type = "n2-standard-4"
  zone         = "europe-west9-a"
  tags         = ["airflow"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  service_account {
    email  = google_service_account.airflow_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }

  network_interface {
    network = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id

    access_config {

    }
  }

  metadata_startup_script = file("${path.module}/scripts/airflow_script.sh")
}

resource "null_resource" "create_dags_dir" {
  depends_on = [google_compute_instance.airflow_vm]

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/airflow/dags /opt/airflow/config",
      "sudo chmod -R 755 /opt/airflow/dags /opt/airflow/config",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /opt/airflow/dags /opt/airflow/config"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(replace(var.ssh_pub_key_path, ".pub", ""))
      host        = google_compute_instance.airflow_vm.network_interface[0].access_config[0].nat_ip
    }
  }
}

