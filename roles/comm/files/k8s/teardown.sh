#! /bin/bash

kubeadm reset;
systemctl stop kubelet;
# 注意: 下面这条命令会干掉所有正在运行的 docker 容器，
# 如果要进行重置操作，最好先确定当前运行的所有容器都能干掉(干掉不影响业务)，
# 否则的话最好手动删除 kubeadm 创建的相关容器(gcr.io 相关的)
docker rm -f -v `docker ps -q`;
find /var/lib/kubelet | xargs -n 1 findmnt -n -t tmpfs -o TARGET -T | uniq | xargs -r umount -v;
rm -r -f /etc/kubernetes /var/lib/kubelet /var/lib/etcd;

ip link delete cni0; 
ip link delete flannel.1;

iptables -F;
iptables -X;
iptables -Z;
iptables -t nat -F;
iptables -t nat -X;
iptables -t nat -Z;