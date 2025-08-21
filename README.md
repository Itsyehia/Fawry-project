# Fawry-project

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Kubernetes cluster (local or cloud)
- kubectl configured
- Python 3.9+ (for local development)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Fawry-project
   ```

2. **Set up Python environment**
   ```bash
   cd flaskapp-database/flaskapp
   pip install -r requirements.txt
   ```

### Kubernetes Deployment

#### Testing Environment
```bash
# Apply base configuration
kubectl apply -k k8s/overlays/testing

# Check deployment status
kubectl get pods,services,ingress

# Access application
curl http://192.168.49.2.nip.io/flask/
```

#### Production Environment
```bash
# Apply production configuration
kubectl apply -k k8s/overlays/production

# Verify deployment
kubectl get pods -l app=flaskapp
kubectl get pods -l app=mysql
```

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

The GitHub Actions workflow (`.github/workflows/flake8.yml`) implements a **three-stage pipeline**:

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

### **Stage 3: Build and Deploy** (`build_and_push`)
```yaml
needs: flake8
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

### **Pipeline Benefits:**
- **Quality Gates**: Each stage must pass before proceeding
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

## 📈 Performance Optimization

### **Application Level**
- **Database Connection Pooling**: Implement connection pooling
- **Caching**: Add Redis for session and data caching
- **Static Assets**: Use CDN for static files

### **Kubernetes Level**
- **Resource Requests/Limits**: Proper resource allocation
- **Horizontal Pod Autoscaler**: Auto-scaling based on CPU/memory
- **Persistent Volume**: SSD storage for database

## 🔄 Future Enhancements

### **Technical Improvements**
- [ ] Implement Redis for session storage
- [ ] Add Prometheus metrics collection
- [ ] Implement Grafana dashboards
- [ ] Add automated backup for MySQL
- [ ] Implement blue-green deployment strategy

---

**Project Developed for Fawry DevOps Internship Program**

*This project demonstrates modern DevOps practices including containerization, Kubernetes orchestration, CI/CD pipelines, comprehensive testing, and production-ready deployment strategies.*