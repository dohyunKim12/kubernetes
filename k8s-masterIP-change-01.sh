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


# kube-system 내 configmap에서 이전ip를 신규ip로 수정

configmaps=$(kubectl --server=https://kubernetes:6443 -n kube-system get cm -o name | \
  awk '{print $1}' | \
  cut -d '/' -f 2)

dir=$(mktemp -d)

for cf in $configmaps; do
  kubectl --server=https://kubernetes:6443 -n kube-system get cm $cf -o yaml > $dir/$cf.yaml
done

grep -Hn $dir/* -e $oldip


echo -e "\n\n\n******** Now, Find old ip: $oldip and Updte to new ip: $newip ********\n"
echo "kubectl --server=https://kubernetes:6443 -n kube-system edit cm kubeadm-config"
echo -e "kubectl --server=https://kubernetes:6443 -n kube-system edit cm kube-proxy\n"

echo -e "And then, RUN k8s-masterIP-change-02.sh\n"

