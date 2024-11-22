resource "google_project_iam_member" "extraction_vm_service_storage_object_admin" {
  project = "reddit-feelings-pipeline"
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.extraction_vm_service_account.email}"
}