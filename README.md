# 🚀 Two-Tier Application (Flask + MySQL) – Docker Practice Project

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Docker](https://img.shields.io/badge/Docker-Automated-2496ED?logo=docker)
![CI/CD](https://img.shields.io/badge/CI%2FCD-Jenkins-D24939?logo=jenkins)
![Auth](https://img.shields.io/badge/Auth-Flask--Bcrypt-orange)

A hands-on two-tier web application built with Flask (backend) and MySQL (database). This repository is designed purely for learning and practising Docker & DevOps concepts step by step — from basic Dockerfiles to Docker Compose, CI/CD, and production-grade authentication.

> 🎯 **Goal:** Learn Docker by *building everything yourself* instead of just running ready-made configs.

---

## 🧩 Application Overview

This is a **Todo List application** with full user authentication where:

* Users can register and log in to their own account
* Each user manages only their own tasks
* Tasks can be added, completed, renamed, and deleted
* All auth activity is tracked in the database
* All data is stored persistently in MySQL

The app follows a **two-tier architecture**:

```
Client (Browser)
      ↓
Flask App (Backend)
      ↓
MySQL Database
```

---

## 🗂️ Project Structure

```
two-tier-app/
├── app.py                  # Flask application logic
├── requirements.txt        # Python dependencies
├── schema.sql              # MySQL schema (users, todos, auth_logs)
├── templates/
│   ├── index.html          # Main todo UI (login required)
│   ├── login.html          # Login page
│   ├── register.html       # Registration page
│   └── deleted.html        # Deleted todos view
├── dockerfile              # Single-stage Dockerfile
├── docker-multi-stage-build# Multi-stage Dockerfile
├── docker-compose.yml      # Orchestration config
├── Jenkinsfile             # CI/CD pipeline
├── backup.sh               # MySQL backup script
├── .env.example            # Environment variable template
└── README.md               # Project documentation
```

---

## ✨ Features

* ✅ User registration & login
* ✅ Session-based authentication
* ✅ Password hashing with Flask-Bcrypt
* ✅ Per-user task isolation
* ✅ Auth logging (login / logout / failed attempts with IP + timestamp)
* ✅ Add todos
* ✅ Mark todos as completed
* ✅ Rename todos (inline)
* ✅ Soft delete todos
* ✅ Persistent storage using MySQL
* ✅ Health check endpoint
* ✅ Clean & simple UI

---

## ⚙️ Tech Stack

| Layer            | Technology             |
| ---------------- | ---------------------- |
| Frontend         | HTML (Jinja Templates) |
| Backend          | Python Flask           |
| Auth             | Flask-Bcrypt + Sessions|
| Database         | MySQL 8.0              |
| Containerization | Docker                 |
| Orchestration    | Docker Compose         |
| CI/CD            | Jenkins                |

---

## 🗄️ Database Schema

Three tables inside a single `mydb` database:

```
mydb/
 ├── users       → registered user accounts
 ├── todos       → tasks linked to users via user_id (FK)
 └── auth_logs   → tracks every login, logout & failed attempt
```

**users**
| Column        | Type         | Description              |
| ------------- | ------------ | ------------------------ |
| id            | INT (PK)     | Auto increment           |
| username      | VARCHAR(50)  | Unique username          |
| email         | VARCHAR(100) | Unique email             |
| password_hash | VARCHAR(255) | Bcrypt hashed password   |
| created_at    | TIMESTAMP    | Account creation time    |

**todos**
| Column     | Type                     | Description               |
| ---------- | ------------------------ | ------------------------- |
| id         | INT (PK)                 | Auto increment            |
| task       | VARCHAR(255)             | Task description          |
| status     | ENUM(pending,completed)  | Task status               |
| deleted    | BOOLEAN                  | Soft delete flag          |
| user_id    | INT (FK → users.id)      | Owner of the task         |
| created_at | TIMESTAMP                | Creation time             |
| deleted_at | TIMESTAMP                | Deletion time             |

**auth_logs**
| Column             | Type                        | Description                    |
| ------------------ | --------------------------- | ------------------------------ |
| id                 | INT (PK)                    | Auto increment                 |
| user_id            | INT (FK → users.id)         | NULL for failed attempts       |
| action             | ENUM(login,logout,failed)   | Auth action type               |
| ip_address         | VARCHAR(45)                 | Client IP (IPv4/IPv6)          |
| username_attempted | VARCHAR(50)                 | Captures username on failure   |
| timestamp          | TIMESTAMP                   | When the action occurred       |

---

## 🚀 Run Without Docker (Local Setup)

### Prerequisites

* Python 3.9+
* MySQL 8.0+

### 1️⃣ Setup MySQL

```bash
mysql -u root -p
source schema.sql
```

### 2️⃣ Install Dependencies

```bash
pip install -r requirements.txt
```

### 3️⃣ Set Environment Variables

```bash
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_DB=mydb
export SECRET_KEY=dev-secret
```

### 4️⃣ Run Application

```bash
python app.py
```

📍 Access:

* App: [http://localhost:5000](http://localhost:5000)
* Health: [http://localhost:5000/health](http://localhost:5000/health)

---

## 🐳 Docker Learning Roadmap

This repository is intentionally **Docker-first learning focused**.

📌 Refer to **DOCKER_PRACTICE_GUIDE.md** for detailed steps.

### Learning Phases

1. 🧱 **Basic Dockerfile**
2. 🏗️ **Multi-stage Docker builds**
3. 🔒 **Distroless images**
4. 💾 **Docker volumes (MySQL persistence)**
5. 🌐 **Docker networking**
6. 🎼 **Docker Compose orchestration**
7. 🏷️ **Image tagging & versioning**
8. 📤 **Push images to Docker Hub**
9. 🔄 **CI/CD with Jenkins**

---

## 🐙 Run with Docker Compose

```bash
docker-compose up -d --build
```

> ⚠️ If you're setting up fresh or changed `schema.sql`, wipe the volume first:
> ```bash
> docker-compose down -v
> docker-compose up -d --build
> ```

Useful commands:

```bash
docker-compose ps
docker-compose logs -f
docker-compose down
docker-compose down -v    # also removes DB volume
```

<img width="1600" height="880" alt="image" src="https://github.com/user-attachments/assets/a3874fd6-917d-4c02-8970-3664710c2bb9" />

---

## 🔑 Environment Variables

| Variable       | Description       |
| -------------- | ----------------- |
| MYSQL_HOST     | Database hostname |
| MYSQL_PORT     | MySQL port        |
| MYSQL_USER     | DB username       |
| MYSQL_PASSWORD | DB password       |
| MYSQL_DB       | Database name     |
| SECRET_KEY     | Flask secret key  |

---

## 🔌 API Endpoints

| Method | Endpoint          | Auth Required | Description              |
| ------ | ----------------- | ------------- | ------------------------ |
| GET    | /                 | ✅ Yes        | View user's todos        |
| POST   | /add              | ✅ Yes        | Add new todo             |
| GET    | /complete/\<id\>  | ✅ Yes        | Mark todo as completed   |
| POST   | /rename/\<id\>    | ✅ Yes        | Rename a todo            |
| GET    | /delete/\<id\>    | ✅ Yes        | Soft delete a todo       |
| GET    | /deleted          | ✅ Yes        | View deleted todos       |
| GET    | /register         | ❌ No         | Register page            |
| POST   | /register         | ❌ No         | Create new account       |
| GET    | /login            | ❌ No         | Login page               |
| POST   | /login            | ❌ No         | Authenticate user        |
| GET    | /logout           | ✅ Yes        | Logout & clear session   |
| GET    | /health           | ❌ No         | Health check             |

---

## 🐞 Common Issues & Fixes

### ❌ Database Connection Error

* Ensure MySQL container is running
* Wait ~30 seconds for DB initialisation
* Verify environment variables

### ❌ Schema changes not reflecting

```bash
docker-compose down -v    # wipes the volume
docker-compose up -d --build
```

### ❌ Port Already in Use

```bash
docker run -p 5001:5000 flask-app
```

### ❌ Docker Permission Denied

```bash
sudo usermod -aG docker $USER
```

(Re-login required)

### ❌ Rename button not showing after update

```bash
docker-compose down
docker-compose up -d --build    # force rebuild, don't use cached image
```

---

## 💡 Best Practices Learned

* ✔ Writing optimised Dockerfiles
* ✔ Using `.dockerignore`
* ✔ Multi-stage builds for smaller images
* ✔ Persistent data using volumes
* ✔ Service discovery via Docker networking
* ✔ Environment-based configuration
* ✔ Session-based authentication in Flask
* ✔ Never storing plain text passwords
* ✔ Relational DB design with foreign keys & cascades
* ✔ Security-first thinking — tracking failed login attempts
* ✔ CI/CD basics

---

## 🎓 Why This Project Matters (Interview POV)

✅ Built from scratch
✅ Not a copy-paste repo
✅ Explains **how Docker actually works**
✅ Demonstrates real DevOps fundamentals
✅ Production-grade auth with bcrypt & session management
✅ Relational DB design with audit logging
✅ Shows security awareness (failed login tracking, password hashing)

** Final app deployment will look like:-

<img width="1140" height="1102" alt="image" src="https://github.com/user-attachments/assets/f371ca61-88e8-4e6e-904a-126763b16c5f" />

---

## 🔄 CI/CD Pipeline

This project includes a complete Jenkins pipeline for automated deployment.

### Pipeline Stages
1. ✅ **Checkout** - Pull latest code
2. ✅ **Build** - Create Docker images
3. ✅ **Test** - Run automated tests
4. ✅ **Security Scan** - Trivy vulnerability detection
5. ✅ **Push** - Push to Docker Hub
6. ✅ **Deploy** - Deploy to staging

### Jenkins Setup

1. **Create Pipeline Job**
   - New Item → Pipeline
   - Name: `two-tier-flask-app`

2. **Configure SCM**
   - Pipeline script from SCM
   - Repository: `https://github.com/Heyyprakhar1/two-tier-app.git`
   - Script Path: `Jenkinsfile`

3. **Add Credentials**
   - Manage Jenkins → Credentials
   - Add Docker Hub credentials
   - ID: `dockerhub-credentials`

4. **Trigger Build**
   - Push to main branch (Webhook-trigger)
   - Or click "Build Now" (manual)

Screenshot Attached:-

<img width="1436" height="955" alt="Screenshot 2026-01-28 015918" src="https://github.com/user-attachments/assets/a160a08c-b9ea-486c-8e53-0e287dbf7317" />

---

## 📜 License

MIT License — Free to use for learning & portfolio.

---

## ⭐ Final Note

> **Break things. Fix them. Repeat.**

That's how real DevOps engineers are made 💪

Happy Dockering 🐳🚀
