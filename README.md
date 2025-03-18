# Intel Arc GPU 离线部署大语言模型指南

## 前置条件

- **操作系统**：Ubuntu 24.04 (x86_64)
- **GPU**：Intel Arc GPU
- **权限**：确保具备 `sudo` 权限
- **安装包**：通过Intel的IPS下载离线部署资源包 Intel_Arc_LLM_Offline_Deployment.tar.gz

---

## **准备工作：下载解压离线部署资源包**

下载离线部署资源包，复制资源包到相应的机器，并解压：

```bash

# 请根据实际Intel提供的下载方式下载离线安装包
wget https://download.01.org/Intel_Arc_LLM_Offline_Deployment.tar.gz 

tar -xvf Intel_Arc_LLM_Offline_Deployment.tar.gz
```

## **第一步：离线部署安装 Docker**

### 1.1 离线安装 Docker

将文件传输到目标机器，执行安装：

```bash
cd Intel_Arc_LLM_Offline_Deployment
bash install_docker.sh
```

### 1.2 可以手动验证 Docker (可跳过)

```bash
docker --version
docker-compose --version
```

### **注意事项**

- 确保 Docker Daemon 正常启动，`sudo systemctl status docker`。
- 可考虑将普通用户加入 `docker` 组，免去频繁输入 sudo： `sudo usermod -aG docker $USER`

---

## **第二步：使用 Docker Compose 部署 LLM 服务**

### 2.1 修改并设置环境变量

编辑 `set_env.sh` 文件，设置环境变量：

#### 2.1.1 根据实际GPU显存情况，选择模型

目前离线安装包提供的模型有：

| 模型名称                        | 显存要求 | 类别  |
|-----------------------------|------|-----|
| Qwen/Qwen2.5-7B-Instruct    | 8GB  | LLM |
| Qwen/Qwen2.5-7B-OpenAI      | 8GB  | LLM |
| Qwen/Qwen2.5-7B-OpenWebText | 8GB  | LLM |
| deepseekai/gpt3-175b        | 16GB | LLM |
| deepseekai/gpt3-175b-turbo  | 16GB | LLM |

```bash
source set_env.sh
```

### 2.1 加载离线镜像并启动LLM服务

```bash
bash start_llm.sh
```

### **注意事项**

- 确保 Docker Compose 文件中的 `capabilities: ["gpu"]` 正确配置 Intel GPU 加速。
- 如果镜像基于 PyTorch 或者 TensorFlow，需确认是否包含 Intel GPU 优化版库（如 `intel-extension-for-pytorch`）。
- 在容器内确认 GPU 可见：`docker exec -it <container_id> bash -c "ls /dev/dri"`。

---

## **第三步：验证 LLM 服务**

### 3.1 使用 cURL 进行简单接口验证

将模型服务启动后，可以使用 cURL 发送请求，验证服务是否正常。
替换 `model` 和 `prompt` 参数，发送请求：

```bash
curl http://localhost:8000/v1/completions \
     -H "Content-Type: application/json" \
     -d '{"model": "Qwen/Qwen2.5-7B-Instruct",
          "prompt": "请介绍你自己",
          "max_tokens": 520
         }'
```

### 3.2 查看 Docker 日志排查 (可选)

如果请求失败，排查日志：

```bash
docker logs <container_id>
```

### **注意事项**

- 确保 LLM 服务配置了正确的端口映射。
- 确保容器内推理模型正常加载，显存充足。
- 如果性能异常，考虑调整等参数。

---

## **总结**

完成以上三步，您应该能在 Intel Arc GPU 上离线运行 LLM 模型服务了 🎉。


