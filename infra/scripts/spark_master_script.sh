#!/bin/bash

# Copyright (c) 2024 Léo Mendoza
# Licensed under the MIT License. See LICENSE file in the project root for details

# Update and install certificates
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl

# Create the directory for Docker's key and add the key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to sources.list
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to Docker group
sudo usermod -aG docker $USER

# Create directories for Spark
sudo mkdir -p /opt/spark
cd /opt/spark

# Create docker-compose.yml for Spark Master only
cat > /opt/spark/docker-compose.yml << 'EOL'
version: '3.8'

services:
  spark-master:
    image: bitnami/spark:3.5.3
    container_name: spark-master
    network_mode: "host"
    ports:
      - "8080:8080"  # Web UI for Spark Master
      - "7077:7077"  # Spark Master
    environment:
      - SPARK_MODE=master
      - SPARK_MASTER_HOST=10.0.0.2
      - SPARK_MASTER_PORT=7077
      - SPARK_MASTER_WEBUI_PORT=8080
      - TRANSFORMERS_CACHE=/opt/bitnami/spark/cache
      - HF_HOME=/opt/bitnami/spark/cache 
    volumes:
      - /opt/spark/jobs:/opt/bitnami/spark/jobs
      - /opt/spark/data:/opt/bitnami/spark/data
      - /opt/spark/cache:/opt/bitnami/spark/cache
      - /opt/spark/jars/gcs-connector-hadoop3-2.2.11.jar:/opt/bitnami/spark/jars/gcs-connector-hadoop3-2.2.11.jar
    command: >
      bash -c "
        pip install transformers torch google-cloud-bigquery google-cloud-storage pandas pyarrow &&
        /opt/bitnami/spark/bin/spark-class org.apache.spark.deploy.master.Master
      "
EOL

# Create directories for jobs and data
sudo mkdir -p /opt/spark/jobs /opt/spark/data /opt/spark/cache /opt/spark/jars
sudo chown -R $USER:$USER /opt/spark/jobs /opt/spark/data /opt/spark/cache /opt/spark/jars
sudo chmod -R 777 /opt/spark/jobs /opt/spark/data /opt/spark/cache /opt/spark/jars

wget https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-2.2.11.jar
mv gcs-connector-hadoop3-2.2.11.jar /opt/spark/jars/gcs-connector-hadoop3-2.2.11.jar

# Start Spark Master using Docker Compose
cd /opt/spark
sudo docker compose up -d spark-master


# Print instructions for user
echo "Installation terminée. Veuillez redémarrer votre machine pour appliquer les changements au groupe Docker."
echo "Spark Master est prêt à être utilisé sur http://127.0.0.1:8080"