# Two-Tier Application (Flask + MySQL)

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://img.shields.io)
[![Docker](https://img.shields.io/badge/Docker-Automated-2496ED?logo=docker)](https://img.shields.io)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Manifests-326CE5?logo=kubernetes)](https://img.shields.io)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=githubactions)](https://img.shields.io)
[![Security](https://img.shields.io/badge/DevSecOps-Trivy%20%7C%20Bandit%20%7C%20Gitleaks-red)](https://img.shields.io)

A two-tier Todo app built with Flask and MySQL. Started as a Docker practice project, now covers the full path from a raw Dockerfile through Kubernetes manifests and a DevSecOps CI/CD pipeline.

> **Goal:** Learn containerisation and orchestration by building everything yourself rather than running ready-made configs.

---

## Application Overview

A simple Todo List — add tasks, mark them complete, delete them. All data persists in MySQL.

```
Client (Browser)
      ↓
Flask App (Backend + Gunicorn)  ← 5 replicas in K8s
      ↓
MySQL 8.0 Database
```

---

## Project Structure

```
two-tier-app/
├── app.py                          # Flask application
├── requirements.txt                # Python dependencies
├── schema.sql                      # MySQL schema (auto-loaded on first run)
├── templates/
│   └── index.html                  # Jinja2 frontend
│
├── dockerfile                      # Single-stage build (python:3.12-slim)
├── docker-multi-stage-build        # Multi-stage build → distroless final image
├── docker-compose.yml              # Local orchestration: Flask + MySQL
├── .env.example                    # Environment variable reference
│
├── k8s/
│   ├── namespace.yml               # Isolates resources under two-tier-ns
│   ├── two-tier-deployment.yml     # Flask app — 5 replicas
│   └── services.yml                # ClusterIP service exposing port 8000
│
├── .github/workflows/
│   ├── DevSecOps-pipeline.yml      # Orchestrates all jobs end-to-end
│   ├── code-quality.yml            # Flake8 + Bandit
│   ├── secrets-scan.yml            # Gitleaks
│   ├── dependencies-scan.yml       # pip-audit
│   ├── dockerfile-scan.yml         # Hadolint
│   ├── docker-build-push.yml       # Build + push to Docker Hub
│   ├── image-scan.yml              # Trivy image scan
│   └── deploy-to-prod-server.yml   # SSH deploy via Docker Compose
│
├── Jenkinsfile                     # Alternative Jenkins pipeline
├── backup.sh                       # DB backup script
└── README.md
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | HTML (Jinja2 Templates) |
| Backend | Python 3.12 + Flask |
| WSGI Server | Gunicorn |
| Database | MySQL 8.0 |
| Containerization | Docker |
| Local Orchestration | Docker Compose |
| Production Orchestration | Kubernetes |
| CI/CD | GitHub Actions |
| Security Scanning | Trivy, Bandit, Gitleaks, Hadolint, pip-audit |

---

## Docker Setup

### Base Image Choice

The app uses **`python:3.12-slim`** as the base image.

Why `slim` over the full `python:3.12`?

- Full Python image is ~900 MB — ships with compilers and build tools you don't need at runtime.
- `slim` cuts that to ~130 MB. Still Debian-based, so `apt-get` works when you need it.
- `alpine` (~50 MB) uses `musl libc` instead of `glibc`, which causes subtle issues with C-extension packages like `mysql-connector`. Not worth debugging for this stack.

### Dockerfile (Single-Stage)

```dockerfile
# Base image: Python 3.12 on Debian slim
FROM python:3.12-slim

# Patch system packages before anything else (covers known CVEs in the base)
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Set working directory inside the container
WORKDIR /app

# Copy source code
COPY . .

# Install Python dependencies — no cache means smaller image layer
RUN pip install --no-cache-dir -r requirements.txt

# Flask/Gunicorn listens on 5000
EXPOSE 5000

# Gunicorn, not the Flask dev server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

**Why Gunicorn instead of `python app.py`?**  
Flask's built-in dev server is single-threaded and not safe for concurrent traffic. Gunicorn handles that and is what you'd actually run in a real deployment.

**Why `--no-cache-dir`?**  
Pip caches downloaded packages assuming you might reinstall. Inside a container image you never will, so it's just dead weight. Drop it.

**Why `apt-get upgrade` first?**  
Base images ship with packages that may have known CVEs. Upgrading at build time patches those before your app layers go on top. The `rm -rf /var/lib/apt/lists/*` clears the apt cache so it doesn't bloat the layer.

### Build and Run

```bash
# Build
docker build -t flask-app:latest .

# Run standalone (needs MySQL running separately)
docker run -d \
  -p 5000:5000 \
  -e MYSQL_HOST=<your-mysql-host> \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=admin \
  -e MYSQL_DB=mydb \
  flask-app:latest
```

### Multi-Stage Dockerfile

Installs dependencies in a builder stage, then copies only what's needed into a **distroless** final image.

```dockerfile
# Stage 1: Install dependencies
FROM python:3.11-slim AS builder
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt --target=/app/deps

# Stage 2: Runtime only — no shell, no package manager
FROM gcr.io/distroless/python3-debian12
WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY app.py .
COPY templates/ ./templates/
EXPOSE 5000
ENV PYTHONPATH=/app/deps
CMD ["python", "app.py"]
```

**What is distroless?**  
Google's distroless images contain only the runtime (Python interpreter here) and nothing else. No bash, no apt, no utilities. The attack surface is minimal because there's nothing extra to exploit. Tradeoff: you can't `docker exec` into a shell for debugging. Use it for production images, not development.

| Image | Approx Size | Shell | When to use |
|---|---|---|---|
| `python:3.12` | ~900 MB | Yes | Quick prototyping |
| `python:3.12-slim` | ~130 MB | Yes | Most deployments |
| `distroless/python3` | ~55 MB | No | Production, security-sensitive |

```bash
# Build the multi-stage image
docker build -f docker-multi-stage-build -t flask-app:distroless .
```

### .dockerignore

Keep junk out of the build context:

```
__pycache__/
*.pyc
*.pyo
.env
.git
*.md
```

Without this, Docker sends your entire git history and local `.env` file to the build daemon on every build.

---

## Docker Compose (Local)

Compose wires the two containers together — shared network, dependency ordering, and persistent volumes.


Key things to understand:

- `MYSQL_HOST: mysql` — containers on the same Docker network reach each other by name. No static IPs.
- `condition: service_healthy` — plain `depends_on` only waits for the container to start. MySQL takes 20-30 seconds to actually accept connections. The healthcheck covers that gap.
- `schema.sql` in `/docker-entrypoint-initdb.d/` — MySQL's official image auto-runs `.sql` files here on the very first start. That's how the `todos` table gets created without manual setup.
- Named volume `two-tier` — without this, your data disappears on `docker-compose down`.

### Running with Compose

```bash
# 1. Build the Flask image
docker build -t your-dockerhub-username/flask-image:latest .

# 2. Create .env file
echo "DOCKER_USER=your-dockerhub-username" > .env
echo "DOCKER_TAG=latest" >> .env

# 3. Start everything
docker-compose up -d

# Useful commands
docker-compose ps
docker-compose logs -f
docker-compose logs flask-app -f
docker-compose down
docker-compose down -v    # Also wipes volumes (deletes DB data)
```

App: `http://localhost:5000`

---

## Kubernetes Setup

The `k8s/` directory contains three manifests that deploy the Flask app on any Kubernetes cluster. MySQL is handled separately (or via an existing service) — the K8S setup here focuses on the Flask tier.

### Namespace
```
Why a namespace? It isolates all resources for this app under `two-tier-ns` so they don't collide with other workloads on the cluster. Every subsequent manifest targets this namespace.

Apply it first, before anything else:

```bash
kubectl apply -f k8s/namespace.yml
```

What this does:

- Creates a `Deployment` that maintains 5 identical Flask pods at all times. If a pod crashes, Kubernetes restarts it automatically.
- The `selector.matchLabels` + `template.labels` pairing is how the Deployment tracks which pods it owns — they must match.
- `containerPort: 5000` is documentation, not a firewall rule. Traffic to port 5000 on each pod is what the Service will route to.

Things to add before using this in a real cluster:

```yaml
# Recommended additions to the container spec:
env:
  - name: MYSQL_HOST
    value: "mysql-service"          # Point to your MySQL K8s service
  - name: MYSQL_USER
    valueFrom:
      secretKeyRef:
        name: mysql-secret
        key: username
  - name: MYSQL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mysql-secret
        key: password
  - name: MYSQL_DB
    value: "mydb"
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "250m"
readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Service

```yaml
# k8s/services.yml
kind: Service
apiVersion: v1

metadata:
  name: todo-service
  namespace: two-tier-ns

spec:
  selector:
    app: two-tier-app               # Routes traffic to pods with this label
  ports:
    - protocol: TCP
      port: 8000                    # Port the Service exposes inside the cluster
      targetPort: 5000              # Port on the pod (Flask/Gunicorn)
```

This is a **ClusterIP** service (the default). It gives the Deployment a stable internal IP and DNS name (`todo-service.two-tier-ns.svc.cluster.local`) so other services in the cluster can reach it at port 8000, regardless of which pod handles the request.

The port mapping: cluster traffic hits port `8000` on the Service → forwarded to port `5000` on whichever pod is selected.

**ClusterIP only exposes the app inside the cluster.** To make it accessible externally, change the service type:

```yaml
# For cloud clusters (AWS ELB, GCP LB, etc.)
spec:
  type: LoadBalancer
  ...

# For local clusters (Minikube, kind)
spec:
  type: NodePort
  ports:
    - port: 8000
      targetPort: 5000
      nodePort: 30080   # Access at <node-ip>:30080
```

### Deploy to Kubernetes

```bash
# Apply all manifests at once
kubectl apply -f k8s/

# Or one by one (namespace first)
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/two-tier-deployment.yml
kubectl apply -f k8s/services.yml
```

### Verify the Deployment

```bash
# Check all resources in the namespace
kubectl get all -n two-tier-ns

# Watch pod rollout
kubectl rollout status deployment/two-tier-deployment -n two-tier-ns

# Check pod logs
kubectl logs -l app=two-tier-app -n two-tier-ns

# Describe a pod (useful for debugging image pull errors, crashloops)
kubectl describe pod -l app=two-tier-app -n two-tier-ns

# Check service endpoints
kubectl get endpoints todo-service -n two-tier-ns
```

### Update the Image

```bash
# Update to a new tag
kubectl set image deployment/two-tier-deployment \
  todo-app-container=heyyprakhar1/two-tier-app:v2 \
  -n two-tier-ns

# Watch the rolling update
kubectl rollout status deployment/two-tier-deployment -n two-tier-ns

# Roll back if something breaks
kubectl rollout undo deployment/two-tier-deployment -n two-tier-ns
```

### Scale the Deployment

```bash
# Scale up
kubectl scale deployment/two-tier-deployment --replicas=8 -n two-tier-ns

# Scale down
kubectl scale deployment/two-tier-deployment --replicas=2 -n two-tier-ns
```

### Tear Down

```bash
# Remove all resources in the namespace
kubectl delete -f k8s/

# Or delete the namespace (removes everything in it)
kubectl delete namespace two-tier-ns
```

---

## DevSecOps Pipeline (GitHub Actions)

Seven security and deployment workflows are wired together under one orchestrator. Triggered manually via `workflow_dispatch`.

### Pipeline Flow

```
DevSecOps-pipeline.yml
│
├── [Parallel gate — all must pass]
│   ├── code-quality.yml        → Flake8 (linting) + Bandit (static security)
│   ├── secrets-scan.yml        → Gitleaks (credential leaks in git history)
│   ├── dependencies-scan.yml   → pip-audit (known CVEs in requirements.txt)
│   └── dockerfile-scan.yml     → Hadolint (Dockerfile best practices)
│
├── docker-build-push.yml       → Builds image, pushes to Docker Hub (runs after gate passes)
│
├── image-scan.yml              → Trivy scans the pushed image for vulnerabilities
│
└── deploy-to-prod-server.yml   → SSH into prod server, pull new image, docker-compose up
```

Each step is a reusable workflow (`workflow_call`), so they can also run independently or be composed differently later.

### What Each Scan Does

| Workflow | Tool | Catches |
|---|---|---|
| `code-quality.yml` | Flake8 + Bandit | PEP8 violations, insecure Python patterns (hardcoded passwords, use of `eval`, etc.) |
| `secrets-scan.yml` | Gitleaks | API keys, tokens, credentials accidentally committed to git history |
| `dependencies-scan.yml` | pip-audit | Python packages in `requirements.txt` with published CVEs |
| `dockerfile-scan.yml` | Hadolint | Dockerfile anti-patterns (running as root, `latest` tags, missing `--no-cache-dir`, etc.) |
| `image-scan.yml` | Trivy | OS-level and language-level CVEs in the final built image |

### Deployment Workflow

After image scan passes, the deploy job SSH's into the prod server and runs:

```bash
docker compose down
docker compose up -d --force-recreate --pull always
```

The image tag passed to Compose is `github.sha` — so every deployment is pinned to the exact commit that triggered it.

### Required Secrets and Variables

Set these in GitHub → Settings → Secrets and Variables → Actions:

| Name | Type | Used by |
|---|---|---|
| `DOCKER_PASSWORD` | Secret | `docker-build-push.yml` — Docker Hub login |
| `PROD_SERVER_HOST` | Secret | `deploy-to-prod-server.yml` — SSH target |
| `PROD_SERVER_SSH_USER` | Secret | `deploy-to-prod-server.yml` — SSH username |
| `PROD_SERVER_SSH_KEY` | Secret | `deploy-to-prod-server.yml` — private key |
| `DOCKER_USER` | Variable (not secret) | `deploy-to-prod-server.yml` — Docker Hub username |

### Trigger the Pipeline

Go to Actions → DevSecOps end-to-end workflow → Run workflow.

---

## Run Without Docker (Local Setup)

**Prerequisites:** Python 3.9+, MySQL 8.0+

```bash
# Load schema
mysql -u root -p
source schema.sql

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_DB=mydb
export SECRET_KEY=dev-secret

# Run
python app.py
```

App: `http://localhost:5000` | Health: `http://localhost:5000/health`

---

## Environment Variables

| Variable | Description | Example |
|---|---|---|
| `MYSQL_HOST` | DB hostname (container name in Compose, service name in K8s) | `mysql` |
| `MYSQL_PORT` | MySQL port | `3306` |
| `MYSQL_USER` | DB username | `admin` |
| `MYSQL_PASSWORD` | DB password | `admin` |
| `MYSQL_DB` | Database name | `mydb` |
| `SECRET_KEY` | Flask session secret | `dev-secret` |
| `DOCKER_USER` | Docker Hub username | `yourname` |
| `DOCKER_TAG` | Image tag | `latest` |

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | View all todos |
| POST | `/add` | Add a todo |
| GET | `/complete/<id>` | Mark complete |
| GET | `/delete/<id>` | Delete a todo |
| GET | `/health` | Health check |

---

## Learning Path Covered

1. **Dockerfile** — single-stage, `python:3.12-slim`, Gunicorn
2. **Multi-stage builds** — separate build and runtime stages
3. **Distroless images** — minimal production images
4. **Volumes** — MySQL persistence in Docker and K8s
5. **Docker networking** — container-to-container by name
6. **Docker Compose** — local multi-container orchestration
7. **Kubernetes — Namespace** — resource isolation
8. **Kubernetes — Deployment** — replica management, rolling updates, rollbacks
9. **Kubernetes — Service** — stable networking, ClusterIP vs NodePort vs LoadBalancer
10. **Image tagging** — versioning with git SHA
11. **DevSecOps pipeline** — 6-stage security gate before deploy
12. **CI/CD** — GitHub Actions + Jenkins

---

## Common Issues

**Database connection error on startup**  
MySQL takes ~20-30 seconds to be ready. In Compose, `condition: service_healthy` handles this. In K8s, add a `readinessProbe` to the Flask container so Kubernetes doesn't route traffic until the pod is actually ready.

**Pods stuck in `ImagePullBackOff`**  
The image `heyyprakhar1/two-tier-app: latest` must exist on Docker Hub. Build and push it first:
```bash
docker build -t heyyprakhar1/two-tier-app:latest .
docker push heyyprakhar1/two-tier-app:latest
```

**Flask can't reach MySQL in K8S**  
`MYSQL_HOST` should be the name of your MySQL Kubernetes Service, not `localhost` or a Docker container name.

**Port already in use (Docker)**
```bash
docker run -p 5001:5000 flask-app
```

**Docker permission denied**
```bash
sudo usermod -aG docker $USER
# Re-login required
```

**Schema not loading (Compose)**  
The `schema.sql` auto-init only runs when the MySQL volume is empty. If the volume already exists, wipe it:
```bash
docker-compose down -v && docker-compose up -d
```

---

## License

MIT — free to use for learning and portfolio work.

---

> **Break things. Fix them. Repeat.**
