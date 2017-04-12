## docker与docker云
### 关于docker配置文件
#### Debian Jessie 8.0
* /etc/systemd/system/docker.service.d/
	* http-proxy.conf - 设置HTTP_PROXY
		* 关键字 HTTP_PROXY NO_PROXY
		* 例子： Environment="HTTP_PROXY=http://proxy.example.com:80/" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"
		* example explanation: have internal Docker registry that you need to contact without proxying

#### flush changes
* systemctl daemon-reload
	* verify that the configuration has been loaded
	* systemctl show --property=Environment docker
* systemctl restart docker

### Notice
* In Debian Jessie 8.0, it seems that the Docker configuration file (/lib/systemd/system/docker.service) is not using /etc/default/docker at all
* The problem is solved by adding an EnvironmentFile directive and modifying the command line to include the options from the file
```
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
EnvironmentFile=-/etc/default/docker
ExecStart=/usr/bin/docker -d $DOCKER_OPTS -H fd://
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
```

#### Conclusion
* 简而言之就是docker在systemd系统上运行时，是不会去读取/etc/default/docker里的配置的，而是回去读取/etc/systemd/system/docker.service.d目录下的配置文件以及/etc/systemd/system/docker.service ，还有默认的/lib/systemd/system/docker.service。
* issue link : https://github.com/halfcrazy/halfcrazy.github.io/issues/4

* 最后记得

```
systemctl daemon-reload
service docker restart
```


#### rabc
* kubectl logs xx
* prompt: the server does not allow access to the requested resource
* In case anyone else is wondering what this means, it looks like you need to create kube-flannel-rbac.yml before you create flannel:

```
kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml
kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
* refereren: https://github.com/kubernetes/kubeadm/issues/212#issuecomment-290908868

* I successfully setup my Kubernetes cluster on centos-release-7-3.1611.el7.centos.x86_64 by taking the following steps (I assume Docker is already installed):

1. (from /etc/yum.repo.d/kubernetes.repo) baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64-unstable
=> To use the unstable repository for the latest Kubernetes 1.6.1
2. yum install -y kubelet kubeadm kubectl kubernetes-cni
3. (/etc/systemd/system/kubelet.service.d/10-kubeadm.conf) add "--cgroup-driver=systemd" at the end of the last line.
=> This is because Docker uses systemd for cgroup-driver while kubelet uses cgroupfs for cgroup-driver.
4. systemctl enable kubelet && systemctl start kubelet
5. kubeadm init --pod-network-cidr 10.244.0.0/16
=> If you used to add --api-advertise-addresses, you need to use --apiserver-advertise-address instead.
6. cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
=> Without this step, you might get an error with kubectl get
=> I didn't do it with 1.5.2
7. kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml
=> 1.6.0 introduces a role-based access control so you should add a ClusterRole and a ClusterRoleBinding before creating a Flannel daemonset
8. kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
=> Create a Flannel daemonset
9. (on every slave node) kubeadm join --token (your token) (ip):(port)
=> as shown in the result of kubeadm init

All the above steps are a result of combining suggestions from various issues around Kubernetes-1.6.0, especially kubeadm.

Hope this will save your time.

### 整理一下以上所说：
### 初始化流程
#### master
* kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address 192.168.31.199
* sudo cp /etc/kubernetes/admin.conf $HOME/
* sudo chown $(id -u):$(id -g) $HOME/admin.conf
* export KUBECONFIG=$HOME/admin.conf
* kubectl create -f kube-flannel-rbac.yml
* kubectl create --namespace kube-system -f kube-flannel.yml
#### slaves
* kubeadm join --token cb4903.7649667498cd20f8 192.168.31.199:6443

#### common
* sh /home/pirate/mk\_docer_opt.sh -c -d /etc/default/docker
	* something remind : MD:docker与docker云-关于docker配置文件
* systemctl daemon-reload
* systemctl restart docker
