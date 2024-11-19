#!/bin/bash

# Copyright (c) 2024 Léo Mendoza
# Licensed under the MIT License. See LICENSE file in the project root for details

set -e  # Arrête le script si une commande échoue

echo "Mise à jour des paquets et installation des dépendances nécessaires..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "Ajout du dépôt Docker officiel..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installation de Docker et Docker Compose..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Création des dossiers pour Kafka..."
sudo mkdir -p /opt/kafka/{config,data,logs}
sudo chmod -R 777 /opt/kafka

CLUSTER_ID=$(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}' | head -c 22)

# Récupérer l'IP externe de la VM
EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

echo "Création du fichier docker-compose.yml..."
cat <<EOL | sudo tee /opt/kafka/docker-compose.yml
version: '3.8'
services:
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: kafka
    ports:
      - "9092:9092"
      - "9094:9094"
    environment:
      # KRaft settings
      CLUSTER_ID: "${CLUSTER_ID}"
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: 'broker,controller'
      KAFKA_CONTROLLER_QUORUM_VOTERS: '1@kafka:29093'
      
      # Listeners basiques
      KAFKA_LISTENERS: 'PLAINTEXT://kafka:29092,CONTROLLER://kafka:29093,EXTERNAL://0.0.0.0:9094'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka:29092,EXTERNAL://${EXTERNAL_IP}:9094'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT'
      KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
      
      # Config simple
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_DEFAULT_REPLICATION_FACTOR: 1
      
    volumes:
      - /opt/kafka/data:/var/lib/kafka/data
      - /opt/kafka/logs:/var/lib/kafka/logs
EOL

echo "Démarrage de Kafka..."
cd /opt/kafka
sudo docker compose up -d

# Attendre que Kafka démarre
echo "Attente du démarrage de Kafka..."
sleep 30

# Vérifier l'état
echo "Vérification de l'état de Kafka..."
sudo docker compose ps
sudo docker compose logs kafka | grep "started"

echo "Installation terminée. Kafka est accessible sur ${EXTERNAL_IP}:9094"
echo "CLUSTER_ID utilisé : ${CLUSTER_ID}"