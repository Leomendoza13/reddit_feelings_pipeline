# Archive (ZIP) pour le déploiement
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../utils/extraction_function" # Chemin vers les fichiers de la fonction
  output_path = "${path.module}/../config/function.zip" # Où le ZIP sera stocké
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "function-${data.archive_file.function_zip.output_md5}.zip"  # Nom unique basé sur le hash MD5
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Cloud Function
resource "google_cloudfunctions2_function" "extract_reddit_data" {
  name        = "extract_reddit_data"
  location    = "europe-west1"
  description = "Extract data from Reddit using PRAW"

  build_config {
    runtime     = "python310"
    entry_point = "main" # Définir le point d'entrée de la fonction
    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
    environment_variables = {
      REDDIT_CREDS_PATH = "reddit_credentials.json"
      OUTPUT_FILE_PATH  = "output.json"
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }

  depends_on = [google_storage_bucket_object.function_zip]
}

# Permission pour la fonction TODO CHANGER ALL USERS
resource "google_cloudfunctions2_function_iam_member" "all_users" {
  project  = "reddit-feelings-pipeline"
  location = "europe-west1"
  role     = "roles/cloudfunctions.invoker"
  member   = "user:tedleo2000@gmail.com"
  cloud_function = google_cloudfunctions2_function.extract_reddit_data.name

  depends_on = [google_cloudfunctions2_function.extract_reddit_data]
}