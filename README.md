# Flask MySQL Todo App - Docker Practice Project

A two-tier web application to practice Docker concepts including images, volumes, networking, multi-stage builds, distroless images, Docker Compose, and CI/CD.

## 📁 Project Structure

```
flask-todo-app/
├── app.py              # Main Flask application
├── templates/
│   └── index.html      # Frontend template
├── requirements.txt    # Python dependencies
├── schema.sql         # MySQL database schema
└── README.md          # This file

# You will create (Docker practice):
├── Dockerfile         # Build Flask image
├── .dockerignore      # Docker ignore patterns
├── docker-compose.yml # Multi-container orchestration
├── Jenkinsfile        # CI/CD pipeline (optional)
└── .env              # Environment variables
```

## 🎯 What This App Does

A simple Todo List application with:
- ✅ Add new todos
- ✅ Mark todos as completed
- ✅ Delete todos
- ✅ View all todos
- ✅ Persistent storage with MySQL
- ✅ Health check endpoint

## 🚀 Running Locally (Without Docker)

### Prerequisites
- Python 3.9+
- MySQL 8.0+

### Setup Steps

1. **Install MySQL and create database**
```bash
# Login to MySQL
mysql -u root -p

# Run the schema
source schema.sql
```

2. **Install Python dependencies**
```bash
pip install -r requirements.txt
```

3. **Set environment variables**
```bash
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_DB=todo_db
export SECRET_KEY=your-secret-key
```

4. **Run the application**
```bash
python app.py
```

5. **Access the app**
- Open browser: http://localhost:5000
- Health check: http://localhost:5000/health

## 🐳 Docker Practice Guide

Now it's time to containerize this application! Here's your learning path:

### Phase 1: Docker Images & Dockerfile

**Goal:** Create a Docker image for the Flask application

**Tasks:**
1. Create a `Dockerfile` for the Flask app
   - Use `python:3.11-slim` as base image
   - Copy application files
   - Install dependencies from `requirements.txt`
   - Expose port 5000
   - Set CMD to run the app

2. Create `.dockerignore` file
   - Exclude `__pycache__`, `*.pyc`, `.env`, etc.

3. Build your first image
   ```bash
   docker build -t flask-todo-app:v1 .
   ```

4. Run the container (without database for now)
   ```bash
   docker run -p 5000:5000 flask-todo-app:v1
   ```

**Expected Challenge:** App won't connect to database yet - that's normal!

### Phase 2: Multi-Stage Builds

**Goal:** Optimize image size using multi-stage builds

**Tasks:**
1. Modify your `Dockerfile` to use multi-stage build
   - Stage 1: Builder stage (install dependencies)
   - Stage 2: Runtime stage (copy only necessary files)

2. Compare image sizes
   ```bash
   docker images flask-todo-app
   ```

3. Aim for at least 30% size reduction

### Phase 3: Distroless Images

**Goal:** Further optimize and secure the image

**Tasks:**
1. Create a new Dockerfile using distroless base image
   - Use `gcr.io/distroless/python3-debian12`
   - This has no shell, package managers, or unnecessary tools
   - More secure with smaller attack surface

2. Build and test the distroless version

**Challenge:** Debugging is harder (no shell access!)

### Phase 4: Docker Volumes

**Goal:** Persist MySQL data even after container restarts

**Tasks:**
1. Create a named volume for MySQL
   ```bash
   docker volume create mysql_data
   ```

2. Run MySQL with the volume
   ```bash
   docker run -d \
     --name mysql \
     -e MYSQL_ROOT_PASSWORD=rootpass \
     -e MYSQL_DATABASE=todo_db \
     -v mysql_data:/var/lib/mysql \
     mysql:8.0
   ```

3. Verify data persistence
   - Add some todos
   - Stop and remove container
   - Start new container with same volume
   - Data should still be there!

### Phase 5: Docker Networking

**Goal:** Connect Flask and MySQL containers

**Tasks:**
1. Create a custom bridge network
   ```bash
   docker network create todo-network
   ```

2. Run MySQL on this network
   ```bash
   docker run -d \
     --name mysql \
     --network todo-network \
     -e MYSQL_ROOT_PASSWORD=rootpass \
     -e MYSQL_DATABASE=todo_db \
     mysql:8.0
   ```

3. Run Flask app on the same network
   ```bash
   docker run -d \
     --name flask-app \
     --network todo-network \
     -e MYSQL_HOST=mysql \
     -e MYSQL_PASSWORD=rootpass \
     -p 5000:5000 \
     flask-todo-app:v1
   ```

4. Test connectivity
   - App should now connect to database!
   - Service discovery works by container name

### Phase 6: Docker Compose

**Goal:** Orchestrate multiple containers with one command

**Tasks:**
1. Create `docker-compose.yml`
   - Define two services: `web` (Flask) and `db` (MySQL)
   - Use environment variables
   - Configure networks
   - Configure volumes
   - Set up depends_on

2. Create a `.env` file for sensitive data

3. Start everything with one command
   ```bash
   docker-compose up -d
   ```

4. Practice Compose commands
   ```bash
   docker-compose ps        # List services
   docker-compose logs -f   # View logs
   docker-compose down      # Stop everything
   docker-compose down -v   # Stop and remove volumes
   ```

