#!/usr/bin/env bash

ARCH="amd64"
CONTAINERD_VERSION="1.7.25"
DOCKER_VERSION="28.0.1"
DOCKER_BUILDX_VERSION="0.21.1"
DOCKER_COMPOSE_VERSION="2.33.1"



sudo dpkg -i ./containerd.io_<version>_<arch>.deb \
  ./docker-ce_<version>_<arch>.deb \
  ./docker-ce-cli_<version>_<arch>.deb \
  ./docker-buildx-plugin_<version>_<arch>.deb \
  ./docker-compose-plugin_<version>_<arch>.deb