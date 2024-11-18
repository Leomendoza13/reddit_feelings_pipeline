resource "google_service_account" "spark_service_account" {
    account_id = "spark-service-account"
    display_name = "Spark Service Account"
}

resource "google_service_account" "airflow_service_account" {
    account_id = "airflow-service-account"
    display_name = "airflow Service Account"
}

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

resource "google_project_iam_member" "airflow_service_instance_admin" {
  project = "reddit-feelings-pipeline"
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.airflow_service_account.email}"
}

resource "google_project_iam_member" "airflow_storage_admin" {
  project = "reddit-feelings-pipeline"
  role   = "roles/storage.admin"  
  member = "serviceAccount:${google_service_account.airflow_service_account.email}"
}
