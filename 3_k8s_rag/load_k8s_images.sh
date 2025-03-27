#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IMGDIR="${SCRIPT_DIR}/../docker_images"
# Load images from local file
echo "👩‍ Loading images from local file"

if ! command -v nerdctl 2>&1 >/dev/null
then
  ${SCRIPT_DIR}/k8s_offline_install/cloudnative_offline_deploy.sh -a _install_pkg_nerdctl
fi

if ! command -v helm 2>&1 >/dev/null
then
  ${SCRIPT_DIR}/k8s_offline_install/cloudnative_offline_deploy.sh -a _install_pkg_helm
fi

ls $IMGDIR | while read image_file; do
  echo "🚚 Loading image: $image_file"
  sudo nerdctl -n k8s.io load -i $IMGDIR/$image_file
done

