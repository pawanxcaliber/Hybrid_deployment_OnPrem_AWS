# Hybrid Cloud Deployment: AWS (Frontend/DB) + On-Prem (Backend)

## 📖 Project Overview
This project implements a Hybrid Cloud Architecture that bridges public cloud services (AWS) with private on-premise infrastructure (Home Lab). It demonstrates cost-effective scaling by hosting the database and frontend on the cloud while keeping the compute-heavy backend API on local hardware.

## 🏗️ Architecture Design
## 🏗️ Architecture Design
```mermaid
graph TD
    subgraph Dev_Environment [YOUR DEV LAPTOP]
        Dev_Tools[Code / Terraform / Ansible]
    end

    subgraph GitLab_env [GITLAB CI/CD]
        GitLab[Repo: hybrid_project<br/>Pipeline: .gitlab-ci]
    end

    subgraph Hybrid_Infra [HYBRID INFRASTRUCTURE]
        direction LR
        subgraph On_Prem [ON-PREM (Dep)]
            Runner[GitLab Runner 🏃<br/>(System/Privileged)]
            Backend[🐳 Backend Cont.<br/>(Node.js API)]
        end
        
        subgraph AWS [AWS CLOUD (ap-south-1)]
            S3[📦 S3 Bucket (Web)<br/>(Hosting React App)]
            RDS[🛢️ RDS (MySQL)<br/>(Private DB Instance)]
        end
    end

    User((END USER<br/>Browser/Mobile))

    %% Flows
    Dev_Tools -->|Push Code| GitLab
    Dev_Tools -.->|Provision & Config| On_Prem
    
    GitLab -.->|Polling for Jobs| Runner
    
    Runner -->|Uploads Frontend| S3
    Runner -->|Spawns Docker| Backend
    
    Backend <-->|Connects| RDS
    
    User -->|HTTPS Traffic| S3
    User -->|API Requests| Backend
```

- **Frontend (Public Cloud)**: React application hosted on AWS S3 (Static Website Hosting).
- **Backend (On-Premise)**: Node.js/Express API running in a Docker Container on a local Linux Server ("Dep System").
- **Database (Public Cloud)**: MySQL hosted on AWS RDS (Relational Database Service) for reliability.
- **Orchestration**: GitLab CI/CD automates deployment to both environments simultaneously via a self-hosted runner.

## � Project File Structure
```
Hybrid_Cloud_Project/
├── .gitignore
├── .gitlab-ci.yml
├── ansible/
│   ├── deploy_containers.yml (Legacy)
│   ├── inventory.ini
│   └── setup_dep.yml
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── package-lock.json
│   └── server.js
├── frontend/
│   ├── package.json
│   ├── package-lock.json
│   ├── public/
│   │   ├── favicon.ico
│   │   ├── index.html
│   │   ├── logo192.png
│   │   ├── logo512.png
│   │   ├── manifest.json
│   │   └── robots.txt
│   └── src/
│       ├── App.css
│       ├── App.js
│       ├── App.test.js
│       ├── index.css
│       ├── index.js
│       ├── logo.svg
│       ├── reportWebVitals.js
│       └── setupTests.js
└── terraform/
    ├── main.tf
    ├── terraform.tfstate
    └── terraform.tfstate.backup
```

## �🛠️ Tech Stack
- **Infrastructure as Code**: Terraform (AWS Resources)
- **Configuration Management**: Ansible (Provisioning Dep System)
- **CI/CD**: GitLab CI (Pipelines & Runners)
- **Containerization**: Docker (Backend runtime)
- **Cloud Provider**: AWS (S3, RDS, IAM, Security Groups)
- **Hardware**: 1 Developer Laptop + 1 Linux Server (Dep System)

---

## ⚙️ Part 1: Infrastructure Setup (Terraform)
We used Terraform to provision the "Cloud" half of the hybrid setup.

### 1. Key Resources Defined (main.tf)
- `aws_s3_bucket`: Created a public-read bucket for hosting the React frontend.
- `aws_db_instance`: Provisioned a Free-Tier MySQL RDS instance.
- `aws_security_group`: Configured to allow traffic only from the Dep System's IP address (Whitelisting).

### 2. Execution Commands
Run these on the Developer Laptop:

```bash
# Initialize Terraform providers
terraform init

# Preview the changes
terraform plan

# Apply changes (creates RDS & S3)
terraform apply -auto-approve

# IMPORTANT: Save these outputs!
terraform output
# -> s3_bucket_name
# -> rds_endpoint
```

---

## 🐧 Part 2: Dep System Configuration (Ansible)
We used Ansible to turn a standard Linux laptop into a production-grade server.

