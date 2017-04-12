## purpose
* for raspberry pi cluster init system env init

## technology selection
* assemble


## process Log

### passwd
* sudo passwd 1q2w3e

### git
* 
###apt-get 国内源
* 见git中source.list
### X11,chrome on rasp
* https://github.com/hypriot/x11-on-HypriotOS

### strace
* apt-get install strace

### zsh
* https://blog.phpgao.com/oh-my-zsh.html
### vim
* 

### shadowsocks
* https://github.com/shadowsocks/shadowsocks/wiki/Shadowsocks-使用说明

### proxychains
* https://github.com/shadowsocks/shadowsocks/wiki/Using-Shadowsocks-with-Command-Line-Tools

### k8s 
* mirrors.aliyun.com 还不行！！
* 手动下载安装
* apt-get install ebtables socat
* dkpg -i ku*

## 获取token
kubectl -n kube-system get secret clusterinfo -o yaml | grep token-map | awk '{print $2}' | base64 --decode | sed "s|{||g;s|}||g;s|:|.|g;s/\"//g;" | xargs echo
***
### 初始化流程
#### master
* kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address 192.168.31.199
* sudo cp /etc/kubernetes/admin.conf $HOME/
* sudo chown $(id -u):$(id -g) $HOME/admin.conf
* export KUBECONFIG=$HOME/admin.conf
* kubectl create -f kube-flannel-rbac.yml
* kubectl create --namespace kube-system -f kube-flannel.yml
#### slaves
* kubeadm join --token 78db77.56e0689fb0170bb8 192.168.31.199:6443

#### common
* sh /home/pirate/mk\_docer_opt.sh -c -d /etc/default/docker
	* something remind : MD:docker与docker云-关于docker配置文件
* systemctl daemon-reload
* systemctl restart docker

```
ansible script
tasks:
  - name: generate docker opt
    shell: sh /home/pirate/mk_docer_opt.sh -c -d /etc/default/docker

  - name: flush docker daemon configuration change
    shell: systemctl daemon-reload

  - name: restart dockerd
    shell: systemctl restart docker
```


```
/etc sudo kubeadm init --pod-network-cidr  10.244.0.0/16 --api-advertise-addresses=192.168.31.199
<master/tokens> generated token: "366b43.1ccaf609e72593d9"
<master/pki> created keys and certificates in "/etc/kubernetes/pki"
<util/kubeconfig> created "/etc/kubernetes/kubelet.conf"
<util/kubeconfig> created "/etc/kubernetes/admin.conf"
<master/apiclient> created API client configuration
<master/apiclient> created API client, waiting for the control plane to become ready

```

### kubeadm 果然卡住……

### 自建docker registry
* https://www.slahser.com/2016/09/29/pi-cluster%E4%B8%8A%E9%85%8D%E5%A5%97Registry/

