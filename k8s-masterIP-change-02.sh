#! /bin/bash

newip=$(ip a | grep inet | sed -n 3p | cut -b 10- | cut -f 1 -d /)

cd /etc/kubernetes/pki

rm apiserver.crt apiserver.key
rm etcd/peer.crt etcd/peer.key
rm etcd/server.crt etcd/server.key


kubeadm init phase certs apiserver
kubeadm init phase certs etcd-peer
kubeadm init phase certs etcd-server

sudo systemctl restart kubelet
sudo systemctl restart docker

sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config

echo -e "\n\n\n******** You can now Use K8S from IPADDR: $newip ********"
echo -e "Lastly, you have to change old ip to new ip with this command: \n"
echo -e "kubectl edit configmap/cluster-info -n kube-public\n"
echo -e "(This might take a few minutes.)\n"

