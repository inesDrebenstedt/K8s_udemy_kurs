cat <<EOF > k8s-lab02.sh
#!/bin/bash

echo "-----> 1. Download files"
git clone -b main https://github.com/asokone/Kube_Fundamentals.git
read -p "Hit ENTER for next step."

echo "-----> 1. go to yaml"
cd Kube_Fundamentals/pods/lab02
read -p "Hit ENTER for next step."

echo "-----> 2. ls"
ls
read -p "Hit ENTER for next step."

echo "-----> 3. Check current pod setup:"
kubectl get pods
read -p "Hit ENTER for next step."

echo "-----> 4. Create pod"
kubectl create -f mypod-02.yaml ; echo -— ; kubectl get pod
read -p "Hit ENTER for next step."

echo "-----> 5. Check current pod setup:"
kubectl get pods
read -p "Hit ENTER for next step."

echo "-----> 6. in order to view the message, we need to use the kubectl logs command:"
kubectl logs mypod-02
read -p "Hit ENTER for next step."

echo "-----> 7. Delete pod:"
kubectl delete -f mypod-02.yaml
read -p "Hit ENTER for next step."

EOF