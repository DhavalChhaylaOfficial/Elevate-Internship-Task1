# CI/CD Pipeline for Node.js App with GitHub Actions

This guide will walk you through setting up a complete CI/CD pipeline for a simple Node.js application using GitHub Actions and Docker. It includes building, testing, and deploying your app to an AWS EC2 instance.

---

## 1. Prerequisites

### 1.1 Git & GitHub

- **Install Git** on your machine: [https://git-scm.com/downloads](https://git-scm.com/downloads)
- **Create a GitHub account** and familiarize yourself with pushing/pulling code.

### 1.2 Docker & Docker Hub

- **Install Docker Desktop**: [https://www.docker.com/get-started](https://www.docker.com/get-started)
- **Create a free Docker Hub account**: [https://hub.docker.com/](https://hub.docker.com/)
- In Docker Hub → **Account Settings** → **Security**, generate a **New Access Token**. You’ll use this in your GitHub Actions secrets.

### 1.3 Node.js

- **Install Node.js** (v18 or later): [https://nodejs.org/en/download/](https://nodejs.org/en/download/)
- Verify with:
  ```bash
  node --version && npm --version
  ```

---

## 2. Clone & Prepare Your Repo

1. **Initialize your GitHub repo**:

   - On GitHub, create a new empty repository named `Elevate-Internship-Task1` (or a name of your choice).

2. **Clone the app locally**:

   ```bash
   cd Task-1 (CI_CD_GH)
   git clone https://github.com/DhavalChhaylaOfficial/Elevate-Internship-Task1.git .
   ```

---

## 3. Add a `.dockerignore`

Create a file named `.dockerignore` in the project root to exclude unnecessary files from your Docker image:

```
node_modules
npm-debug.log
.git
.github
```

---

## 4. Write the Dockerfile

Create a `Dockerfile` in the project root (no extension):

```dockerfile
# ---------- Stage 1: builder ----------
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# ---------- Stage 2: runtime ----------
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app .
EXPOSE 3033
CMD ["node", "server.js"]
```

### 4.1 Explanation of each line

- **FROM node:18-alpine**: Base image (lightweight Node.js).
- **WORKDIR /app**: Sets working directory inside the container.
- *COPY package**.json ./*\* & **RUN npm install**: Installs dependencies.
- **COPY . .**: Copies application source code.
- **EXPOSE 3033**: Documents that the app listens on port 3033.
- **CMD ["node", "server.js"]**: Default command to start the app.

---

## 5. Build & Test Locally

1. **Build the Docker image**:
   ```bash
   docker build -t demo-app-nodejs:local .
   ```
2. **Run the container**:
   ```bash
   docker run -p 3000:3033 demo-app-nodejs:local
   ```
3. Visit `http://localhost:3033` in your browser to verify that the app is running.

---

## 6. Push Image to Docker Hub (Manual First Time)

1. **Login to Docker Hub**:
   ```bash
   docker login
   # Username: <your-username>
   # Password: <access-token>
   ```
2. **Tag & push the image**:
   ```bash
   docker tag demo-app-nodejs:local <your-username>/demo-app-nodejs:latest
   docker push <your-username>/demo-app-nodejs:latest
   ```

---

## 7. Store Credentials in GitHub Secrets

In your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
2. Add the following secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username.
   - `DOCKERHUB_TOKEN`: The access token you generated.
   - `EC2_HOST`: Public IP or DNS of your EC2 instance.
   - `EC2_USER`: SSH username (e.g., `ubuntu`).
   - `EC2_SSH_KEY`: Private SSH key (contents) for your EC2 access.

---

## 8. Create the GitHub Actions Workflow

1. Create the workflow directory:
   ```bash
   mkdir -p .github/workflows/
   ```
2. Create `.github/workflows/main.yml` with the following content:
   ```yaml
   name: CI/CD Pipeline

   on:
     push:
       branches: [ main ]

   jobs:
     build-and-push:
       runs-on: ubuntu-latest

       steps:
         - name: Checkout code
           uses: actions/checkout@v4

         - name: Set up Node.js
           uses: actions/setup-node@v4
           with:
             node-version: '18'
             cache: 'npm'

         - name: Install dependencies
           run: npm ci

         - name: Run tests
           run: npm test
           # Make sure you have tests defined in package.json

         - name: Log in to Docker Hub
           uses: docker/login-action@v2
           with:
             username: ${{ secrets.DOCKERHUB_USERNAME }}
             password: ${{ secrets.DOCKERHUB_TOKEN }}

         - name: Build Docker image
           run: |
             IMAGE=${{ secrets.DOCKERHUB_USERNAME }}/nodejs-app
             docker build -t $IMAGE:${{ github.sha }} .
             docker tag $IMAGE:${{ github.sha }} $IMAGE:latest

         - name: Push Docker images
           run: |
             IMAGE=${{ secrets.DOCKERHUB_USERNAME }}/nodejs-app
             docker push $IMAGE:${{ github.sha }}
             docker push $IMAGE:latest

         - name: Deploy to EC2 via SSH
           uses: appleboy/ssh-action@v1.0.0
           with:
             host: ${{ secrets.EC2_HOST }}
             username: ${{ secrets.EC2_USER }}
             key: ${{ secrets.EC2_SSH_KEY }}
             script: |
               docker pull ${{ secrets.DOCKERHUB_USERNAME }}/nodejs-app:latest
               docker stop myapp || true && docker rm myapp || true
               docker run -d --name myapp -p 3033:3033 ${{ secrets.DOCKERHUB_USERNAME }}/nodejs-app:latest
   ```

---

## 9. Commit & Trigger the Pipeline

```bash
git add Dockerfile .dockerignore .github/workflows/main.yml
git commit -m "Add Dockerfile and CI/CD pipeline"
git push origin main
```

- Navigate to the **Actions** tab in your repository to watch the workflow run.
- Upon completion, confirm that:
  - Docker images appear in your Docker Hub repository tags.
  - Your application is running on the EC2 instance.

---

## 10. Future Enhancements

- **Testing**: Integrate real test suites (e.g., Jest, Mocha).
- **Multi-Environment**: Use branch-based tags for staging & production.
- **Security**: Scan Docker images with Trivy or similar tools.
- **Infrastructure as Code**: Automate EC2 provisioning with Terraform or CloudFormation.

---

## 11. Interview Questions & Answers

### Q1: What is CI/CD?

**A:** CI (Continuous Integration) automates the merging and testing of code changes. CD (Continuous Delivery/Deployment) automates deploying code to production-like environments or directly to production.

### Q2: How do GitHub Actions work?

**A:** GitHub Actions uses YAML-defined workflows that run on specified triggers (e.g., `push`, `pull_request`). Jobs run on virtual runners, executing steps like checkout, build, test, and deploy.

### Q3: What are runners?

**A:** Runners are servers (hosted by GitHub or self-hosted) that execute the workflows' jobs and steps.

### Q4: Difference between jobs and steps

**A:** A **job** is a collection of **steps** that run in a single runner environment. Steps execute sequentially within a job; jobs can run in parallel or depend on each other.

### Q5: How to secure secrets in GitHub Actions?

**A:** Store sensitive values (tokens, keys) in **GitHub Secrets**. They are encrypted and injected at runtime, never exposed in logs.

### Q6: How to handle deployment errors?

**A:** Use `continue-on-error: false` (default) to fail jobs on errors. Implement retry logic, notifications, and rollbacks in your scripts.

### Q7: Explain the Docker build-push workflow

**A:** 1. Build your Docker image locally or in CI.\
2\. Tag the image with identifiers (e.g., commit SHA, `latest`).\
3\. Authenticate to your registry.\
4\. Push the tagged images to the registry.

### Q8: How can you test a CI/CD pipeline locally?

**A:** Use tools like [act](https://github.com/nektos/act) to simulate GitHub Actions on your machine. You can also run individual scripts and Docker commands manually.

---

*Happy Coding!* <br>
*Dhaval Chhayla*