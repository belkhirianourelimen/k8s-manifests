# WellnessHub — Manifests Kubernetes

Infrastructure Kubernetes pour le déploiement de l'application WellnessHub.
PFE 2024/2025 — ESPRIT × AuroraIQ

## Architecture

```
Namespace : wellnesshub
Cluster   : Minikube v1.38.1 (local) / AuroraIQ K8s (production)

Services déployés :
  - PostgreSQL 15        (ClusterIP :5432)
  - Eureka Server        (ClusterIP :8761)
  - AdminMS              (ClusterIP :8763)
  - ExpertMS             (ClusterIP :8764)
  - EntrepriseX          (ClusterIP :8765)
  - EntrepriseY          (ClusterIP :8766)
  - API Gateway          (NodePort  :30762)
  - Frontend prod        (NodePort  :30080)
```

## Prérequis

- Minikube v1.38.1+
- kubectl v1.36.0+
- Docker 29+
- Registry Docker locale sur 192.168.49.1:5000

## Configuration

### 1. Créer le fichier secret.yaml

```bash
cp secret.yaml.example secret.yaml
# Editer secret.yaml avec tes vraies valeurs
nano secret.yaml
```

> ⚠️ Ne jamais commiter `secret.yaml` sur GitHub !

### 2. Configurer le secret Docker Hub (frontend privé)

```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=TON_USERNAME \
  --docker-password=TON_TOKEN \
  --docker-email=TON_EMAIL \
  -n wellnesshub
```

### 3. Charger les images dans Minikube

```bash
minikube image load 192.168.49.1:5000/wellness-eureka:latest
minikube image load 192.168.49.1:5000/wellness-adminms:latest
minikube image load 192.168.49.1:5000/wellness-expertms:latest
minikube image load 192.168.49.1:5000/wellness-entreprisex:latest
minikube image load 192.168.49.1:5000/wellness-entreprisey:latest
minikube image load 192.168.49.1:5000/wellness-gateway:latest
```

## Déploiement

### Set minimal (5 services — 3GB RAM Minikube)
```bash
bash deploy-minimal.sh
```

### Set complet (7 services — 6GB RAM Minikube minimum)
```bash
# Recréer Minikube avec plus de RAM
minikube delete
minikube start --driver=docker --cpus=3 --memory=6144 \
  --insecure-registry="192.168.49.1:5000"
minikube addons enable ingress

bash deploy-all.sh
```

## Accès

Ajouter dans `/etc/hosts` de ta machine :
```
192.168.49.2  wellnesshub.local
```

| Service   | URL                              |
|-----------|----------------------------------|
| Frontend  | http://100.122.204.32:30080      |
| Gateway   | http://100.122.204.32:30762      |
| Eureka    | http://100.122.204.32:9761       |
| Ingress   | http://wellnesshub.local         |

## Structure des fichiers

```
k8s/
├── .gitignore
├── README.md
├── secret.yaml.example     ← template (commiter)
├── secret.yaml             ← valeurs réelles (NE PAS commiter)
├── namespace.yaml
├── configmap.yaml
├── postgres-*.yaml         (4 fichiers)
├── eureka-*.yaml           (2 fichiers)
├── adminms-*.yaml          (2 fichiers)
├── expertms-*.yaml         (2 fichiers)
├── entreprisex-*.yaml      (2 fichiers)
├── entreprisey-*.yaml      (2 fichiers)
├── gateway-*.yaml          (2 fichiers)
├── frontend-*.yaml         (2 fichiers)
├── ingress.yaml
├── deploy-minimal.sh
└── deploy-all.sh
```
