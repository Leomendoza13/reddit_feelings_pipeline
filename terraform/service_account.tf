resource "google_service_account" "kafka_service_account" {
    account_id = "kafka_service_account"
    display_name = "Kafka Service Account"
}

resource "google_service_account" "spark_service_account" {
    account_id = "Spark_service_account"
    display_name = "Spark Service Account"
}

resource "google_project_iam_member" "kafka_service_storage_object_admin" {
  project = :"reddit-feelings-pipeline"
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.kafka_service_account.email}"
}

resource "google_project_iam_member" "spark_service_storage_object_admin" {
  project = :"reddit-feelings-pipeline"
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.spark_service_account.email}"
}

resource "google_project_iam_member" "spark_service_storage_object_admin" {
  project = :"reddit-feelings-pipeline"
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.spark_service_account.email}"
}
