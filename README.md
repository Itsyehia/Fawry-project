# Fawry-project


## 🏛️ Kubernetes Architecture

### Base Components (`k8s/base/`)

#### **ConfigMap** (`configmap.yaml`)
Stores non-sensitive configuration data:
```yaml
MYSQL_DATABASE_USER: root
MYSQL_DATABASE_DB: BucketList
MYSQL_DATABASE_HOST: mysql
FLASK_RUN_PORT: "5002"
```

#### **Secrets** (`secrets/db.env`)
Manages sensitive data like database passwords:
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_DATABASE_PASSWORD`
- `MYSQL_DATABASE`

#### **Deployments** (`deployment.yaml`, `mysql-deployment.yaml`)

**Flask Application Deployment:**
- **Replicas**: 1 (configurable per environment)
- **Health Probes**: 
  - Readiness: `/readiness` endpoint (checks DB connectivity)
  - Liveness: `/healthz` endpoint (basic health check)
- **Resource Limits**: CPU and memory constraints
- **Environment**: Loads config from ConfigMap and Secrets

**MySQL Deployment:**
- **Persistent Storage**: 1Gi PVC for data persistence
- **Health Probes**: Uses `mysqladmin ping` for health checks
- **Custom Image**: Includes pre-loaded schema and stored procedures

#### **Services** (`service.yaml`)
- **MySQL Service**: ClusterIP on port 3306 for internal communication
- **Flask Service**: ClusterIP on port 80, targets container port 5002

#### **Ingress** (`ingress.yaml`)
- **Controller**: Nginx Ingress
- **Path Routing**: `/flask(/|$)(.*)` with regex support
- **Rewrite Rules**: Strips `/flask` prefix before forwarding to service
- **SSL**: Disabled for development (configurable)

#### **Persistent Volume** (`pvc.yaml`)
- **Storage Class**: Default (depends on cluster)
- **Access Mode**: ReadWriteOnce
- **Capacity**: 1Gi for MySQL data

### Environment Overlays

#### **Testing Environment** (`k8s/overlays/testing/`)
- **Scaling**: 1 Flask replica
- **Resources**: Minimal (100m CPU, 128Mi RAM)
- **Hostname**: `192.168.49.2.nip.io` (Minikube compatible)
- **Image Tags**: `latest` for rapid development

#### **Production Environment** (`k8s/overlays/production/`)
- **Scaling**: 3 Flask replicas for high availability
- **Resources**: Production-grade (200-500m CPU, 512Mi-1Gi RAM)
- **Hostname**: `production.local`
- **Image Tags**: `stable` for release versions
- **Additional Features**:
  - Rate limiting (100 requests/minute)
  - Extended timeouts (60s)
  - Body size limits (50MB)

## 🔄 CI/CD Pipeline

The project includes **two comprehensive CI/CD pipelines**:

### **Flask Application Pipeline** (`.github/workflows/flake8.yml`)
A **six-stage pipeline** for the Flask application:

### **Infrastructure Pipeline** (`.github/workflows/terraform.yml`)
A **complete infrastructure-as-code pipeline** that provisions AWS resources and deploys the application:

## 🏗️ Infrastructure Pipeline (terraform.yml)

### **Stage 1: Infrastructure Provisioning** (`terraform`)
```yaml
steps:
  - Setup Terraform 1.8.4
  - Create S3 backend bucket
  - Initialize and validate Terraform
  - Plan and apply infrastructure changes
  - Capture outputs (IPs, ECR URL)
```

**What it provisions:**
- **VPC and Networking**: Custom VPC with public subnets and internet gateway
- **Security Groups**: Comprehensive K3s security group with all required ports
- **EC2 Instances**: 2 instances (control plane + worker) with Ubuntu 22.04
- **ECR Repository**: Private container registry for application images
- **SSH Keys**: Automatically generated key pairs for secure access

### **Stage 2: K3s Cluster Setup** (`ansible`)
```yaml
steps:
  - Generate dynamic inventory from Terraform outputs
  - Wait for SSH availability on all instances  
  - Run Ansible playbook to setup K3s cluster
  - Configure control plane and join worker nodes
```

**What it configures:**
- **K3s Control Plane**: Installs K3s server with TLS configuration
- **K3s Worker**: Joins worker node to the cluster
- **Docker & AWS CLI**: Installs required tools on all nodes
- **ECR Authentication**: Configures Docker to pull from ECR

### **Stage 3: Application Deployment** (`kubectl`)
```yaml
steps:
  - Copy kubeconfig from control plane
  - Deploy Flask app using Kustomize overlays
  - Wait for deployments to be ready
  - Run health checks and display access URLs
