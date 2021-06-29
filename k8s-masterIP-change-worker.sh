#! /bin/bash

echo -n "Enter Master's NEW IP: "
read newip


sed -i "s/    server: https:.*/    server: https:\/\/$newip:6443/" /etc/kubernetes/kubelet.conf
sed -i "s/    server: https:.*/    server: https:\/\/$newip:6443/" /etc/kubernetes/bootstrap-kubelet.conf

systemctl restart kubelet

echo -e "\n\nDONE! Now Run 'kubectl get nodes' in Control-Plane\n"
