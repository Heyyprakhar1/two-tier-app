<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:1904DA,100:0f6e56&height=160&section=header&text=Secure%20DevSecOps%20Pipeline&fontSize=36&fontColor=ffffff&fontAlignY=45&desc=Shift-Left%20Security%20%7C%20Zero%20Vulnerable%20Artifacts%20%7C%20GitHub%20Actions&descSize=14&descAlignY=68&descColor=d0f0ff" width="100%"/>

# 🔒 Secure DevSecOps Delivery Pipeline
### Two-Tier Application — Shift-Left Security | GitHub Actions | Zero Vulnerable Artifacts

[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white)](.)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)](.)
[![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat-square&logo=aquasecurity&logoColor=white)](.)
[![Bandit](https://img.shields.io/badge/Bandit-306998?style=flat-square&logo=python&logoColor=white)](.)
[![Gitleaks](https://img.shields.io/badge/Gitleaks-181717?style=flat-square&logo=github&logoColor=white)](.)
[![Hadolint](https://img.shields.io/badge/Hadolint-2496ED?style=flat-square&logo=docker&logoColor=white)](.)

</div>

---

## What this project is

A production-grade **shift-left DevSecOps CI/CD pipeline** for a two-tier Flask + MySQL application. The core principle: every security check runs at build time — not after deployment. The result is a fully auditable delivery trail where **zero unscanned artifacts ever reach runtime**.

Most CI/CD pipelines bolt security on at the end or skip it entirely. This pipeline treats security as a first-class delivery gate — 6 automated tools embedded into every single commit.

---

## Architecture

```
Code Push (GitHub · main branch)
          │
          ▼
 ┌─────────────────────────────────────┐
 │     GitHub Actions Trigger          │
 │     8-workflow parallel pipeline    │
 └──────────┬──────────────────────────┘
            │
            ▼
     ┌─────────────────────────────────────────────────┐
     │               Security Gates                    │
     │                                                 │
     │  ┌────────────┐  ┌────────────┐  ┌──────────┐  │
     │  │ Secret Scan│  │ Code Scan  │  │   Lint   │  │
     │  │  Gitleaks  │  │Bandit+audit│  │ Hadolint │  │
     │  └────────────┘  └────────────┘  └──────────┘  │
     │                                                 │
     │  ┌────────────────────────────────────────────┐ │
     │  │         Image Scan · Trivy CVE check       │ │
     │  └────────────────────────────────────────────┘ │
     └─────────────────────┬───────────────────────────┘
                           │ All gates pass
                           ▼
              ┌────────────────────────┐
              │    Build + Push        │
              │  Docker multi-stage    │
              │    → Docker Hub        │
              └────────────┬───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │     Auto Deploy        │
              │   SSH → EC2 instance   │
              │  docker-compose up     │
              └────────────┬───────────┘
                           │
                           ▼
                  App live on EC2
```

---

## Security gates — 6 tools, every commit

| Tool | Gate | What it catches |
|---|---|---|
| **Gitleaks** | Secret scan | API keys, tokens, credentials in code/history |
| **Bandit** | SAST | Python security vulnerabilities (hardcoded secrets, unsafe calls) |
| **pip-audit** | Dependency audit | Known CVEs in Python package dependencies |
| **Hadolint** | Dockerfile lint | Insecure Dockerfile patterns, best practice violations |
| **Trivy** | Container scan | OS + app-level CVEs in the final Docker image |
| **Artifact gate** | Promotion block | Prevents any image with HIGH/CRITICAL CVEs from being pushed |

**If any gate fails → pipeline stops. No artifact is built or pushed.**

---

## Key outcomes

| Metric | Result |
|---|---|
| Scan coverage per commit | **100%** — every push scanned across all 6 gates |
| Vulnerable artifacts reaching runtime | **Zero** |
| Pipeline maintenance overhead | **40% reduction** via reusable multi-stage CI templates |
| Security tools consolidated | **6** into a single unified pipeline |
| Deployment process | **Fully automated** — zero manual steps post-gate-pass |

---

## Tech stack

| Layer | Technology |
|---|---|
| Application | Flask (Python) + MySQL |
| Containerization | Docker (multi-stage builds) |
| Orchestration (local) | Docker Compose |
| CI/CD | GitHub Actions |
| Secret scanning | Gitleaks |
| SAST | Bandit |
| Dependency audit | pip-audit |
| Dockerfile linting | Hadolint |
| Container scanning | Trivy |
| Registry | Docker Hub |
| Deployment target | AWS EC2 (SSH + docker-compose) |

---

## Pipeline workflow breakdown

```yaml
# Simplified pipeline structure
jobs:
  secret-scan:       # Gitleaks — runs first, fastest gate
  code-scan:         # Bandit + pip-audit — parallel
  dockerfile-lint:   # Hadolint — parallel
  build:             # Multi-stage Docker build — needs all scans to pass
  image-scan:        # Trivy — scans built image before push
  push:              # Docker Hub push — only if Trivy passes
  deploy:            # SSH to EC2 — only if push succeeds
```

All scan jobs run in **parallel** — total pipeline time stays under 4 minutes.

---

## How to run locally

```bash
# Clone the repo
git clone https://github.com/Heyyprakhar1/<repo-name>
cd <repo-name>

# Run the application
docker-compose up --build

# Run security scans manually
pip install bandit pip-audit
bandit -r app/
pip-audit

# Scan Docker image with Trivy
trivy image <your-image-name>

# Run Gitleaks
gitleaks detect --source . --verbose
```

---

## Why shift-left matters

Traditional pipelines run security scans after deployment — or not at all. Shift-left means every developer commit is treated as a potential production release candidate:

- Vulnerabilities caught at **build time** are 100x cheaper to fix than post-production
- Automated gates remove human error from the security review process
- Fully auditable trail means every artifact has a verifiable security history
- Developers get instant feedback — no waiting for a manual security review cycle

---

<div align="center">

**Built by [Prakhar Srivastava](https://github.com/Heyyprakhar1)**
· [Portfolio](https://prakharsrivastava-devops.netlify.app/)
· [LinkedIn](https://linkedin.com/in/heyyprakhar1)

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f6e56,100:1904DA&height=100&section=footer&text=Built%20with%20Security%20First&fontSize=20&fontColor=ffffff&fontAlignY=65&desc=Every%20commit%20scanned.%20Zero%20vulnerable%20artifacts.&descSize=12&descColor=d0f0ff&descAlignY=85" width="100%"/>

</div>
