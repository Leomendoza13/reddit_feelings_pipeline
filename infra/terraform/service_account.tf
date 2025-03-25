resource "google_service_account" "spark_service_account" {
    account_id = "spark-service-account"
    display_name = "Spark Service Account"
}

resource "google_service_account" "extraction_vm_service_account" {
    account_id = "extraction-vm-service-account"
    display_name = "Extraction Vm Service Account"
}

