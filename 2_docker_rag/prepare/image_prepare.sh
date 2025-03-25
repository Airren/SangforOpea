#!/bin/bash


# 设置镜像保存路径
image_path="../../docker_images"
mkdir -p "$image_path"

TAG=1.2
# 定义需要下载的镜像
images=(
  "intelanalytics/ipex-llm-serving-xpu:2.2.0-b14"
  "redis/redis-stack:7.2.0-v9"
  "ghcr.io/huggingface/text-embeddings-inference:cpu-1.5"
  "${REGISTRY:-opea}/dataprep:${TAG:-latest}"
  "${REGISTRY:-opea}/retriever:${TAG:-latest}"
  "${REGISTRY:-opea}/chatqna:${TAG:-latest}"
  "${REGISTRY:-opea}/chatqna-conversation-ui:${TAG:-latest}"
  "${REGISTRY:-opea}/chatqna-ui:${TAG:-latest}"
  "${REGISTRY:-opea}/nginx:${TAG:-latest}"
  "registry.k8s.io/nfd/node-feature-discovery:v0.17.1"
  "intel/intel-gpu-plugin:0.32.0"
  "lianhao/intel-opencl-icd:0.32.0"
  "busybox:1.36"
)

# 依次下载并保存镜像
for image in "${images[@]}"; do
  # 转换镜像名为文件名
  image_file="$image_path/$(echo "$image" | sed 's!/!---!g' | sed 's!:!-!g').tar"

  # 检查镜像文件是否存在
  if [ ! -f "$image_file" ]; then
    echo "💾 镜像文件不存在，正在拉取镜像: $image"
    docker pull "$image"
    echo "🛳️  保存镜像到 $image_file"
    docker save -o "$image_file" "$image"
    chmod a+r $image_file
  else
    echo "✅ 镜像文件已存在: $image_file"
  fi
done

echo "🚀 所有镜像处理完成！"
