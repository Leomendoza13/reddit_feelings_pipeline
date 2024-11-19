resource "google_service_account" "spark_service_account" {
    account_id = "spark-service-account"
    display_name = "Spark Service Account"
}

resource "google_service_account" "airflow_service_account" {
    account_id = "airflow-service-account"
    display_name = "airflow Service Account"
}

resource "google_service_account" "kafka_service_account" {
    account_id = "kafka-service-account"
    display_name = "Kafka Service Account"
}