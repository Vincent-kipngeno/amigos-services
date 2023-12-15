#!/bin/bash

# run in the terminal using command: $ bash deploy.sh

# Step 1: Start Minikube
minikube start

# Step 2: Set the Docker environment for Minikube
eval $(minikube docker-env)

# Step 3: Build Docker Images for Microservices
# microservices=("microservice1" "microservice2" "microservice3")

# for service in "${microservices[@]}"
# do
#  echo "Building Docker image for $service"
#  cd $service
#  mvn clean install
#  docker build -t $service .
#  cd ..
# done

mvn clean install -Pbuild-docker-image

# Step 4: Apply Kubernetes Configurations for Microservices
microservices=("customer" "fraud" "notification")

for service in "${microservices[@]}"
do
  echo "Applying Kubernetes configurations for $service"
  kubectl apply -f k8s/minikube/services/${service}/deployment.yml
  kubectl apply -f k8s/minikube/services/${service}/service.yml
done

# Step 5: Apply Bootstrap Configurations
bootstrap_services=("zipkin" "postgres" "rabbitmq")
bootstrap_files=("configmap" "service" "statefulset" "volume" "rbac")

for service in "${bootstrap_services[@]}"
do
  echo "Applying Kubernetes configurations for $service"
  for cs_file in "${bootstrap_files[@]}"
  do
    config_file="k8s/minikube/bootstrap/${service}/${cs_file}.yml"

    # Check if the file exists before applying
    if [ -e "$config_file" ]; then
      kubectl apply -f "$config_file"
    else
      echo "Warning: Configuration file $config_file does not exist. Skipping..."
    fi
  done
done

# Step 6: Verify Deployments
kubectl get pods
kubectl get services

kubectl exec -it postgres-0 -- psql -U vincent

minikube service customer --url