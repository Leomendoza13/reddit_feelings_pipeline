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

resource "google_compute_firewall" "allow_local_to_airflow" {
  name    = "allow-local-to-airflow"
  network = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8080"] # Le port par défaut pour l'interface web d'Airflow
  }

  source_ranges = ["TON_IP_LOCALE"]
  target_tags   = ["airflow"]
}