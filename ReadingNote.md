## kubernetes实战 读书笔记

### 网络
#### flannel
* flannel会为不同的node的docker网桥配置不同的IP网段以保证Docker容器的IP在集群内唯一，所以flannel会重新配置Docker网桥，需要先 _删除原来的创建的Docker网桥_

```
iptables -t nat -F #清空iptables的关于natp的规则, --flush   -F [chain]		Delete all rules in  chain or all chains
ifconfig docker0 down #关闭网桥
brctl delbr docker0   #删除网桥

```
* flannel运行后会生成一个文件subnet.env

```
一般subnet.env的绝对地址在/run/flannel/subnet.env

而且docker启动命令（ps aux | grep docker）应该会是这样的
--bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}

注意里面对应上里面的$值

```	

#### kube-dns
* 注意cluster-dns的启动参数, (ps aux | grep kube-dns)

```
	--cluster-dns=xx
	--cluster-domain=cluster.local
```
* 具体不知道应该怎么对应上,是不是kubectl describe pod kube-dns上的IP对应上?
* 验证dns服务是不是正常运行

```
kubectl exec my-pod -- nslookup kubernetes.default.cluster.local

注：这个my-pod是需要创建的，比如说
kubectl run test --image=hypriot/armhf-busybox -- sleep 10000
然后用这个pod替换上面的my-pod执行命令，不知道这样对不对？

可不可以直接用kube的原生的Pod去验证，那不就更有说服力么。难道kube原生的pod就不用去调用这个服务？

```
* pod中的容器使用容器宿主机的DBS域名解析配置，称为默认DNS配置。另外，如果kube部署并设置了cluster DNS支持，那么在创建Pod的时候，默认会将Cluster DNS的配置写入Pod中Pod中容器的DNS域名解析配置中，称为Cluster DNS配置。

```
pod的定义中通过.spec.dnsPolicy设置Pod的DNS策略，默认值是ClusterFirst.
查看DNS策略设置为ClusterFirst的Pod中容器的/etc/resolv.conf
验证：
	kubectl exec pod_name -- cat /etc/resolv.conf
	
	类似输出：
	nameserver 10.254.10.2	
	nameserver 218.85.157.99
	search default.svc.cluster.local svc.cluster.local cluster.local
	其中 第一行 是cluster DNS 的IP,第二行是宿主的默认DNS配置。
	第三行是搜索域
	
	验证：
	kubectl exec my-pod -- nslookup my-service.my-ns --namespace=default

```

#### pod

* pod包含一个或者多个容器

```
kubeclt get pod --all-namespaces
随便选一个pod的名称，例如kube-proxy-xxxx
然后在master或者node节点(这个取决于这个pod是运行在哪一个node上的),执行
docker ps | grep kube-proxy-xxxx
有些情况下会看到不止一个容器在运行。

```

#### yaml描述文件里面的关键字说明
* kind


```
 - secret 使用docker私有仓库时使用，暂时不需要关心
 - pod 单纯的pod
 - replicationController: 主要作用是管理创建pod
	- spec.replicas : pod副本的数量
	- spec.template : pod的模板，主要是说明一个pod包含了几个容器，每个容器使用的镜像是什么。
	注：通过label来关联
 - Service : 虚拟的服务层，用来代理Pod，是一个抽象的概念，定义了一个Pod逻辑集合以及访问它们的策略，可以理解为真实应用的抽象，某种程度上说作用类似于Virtual IP，以及进行 _服务发现_
 	注： kubectl get service (服务名)
 	得到
```
 NAME | CLUSTER_IP | EXTERNAL_IP | PORT | SELECTOR | AGE
-----|------------|-------------|------|----------|----

```
其中的CLUSTER_IP就是kube分配给Service的虚拟IP
其中的PORT则是Service会转发的端口
注：所有访问CLUSTER_IP:PORT的（TCP）请求都会转发到Service指定的pod（s）中，目标端口是（在PORT字段有描述，例子：6379:8081(TCP),类似形式）

 - 关于服务发现，Service发现Pod有两种方式，但是比较推荐使用cluster-dns的方式。

 注： 如果没有设置端口转发的话，pod中的spec.ports.containerPort应该需要与service中的spec.ports.port相同才行吧……？
 
```
* 至此我们已经可以创建pods(via. replicas)和vip(via. service),但是cluster_ip毕竟是内网的IP地址，外网如何可以访问到呢。
* NodePort

```
	- service配置中
		- spec.type: NodePort (关键配置)
		- spec.ports.port : 80 (配置参数，这里的端口是指这个service的端口，并非node的端口)

	kube replace -f service.yml --force
	注：该命令强制重新创建service,为什么会加--force因为很多pod的属性是没有办法修改的，比如说镜像（镜像是由docker管理的），所以需要强制重新创建。
	重新创建service后，kube会随机分配一个Node的端口作为这个spec.ports.port的端口映射。
	
	- deployment
		- 
	
```

#### pod
* pod包含一个或者多个容器
* pod的volume是pod级别的，也就是说pod中的所有容器可以共享
* pod的网络也是pod级别，也就是PodIP，pod内的所有的容器的网络是一致的，他们能够通过本地地址（localhost）访问其他容器的端口。
* pod包含的一组容器是共享的,共享Namespace包括：PID，Network,IPC, UTS
* pod中的容器可以访问共同的数据卷实现文件系统的共享，所以kube的数据卷是Pod级别的，不是容器级别的。
* 补充： Linux的Namespace隔离

