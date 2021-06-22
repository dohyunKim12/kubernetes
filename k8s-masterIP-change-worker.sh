#! /bin/bash

echo -e "Enter Master's old ip: "
read oldip
echo -e "Enter Master's new ip: "
read newip


sed -i "s/    server: https:\/\/$oldip:6443/    server: https:\/\/$newip:6443/" /etc/kubernetes/kubelet.conf
sed -i "s/    server: https:\/\/$oldip:6443/    server: https:\/\/$newip:6443/" /etc/kubernetes/bootstrap-kubelet.conf

systemctl restart kubelet