```

**What it deploys:**
- **Nginx Ingress Controller**: Installs and configures ingress controller with NodePort access
- **Flask Application**: Multi-replica Flask app with health probes
- **MySQL Database**: Persistent MySQL with pre-loaded schema
- **Services**: ClusterIP services for internal communication
- **Ingress**: Nginx ingress with dynamic host configuration for external access

### **Security Group Configuration** ✅ **FIXED**

The security group configuration has been **consolidated and optimized**:

**Before (Problem):**
- ❌ Duplicate security groups in network and compute modules
- ❌ Inconsistent port configurations
- ❌ Resource conflicts and management issues

**After (Solution):**
- ✅ **Single K3s Security Group** in network module
- ✅ **Comprehensive port configuration**:
  ```hcl
  # SSH Access
  port 22: SSH access from anywhere
  
  # Web Traffic  
  port 80/443: HTTP/HTTPS traffic
  
  # Kubernetes
  port 6443: Kubernetes API server
  port 5002: Flask application direct access
  port 30000-32767: NodePort service range
  
  # Internal Cluster Communication
  port 0-65535: Self-referencing for cluster traffic
  ```
- ✅ **Proper module dependencies**: Compute module uses security group from network module

### **Application Access Points** ✅ **UPDATED**

After successful deployment, the application is accessible via **Nginx Ingress**:

1. **Primary Access (Ingress)**: `http://<control-plane-ip>.nip.io/flask/`
2. **Direct Ingress Controller**: `http://<control-plane-ip>:30080/flask/`
3. **Health Endpoints via Ingress**: 
   - Liveness: `http://<control-plane-ip>.nip.io/flask/healthz`
   - Readiness: `http://<control-plane-ip>.nip.io/flask/readiness`

**Benefits of Ingress Setup:**
- ✅ **Production-ready routing** with path-based and host-based rules
- ✅ **SSL termination** capability (can be enabled for HTTPS)
- ✅ **Load balancing** across multiple Flask replicas
- ✅ **Path rewriting** for clean URLs
- ✅ **Centralized ingress management** for multiple services

### **Flask Application Pipeline** (`.github/workflows/flake8.yml`)

### **Stage 1: Test and Coverage** (`test_and_coverage`)
```yaml
runs-on: ubuntu-latest
steps:
  - Checkout code
  - Setup Python 3.11
  - Install dependencies (Flask, pytest, pytest-cov)
  - Run test suite with coverage reporting
  - Upload coverage artifacts
```

**What it does:**
- Runs all unit tests in `flaskapp-database/flaskapp/tests/`
- Generates HTML and XML coverage reports
- Ensures code quality and functionality before proceeding

### **Stage 2: Code Quality** (`flake8`)
```yaml
needs: test_and_coverage
steps:
  - Install flake8 linter
  - Run code style checks
  - Enforce PEP 8 compliance
```

**What it does:**
- Checks Python code style and formatting
- Identifies potential issues like unused imports, trailing whitespace
- Maintains consistent code quality across the project

### **Stage 3: Secret Detection** (`gitleaks`)
```yaml
needs: flake8
steps:
  - Checkout code
  - Run Gitleaks Secret Scan
  - Detect secrets in repository
  - Continue on error for non-blocking scan
```

**What it does:**
- Scans the entire repository for exposed secrets and sensitive information
- Detects API keys, passwords, tokens, and other credentials
- Uses redaction to safely report findings without exposing actual secrets
- Continues pipeline execution even if secrets are found (for visibility)

### **Stage 4: CodeQL Security Analysis** (`codeql`)
```yaml
needs: gitleaks
steps:
  - Initialize CodeQL for Python
  - Run CodeQL static analysis
  - Upload results to GitHub Security tab
```

**What it does:**
- Performs static code analysis using GitHub CodeQL
- Detects vulnerabilities such as SQL injection, unsafe deserialization, and XSS
- Uploads detailed findings to GitHub's Security tab for visibility

### **Stage 5: Build and Deploy** (`build_and_push`)
```yaml
needs: CodeQL
steps:
  - Setup Docker Buildx
  - Login to Docker Hub
  - Build Flask application image
  - Build MySQL database image
  - Push images with 'latest' tag
```

**What it does:**
- Creates production-ready Docker images
- Pushes to Docker Hub registry
- Enables automated deployments to Kubernetes

### **Stage 6: Trivy Vulnerability Scan (`trivy_scan`)
```yaml
needs: build_and_push
steps:
  - Install Trivy security scanner
  - Scan Flask application Docker image
  - Scan MySQL Docker image
  - Upload vulnerability reports as artifacts
```

**What it does:**
- Scans container images for known CVEs (Critical/High/Medium vulnerabilities)
- Produces JSON reports for both Flask and MySQL images
- Uploads reports as artifacts for auditing
- Provides an additional security gate before deployment

