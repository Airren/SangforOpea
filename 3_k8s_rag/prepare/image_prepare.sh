#!/usr/bin/env bash

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${SCRIPTDIR}/utils.sh

# 设置镜像保存路径
image_path="${SCRIPTDIR}/../../docker_images"
mkdir -p "$image_path"

# 定义需要下载的镜像
TAG=1.2
images=(
"intelanalytics/ipex-llm-serving-xpu:2.2.0-b14"
"redis/redis-stack:7.2.0-v9"
"${REGISTRY:-opea}/dataprep:${TAG:-latest}"
"ghcr.io/huggingface/text-embeddings-inference:cpu-1.5"
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

function _download_image() {
  local image=$1
  # 转换镜像名为文件名
  local image_filename=`_get_image_filename $image`
  local image_file="$image_path/${image_filename}"

  # 检查镜像文件是否存在
  if [ ! -f "$image_file" ]; then
    echo "Non existing image, pulling now: $image"
    docker pull "$image"
    echo "Image saved to $image_file"
    docker save -o "$image_file" "$image"
    chmod a+r $image_file
  else
    echo "Image file existing: $image_file"
  fi
}

set -e
# 依次下载并保存镜像
for image in "${images[@]}"; do
  _download_image $image
done

# Download k8s related images
K8S_IMAGE_LIST="${SCRIPTDIR}/../k8s_offline_install/pkg/_image_list.txt"
for image in `cat $K8S_IMAGE_LIST`; do
  _download_image $image
done

echo "All images are pulled successfully!"
