
# 离线安装Kubernetes(K8s)

本教程提供了离线安装K8s的方法。

## 前置条件

- 操作系统: Ubuntu 22.04/24.04
- 权限：确保具备 sudo 权限
- 安装包: 通过Intel提供的方式下载离线部署资源包

## **准备工作：下载解压离线部署资源包**

下载离线部署资源包，复制资源包到相应的机器，并解压：

```bash
# 请根据实际Intel提供的下载方式下载离线安装包,并解压

tar -xvf <offline_tarball>
cd SangforOpea/3_K8s_rag/

```

## **第一步: 检查并配置系统环境**

建议在新安装的操作系统上安装K8s. 如果操作系统上已经安装了docker/containerd的环境，建议卸载清理干净。

确保每个安装K8s的节点上的网卡mac地址和product uuid是唯一不重复的.
```
# Get MAC address
ip link
# Get product uuid
sudo cat /sys/class/dmi/id/product_uuid
```

检擦所有节点上的网卡，如果节点上有多网卡（包括虚拟网卡），并且k8s各个节点间无法通过默认路由连通，建议在各节点上手工添加路由保证各个节点之间的网络连通性。

检擦节点上端口打开情况，确保下列K8s所需使用的端口没有被其他服务所占用。
具体端口信息可以参考[此表格](https://kubernetes.io/docs/reference/networking/ports-and-protocols/).
```
# 可以使用如下指令查看端口占用情况
nc 127.0.0.1 6443 -zv -w 2
```

## **第二步: 安装K8s控制节点**

**注意**: 需要在K8s的控制节点运行下面的命令

```
./k8s_offline_install/cloudnative_offline_deploy.sh -a install_k8s_master
```

安装结束后，脚本会显示部署K8s计算节点的命令。记下这条命令，稍后需要在k8s计算节点上运行。

安装脚本成功运行后，运行如下命令确保所有的Pod都已经Ready，并且所有的node都已经ready。
```
kubectl get node -owide
kubectl get pod -A
```

成功部署控制节点后的输出如下:
```
NAME     STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION     CONTAINER-RUNTIME
811649   Ready    control-plane   5m51s   v1.32.2   10.0.11.101   <none>        Ubuntu 24.04 LTS   6.8.0-55-generic   containerd://2.0.4

NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-79949b87d-kq9v7   1/1     Running   0          7m29s
kube-system   calico-node-zpj5t                         1/1     Running   0          7m29s
kube-system   coredns-668d6bf9bc-tmt78                  1/1     Running   0          17s
kube-system   coredns-668d6bf9bc-v7fz4                  1/1     Running   0          17s
kube-system   etcd-811649                               1/1     Running   10         7m37s
kube-system   kube-apiserver-811649                     1/1     Running   7          7m37s
kube-system   kube-controller-manager-811649            1/1     Running   7          7m34s
kube-system   kube-proxy-dvp28                          1/1     Running   0          7m29s
kube-system   kube-scheduler-811649                     1/1     Running   10         7m34s
```

注意1: 默认安装的K8s环境使用的POD_CIDR是`10.244.0.0/16`, 确保此网段与k8s所有节点坐在的网段之间没有重叠。如果网段有重叠，请选择正确的POD_CIDR进行安装。
```
POD_CIDR=<your pod cidr> ./k8s_offline_install/cloudnative_offline_deploy.sh -a install_k8s_master
```

注意2: 脚本选择默认路由的网卡为k8s API服务的通信网卡，如果控制节点上没有默认路由或者需要配置其他网卡为k8s的通信网卡，需要配置环境变量`APISERVER_ADDR`指定K8s API server所绑定的ip地址.
```
	  APISERVER_ADDR=<K8s contrller ip address> ./k8s_offline_install/cloudnative_offline_deploy.sh -a install_k8s_master
```

## **第三步: 安装K8s计算节点(可选)**

在所有的k8s计算节点上运行第二步中所记录下来的命令，安装k8s计算节点
```
APISERVER_ADDR=<ip address> ./k8s_offline_install/cloudnative_offline_deploy.sh -a install_k8s_worker
```

## **第四步: 安装后步骤**

如果整个k8s cluster只有一个控制节点，需要运行下面的命令:
```
./k8s_offline_install/cloudnative_offline_deploy.sh -a k8s_master_untaint
```

## **第五步: 验证k8s网络环境 **

**注意**: 需要在K8s的控制节点运行下面的命令

启动两个netshoot pod: `kubectl apply -f k8s_offline_install/debug.yaml`.

执行`kubectl get pod -owide`, 确认两个netshoot pod已经启动并获取其ip地址:
```
NAME                        READY   STATUS    RESTARTS   AGE    IP              NODE     NOMINATED NODE   READINESS GATES
netshoot-6c97b976f9-gvlvb   1/1     Running   0          3m4s   10.244.42.202   811649   <none>           <none>
netshoot-6c97b976f9-jqtkd   1/1     Running   0          3m4s   10.244.42.203   811649   <none>           <none>
```

确保两个netshoot pod之间东西向网络连通, 执行`kubectl exec netshoot-6c97b976f9-gvlvb -- ping -c 1 10.244.42.203`
```
PING 10.244.42.203 (10.244.42.203) 56(84) bytes of data.
64 bytes from 10.244.42.203: icmp_seq=1 ttl=63 time=0.182 ms

--- 10.244.42.203 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.182/0.182/0.182/0.000 ms
```

确保南北向网络连通, netshoot pod可以连接到k8s节点主机地址(假设有一个k8s节点的ip地址为10.0.11.100)，执行`kubectl exec netshoot-6c97b976f9-gvlvb -- ping -c 1 10.0.11.100`:
```
PING 10.0.11.100 (10.0.11.100) 56(84) bytes of data.
64 bytes from 10.0.11.100: icmp_seq=1 ttl=63 time=1.67 ms

--- 10.0.11.100 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.672/1.672/1.672/0.000 ms
```

确保k8s内coredns工作正常，执行`kubectl exec netshoot-6c97b976f9-gvlvb -- nslookup kube-dns.kube-system.svc.cluster.local`:
```
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   kube-dns.kube-system.svc.cluster.local
Address: 10.96.0.10
```

删除测试pod: `kubectl delete -f k8s_offline_install/debug.yaml`

## 准备k8s离线安装二进制包

在有网络和已经安装docker的机器上，运行下面的命令，可以下载用于k8s离线安装的二进制程序包已经相关的容器镜像:
```
./k8s_offline_install/cloudnative_offline_deploy.sh -a download_k8s_pkg
./prepare/image_prepare.sh
```