### 1. The Playbook (setup.yml)
Automated the installation of:
- Docker & Docker Compose.
- Git.
- Python3 & Pip.
- User permissions (adding user to docker group).

### 2. Execution
```bash
# Run against the inventory file (IP of Dep System)
ansible-playbook -i inventory.ini setup.yml --user pawan --ask-pass
```

---

## 🚀 Part 3: CI/CD Pipeline (GitLab)
The pipeline connects the code to the infrastructure.

### 1. GitLab Variables (CI/CD Settings)
We securely stored secrets in **Settings > CI/CD > Variables**:
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`: For S3 Uploads.
- `DB_HOST`: The RDS Endpoint from Terraform.
- `DB_USER` / `DB_PASS`: Database credentials.
- `REACT_APP_API_URL`: The local IP of the backend API.

### 2. The .gitlab-ci.yml Workflow
The pipeline has two primary parallel jobs:

**Frontend Job:**
- Uses `node:18-alpine`.
- Runs `npm install` & `npm run build`.
- Installs AWS CLI (and its 60 dependencies).
- Syncs the `build/` folder to the S3 Bucket.

**Backend Job:**
- Uses `docker:dind` (Docker-in-Docker).
- Builds the Docker image from Dockerfile.
- Stops/Removes old containers on the Dep System.
- Runs the new container on port 5000.

---

## 🏃 Part 4: The Runner (The Engine)
This was the most critical component. We registered a specific runner on the Dep System to handle the workload.

### 1. Registration Command (System Mode)
We used `sudo` to ensure the runner survives system restarts:

```bash
sudo gitlab-runner register \
  --url https://gitlab.com \
  --token glrt-YOUR_TOKEN_HERE \
  --description "hybrid-dep-runner" \
  --executor docker \
  --docker-image "node:18-alpine"
```

### 2. Runner Configuration (config.toml)
**Crucial Step**: We had to edit `/etc/gitlab-runner/config.toml` to enable Docker-in-Docker.

```toml
[[runners]]
  [runners.docker]
    privileged = true  # <--- CHANGED FROM FALSE
    tls_verify = false
```

---

## 🔧 Troubleshooting Chronicles (Troubles & Fixes)
This project faced several real-world DevOps challenges. Here is how we solved them:

### 1. The "Protected Branch" Lock
- **Error**: `remote: GitLab: You are not allowed to force push code to a protected branch`
- **Cause**: We reset local git history, but GitLab protects main by default.
- **Fix**: GitLab Settings > Repository > Protected Branches > "Allowed to force push" (Toggle ON).

### 2. The "Stuck" Pipeline
- **Error**: `Job is stuck. Check runners.`
- **Cause**: The runner was online but missing the specific tag required by the pipeline.
- **Fix**: Added the tag `self-hosted` in GitLab Runner Settings to match the `.gitlab-ci.yml`.

### 3. The "Zombie" Runner
- **Error**: Runner showed "Last contact: 55 mins ago".
- **Cause**: The runner service on the Linux laptop had crashed or was running in User Mode.
- **Fix**: Restarted the service in System Mode:
  ```bash
  sudo gitlab-runner verify
  sudo gitlab-runner restart
  ```

### 4. Docker Permission Denied
- **Error**: `Cannot connect to the Docker daemon at tcp://docker:2375`
- **Cause**: The runner was unprivileged and couldn't access the host's Docker socket.
- **Fix**: Edited `config.toml` to set `privileged = true`.

### 5. TLS/SSL Connection Errors
- **Error**: `Client.Timeout exceeded while awaiting headers during Docker build.`
- **Cause**: Docker client trying to use HTTPS to talk to the daemon over a plain text connection.
- **Fix**: Added this variable to the pipeline job:
  ```yaml
  variables:
    DOCKER_TLS_CERTDIR: ""
  ```

### 6. The "60 Packages" Panic
- **Observation**: Logs showed `Installing libbz2`, `Installing python3`, etc. (60 items).
- **Context**: User has slow internet and worried about download size.
- **Explanation**: The `node:18-alpine` image is tiny and doesn't have Python. The AWS CLI needs Python. This is normal behavior for a fresh container environment.

---

## 📜 Final Deployment Commands

**To Deploy Updates:**
```bash
git add .
git commit -m "Update hybrid architecture"
git push origin main
```

**To Destroy (Save Money):**
```bash
# 1. Kill Backend
ssh user@dep-system "docker stop hybrid_backend && docker rm hybrid_backend"

# 2. Kill Cloud
cd terraform
terraform destroy -auto-approve
```
