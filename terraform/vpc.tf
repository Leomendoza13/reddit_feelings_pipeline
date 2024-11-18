resource "google_compute_network" "reddit_vpc" {
  name                    = "reddit-feelings-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "reddit_subnet" {
  name          = "reddit-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = "europe-west9"
  network       = google_compute_network.reddit_vpc.id
}

resource "google_compute_firewall" "allow_airflow_to_spark" {
  name    = "allow-airflow-to-spark"
  network = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "7077", "8080"]
  }

  source_ranges = [google_compute_instance.airflow_vm.network_interface[0].access_config[0].nat_ip]
  target_tags   = ["spark"]
}

resource "google_compute_firewall" "allow_iap_to_vms" {
  name    = "allow-iap-to-vms"
  network = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # Google IAP range
  target_tags   = ["airflow", "spark"]
}

resource "google_compute_firewall" "allow_local_access" {
  name    = "allow-local-access"
  network = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "8888", "7077"]  # Ports pour Airflow et Spark UI
  }

  source_ranges = [var.your_ip_adress]
  target_tags   = ["airflow", "spark"]
}