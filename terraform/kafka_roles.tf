resource "google_project_iam_member" "kafka_storage" {
    project = "reddit-feelings-pipeline"
    role    = "roles/storage.objectViewer"
    member  = "serviceAccount:${google_service_account.kafka_service_account.email}"
}

resource "google_project_iam_member" "kafka_networking" {
    project = "reddit-feelings-pipeline"
    role    = "roles/compute.networkUser"
    member  = "serviceAccount:${google_service_account.kafka_service_account.email}"
}

resource "google_project_iam_member" "kafka_metrics" {
    project = "reddit-feelings-pipeline"
    role    = "roles/monitoring.metricWriter"
    member  = "serviceAccount:${google_service_account.kafka_service_account.email}"
}