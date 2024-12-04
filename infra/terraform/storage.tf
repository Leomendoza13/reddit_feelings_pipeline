resource "google_storage_bucket" "raw_bucket" {
  name     = "reddit-feelings-pipeline-bucket"
  location = "europe-west1"
  force_destroy = true
}

resource "google_storage_bucket" "process_bucket" {
  name = "reddit-feelings-pipeline-process-bucket"
  location = "europe-west1"
  force_destroy = true
}

resource "google_storage_bucket_object" "posts" {
  name    = "posts/"
  bucket  = google_storage_bucket.process_bucket.name
  content = " " 
}

resource "google_storage_bucket_object" "comments" {
  name    = "comments/"
  bucket  = google_storage_bucket.process_bucket.name
  content = " "
}