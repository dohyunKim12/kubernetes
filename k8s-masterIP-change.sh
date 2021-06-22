#! /bin/bash

# 이전 ip, 현재 ip 설정

oldip=$(cat $HOME/.kube/config | grep '^    server:' |cut -c 21- | cut -f 1 -d :)
newip=$(ip a | grep inet | sed -n 3p | cut -b 10- | cut -f 1 -d /)


# 이전 ip가 포함된 파일들을 전부 신규 아이피로 바꾸고 확인.

cd /etc/kubernetes

find . -type f | xargs grep $oldip
find . -type f | xargs sed -i "s/$oldip/$newip/"
find . -type f | xargs grep $newip


# 혹시 모르니 인증서 백업

mkdir $HOME/k8s-old-pki
cp -Rvf /etc/kubernetes/pki/* $HOME/k8s-old-pki


# /etc/kubernetes/pki에 이전 ip를 갖는 인증서가 있는지 확인, 삭제

cd /etc/kubernetes/pki

for f in $(find -name "*.crt"); do
  openssl x509 -in $f -text -noout > $f.txt;
done

grep -Rl $oldip .

for f in $(find -name "*.crt"); do rm $f.txt; done


# kubectl에서 server값으로 사용할 신규 ip를 kbuernetes란 호스트명으로 정의

cat <<EOF | tee /etc/hosts
127.0.0.1 localhost
$newip kubernetes
EOF

sleep 5

# kube-system 내 configmap에서 이전ip를 신규ip로 수정

configmaps=$(kubectl --server=https://kubernetes:6443 -n kube-system get cm -o name | \
  awk '{print $1}' | \
  cut -d '/' -f 2)

dir=$(mktemp -d)

for cf in $configmaps; do
  kubectl --server=https://kubernetes:6443 -n kube-system get cm $cf -o yaml > $dir/$cf.yaml
done

grep -Hn $dir/* -e $oldip

cd $dir
sed -i "s/$oldip/$newip/" $dir/*

kubectl --server=https://kubernetes:6443 apply -f kubeadm-config.yaml
kubectl --server=https://kubernetes:6443 apply -f kube-proxy.yaml

#kubectl --server=https://kubernetes:6443 get cm/kubeadm-config -n kube-system -o yaml | sed -e "s/^        advertiseAddress: $oldip/        advertiseAddress: $newip/" | kubectl apply -f -

#kubectl --server=https://kubernetes:6443 get cm/kube-proxy -n kube-system -o yaml | sed -e "s/^        server: https://$oldip:6443/        server:https://$newip:6443" | kubectl apply -f -


# number 2
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
echo -e "Lastly, you have to change OLD IP($oldip) to NEW IP($newip) with this command: \n"
echo -e "kubectl edit configmap/cluster-info -n kube-public\n"
echo -e "(This might take a few minutes.)\n"
