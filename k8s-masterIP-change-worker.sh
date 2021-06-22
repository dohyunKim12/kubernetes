#! /bin/bash

echo -n "Enter Master's OLD IP: "
read oldip
echo -n "Enter Master's NEW IP: "
read newip


sed -i "s/    server: https:\/\/$oldip:6443/    server: https:\/\/$newip:6443/" /etc/kubernetes/kubelet.conf
sed -i "s/    server: https:\/\/$oldip:6443/    server: https:\/\/$newip:6443/" /etc/kubernetes/bootstrap-kubelet.conf

systemctl restart kubelet

echo -e "\n\nDONE! Now Run 'kubectl get nodes' in Control-Plane\n"
