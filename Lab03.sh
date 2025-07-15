 cat <<EOF > k8s-lab03.sh
#!/bin/bash
 echo "-----> 1. Download files"
 git clone -b main https://github.com/asokone/Kube_Fundamentals.git read -p "Hit ENTER for next step." 
  echo "-----> 1. cd to yaml"
 cd Kube_Fundamentals/pods/lab03 read -p "Hit ENTER for next step." 
  echo "-----> 1. Create pod"
 kubectl create -f mypod-03.yaml ; kubectl get pods read -p "Hit ENTER for next step." 
  echo "-----> 1. Describe pod ns"
 kubectl describe pod mypod-03 | grep -i namespace read -p "Hit ENTER for next step." 
  echo "-----> 1. Describe pod"
 kubectl describe pod mypod-03 read -p "Hit ENTER for next step." 
  echo "-----> 1. Describe pods in detail"
 kubectl get pods -o wide read -p "Hit ENTER for next step." 
  echo "-----> 1. Curl the pod at port 80"
 curl <pod_IP>:80/ read -p "Hit ENTER for next step." 
  echo "-----> 1. Delete pod"
 kubectl delete -f mypod-03.yaml read -p "Hit ENTER for next step." 
  echo "-----> 1. Deleted pod is not listed anymore:"
 kubectl get pods -o wide
 
 EOF