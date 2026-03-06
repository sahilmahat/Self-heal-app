# Self-Healing Kubernetes Application with CI/CD and GitOps

A production-style DevOps project demonstrating CI/CD automation, containerized deployment, Kubernetes orchestration, and GitOps-based continuous delivery using **GitHub Actions** and **ArgoCD**.

---

# Architecture Overview

```
Developer Push
      │
      ▼
GitHub Repository
      │
      ▼
GitHub Actions (CI)
 ├─ Run Tests
 ├─ Build Docker Image
 └─ Push Image to DockerHub
      │
      ▼
GitOps Repository
      │
      ▼
ArgoCD (CD)
      │
      ▼
Kubernetes Cluster (KIND on EC2)
      │
      ▼
Self-Healing Application Deployment
```

---

# Technology Stack

| Layer | Technology |
|------|-------------|
| CI/CD | GitHub Actions |
| Containerization | Docker |
| Orchestration | Kubernetes (KIND) |
| Continuous Deployment | ArgoCD |
| Cloud Environment | AWS EC2 |
| Application | Python Flask |

---

# Project Repository Structure

```
self-heal-app/
│
├── app.py
├── Dockerfile
├── requirements.txt
├── deployment.yaml
├── service.yaml
│
└── .github/
    └── workflows/
        └── pipeline.yaml
```

---

# Step 1 — Create Kubernetes Deployment

`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: self-healing-deployment

spec:
  replicas: 3

  selector:
    matchLabels:
      app: self-heal-app

  template:
    metadata:
      labels:
        app: self-heal-app

    spec:
      containers:
      - name: self-heal-container
        image: sahilmahat/self-heal-app:latest

        ports:
        - containerPort: 5000

        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
```

Apply deployment:

```bash
kubectl apply -f deployment.yaml
```

Verify pods:

```bash
kubectl get pods
```

---

# Step 2 — Create Kubernetes Service

`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: self-healing-service

spec:
  type: NodePort

  selector:
    app: self-heal-app

  ports:
  - port: 80
    targetPort: 5000
    nodePort: 30007
```

Apply service:

```bash
kubectl apply -f service.yaml
```

Verify:

```bash
kubectl get svc
```

---

# Step 3 — Access Application (KIND Cluster)

Since KIND runs inside Docker, NodePort cannot be accessed directly.

Use **port forwarding**.

```bash
kubectl port-forward svc/self-healing-service 8080:80 --address 0.0.0.0
```

Open browser:

```
http://EC2_PUBLIC_IP:8080
```

Example:

```
http://65.0.118.29:8080
```

---

# Step 4 — Build Docker Image

Build container:

```bash
docker build -t sahilmahat/self-heal-app:latest .
```

Login to DockerHub:

```bash
docker login
```

Push image:

```bash
docker push sahilmahat/self-heal-app:latest
```

---

# Step 5 — Setup CI Pipeline (GitHub Actions)

Create file:

```
.github/workflows/pipeline.yaml
```

Pipeline configuration:

```yaml
name: self-healing-ci

on:
  push:
    branches:
      - main

jobs:
  build:

    runs-on: ubuntu-latest

    steps:

    - name: Checkout Repository
      uses: actions/checkout@v3

    - name: Login to DockerHub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKERUSER }}
        password: ${{ secrets.DOCKERPASS }}

    - name: Build Docker Image
      run: |
        docker build -t ${{ secrets.DOCKERUSER }}/self-heal-app:latest .

    - name: Push Docker Image
      run: |
        docker push ${{ secrets.DOCKERUSER }}/self-heal-app:latest
```

---

# Step 6 — Install ArgoCD

Create namespace:

```bash
kubectl create namespace argocd
```

Install ArgoCD:

```bash
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Verify installation:

```bash
kubectl get pods -n argocd
```

---

# Step 7 — Access ArgoCD UI

Run port forwarding:

```bash
kubectl port-forward svc/argocd-server -n argocd 9090:443 --address 0.0.0.0
```

Open browser:

```
https://EC2_PUBLIC_IP:9090
```

---

# Step 8 — Get ArgoCD Login Password

Retrieve admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
```

Login credentials:

```
Username: admin
Password: <generated-password>
```

---

# Step 9 — Create ArgoCD Application

`app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: self-heal-app
  namespace: argocd

spec:
  project: default

  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-manifests
    targetRevision: HEAD
    path: .

  destination:
    server: https://kubernetes.default.svc
    namespace: default

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Deploy application:

```bash
kubectl apply -f app.yaml
```

---

# Step 10 — Final CI/CD Workflow

```
Developer pushes code
        │
        ▼
GitHub Actions (CI)
 ├── Build Docker Image
 └── Push Image to DockerHub
        │
        ▼
ArgoCD watches Git repository
        │
        ▼
Automatic deployment to Kubernetes
        │
        ▼
Self-healing containerized application
```

---

# Kubernetes Self-Healing Validation

Test failure recovery:

```bash
kubectl delete pod <pod-name>
```

Kubernetes automatically recreates the pod.

Verify:

```bash
kubectl get pods
```

---

# Useful Debug Commands

Check pods:

```bash
kubectl get pods
```

View logs:

```bash
kubectl logs <pod-name>
```

Check service endpoints:

```bash
kubectl get endpoints
```

Inspect deployment:

```bash
kubectl describe deployment self-healing-deployment
```

---

# Key DevOps Concepts Demonstrated

- Continuous Integration using GitHub Actions
- Containerized microservice architecture
- Kubernetes orchestration and scaling
- GitOps-based Continuous Deployment with ArgoCD
- Automated self-healing through Kubernetes health probes
- Cloud infrastructure deployment on AWS EC2

---

# Future Improvements

Possible enhancements for production readiness:

- Helm charts for deployment management
- Docker image version tagging
- ArgoCD Image Updater
- Prometheus and Grafana monitoring
- Canary or Blue-Green deployments
- Security scanning using Trivy
- Ingress controller with TLS

---

# Outcome

This project demonstrates a **complete DevOps pipeline integrating CI, container registry, Kubernetes orchestration, and GitOps-based deployment**, closely resembling modern production infrastructure workflows.
