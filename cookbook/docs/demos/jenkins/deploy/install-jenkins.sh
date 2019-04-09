#!/bin/bash

###################### Update as per ENVIRONMENT ####################
namespace="mcm-devops-demo"
jenkins_chart="stable/jenkins"
jenkins_release_name="jenkins"
jenkins_values="jenkins-values.yaml"
###################### Update as per ENVIRONMENT ####################

separator="**********************************************************"

### Creating PVC
echo "Creating PVC..."
kubectl apply -f jenkins-pvc.yaml
echo "${separator}"

### Update as much of standard values in jenkins-values.yaml file
echo "Installing Jenkins..."
helm upgrade --namespace $namespace --install $jenkins_release_name -f $jenkins_values $jenkins_chart --tls
echo "${separator}"

### Creating Ingress
echo "Creating Ingress..."
kubectl apply -f jenkins-ingress.yaml
echo "${separator}"

echo "Done."