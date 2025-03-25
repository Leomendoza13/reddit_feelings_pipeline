resource "google_project_iam_member" "spark_service_storage_object_admin" {
  project = "reddit-feelings-pipeline"
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.spark_service_account.email}"
}

resource "google_project_iam_member" "spark_service_biqquery_admin" {
  project = "reddit-feelings-pipeline"
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.spark_service_account.email}"
}