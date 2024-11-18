resource "google_compute_instance" "spark_vm" {
  name         = "spark-instance"
  machine_type = "n2-standard-4"
  zone         = "europe-west9-a"
  tags         = ["spark"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id

    access_config {

    }
  }

  service_account {
    email  = google_service_account.spark_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    ssh-keys = "airflow:${tls_private_key.airflow_ssh_key.public_key_openssh}"
  }

  metadata_startup_script = file("${path.module}/scripts/spark_script.sh")
}