Linux Namespace | 系统调用参数 | 隔离内容
----------------|------------|--------
UTS				   |CLONE_NEWUTS|主机名与域名
IPC             |CLONE_NEWIPC|信号量、消息队列和共享内存
PID					|CLONE_NEWPOD| 进程编号
Network			| CLONE_NEWNET| 网络设备、网络栈、端口等
Mount				| CLONE_NEWNS| 挂载点（文件系统）
User				| CLONE_NEWUSER | 用户和用户组


#### probe 探测机制
* liveness probe: 用于容器的自定义健康检查，如果liveness probe检查失败，kube将杀死容器，然后根据Pod的重启策略来决定是否重启容器。
* readiness probe: 用于容器的自定义准备状况检查，如果readiness probe检查失败，kube将会把pod从服务代理的分发后端溢出，即不会分发请求给该pod.

#### 事件查询
* kubectl get cs -- 获取kube的components的运行状态
* kubectl get event 
	* 获取所有时间
* kubectl describe pod my-pod
	* describe命令
* kubectl logs pod_name [容器名] [-p --previous 表示查询容器停止前的日志]
* pod的临终遗言，在容器?上的/dev/termination-log
	* 例子: kubectl get pod pod_name --template="{{range .status.containerStatuses}}{{.lastState.terminated.message}}{{end}}"

#### 远程连接容器
* kubectl attach (VS docker attach)

* kubectl exec (VS docker exec)
	* 例子：运行date命令，kubectl exec pod_name [容器名] -- date
	* 例子：直接进入容器中，kubectl exec -ti pod_name [容器名] /bin/bash

#### expose service
* NodePort
	* kind : Service 
* LoadBalancer Service 需要底层云服务商支持创建负载均衡器
	* kind : Service
* ingress
	* kind : Ingress
	* kubectl get ingress my-ingress

#### 网络
* 容器间通信
	* 在Pod中多出来的容器google_containers/pause,实际上它是kube中定义的网络容器，它不做任何事情，只是用来接管Pod的网络，业务容器通过加入网络容器的网络实现网络共享。启动容器后只会运行一个叫做pause的程序。
	* 这样的做法是为了避免产生 _业务间的容器间依赖_ 注意：业务间的
* Pod间通信
	* flannel通过etcd创建一个路由表，配置分配可用节点的IP网段
	
	```
	etcdctl ls /coreos.com/network/subnets
	
	etcdctl get /cores.com/network.subnets/10.0.62.0-24
	
	so on...
	```
	* flannel接收到分配的IP后（？flannel是分布式的？这里说的是Node上的flannel），会在Node上查询flannel虚拟网卡
		
	```
	ifconfig | grep flannel
	ip addr show flannel.1
	在上面这两条命令中的inet应该都应可以看到上述flannel在Ectd中分配的ip段对应上
	```
	* flannel会配置docker网桥 - docker0,(node上的)
	```
	ip addr show docker0
	此命令看到的inet应该也是可以跟上述说的ip端对应上。（那掩码？）
	```
	* flannel会修改路由表，使用得flannel虚拟网卡可以接管容器跨主机的通信
	```
	在node节点上分别查询：
	route -n | grep flannel 
	route -n | grep docker
	```
	
* Service到Pod的通信
	* Service的网络转发是kubernetes实现服务编排的关键一环。严重同意！
	* kube proxy - 负责实现虚拟IP路由和转发
		* 转发访问Service的虚拟IP的请求到EndPoints
		* 监控Service和EndPoint的变化，实时刷新转发规则
		* 提供负载均衡能力
		* Userspace模式与Iptables模式，前者是只创建到某端口上，转发由kube proxy程序完成；后者是kube proxy不提供转发功能，而是通过iptables规则进行转发，依赖linux的转发功能。
		* Userspace的路由规则
			* KUBE-PORTALS-CONTAINER，用于匹配容器发出的报文，绑定在NAT表PREROUTING链。
			* KUBE-PORTALS-HOST, 用于匹配日宿主机发出的报文，绑定在NAT表OUTOUT链。
			* 其中dest端口是kube proxy在监听的端口，kube proxy作为反向代理
		* iptables的路由规则
			* KUBE-SERVICES: 绑定在NAT表PREROUTING链和OUTPUT链
			* KUBE-SVC-*: 代表一个service, 绑定在KUBE-SERVICES
			* KUBE-SEP-\*: 代表Endpoints的每一个后端，绑定在KUBE-SVC-\*

#### 运维信息收集
* Daemon Set
* 以kind : DaemonSet的方式运行保证易于管理（推荐）
* cAdvisor : google开源的一个容器监控工具,监控agent,在Node级别启动
* kueblet组件已经集成了cAdvisor,在kube Node上可以直接访问cAdvisor,默认端口10255获取Node和Pod/容器的监控数据。
* Heapster : 将每个Node上的cAdvisor的数据进行汇总，（然后倒入到influxDB中作汇总，存储，分析）
* Elasticsearch + Fluent + Kibana 应用级别的日志系统，上述的是系统级别的信息

####  open vSwitch
* 略过，暂时不关心


