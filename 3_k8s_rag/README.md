# Intel Arc GPU 离线部署OPEA ChatQnA指南(K8s)

本指南介绍了如何在Kubernets(K8s)环境下使用Intel Arc GPU离线部署[OPEA ChatQnA](https://github.com/opea-project/GenAIExamples/tree/v1.2rc/ChatQnA).

## 前置条件

- **操作系统**：Ubuntu 22.04 (x86_64)
- **GPU**：Intel Arc GPU (A770)
- **权限**：确保具备 `sudo` 权限
- **安装包**：通过Intel的IPS下载离线部署资源包 Intel_Arc_OPEA_ChatQnA_K8s_Offline_Deployment.tar.gz

---

## **准备工作：下载解压离线部署资源包**

下载离线部署资源包，复制资源包到相应的机器，并解压：

```bash
# 请根据实际Intel提供的下载方式下载离线安装包,并解压

tar -xvf Intel_Arc_OPEA_ChatQnA_K8s_Offline_Deployment.tar.gz
cd SangforOpea/3_K8s_rag

```

## **第一步: 安装操作系统，内核，GPU驱动**

请参见[操作系统安装](../README_OS_Install.md).

## **第二步: 安装Kubernetes**

如果已经安装了Kubernetes(K8s),可跳过此步骤。否则参见[K8s离线安装指南](k8s_offline_install/README.md)

## **第三步: 导入容器镜像**

**注意**: 需要在所有的K8s节点上运行下面的命令

```bash
./load_k8s_images.sh
```

## **第四步: 安装GPU K8s device plugin**

**注意**: 需要在K8s的控制节点运行下面的命令

```bash
./k8s_offline_install/cloudnative_offline_deploy.sh -a install_gpu_device_plugin
```
验证GPU K8s device plugin 工作正常

```bash
./k8s_offline_install/cloudnative_offline_deploy.sh -a verify_intel_gpu
```

## **第五步: 拷贝模型等OPEA离线数据**

**注意**: 需要在所有的K8s节点上运行下面的命令

```bash
./populate_opea_offline_data.sh
```

目前离线安装包提供的模型有：

| 模型名称                                   | 显存要求 | 类别    |
|-------------------------------------------|--------|---------|
| deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B | 8GB  | LLM       |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-7B   | 16GB | LLM       |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-32B  | 32GB | LLM       |
| Qwen/Qwen2.5-7B-Instruct                  | 16GB | LLM       |
| meta-llama/Meta-Llama-3-8B-Instruct       | 16GB | LLM       |
| BAAI/bge-base-en-v1.5                     |      | Embedding |
| BAAI/bge-reranker-base                    |      | Reranking |
| unstructuredio/yolo_x_layout              |      | dataprep  |

## ** 第六步: 离线部署 OPEA ChatQnA

**注意**: 需要在K8s的控制节点运行下面的命令

### 6.1 修改helm value文件中的变量

```bash
cd helm-charts/chatqna/
vim sangfor-values.yaml
```

`sangfor-values.yaml` 文件中定义了离线部署ChatQnA的相关变量，用户可以需要根据自己的需要替换相关的LLM模型，并配置所需的Arc GPU个数。具体所需要的Arc GPU数量，请[参见](https://github.com/intel/ipex-llm/blob/main/docs/mddocs/DockerGuides/vllm_docker_quickstart.md#validated-models-list).

```
ipexllm:
  ... ...
  # 修改 LLM_MODEL_ID 变量指向用户需要的LLM模型
  LLM_MODEL_ID: "/data/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B"
  # 根据具体模型和用户对模型inference SLA的要求，选择使用的Arc GPU个数，默认情况下，TENSOR_PARALLEL_SIZE的值推荐和resource limit的值一致。
  TENSOR_PARALLEL_SIZE: 4
  resources:
    limits:
      gpu.intel.com/i915: 4
... ...
global:
  HUGGINGFACEHUB_API_TOKEN: "<请配置Huggingface API token>"
```

### 6.2 离线安装ChatQnA

```bash
helm install chatqna . -f sangfor-values.yaml
```

请等待一段时间，重复运行命令`kubectl get pod`确保所有的K8s pod都在ready状态, 例如:

```
NAME                                       READY   STATUS    RESTARTS   AGE
chatqna-7444fdbbd7-wjbvr                   1/1     Running   0          105s
chatqna-chatqna-ui-8596c7cc86-rbtjz        1/1     Running   0          105s
chatqna-data-prep-6887675f48-4m8n4         1/1     Running   0          105s
chatqna-ipexllm-f4bb8998f-qnpfz            1/1     Running   0          105s
chatqna-nginx-6c57d4865f-4jm86             1/1     Running   0          105s
chatqna-redis-vector-db-8566ffdb78-ghq82   1/1     Running   0          105s
chatqna-retriever-usvc-76d56b6d5b-zxwtn    1/1     Running   0          105s
chatqna-tei-69bfbb6c4-gpl9c                1/1     Running   0          105s
chatqna-teirerank-7544df7696-mblz7         1/1     Running   0          105s
```

## **第七步：验证 ChatQnA**

### 7.1 使用 cURL 进行简单验证

**注意**: 需要在K8s的控制节点运行下面的命令

运行如下命令暴露chatqna服务端口:

```bash
kubectl port-forward svc/chatqna 8888:8888
```

在新的终端运行如下curl命令:

```bash
curl http://localhost:8888/v1/chatqna \
    -H "Content-Type: application/json" \
    -d '{"messages": "What is the revenue of Nike in 2023?"}'
```

### 7.2 使用 UI 进行验证

**注意**: 需要在K8s的控制节点运行下面的命令

```bash
export port=$(kubectl get service chatqna-nginx --output='jsonpath={.spec.ports[0].nodePort}')
echo $port
```

打开浏览器，输入如下地址访问ChatQnA UI界面`http://<k8s-node-ip-address>:${port}`

## **第八步: 删除ChatQnA**

```bash
helm delete chatqna
```

## **注意事项**

- 确保容器内推理模型正常加载，显存充足。

-  如果性能异常，考虑调整ipexllm的参数。

- 如果chatqna运行异常，可以按照此[验证步骤](https://github.com/opea-project/GenAIExamples/blob/main/ChatQnA/docker_compose/intel/cpu/xeon/README.md#validate-microservices)，对各个后台service进行单独的验证。对于每个service，按照如下步骤经行验证：

   ```
   # 获取K8s 服务名称和端口号
   kubect get svc

   # 暴露服务端口
   kubectl port-forward svc/<服务名> <端口号>:<端口号>

   # 在新的终端下运行相关的curl命令进行验证:
   curl http://localhost:<端口号>/v1/... ...
   ```

   如果curl命令返回错误，可以运行kubectl logs <服务所对应的K8s pod名> 查看具体的错误log.
