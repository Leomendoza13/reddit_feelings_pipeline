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

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-traffic"
  network = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
  direction     = "INGRESS"
  target_tags   = ["spark"]
}