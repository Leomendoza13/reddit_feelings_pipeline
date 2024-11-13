resource "tls_private_key" "airflow_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}