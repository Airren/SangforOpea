#!/bin/bash

bash ./prepare_apt.sh

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
  echo "❌ exit failed"
  exit 1
}

echo "✅ Docker Install Successful！"

sudo groupadd docker
sudo usermod -aG docker $USER