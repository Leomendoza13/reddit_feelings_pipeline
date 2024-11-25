#!/bin/bash

# Copyright (c) 2024 Léo Mendoza
# Licensed under the MIT License. See LICENSE file in the project root for details

sudo mkdir salut

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


# Create docker-compose.yml for Spark Worker
cat > /opt/spark/docker-compose.yml << EOL
version: '3.8'

services:
  spark-worker:
    image: bitnami/spark:3.5.3
    container_name: spark-worker
    ports:
      - "8081:8081"   # Worker Web UI
      - "7078:7078"   # Worker port
    networks:
      - spark-network
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://10.0.0.2:7077
      - SPARK_WORKER_CORES=2
      - SPARK_WORKER_MEMORY=2G
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
    volumes:
      - /opt/spark/jobs:/opt/spark/jobs
      - /opt/spark/data:/opt/spark/data
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081"]
      interval: 30s
      timeout: 10s
      retries: 3
    command: "/opt/bitnami/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://10.0.0.2:7077"

networks:
  spark-network:
    driver: bridge
EOL

# Create directories for jobs and data
sudo mkdir -p /opt/spark/jobs /opt/spark/data
sudo chmod -R 777 /opt/spark/jobs /opt/spark/data

# Start Spark Worker using Docker Compose
cd /opt/spark
sudo docker compose up -d spark-worker

echo "Vérification de la connexion au master..."
timeout 30 bash -c "until docker logs spark-worker 2>&1 | grep -q 'Successfully registered with master'; do sleep 2; done" || {
    echo "Erreur: Le worker ne s'est pas connecté au master dans les 30 secondes"
    exit 1
}

cat > /opt/spark/health-check.sh << EOL
#!/bin/bash
if ! docker ps | grep -q spark-worker; then
    echo "Container worker non démarré"
    exit 1
fi
if ! curl -s http://localhost:8081 > /dev/null; then
    echo "Interface Web du worker non accessible"
    exit 1
fi
if ! nc -z 10.0.0.2 7077; then
    echo "Master Spark non accessible"
    exit 1
fi
echo "Worker Spark en bon état"
exit 0
EOL
chmod +x /opt/spark/health-check.sh

# Print instructions for user
echo "Installation terminée. Spark Worker est connecté au Master Spark ($SPARK_MASTER_IP:7077)."
echo "Interface Web du Worker: http://localhost:8081"
echo "Script de vérification: /opt/spark/health-check.sh"

# logs display
echo "Derniers logs du worker:"
docker logs spark-worker --tail 20