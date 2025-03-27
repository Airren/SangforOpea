#!/usr/bin/env bash

echo "👩‍ Loading images from local file"

docker_images=(
  "intelanalytics---ipex-llm-serving-xpu-2.2.0-b14.tar"
  "ghcr.io---huggingface---text-embeddings-inference-cpu-1.5.tar"
  "redis---redis-stack-7.2.0-v9.tar"
  "opea---chatqna-1.2.tar"
  "opea---chatqna-conversation-ui-1.2.tar"
  "opea---chatqna-ui-1.2.tar"
  "opea---dataprep-pre-1.3.tar"
  "opea---nginx-1.2.tar"
  "opea---retriever-1.2.tar"
)

for image_file in "${docker_images[@]}"; do
  echo "🚚 Loading image: $image_file"
  sudo docker load -i ../docker_images/$image_file
done
