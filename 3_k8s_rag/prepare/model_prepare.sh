#!/bin/bash


# 设置模型保存路径
model_path="../../models"
mkdir -p "$model_path"

# 定义需要下载的模型
models=(
"unstructuredio/yolo_x_layout"
"Qwen/Qwen2.5-7B-Instruct"
"meta-llama/Meta-Llama-3-8B-Instruct"
"BAAI/bge-base-en-v1.5"
"BAAI/bge-reranker-base"
"deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
"deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"
"deepseek-ai/DeepSeek-R1-Distill-Qwen-32B"
)


huggingface-cli login --token "$HF_TOKEN";


# 依次下载模型
for model in "${models[@]}"; do
  echo "📥 正在下载模型: $model"
  huggingface-cli download "$model" --local-dir "$model_path/$model"
done

echo "✅ 所有模型下载完成！"
