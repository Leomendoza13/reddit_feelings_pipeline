#!/bin/bash

# Copyright (c) 2024 Léo Mendoza
# Licensed under the MIT License. See LICENSE file in the project root for details

echo "Starting startup script..."

# Timeout et vérifications
TIMEOUT=60
SECONDS=0

while [ ! -f requirements.txt ] || [ ! -f main.py ]; do
    echo "Waiting for requirements.txt and main.py..."
    sleep 5
    SECONDS=$((SECONDS + 5))
    if [ "$SECONDS" -ge "$TIMEOUT" ]; then
        echo "Timeout waiting for required files."
        exit 1
    fi
done

export DEBIAN_FRONTEND=noninteractive

sudo apt install

sudo apt update -y

sudo apt install -y python3 python3-venv python3.10-venv python3-pip

python3 -m venv venv

sudo pip install -r requirements.txt

sudo python3 main.py
