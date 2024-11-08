resource "google_compute_instance" "kafka_vm" {
  name         = "kafka-vm"
  machine_type = "e2-micro"
  zone         = "europe-west9-a"
  tags         = ["kafka"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-focal-v20220712"
    }
  }

  network_interface {
    network    = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id
  }

  service_account {
    email  = google_service_account.kafka_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}