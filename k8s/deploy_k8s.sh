set -e
echo "Turning swap off..."
sudo swapoff -a
# sudo mount bpffs /sys/fs/bpf -t bpf
echo "Starting Kubernetes..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

echo "Setting kubeconfig..."
mkdir -p $HOME/.kube
sudo -H cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo -H chown $(id -u):$(id -g) $HOME/.kube/config

echo "Taint k8s to use same as worker..."
kubectl taint nodes --all node-role.kubernetes.io/master-