### Phase 7: Image Tagging

**Goal:** Learn proper versioning and tagging strategies

**Tasks:**
1. Tag your image with multiple tags
   ```bash
   docker tag flask-todo-app:v1 flask-todo-app:latest
   docker tag flask-todo-app:v1 flask-todo-app:1.0.0
   docker tag flask-todo-app:v1 your-dockerhub-username/flask-todo-app:v1
   ```

2. Understand tagging conventions
   - `latest` - most recent build
   - `v1`, `v2` - major versions
   - `1.0.0` - semantic versioning
   - Git commit SHA - for traceability

### Phase 8: Push to Docker Hub

**Goal:** Share your image on Docker Hub

**Tasks:**
1. Create Docker Hub account (if you don't have one)

2. Login from terminal
   ```bash
   docker login
   ```

3. Tag image with your username
   ```bash
   docker tag flask-todo-app:v1 yourusername/flask-todo-app:v1
   docker tag flask-todo-app:v1 yourusername/flask-todo-app:latest
   ```

4. Push to Docker Hub
   ```bash
   docker push yourusername/flask-todo-app:v1
   docker push yourusername/flask-todo-app:latest
   ```

5. Verify on Docker Hub website

6. Pull and run from anywhere
   ```bash
   docker pull yourusername/flask-todo-app:latest
   docker run -p 5000:5000 yourusername/flask-todo-app:latest
   ```

### Phase 9: Jenkins CI/CD Pipeline

**Goal:** Automate build, test, and deployment

**Tasks:**
1. Install Jenkins (local or Docker)

2. Create `Jenkinsfile` with stages:
   - Checkout code from Git
   - Build Docker image
   - Run tests (optional)
   - Tag image
   - Push to Docker Hub
   - Deploy to staging/production

3. Configure Jenkins:
   - Add Docker Hub credentials
   - Create pipeline job
   - Connect to your Git repository

4. Test the pipeline:
   - Make a code change
   - Commit and push
   - Watch Jenkins build and deploy automatically

## 🎓 Learning Checkpoints

After completing all phases, you should be able to:

- ✅ Write efficient Dockerfiles
- ✅ Use multi-stage builds to reduce image size
- ✅ Implement distroless images for security
- ✅ Manage persistent data with volumes
- ✅ Configure container networking
- ✅ Orchestrate multi-container apps with Docker Compose
- ✅ Tag and version images properly
- ✅ Push images to Docker Hub
- ✅ Build CI/CD pipelines with Jenkins

## 📝 Application Details

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_HOST` | MySQL hostname | `localhost` |
| `MYSQL_PORT` | MySQL port | `3306` |
| `MYSQL_USER` | Database user | `root` |
| `MYSQL_PASSWORD` | Database password | `` |
| `MYSQL_DB` | Database name | `todo_db` |
| `SECRET_KEY` | Flask secret key | `dev-secret-key-change-this` |

### API Endpoints

- `GET /` - Display all todos
- `POST /add` - Add new todo
- `GET /complete/<id>` - Mark todo as completed
- `GET /delete/<id>` - Delete todo
- `GET /health` - Health check endpoint

### Database Schema

```sql
CREATE TABLE todos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task VARCHAR(255) NOT NULL,
    status ENUM('pending', 'completed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🐛 Common Issues & Solutions

### Database Connection Failed
- Check if MySQL container is running
- Verify network connectivity
- Check environment variables
- Ensure MySQL is fully initialized (wait 30 seconds)

### Port Already in Use
```bash
# Change the port mapping
docker run -p 5001:5000 flask-todo-app:v1
```

### Permission Denied
```bash
# Add your user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

## 💡 Tips for Success

1. **Start Simple**: Begin with basic Dockerfile, then optimize
2. **Test Frequently**: Build and test after each change
3. **Read Errors**: Docker errors are usually informative
4. **Use .dockerignore**: Exclude unnecessary files
5. **Version Everything**: Tag your images properly
6. **Document Your Work**: Update README as you learn
7. **Practice Daily**: Docker skills improve with practice

## 🎯 Next Steps After Mastering Docker

1. **Kubernetes**: Orchestrate containers at scale
2. **Docker Swarm**: Alternative orchestration
3. **Monitoring**: Add Prometheus + Grafana
4. **Logging**: Implement ELK stack
5. **Security**: Scan images for vulnerabilities
6. **Cloud Deployment**: Deploy to AWS ECS, GCP, or Azure

## 📚 Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contributing

This is your learning project! Feel free to:
- Add new features
- Improve the UI
- Add tests
- Enhance security
- Optimize performance

## 📄 License

MIT License - Feel free to use this for learning and portfolio

## 🌟 Why Build Your Own Instead of Forking?

**✅ Building from scratch:**
- You understand every line of code
- You can explain all design decisions
- You learn by doing
- You can customize freely
- Shows real understanding in interviews

**❌ Forking someone else's repo:**
- You might not understand the code
- Can't explain architectural choices
- Limited learning
- Looks like everyone else's project
- Interviewers can tell

**Your choice to build your own Docker configs is absolutely the right approach!** 💪

---

**Good luck with your Docker journey!** 🐳

Remember: The best way to learn Docker is by doing. Start simple, break things, fix them, and keep practicing!

