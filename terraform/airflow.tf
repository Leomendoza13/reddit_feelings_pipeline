resource "google_compute_instance" "airflow_vm" {
  name         = "airflow-instance"
  machine_type = "n2-standard-4"
  zone         = "europe-west9-a"
  tags         = ["airflow"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  service_account {
    email  = google_service_account.airflow_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  network_interface {
    network = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id
    access_config {}
  }

}

