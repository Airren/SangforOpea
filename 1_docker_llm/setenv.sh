
export DOCKER_IMAGE=intelanalytics/ipex-llm-serving-xpu:2.2.0-b14
export LLM_CONTAINER_NAME=ipex-llm-serving-xpu-container


# Set bind local models path to the container
export MODELS_PATH=$(pwd)/../models



# set the name of model used for serving
export LLM_MODEL_ID=deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B
# set the path where locates the pre-downloaded model corresponding to the LLM_MODEL_ID
export LLM_MODEL_LOCAL_PATH=/data/${LLM_MODEL_ID}

export SHM_SIZE="8g"

export DTYPE=float16
export QUANTIZATION=fp8
export MAX_MODEL_LEN=2048
export MAX_NUM_BATCHED_TOKENS=4000
export MAX_NUM_SEQS=256
export TENSOR_PARALLEL_SIZE=1


