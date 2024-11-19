resource "google_compute_instance" "kafka_vm" {
  name         = "kafka-instance"
  machine_type = "n2-standard-4"
  zone         = "europe-west9-a"
  tags         = ["kafka"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  service_account {
    email  = google_service_account.kafka_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  network_interface {
    network = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id
    access_config {
    }
  }

  metadata_startup_script = file("${path.module}/scripts/kafka_script.sh")
}