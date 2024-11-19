# Archive (ZIP) pour le déploiement
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../utils/extraction_function" # Chemin vers les fichiers de la fonction
  output_path = "${path.module}/../config/function.zip" # Où le ZIP sera stocké
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "function.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = "${path.module}/../config/function.zip" # Chemin vers le fichier local
}

# Cloud Function
resource "google_cloudfunctions_function" "extract_reddit_data" {
  name                  = "extract_reddit_data"
  runtime               = "python310"
  region                = "europe-west1"
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  entry_point           = "main"
  trigger_http          = true

  available_memory_mb = 256

  environment_variables = {
    REDDIT_CREDS_PATH = "reddit_credentials.json"
    OUTPUT_FILE_PATH  = "output.json"
  }
}

# Permission pour la fonction
resource "google_cloudfunctions_function_iam_member" "all_users" {
  project        = "reddit-feelings-pipeline"
  region         = "europe-west1"
  cloud_function = google_cloudfunctions_function.extract_reddit_data.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}