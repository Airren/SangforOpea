#!/usr/bin/env bash

echo "👩‍ Loading images from local file"

docker_images=(
  "intelanalytics---ipex-llm-serving-xpu-2.2.0-b14.tar"
)

for image_file in "${docker_images[@]}"; do
  echo "🚚 Loading image: $image_file"
  sudo docker load -i ../docker_images/$image_file
done