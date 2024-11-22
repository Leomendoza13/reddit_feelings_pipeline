resource "google_storage_bucket" "raw_bucket" {
  name     = "reddit-feelings-pipeline-bucket"
  location = "europe-west1"
  force_destroy = true
}