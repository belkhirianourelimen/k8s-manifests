#!/bin/bash
set -e

DOCKERHUB_USER="blknourelimen"
DOCKERHUB_PASSWORD="REMPLACE_PAR_TON_TOKEN"
DOCKERHUB_EMAIL="REMPLACE_PAR_TON_EMAIL"

echo "Deploying WellnessHub (ALL 7 services) to Kubernetes..."
echo "WARNING: Requires at least 6GB RAM allocated to Minikube!"

kubectl apply -f namespace.yaml
echo "Namespace created"

kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=$DOCKERHUB_USER \
  --docker-password=$DOCKERHUB_PASSWORD \
  --docker-email=$DOCKERHUB_EMAIL \
  -n wellnesshub \
  --dry-run=client -o yaml | kubectl apply -f -
echo "Docker Hub secret created"

kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
echo "Secret & ConfigMap applied"

kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
echo "PostgreSQL deployed"

echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n wellnesshub --timeout=120s

kubectl apply -f postgres-init-job.yaml
echo "Waiting for database initialization..."
kubectl wait --for=condition=complete job/postgres-init -n wellnesshub --timeout=120s
echo "Databases initialized"

kubectl apply -f eureka-deployment.yaml
kubectl apply -f eureka-service.yaml
echo "Eureka deployed"

echo "Waiting for Eureka..."
kubectl wait --for=condition=ready pod -l app=eureka -n wellnesshub --timeout=180s

kubectl apply -f adminms-deployment.yaml
kubectl apply -f adminms-service.yaml
echo "AdminMS deployed"

kubectl apply -f expertms-deployment.yaml
kubectl apply -f expertms-service.yaml
echo "ExpertMS deployed"

kubectl apply -f entreprisex-deployment.yaml
kubectl apply -f entreprisex-service.yaml
echo "EntrepriseX deployed"

kubectl apply -f entreprisey-deployment.yaml
kubectl apply -f entreprisey-service.yaml
echo "EntrepriseY deployed"

kubectl apply -f gateway-deployment.yaml
kubectl apply -f gateway-service.yaml
echo "API Gateway deployed"

kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
echo "Frontend deployed"

kubectl apply -f ingress.yaml
echo "Ingress configured"

echo ""
echo "WellnessHub ALL services deployed on Kubernetes!"
echo ""
kubectl get pods -n wellnesshub
echo ""
kubectl get svc -n wellnesshub
