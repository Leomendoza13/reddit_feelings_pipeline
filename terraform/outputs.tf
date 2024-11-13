output "airflow_ip_address" {
  value = google_compute_instance.airflow_vm.network_interface[0].access_config[0].nat_ip
}

output "airflow_private_key" {
  value     = tls_private_key.airflow_ssh_key.private_key_pem
  sensitive = true
}