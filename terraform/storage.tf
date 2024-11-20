resource "google_storage_bucket" "functions_bucket" {
  name     = "reddit-feelings-pipeline-functions"
  location = "europe-west1"
}