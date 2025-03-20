#!/bin/bash
#
#


# 设置镜像保存路径
image_path="../../docker_images"
mkdir -p "$image_path"

# 定义需要下载的镜像
images=(
  "intelanalytics/ipex-llm-serving-xpu:2.2.0-b14"
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
  else
    echo "✅ 镜像文件已存在: $image_file"
  fi
done

echo "🚀 所有镜像处理完成！"