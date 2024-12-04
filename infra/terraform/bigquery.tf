resource "google_bigquery_dataset" "dataset" {
  dataset_id = "dataset"
  location   = "EU" 
}

resource "google_bigquery_table" "posts" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "posts"
  deletion_protection=false
  schema = <<EOF
[
  {
    "name": "id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "url",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "score",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "author",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "num_comments",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "selftext",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "subreddit",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "post_date",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "processing_time",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  }
]
EOF
}

# Création de la table comments
resource "google_bigquery_table" "comments" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "comments"
  deletion_protection=false
  schema = <<EOF
[
  {
    "name": "post_id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "comment_id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "comment_author",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "comment_body",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "comment_score",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "comment_date",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "processing_time",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "sentiment",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}