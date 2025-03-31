# Intel Arc GPU 离线部署大语言模型指南

本指南介绍了如何在docker环境下使用Intel Arc GPU离线部署大预言大语言模型提供inference服务.

## 前置条件

- **操作系统**：Ubuntu 24.04 (x86_64)
- **GPU**：Intel Arc GPU (A750/A770/B580)
- **权限**：确保具备 `sudo` 权限
- **安装包**：通过Intel的IPS下载离线部署资源包 Intel_Arc_LLM_Offline_Deployment.tar.gz

---

## **准备工作：下载解压离线部署资源包**

下载离线部署资源包，复制资源包到相应的机器，并解压：

```bash
# 请根据实际Intel提供的下载方式下载离线安装包,并解压

tar -xvf Intel_Arc_LLM_Offline_Deployment.tar.gz

```

## **第一步：离线部署安装 Docker** (可跳过)

请使用[Docker engine community version](https://docs.docker.com/engine/install). 如果系统里已经安装有其他版本docker，请先卸载旧版本的docker，再安装Docker engine community version.

### 1.1 离线安装 Docker

将文件传输到目标机器，执行安装：

```bash
cd SangforOpea/1_docker_llm
bash install_docker.sh
```

### 1.2 可以手动验证 Docker (可跳过)

```bash
sudo docker version
sudo docker compose version
```

### **注意事项**

- 确保 Docker Daemon 正常启动，`sudo systemctl status docker`。
- 可考虑将普通用户加入 `docker` 组，免去频繁输入 sudo： `sudo usermod -aG docker $USER`

---

## **第二步：使用 Docker Compose 部署 LLM 服务**

### 2.0 拷贝模型等OPEA离线数据

```bash
./populate_opea_offline_data.sh
```

### 2.1 修改并设置环境变量

编辑 `setenv.sh` 文件，设置环境变量。

#### 2.1.1 根据环境的Intel Arc GPU的数量，设置TP

> 建议设置TP=4，运行32B模型

```bash
export TENSOR_PARALLEL_SIZE=4 # 对应GPU数量
```
#### 2.1.2 如果在8卡的机器上运行两个4卡32B模型的实例，需要设置GPU的亲和性

```bash
# 使用0-3 GPU
export GPU_AFFINITY="0,1,2,3"
```

#### 2.1.3 根据实际GPU显存情况，选择模型

目前离线安装包提供的模型有：

| 模型名称                                      | 显存要求 | 类别        |
|-------------------------------------------|------|-----------|
| deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B | 8GB  | LLM       |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-7B   | 16GB | LLM       |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-32B  | 32GB | LLM       |
| Qwen/Qwen2.5-7B-Instruct                  | 16GB | LLM       |
| meta-llama/Meta-Llama-3-8B-Instruct       | 16GB | LLM       |
| BAAI/bge-base-en-v1.5                     |      | Embedding |
| BAAI/bge-reranker-base                    |      | Reranking |

```bash
# 修改setenv.sh 中以下变量成对应的模型
export LLM_MODEL_ID=deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B
```

#### 2.1.4 量化设置

```sh
export QUANTIZATION=fp8
```

### 2.2 加载离线docker 容器镜像

```bash
bash load_docker_images.sh
```

#### **注意事项**
- 此步骤只需执行一次
- docker image load 可能会花费较长时间🕐🕐🕐，请耐心等待。


### 2.3 启动LLM服务

```bash
bash start_llm.sh
```

### **注意事项**

- ❗️服务默认暴露在了9009端口，请确保端口不被占用，如需修改，请修改`compose.yaml`中的端口映射。
- 在容器内确认 GPU 可见：`docker exec -it <container_id> bash -c "ls /dev/dri"`。

---

## **第三步：验证 LLM 服务**

### 3.1 等待LLM服务启动完成

```bash
source setenv.sh
sudo -E docker compose ps
```

请等待vllm_service为healthy状态.

> 根据所选模型的不同，启动时间不等，可以通过 `sudo -E docker compose logs vllm-service` 查看日志。
> 如果出现 `INFO:     Uvicorn running on http://0.0.0.0:80 (Press CTRL+C to quit)`，说明服务正常启动

### 3.2 使用 cURL 进行简单接口验证

将模型服务启动后，可以使用 cURL 发送请求，验证vllm服务是否正常。此验证不包含RAG其他组件的调用，仅对LLM模型进行验证。


```bash
  curl http://localhost:9009/v1/completions \
     -H "Content-Type: application/json" \
     -d "{\"model\": \"$LLM_MODEL_ID\",
      \"prompt\": \"上海是一个什么样的城市？\", 
      \"max_tokens\": 256}"
```

### 3.2 通过chatQna的UI验证RAG功能的完整性

通过访问 http://${host-ip}:80,可以在Web UI页面测试RAG功能。



### 3.3 查看 Docker 日志排查 (可选)

如果请求失败，排查日志：

```bash
source setenv.sh
sudo -E docker compose logs vllm-service
```

### 3.4 停止LLM服务

```bash
bash stop_llm.sh
```

### **注意事项**

- 确保 LLM 服务配置了正确的端口映射。
- 确保容器内推理模型正常加载，显存充足。
- 如果性能异常，考虑调整等参数。

---

## **总结**

完成以上三步，您应该能在 Intel Arc GPU 上离线运行 LLM 模型服务了 🎉。


