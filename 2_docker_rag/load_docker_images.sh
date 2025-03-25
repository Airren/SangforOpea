#!/usr/bin/env bash

# Load images from local file
echo "👩‍ Loading images from local file"

ls ../docker_images | while read image_file; do
  echo "🚚 Loading image: $image_file"
  sudo docker load -i ../docker_images/$image_file
done

