resource "google_compute_instance" "spark_vm" {
  name         = "spark-vm"
  machine_type = "n2-standard-4"
  zone         = "europe-west9-a"
  tags         = ["spark"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id
  }

  service_account {
    email  = google_service_account.spark_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}