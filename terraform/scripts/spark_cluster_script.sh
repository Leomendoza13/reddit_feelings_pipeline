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

# Prompt user for Spark Master IP
read -p "Enter the IP address of the Spark Master: " SPARK_MASTER_IP

# Create docker-compose.yml for Spark Worker only
cat > /opt/spark/docker-compose.yml << EOL
version: '3.8'

services:
  spark-worker:
    image: bitnami/spark:3.5.3
    container_name: spark-worker
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://$SPARK_MASTER_IP:7077
    command: "/opt/bitnami/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://$SPARK_MASTER_IP:7077"
EOL

# Create directories for jobs and data
sudo mkdir -p /opt/spark/jobs /opt/spark/data
sudo chmod -R 777 /opt/spark/jobs /opt/spark/data

# Start Spark Worker using Docker Compose
cd /opt/spark
sudo docker compose up -d spark-worker

# Print instructions for user
echo "Installation terminée. Spark Worker est connecté au Master Spark ($SPARK_MASTER_IP:7077)."