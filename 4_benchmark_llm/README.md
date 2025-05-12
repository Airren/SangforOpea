
# Intel Arc GPU 离线部署大模型性能测试

本指南介绍了如何在离线环境下对Intel Arc GPU部署了的大模型进行性能测试

## 前置条件

- 操作系统：Ubuntu 22.04 (x86_64)
- GPU：Intel Arc GPU (A770)
- 权限：确保具备 `sudo` 权限
- 安装包：通过Intel的IPS下载离线部署资源包 opea-oneclick-release-ubuntu22.04.1-v0.1-offline-sangfor.tar.gz


## 准备工作：安装所需要相应的工具

TBD


**注意：执行下列步骤前，确保已经按照[docker环境文档](../2_docker_rag)或者[K8s环境文档](../3_k8s_rag)设置的相关环境。**

## 第一步: 设置CPU频率和GPU频率

首先找到CPU的最大频率：
```
# 在每一台机器上运行如下命令
sudo cpupower frequency-info | grep 'hardware limits'
```
例如，当前的最大频率假设是3.9GHz。那么运行如下命令锁定CPU频率为上一步找到的最大频率：
```
# 在每一台机器上运行如下命令
sudo cpupower frequency-set -g performance
sudo cpupower frequency-set -d 3.9GHz
```

其次，设置GPU频率：
```
# 在每一台机器上运行如下命令, 假设机器上有8块Intel Arc A770 GPU
sudo xpu-smi config -d 0 -t 0 --frequencyrange 2400,2400
sudo xpu-smi config -d 1 -t 0 --frequencyrange 2400,2400
sudo xpu-smi config -d 2 -t 0 --frequencyrange 2400,2400
sudo xpu-smi config -d 3 -t 0 --frequencyrange 2400,2400
sudo xpu-smi config -d 4 -t 0 --frequencyrange 2400,2400
sudo xpu-smi config -d 5 -t 0 --frequencyrange 2400,2400
sudo xpu-smi config -d 6 -t 0 --frequencyrange 2400,2400
sudo xpu-smi config -d 7 -t 0 --frequencyrange 2400,2400
```
## 第二步: 启动LLM服务

### 2.1 docker 环境
首先运行`docker ps`指令，确保本机上没有其他container在运行，避免对后续性能测试造成干扰。

参考[README](../1_docker_llm/README.md)启动llm服务：
1. 进入对应目录
```
cd SangforOpea/1_docker_llm
```
2. 打开文件set_env.sh，修改当中的相应参数值并保存。 设置`MAX_MODEL_LEN`的值为2000， `MAX_NUM_BATCHED_TOKENS`的值为3000。
```
vim setenv.sh
```
3.  启动llm服务, 并等待服务进入healthy状态
```
bash start_llm.sh
source setenv.sh
sudo -E docker compose ps
```
### 2.2 K8s 环境
1. 首先运行`kubectl get pod` 命令确保没有其他的pod运行，免对后续性能测试造成干扰。

2. 启动ipexllm
```
# 在K8s控制节点运行下面命令
cd SangforOpea/3_k8s_rag/helm-charts/common/ipexllm/
helm install ipexllm . -f sangfor-values.yaml --set service.type=NodePort --set MAX_MODEL_LEN=2000,MAX_NUM_BATCHED_TOKENS=3000
```
   请等待一段时间，重复运行命令`kubectl get pod`确保所有的K8s pod都在ready状态, 例如:
```
NAME                       READY   STATUS    RESTARTS   AGE
ipexllm-5d8cb9cc7b-n49kb   1/1     Running   0          6m42s
```

## 第三步: 运行性能测试脚本
ipexllm的容器镜像中本来就包含了性能测试的脚本。

### 3.1 docker 环境
首先进入ipex容器： `docker exec -it ipex-llm-serving-xpu-container bash`

下面的指令需要在ipex容器内的bash环境下运行。

修改容器内的文件`/llm/vllm/benchmarks/benchmark_serving.py`，取消782行前面的注释符号，并注释掉783行，然后保存。修改后的782行和783行如下所示：
```
    model_id = args.model
    #model_id = args.model.split('/')[-1]
```

运行下面指令开始性能测试，下面以模型`deepseek-ai/DeepSeek-R1-Distill-Qwen-32B`为例，测试输入token为1024字节，输出测试为512字节，并发度为8的情况：
```
export model=deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
python /llm/vllm/benchmarks/benchmark_serving.py --port 80 --model "${model}" --tokenizer "/data/${model}" --dataset-name random --trust_remote_code --num_prompt 8 --random-input-len=1024 --random-output-len=512
```

### 3.2 K8s 环境
首先进入ipexllm pod：
```
export podname=`kubectl get pod --output='jsonpath={.items[0].metadata.name}'`
kubectl exec -it $podname -- bash
```

下面的指令需要在ipexllm容器内的bash环境下运行。

修改容器内的文件`/llm/vllm/benchmarks/benchmark_serving.py`，取消782行前面的注释符号，并注释掉783行，然后保存。修改后的782行和783行如下所示：
```
    model_id = args.model
    #model_id = args.model.split('/')[-1]
```

运行下面指令开始性能测试，下面以模型`deepseek-ai/DeepSeek-R1-Distill-Qwen-32B`为例，测试输入token为1024字节，输出测试为512字节，并发度为8的情况：
```
export model=deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
python /llm/vllm/benchmarks/benchmark_serving.py --model "${model}" --tokenizer "/data/${model}" --dataset-name random --trust_remote_code --num_prompt 8 --random-input-len=1024 --random-output-len=512
```
**注意** 
1. 测试运行时，开始需要多跑几遍`/llm/vllm/benchmarks/benchmark_serving.py`后再取数据，已避免ipexllm服务的冷启动问题。
2. benchmark_serving.py脚本的详细用法可以参看[ipexllm快速开始文档](https://github.com/intel/ipex-llm/blob/main/docs/mddocs/DockerGuides/vllm_docker_quickstart.md#6-benchmarking)

## 第四步: 停止LLM服务
### 4.1 docker 环境
```
cd SangforOpea/1_docker_llm
bash stop_llm.sh
```

### 4.2 K8s 环境
```
cd SangforOpea/3_k8s_rag/helm-charts/common/ipexllm/
helm delete ipexllm
```
