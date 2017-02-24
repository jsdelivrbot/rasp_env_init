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

### kubeadm init
* kubeadm init --pod-network-cidr  10.244.0.0/16 --api-advertise-addresses=192.168.31.199
* kubeadm join --token=082791.e2d2af8e051945b9 192.168.31.199

```
215d33.4eb87bcf725a837a


```

### kubeadm 果然卡住……

### 自建docker registry
* https://www.slahser.com/2016/09/29/pi-cluster%E4%B8%8A%E9%85%8D%E5%A5%97Registry/


# 2017.2.24
### docker pull还是卡住
* 解决方案： http://dockone.io/question/281