### **Pipeline Benefits:**
- **Quality Gates**: Each stage must pass before proceeding
- **Security by Design**: Integrated Gitleaks, CodeQL and Trivy ensure vulnerabilities and secrets are caught early
- **Fast Feedback**: Developers get immediate feedback on issues
- **Automated Deployment**: Successful builds trigger image updates
- **Rollback Capability**: Tagged images enable easy rollbacks

## 🧪 Testing Strategy

### **Test Suite Overview** (`flaskapp-database/flaskapp/tests/test_app.py`)

The project includes **comprehensive unit tests** covering all application endpoints and scenarios:

#### **Authentication Tests**
```python
def test_signup_success()           # Valid user registration
def test_signup_missing_fields()    # Validation error handling
def test_validate_login_success()   # Successful login flow
def test_validate_login_wrong_password()  # Authentication failure
```

#### **Session Management Tests**
```python
def test_user_home_unauthorized()   # Access control
def test_logout()                   # Session cleanup
def test_show_add_wish_with_session()  # Authorized access
```

#### **CRUD Operations Tests**
```python
def test_add_wish_success()         # Create functionality
def test_get_wish_success()         # Read functionality
def test_add_wish_db_error()        # Error handling
```

#### **Health Check Tests**
```python
def test_healthz()                  # Liveness probe
def test_readiness_success()        # Readiness probe
def test_readiness_failure()        # Failure scenarios
```

### **Testing Features:**
- **Mocking**: Database connections mocked for isolated testing
- **Coverage**: Comprehensive test coverage reporting
- **Edge Cases**: Error conditions and boundary testing
- **Integration**: End-to-end workflow testing

## 🔧 Configuration Management

### **Environment Variables**
```bash
# Database Configuration
MYSQL_DATABASE_USER=root
MYSQL_DATABASE_PASSWORD=<secret>
MYSQL_DATABASE_DB=BucketList
MYSQL_DATABASE_HOST=mysql

# Flask Configuration
FLASK_APP=app.py
FLASK_ENV=production
FLASK_RUN_PORT=5002
```

### **Kubernetes Configuration**
- **ConfigMaps**: Non-sensitive configuration
- **Secrets**: Database passwords and sensitive data
- **Kustomize**: Environment-specific customizations

## 🚨 Monitoring and Health Checks

### **Application Endpoints**
- **`/healthz`**: Basic liveness check (returns "ok")
- **`/readiness`**: Database connectivity check
- **Error Logging**: Comprehensive error tracking

## 🔒 Security Considerations

### **Application Security**
- **Session Management**: Secure Flask sessions
- **Input Validation**: Form data validation
- **SQL Injection Prevention**: Stored procedures and parameterized queries
- **Error Handling**: Secure error messages

### **Infrastructure Security**
- **Secrets Management**: Kubernetes secrets for sensitive data
- **Network Policies**: Service-to-service communication
- **Resource Limits**: Prevent resource exhaustion
- **Image Security**: Regular base image updates

## 🚀 Deployment Guide

### **Development Deployment**
1. Start local Kubernetes cluster
2. Apply testing overlay: `kubectl apply -k k8s/overlays/testing`
3. Access via: `http://192.168.49.2.nip.io/flask/`

### **Production Deployment**
1. Configure production Kubernetes cluster
2. Update secrets in `k8s/base/secrets/`
3. Apply production overlay: `kubectl apply -k k8s/overlays/production`
4. Configure DNS for `production.local`
5. Monitor deployment: `kubectl get pods,services,ingress`

### **Scaling Operations**
```bash
# Scale Flask application
kubectl scale deployment flaskapp --replicas=5

# Rolling update
kubectl rollout status deployment/flaskapp
```

## 🛠️ Troubleshooting

### **Common Issues**

#### **Database Connection Errors**
```bash
# Check MySQL pod status
kubectl logs -l app=mysql

# Verify connectivity
kubectl exec -it <flask-pod> -- nc -z mysql 3306
```

#### **Ingress Not Working**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify ingress rules
kubectl describe ingress flaskapp-ingress
```

#### **Application Errors**
```bash
# Check application logs
kubectl logs -l app=flaskapp

# Debug readiness probe
kubectl exec -it <flask-pod> -- curl localhost:5002/readiness
```

## 🔄 Future Enhancements

### **Technical Improvements**
- [ ] Add Prometheus metrics collection
- [ ] Implement Grafana dashboards
- [ ] Add automated backup for MySQL

---

**Project Developed for Fawry DevOps Internship Program**

*This project demonstrates modern DevOps practices including containerization, Kubernetes orchestration, CI/CD pipelines, comprehensive testing, and production-ready deployment strategies.*