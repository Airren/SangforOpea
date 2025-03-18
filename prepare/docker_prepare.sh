#!/usr/bin/env bash

ARCH="amd64"
CONTAINERD_VERSION="1.7.25"
DOCKER_VERSION="28.0.1"
DOCKER_BUILDX_VERSION="0.21.1"
DOCKER_COMPOSE_VERSION="2.33.1"

UBUNTU_VERSION_CODENAME="ubuntu.24.04~noble"

BASE_URL="https://download.docker.com/linux/ubuntu/dists/noble/pool/stable/${ARCH}/"
mkdir -p docker_packages

function download_package() {
  local package_name=$1
  local url=$2
  local store_path=$3
  echo "Downloading: $package_name"
  if ! wget -q --show-progress "$url" -O $store_path; then
    echo "⚠️ Failed: $package_name"
  else
    echo "✅ Success: $package_name"
  fi
}

# Download containerd
echo "Downloading containerd"
containerd_name=containerd.io_${CONTAINERD_VERSION}-1_${ARCH}.deb
if [ ! -f docker_packages/${containerd_name} ]; then
  #  wget -q ${BASE_URL}${containerd_name} -O docker_packages/${containerd_name}
  download_package $containerd_name ${BASE_URL}${containerd_name} docker_packages/${containerd_name}
fi

# Download docker-ce
echo "Downloading docker-ce"
docker_ce_name=docker-ce_${DOCKER_VERSION}-1~${UBUNTU_VERSION_CODENAME}_${ARCH}.deb
if [ ! -f docker_packages/${docker_ce_name} ]; then
  #  wget -q ${BASE_URL}${docker_ce_name} -O docker_packages/${docker_ce_name}
  download_package $docker_ce_name ${BASE_URL}${docker_ce_name} docker_packages/${docker_ce_name}
fi

# Download docker-ce-cli
echo "Downloading docker-ce-cli"
docker_ce_cli_name=docker-ce-cli_${DOCKER_VERSION}-1~${UBUNTU_VERSION_CODENAME}_${ARCH}.deb
if [ ! -f docker_packages/${docker_ce_cli_name} ]; then
  #  wget -q ${BASE_URL}${docker_ce_cli_name} -O docker_packages/${docker_ce_cli_name}
  download_package $docker_ce_cli_name ${BASE_URL}${docker_ce_cli_name} docker_packages/${docker_ce_cli_name}
fi

# Download docker-buildx
echo "Downloading docker-buildx-plugin"
docker_buildx_name=docker-buildx-plugin_${DOCKER_BUILDX_VERSION}-1~${UBUNTU_VERSION_CODENAME}_${ARCH}.deb
if [ ! -f docker_packages/${docker_buildx_name} ]; then
  #  wget -q ${BASE_URL}${docker_buildx_name} -O docker_packages/${docker_buildx_name}
  download_package $docker_buildx_name ${BASE_URL}${docker_buildx_name} docker_packages/${docker_buildx_name}
fi

# Download docker-compose
echo "Downloading docker-compose"
docker_compose_name=docker-compose-plugin_${DOCKER_COMPOSE_VERSION}-1~${UBUNTU_VERSION_CODENAME}_${ARCH}.deb
if [ ! -f docker_packages/${docker_compose_name} ]; then
  #  wget -q ${BASE_URL}${docker_compose_name} -O docker_packages/${docker_compose_name}
  download_package $docker_compose_name ${BASE_URL}${docker_compose_name} docker_packages/${docker_compose_name}
fi
