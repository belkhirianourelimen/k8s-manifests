# WellnessHub — Kubernetes Manifests

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat&logo=jenkins&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=flat&logo=spring-boot&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![React](https://img.shields.io/badge/React-20232A?style=flat&logo=react&logoColor=61DAFB)

> Infrastructure Kubernetes pour le déploiement de l'application **WellnessHub** — plateforme de bien-être au travail (workplace wellness).

---

## Contexte du projet

**Projet de Fin d'Études (PFE) — ESPRIT 2024/2025**

Dans le cadre d'un stage chez **AuroraIQ** pour le compte de **WellnessHub**, ce dépôt contient l'ensemble des manifests Kubernetes permettant de déployer l'application WellnessHub sur un cluster local (Minikube) dans le cadre d'une architecture **DevOps hybride** — avant migration vers AWS.

| Champ | Valeur |
|-------|--------|
| Projet | Mise en place d'une Infrastructure Cloud AWS et DevOps Hybride |
| Etudiante | Nour El Imen Belkhiria — ESPRIT, 5ème année Cloud & DevOps |
| Entreprise | WellnessHub × AuroraIQ |
| Stack applicative | Spring Boot (microservices) + React/Next.js (frontend) |
| Cluster cible | Minikube v1.38.1 (local) / AuroraIQ Kubernetes (production) |

---

## Architecture

```
Namespace : wellnesshub
┌─────────────────────────────────────────────────────────────┐
│                    Cluster Minikube                          │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Ingress    │    │   Gateway    │    │   Frontend   │  │
│  │  Nginx :80   │───>│  :8762       │    │  :30080      │  │
│  └──────────────┘    └──────┬───────┘    └──────────────┘  │
│                             │                                │
│              ┌──────────────┼──────────────┐                │
│              ▼              ▼              ▼                │
│       ┌──────────┐  ┌──────────┐  ┌──────────────┐        │
│       │ AdminMS  │  │ ExpertMS │  │ EntrepriseX  │        │
│       │  :8763   │  │  :8764   │  │    :8765     │        │
│       └──────────┘  └──────────┘  └──────────────┘        │
│                                    ┌──────────────┐        │
│                                    │ EntrepriseY  │        │
│                                    │    :8766     │        │
│                                    └──────────────┘        │
│                                                              │
│  ┌──────────────┐    ┌──────────────────────────────────┐  │
│  │    Eureka    │    │           PostgreSQL              │  │
│  │    :8761     │    │  WellnessHubAdmin | Hubbase       │  │
│  └──────────────┘    │  EntrepriseXdb   | EntrepriseYdb  │  │
│                       └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Services déployés

| Service | Image | Type | Port |
|---------|-------|------|------|
| PostgreSQL | `postgres:15-alpine` | ClusterIP | 5432 |
| Eureka Server | `wellness-eureka:latest` | ClusterIP | 8761 |
| AdminMS | `wellness-adminms:latest` | ClusterIP | 8763 |
| ExpertMS | `wellness-expertms:latest` | ClusterIP | 8764 |
| EntrepriseX | `wellness-entreprisex:latest` | ClusterIP | 8765 |
| EntrepriseY | `wellness-entreprisey:latest` | ClusterIP | 8766 |
| API Gateway | `wellness-gateway:latest` | NodePort | 8762 / 30762 |
| Frontend | `wellness-front-prod:latest` | NodePort | 80 / 30080 |

---

## Pipeline CI/CD

Ce dépôt s'intègre dans une chaîne CI/CD complète avec **2 pipelines Jenkins** :

```
Push GitHub
    │
    ▼
Pipeline Backend (wellnesshub-backend-pipeline)
    ├── Clone repo
    ├── Détection des changements (git diff)
    ├── Build Docker images (conditionnel par service)
    ├── Push vers registry locale (192.168.49.1:5000)
    ├── Deploy via Docker Compose
    ├── Initialisation databases PostgreSQL
    └── ✅ Succès → déclenche automatiquement ↓
    │
    ▼
Pipeline K8s (wellnesshub-k8s-pipeline)
    ├── Verify cluster Minikube
    ├── kubectl rollout restart deployments
    ├── Wait for rollout status
    ├── Verify pods Running
    └── Email notification (succès/échec)
```

---

## Prérequis

- [Minikube](https://minikube.sigs.k8s.io/) v1.38.1+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.36.0+
- [Docker](https://www.docker.com/) 29+
- Registry Docker locale sur `192.168.49.1:5000`
- Images backend buildées via Jenkins

---

## Installation

### 1. Démarrer le cluster Minikube

```bash
# Set minimal (5 services) — 3GB RAM
minikube start --driver=docker --cpus=2 --memory=3072 \
  --insecure-registry="192.168.49.1:5000"

# Set complet (7 services) — 6GB RAM minimum
minikube start --driver=docker --cpus=3 --memory=6144 \
  --insecure-registry="192.168.49.1:5000"

# Activer l'addon Ingress
minikube addons enable ingress
```

### 2. Configurer les secrets

```bash
# Copier le template et remplir avec vos valeurs
cp secret.yaml.example secret.yaml
nano secret.yaml
```

> ⚠️ **Ne jamais commiter `secret.yaml` sur GitHub !** Il est exclu via `.gitignore`.

### 3. Créer le secret Docker Hub (pour le frontend privé)

```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=VOTRE_USERNAME \
  --docker-password=VOTRE_ACCESS_TOKEN \
  --docker-email=VOTRE_EMAIL \
  -n wellnesshub
```

### 4. Charger les images backend dans Minikube

```bash
# Les images doivent être présentes dans la registry locale
minikube image load 192.168.49.1:5000/wellness-eureka:latest
minikube image load 192.168.49.1:5000/wellness-adminms:latest
minikube image load 192.168.49.1:5000/wellness-expertms:latest
minikube image load 192.168.49.1:5000/wellness-entreprisex:latest
minikube image load 192.168.49.1:5000/wellness-entreprisey:latest
minikube image load 192.168.49.1:5000/wellness-gateway:latest
```

### 5. Configurer le VITE_API_URL

Dans `configmap.yaml`, remplacer `YOUR_VM_IP` par l'IP de votre VM :

```yaml
VITE_API_URL: "http://YOUR_VM_IP:8762/api"
```

---

## Déploiement

### Set minimal — 5 services (3GB RAM)

Déploie : PostgreSQL + Eureka + ExpertMS + Gateway + Frontend

```bash
bash deploy-minimal.sh
```

### Set complet — 7 services (6GB RAM minimum)

Déploie tous les microservices :

```bash
bash deploy-all.sh
```

### Vérifier le déploiement

```bash
# Etat des pods
kubectl get pods -n wellnesshub

# Etat des services
kubectl get svc -n wellnesshub

# Logs d'un pod
kubectl logs -l app=expertms -n wellnesshub --tail 50

# Etat de l'ingress
kubectl get ingress -n wellnesshub
```

---

## Accès aux services

Ajouter dans `/etc/hosts` de votre machine :

```
192.168.49.2  wellnesshub.local
```

| Service | URL directe | URL Ingress |
|---------|-------------|-------------|
| Frontend | `http://VM_IP:30080` | `http://wellnesshub.local` |
| API Gateway | `http://VM_IP:30762` | `http://wellnesshub.local/api` |
| Eureka | `http://VM_IP:9761` (port-forward) | `http://wellnesshub.local/eureka` |

> Port-forward pour accès externe :
> ```bash
> kubectl port-forward svc/frontend-service 30080:80 -n wellnesshub --address 0.0.0.0 &
> kubectl port-forward svc/gateway-service 30762:8762 -n wellnesshub --address 0.0.0.0 &
> kubectl port-forward svc/eureka-service 9761:8761 -n wellnesshub --address 0.0.0.0 &
> ```

---

## Structure des fichiers

```
k8s-manifests/
├── .gitignore
├── README.md
├── secret.yaml.example          ← template (à commiter)
│
├── namespace.yaml               ← Namespace : wellnesshub
├── configmap.yaml               ← Variables de configuration
│
├── postgres-pvc.yaml            ← PersistentVolumeClaim 5GB
├── postgres-deployment.yaml     ← PostgreSQL 15-alpine
├── postgres-service.yaml        ← ClusterIP :5432
├── postgres-init-job.yaml       ← Job : création des 4 databases
│
├── eureka-deployment.yaml       ← Service Discovery
├── eureka-service.yaml          ← ClusterIP :8761
│
├── adminms-deployment.yaml      ← Microservice Admin
├── adminms-service.yaml         ← ClusterIP :8763
│
├── expertms-deployment.yaml     ← Microservice Expert
├── expertms-service.yaml        ← ClusterIP :8764
│
├── entreprisex-deployment.yaml  ← Microservice EntrepriseX
├── entreprisex-service.yaml     ← ClusterIP :8765
│
├── entreprisey-deployment.yaml  ← Microservice EntrepriseY
├── entreprisey-service.yaml     ← ClusterIP :8766
│
├── gateway-deployment.yaml      ← API Gateway (NodePort :30762)
├── gateway-service.yaml
│
├── frontend-deployment.yaml     ← Frontend React/Next.js prod
├── frontend-service.yaml        ← NodePort :30080
│
├── ingress.yaml                 ← Nginx Ingress → wellnesshub.local
│
├── deploy-minimal.sh            ← Déploiement 5 services (3GB RAM)
└── deploy-all.sh                ← Déploiement complet (6GB RAM)
```

---

## Choix techniques clés

| Décision | Justification |
|----------|---------------|
| `imagePullPolicy: Never` (backend) | Images chargées localement via `minikube image load` depuis la registry privée |
| `imagePullPolicy: Always` (frontend) | Pull automatique depuis Docker Hub à chaque redémarrage |
| `readinessProbe: tcpSocket` | Spring Security bloque `/actuator/health` (403) — tcpSocket valide l'ouverture du port sans authentification |
| `Job` pour init databases | Exécution unique idempotente — un `initContainer` se relancerait à chaque redémarrage de pod |
| `Namespace: wellnesshub` | Isolation complète des ressources de l'application |
| `Secret K8s` pour credentials | Données sensibles chiffrées, jamais en clair dans les manifests |
| `ConfigMap` pour config | Séparation configuration / secrets selon les bonnes pratiques 12-factor |

---

## Problèmes résolus

| Problème | Cause | Solution |
|----------|-------|----------|
| `ErrImageNeverPull` | Daemon Docker interne Minikube isolé du Docker de la VM | `minikube image load` |
| `CrashLoopBackOff` | Variables d'env absentes des manifests (présentes dans .env Docker) | Ajout explicite dans `env:` des deployments |
| `ReadinessProbe 403` | Spring Security bloque `/actuator/health` | `httpGet` → `tcpSocket` |
| Cluster saturé (timeout TLS) | 9 services Spring Boot = ~4GB RAM > 3GB alloués | Set minimal 5 services |
| Gateway bloqué en `Init:1/2` | `wait-for-adminms` (service non déployé dans le set minimal) | `wait-for-expertms` |

---

## Licence

Projet académique — PFE ESPRIT 2024/2025. Non destiné à un usage en production tel quel.

---

*Nour El Imen Belkhiria — ESPRIT × AuroraIQ × WellnessHub — 2025*
