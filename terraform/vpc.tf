resource "google_compute_network" "reddit_vpc" {
  name                    = "reddit-feelings-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "reddit_subnet" {
  name          = "reddit-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = "europe-west1"
  network       = google_compute_network.reddit_vpc.id
}

# Rule for SSH via Google IAP
resource "google_compute_firewall" "allow_iap_to_vms" {
  name        = "allow-iap-to-vms"
  description = "Allow SSH access via Identity-Aware Proxy"
  priority    = 900
  network     = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP range
  target_tags   = ["spark-master", "spark-worker", "extraction-vm"]
}

# Rule for local access
resource "google_compute_firewall" "allow_local_access" {
  name        = "allow-local-access"
  description = "Allow access from developer workstation to service UIs"
  priority    = 1100
  network     = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = [
      "22",    # SSH
      "8080",  # Spark Master UI
      "8081",  # Spark Worker UI
      "7077",  # Spark Master port
    ]
  }

  source_ranges = [var.your_ip_adress] 
  target_tags   = ["spark-master", "spark-worker", "extraction-vm"]
}

# Rule for communication Spark Master ↔ Spark Workers
resource "google_compute_firewall" "allow_spark_master_to_workers" {
  name        = "allow-spark-master-to-workers"
  description = "Allow Spark Master to communicate with Spark Workers"
  priority    = 1000
  network     = google_compute_network.reddit_vpc.id

  allow {
    protocol = "tcp"
    ports    = [
      "7077",    # Spark Master comunication
      "8081"     # Spark Worker UI
    ]
  }

  source_tags = ["spark-master"]
  target_tags = ["spark-worker"]
}

# Rule for monitoring ICMP
resource "google_compute_firewall" "allow_monitoring" {
  name        = "allow-monitoring"
  description = "Allow monitoring between services"
  priority    = 2000
  network     = google_compute_network.reddit_vpc.id

  allow {
    protocol = "icmp"
  }

  source_tags = ["spark-master", "spark-worker"]
  target_tags = ["spark-master", "spark-worker"]
}