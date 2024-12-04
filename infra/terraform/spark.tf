resource "google_compute_instance" "spark_master_vm" {
  name         = "spark-master-instance"
  machine_type = "e2-standard-2"
  zone         = "europe-west1-b"
  tags         = ["spark-master"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id

    network_ip = "10.0.0.2"

    access_config {

    }
  }

  service_account {
    email  = google_service_account.spark_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }

  metadata_startup_script = file("${path.module}/../scripts/spark_master_script.sh")
}

# Spark Worker VMs
resource "google_compute_instance" "spark_worker0" {
  name         = "spark-worker-0"
  machine_type = "e2-standard-2"
  zone         = "europe-west1-c" # Workers dans une zone différente pour tolérance de panne
  tags         = ["spark-worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  service_account {
    email  = google_service_account.spark_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  network_interface {
    network    = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id
    network_ip = "10.0.0.3"
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }

  metadata_startup_script = file("${path.module}/../scripts/spark_cluster_script.sh")
}

# Spark Worker VMs
resource "google_compute_instance" "spark_worker1" {
  name         = "spark-worker-1"
  machine_type = "e2-standard-2"
  zone         = "europe-west1-c" # Workers dans une zone différente pour tolérance de panne
  tags         = ["spark-worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  service_account {
    email  = google_service_account.spark_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  network_interface {
    network    = google_compute_network.reddit_vpc.id
    subnetwork = google_compute_subnetwork.reddit_subnet.id
    access_config {}
    network_ip = "10.0.0.4"
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }

  metadata_startup_script = file("${path.module}/../scripts/spark_cluster_script.sh")
}

resource "null_resource" "processing" {
  depends_on = [google_compute_instance.spark_master_vm]

  provisioner "file" {
    source      = "../../src/processing/spark.py"
    destination = "/home/${var.ssh_user}/spark.py" 

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(replace(var.ssh_pub_key_path, ".pub", ""))
      host        = google_compute_instance.spark_master_vm.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv ~/spark.py /opt/spark/jobs/"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(replace(var.ssh_pub_key_path, ".pub", ""))
      host        = google_compute_instance.spark_master_vm.network_interface[0].access_config[0].nat_ip
    }
  }
}