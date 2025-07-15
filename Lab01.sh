cat <<EOF > k8s-lab01.sh
#!/bin/bash

echo "1. Check current node setup:"
kubectl get nodes
read -p "Hit ENTER for next step."

echo "2. Check current pod setup:"
kubectl get pod 
read -p "Hit ENTER for next step."

echo "3. Check current namespace setup:"
kubectl get ns
read -p "Hit ENTER for next step."

echo "4. Get pods in ns kube-system:"
kubectl get pod --namespace=kube-system
read -p "Hit ENTER for next step."

echo "5. Check current services setup:"
kubectl get services
read -p "Hit ENTER for next step."

echo "6. Check current pods setup in detail:"
kubectl get pods --all-namespaces -o wide
read -p "Hit ENTER for next step."

EOF