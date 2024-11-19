resource "google_storage_bucket" "functions_bucket" {
  name          = "reddit-feelings-pipeline-bucket-functions"
  location      = "EU"
  force_destroy = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}