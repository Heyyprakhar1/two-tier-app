# Docker Practice - Quick Reference

## 🎯 Your Learning Path

### Phase 1: Basic Dockerfile ✍️
**What to create:** `Dockerfile`

```dockerfile
# Hint: Start with this structure
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

**Build and run:**
```bash
docker build -t flask-todo-app:v1 .
docker run -p 5000:5000 flask-todo-app:v1
```

---

### Phase 2: Multi-Stage Build 🏗️
**What to improve:** Make your `Dockerfile` use multi-stage build

```dockerfile
# Hint: Two stages
# Stage 1: Build dependencies
FROM python:3.11-slim AS builder
# ... install dependencies

# Stage 2: Runtime
FROM python:3.11-slim
# ... copy only what's needed
```

**Compare sizes:**
```bash
docker images | grep flask-todo-app
```

---

### Phase 3: Distroless Image 🔒
**What to create:** `Dockerfile.distroless`

```dockerfile
# Hint: Use distroless base
FROM python:3.11-slim AS builder
# ... build stage

FROM gcr.io/distroless/python3-debian12
# ... runtime stage
```

**Security benefits:**
- No shell
- No package manager
- Smaller attack surface

---

### Phase 4: Docker Compose 🎼
**What to create:** `docker-compose.yml`

```yaml
# Hint: Define two services
version: '3.8'

services:
  db:
    image: mysql:8.0
    # ... environment, volumes, networks
    
  web:
    build: .
    # ... ports, environment, depends_on
    
volumes:
  mysql_data:

networks:
  app-network:
```

**Usage:**
```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
```

---

### Phase 5: Environment Variables 🔑
**What to create:** `.env`

```env
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=todo_db
MYSQL_USER=todouser
MYSQL_PASSWORD=todopass
SECRET_KEY=your-secret-key-here
```

**Reference in docker-compose.yml:**
```yaml
environment:
  - MYSQL_HOST=db
  - MYSQL_PASSWORD=${MYSQL_PASSWORD}
```

---

### Phase 6: .dockerignore 🚫
**What to create:** `.dockerignore`

```
__pycache__
*.pyc
*.pyo
.git
.env
.venv
*.md
.DS_Store
```

---

### Phase 7: Jenkins Pipeline 🔄
**What to create:** `Jenkinsfile`

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t flask-todo-app .'
            }
        }
        
        stage('Test') {
            steps {
                sh 'docker run --rm flask-todo-app python -m pytest'
            }
        }
        
        stage('Push') {
            steps {
                sh 'docker push yourusername/flask-todo-app:latest'
            }
        }
    }
}
```

---

## 📋 Checklist

Create these files yourself:

- [ ] `Dockerfile` - Basic image
- [ ] `Dockerfile.multistage` - Optimized build
- [ ] `Dockerfile.distroless` - Secure image
- [ ] `.dockerignore` - Exclude unnecessary files
- [ ] `docker-compose.yml` - Orchestration
- [ ] `.env` - Environment variables
- [ ] `Jenkinsfile` - CI/CD pipeline (optional)

---

## 🎓 Practice Commands

### Image Management
```bash
# Build
docker build -t myapp:v1 .
docker build -f Dockerfile.distroless -t myapp:distroless .

# List
docker images

# Remove
docker rmi myapp:v1

# Tag
docker tag myapp:v1 myapp:latest
docker tag myapp:v1 username/myapp:v1

# Push
docker push username/myapp:v1
```

### Container Management
```bash
# Run
docker run -d -p 5000:5000 --name myapp myapp:v1

# Stop
docker stop myapp

# Remove
docker rm myapp

# Logs
docker logs -f myapp

# Execute command
docker exec -it myapp /bin/bash
```

### Volume Management
```bash
# Create
docker volume create mysql_data

# List
docker volume ls

# Inspect
docker volume inspect mysql_data

# Remove
docker volume rm mysql_data
```

### Network Management
```bash
# Create
docker network create app-network

# List
docker network ls

# Inspect
docker network inspect app-network

# Connect container
docker network connect app-network myapp
```

### Docker Compose
```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs -f

# Restart service
docker-compose restart web

# Scale
docker-compose up -d --scale web=3
```

---

## 🎯 Success Criteria

You've mastered Docker when you can:

1. ✅ Build efficient Docker images (< 100MB)
2. ✅ Use multi-stage builds
3. ✅ Implement distroless images
4. ✅ Configure volumes for persistence
5. ✅ Set up container networking
6. ✅ Write docker-compose.yml from scratch
7. ✅ Push images to Docker Hub
8. ✅ Create CI/CD pipelines
9. ✅ Troubleshoot container issues
10. ✅ Explain everything in interviews

---

## 💡 Pro Tips

1. **Start Small**: Basic Dockerfile first, then optimize
2. **Read Errors**: Docker errors are descriptive
3. **Use Cache**: Leverage Docker layer caching
4. **Be Secure**: Use distroless, non-root users, secrets
5. **Tag Properly**: Use semantic versioning
6. **Document**: Comment your Dockerfiles
7. **Test Often**: Build and run frequently
8. **Learn from Others**: Check Docker Hub for examples
9. **Practice Daily**: Consistency is key
10. **Break Things**: Best way to learn debugging

---

## 🏆 Challenge Yourself

After the basics, try:

1. **Add health checks** to your Dockerfile
2. **Implement CI/CD** with GitHub Actions
3. **Add monitoring** with Prometheus
4. **Set up logging** with ELK stack
5. **Deploy to cloud** (AWS ECS, GCP Cloud Run)
6. **Use Docker secrets** for sensitive data
7. **Optimize** to < 50MB image size
8. **Add tests** in your pipeline
9. **Implement** blue-green deployment
10. **Scale** with Kubernetes

---

## 📚 When You're Stuck

1. Check the main README.md
2. Read Docker documentation
3. Search Docker Hub for similar images
4. Look at the reference repo structure
5. Google the error message
6. Ask in Docker community forums
7. Review Docker best practices guide

---

**Remember:** You're not copying, you're **learning by doing**! 💪

Every file you create yourself is a skill you've truly mastered.

Good luck! 🚀

