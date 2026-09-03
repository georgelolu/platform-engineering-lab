# Platform Engineering Lab

A hands-on Platform Engineering laboratory demonstrating production-oriented practices demonstrating how to build, deploy, expose, monitor, and continuously deliver a containerized application using **Nomad, Consul, APISIX, GitHub Actions, Docker, Prometheus, and Grafana**.

The project is deployed on an **AWS EC2 instance** and uses a **GitHub Actions self-hosted runner** to perform automated deployment directly to Nomad.

---

## 🚀 Project Overview

The goal of this project is to demonstrate the core capabilities of an internal developer platform:

* Automated application testing
* Container image creation
* Immutable container image versioning
* GitHub Container Registry integration
* Self-hosted CI/CD execution
* Container orchestration with Nomad
* Service discovery with Consul
* API routing with APISIX
* Application metrics with Prometheus
* Monitoring and visualization with Grafana
* Automated deployment health verification
* Persistent infrastructure services
* Secure administration credentials
* Reproducible configuration

### Platform workflow

```text
Developer
    │
    │ git push
    ▼
GitHub Repository
    │
    ▼
GitHub Actions
    │
    ├── Run Python tests
    │
    ├── Build Docker image
    │
    └── Push image to GHCR
            │
            ▼
    EC2 Self-Hosted Runner
            │
            ▼
          Nomad
            │
            ├──────────────► Consul
            │                Service Discovery
            │
            ▼
     Platform Application
          :8080
            │
            ▼
          APISIX
           :80
            │
            ▼
          Users

Application
    │
    │ /metrics
    ▼
Prometheus
    │
    ▼
Grafana
```

---

# 🏗️ Architecture

The platform consists of the following major components.

| Component          | Purpose                                   |
| ------------------ | ----------------------------------------- |
| AWS EC2            | Hosts the platform environment            |
| Docker             | Container runtime                         |
| Nomad              | Application orchestration                 |
| Consul             | Service discovery and health registration |
| APISIX             | API Gateway and HTTP routing              |
| GitHub Actions     | CI/CD automation                          |
| Self-hosted Runner | Executes deployment directly on EC2       |
| GHCR               | Stores immutable application images       |
| Prometheus         | Metrics collection                        |
| Grafana            | Monitoring and visualization              |
| Flask              | Demo application                          |
| Pytest             | Application testing                       |

---

# 🔄 CI/CD Pipeline

Every push to the `main` branch triggers the GitHub Actions pipeline.

```text
Git Push
   │
   ▼
Test Application
   │
   │ pytest
   ▼
Build Docker Image
   │
   ▼
Push Image to GHCR
   │
   ▼
EC2 Self-Hosted Runner
   │
   ▼
Deploy to Nomad
   │
   ▼
Verify Nomad Deployment
   │
   ▼
Verify APISIX
   │
   ▼
Verify Application Metrics
   │
   ▼
Deployment Successful
```

## CI/CD stages

### 1. Application tests

The pipeline installs Python dependencies and runs:

```bash
pytest -v
```

The application currently contains tests covering:

* Home endpoint
* Health endpoint

---

### 2. Docker image build

The application is packaged using the Dockerfile located at:

```text
app/Dockerfile
```

Images are pushed to GitHub Container Registry.

Images use the Git commit SHA as the tag:

```text
ghcr.io/georgelolu/platform-engineering-lab:<commit-sha>
```

This provides immutable deployment versions.

---

### 3. Self-hosted runner

Deployment jobs execute on an AWS EC2 self-hosted GitHub Actions runner.

Runner labels:

```text
self-hosted
linux
x64
nomad
```

The runner has access to:

* Docker
* Nomad
* The application environment
* APISIX
* Monitoring services

---

### 4. Nomad deployment

The deployment job runs:

```bash
nomad job run \
  -var="IMAGE=$IMAGE" \
  nomad/platform-demo.nomad
```

The Docker image is passed into the Nomad job dynamically.

---

### 5. Automated deployment verification

The pipeline does not simply deploy and assume success.

It checks:

* Deployment status
* Desired allocations
* Placed allocations
* Healthy allocations
* Unhealthy allocations

The pipeline only continues when the Nomad deployment becomes healthy.

---

### 6. APISIX verification

The pipeline tests the application through APISIX:

```bash
curl http://127.0.0.1/platform-demo/health
```

Expected response:

```text
healthy
```

---

### 7. Metrics verification

The pipeline also verifies that the application exposes Prometheus metrics:

```bash
curl http://127.0.0.1:8080/metrics
```

The deployment is considered successful only after the application metrics endpoint is confirmed.

---

# 📦 Application

The demo application is a lightweight Flask service.

Available endpoints:

| Endpoint   | Purpose              |
| ---------- | -------------------- |
| `/`        | Application response |
| `/health`  | Health check         |
| `/metrics` | Prometheus metrics   |

Example:

```bash
curl http://127.0.0.1:8080/
```

Response:

```text
Hello from the Platform Engineering Lab!
```

Health check:

```bash
curl http://127.0.0.1:8080/health
```

Response:

```text
healthy
```

Metrics:

```bash
curl http://127.0.0.1:8080/metrics
```

---

# 🐳 Docker

The application is containerized using Docker.

Build locally:

```bash
docker build -t platform-demo:local ./app
```

Run:

```bash
docker run --rm \
  -p 8080:8080 \
  platform-demo:local
```

Test:

```bash
curl http://127.0.0.1:8080/health
```

---

# 🧭 Nomad

Nomad manages the application workload.

Job definition:

```text
nomad/platform-demo.nomad
```

The job:

* Runs as a service
* Uses Docker
* Allocates CPU and memory
* Exposes port `8080`
* Registers the service with Consul
* Performs HTTP health checks

Validate:

```bash
nomad job validate nomad/platform-demo.nomad
```

Plan:

```bash
nomad job plan nomad/platform-demo.nomad
```

Run:

```bash
nomad job run nomad/platform-demo.nomad
```

Check status:

```bash
nomad job status platform-demo
```

Check allocations:

```bash
nomad job allocations platform-demo
```

---

# 🔎 Consul Service Discovery

Consul provides service registration and discovery for the application.

The Nomad service definition registers:

```text
platform-demo
```

Check the registered service:

```bash
curl -s \
  http://127.0.0.1:8500/v1/catalog/service/platform-demo
```

Check the Consul leader:

```bash
curl -fsS \
  http://127.0.0.1:8500/v1/status/leader
```

Consul also performs service health checking through the Nomad service definition.

---

# 🌐 APISIX API Gateway

APISIX provides the external HTTP entry point for the application.

Traffic flow:

```text
Client
  │
  ▼
APISIX :80
  │
  ▼
Platform Application :8080
```

Application route:

```text
/platform-demo
```

Health check through APISIX:

```bash
curl http://127.0.0.1/platform-demo/health
```

Expected:

```text
healthy
```

Application through APISIX:

```bash
curl http://127.0.0.1/platform-demo/
```

Expected:

```text
Hello from the Platform Engineering Lab!
```

---

# 🔐 APISIX Security

The APISIX Admin API is protected using an environment variable.

The real credential is stored locally in:

```text
apisix/.env
```

The file is intentionally excluded from Git.

```text
.env
```

is protected through `.gitignore`.

A safe example configuration is provided:

```text
apisix/.env.example
```

Example:

```text
APISIX_ADMIN_KEY=replace-with-a-strong-secret
```

The APISIX configuration references the environment variable rather than storing the real credential:

```yaml
key: ${{APISIX_ADMIN_KEY}}
```

The admin credential was also rotated and the previous credential was verified to be rejected.

### Security principles demonstrated

* Secrets are not committed to Git
* `.env` is ignored
* `.env.example` contains only a placeholder
* Administrative authentication is required
* Credentials are rotated
* Old credentials are invalidated

---

# 📊 Monitoring

The platform includes Prometheus and Grafana.

## Prometheus

Prometheus scrapes:

```text
platform-demo: /metrics
```

Prometheus is available on:

```text
:9090
```

Health check:

```bash
curl -fsS http://127.0.0.1:9090/-/healthy
```

Expected:

```text
Prometheus Server is Healthy.
```

The application Prometheus target is:

```text
172.31.17.49:8080
```

---

## Grafana

Grafana provides monitoring dashboards.

Grafana is available on:

```text
:3000
```

Check:

```bash
curl -I http://127.0.0.1:3000
```

The expected response redirects to the Grafana login page.

---

# 💾 Persistent Services

The platform was tested for service persistence and automatic restart.

APISIX and etcd use:

```yaml
restart: unless-stopped
```

Prometheus and Grafana also use persistent Docker volumes.

Docker itself is configured as a system service.

The environment was tested after an EC2 reboot.

Following reboot, the following services successfully returned:

* Docker
* Nomad
* Consul
* APISIX
* etcd
* Prometheus
* Grafana
* Platform application

The APISIX application route and monitoring endpoints were also re-tested successfully.

---

# 🧪 Testing

Application tests:

```bash
cd app
pytest -v
```

Expected:

```text
2 passed
```

Nomad validation:

```bash
nomad job validate nomad/platform-demo.nomad
```

Nomad deployment:

```bash
nomad job status platform-demo
```

Application health:

```bash
curl http://127.0.0.1/platform-demo/health
```

APISIX routing:

```bash
curl http://127.0.0.1/platform-demo/
```

Prometheus:

```bash
curl http://127.0.0.1:9090/-/healthy
```

Grafana:

```bash
curl -I http://127.0.0.1:3000
```

---

# 📁 Project Structure

```text
platform-engineering-lab/
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml
│
├── app/
│   ├── Dockerfile
│   ├── app.py
│   ├── requirements.txt
│   └── test_app.py
│
├── apisix/
│   ├── .env
│   ├── .env.example
│   ├── config.yaml
│   ├── docker-compose.yml
│   └── config.yaml.backup
│
├── monitoring/
│   ├── docker-compose.yml
│   └── prometheus/
│       └── prometheus.yml
│
├── nomad/
│   └── platform-demo.nomad
│
├── .gitignore
├── LICENSE
└── README.md
```

> `apisix/.env` contains the local administrative credential and is intentionally excluded from version control.

---

# 🚀 Deployment

## Prerequisites

The lab requires:

* AWS EC2
* Ubuntu
* Docker
* Nomad
* Consul
* Git
* GitHub repository
* GitHub Container Registry access
* GitHub Actions self-hosted runner

---

## Start APISIX

```bash
cd ~/platform-engineering-lab/apisix
docker compose up -d
```

Verify:

```bash
docker compose ps
```

---

## Start monitoring

```bash
cd ~/platform-engineering-lab/monitoring
docker compose up -d
```

Verify:

```bash
docker compose ps
```

---

## Deploy application

```bash
cd ~/platform-engineering-lab

nomad job plan nomad/platform-demo.nomad

nomad job run nomad/platform-demo.nomad
```

Verify:

```bash
nomad job status platform-demo
```

---

# 🔄 Rollback Strategy

The CI/CD pipeline uses immutable Git commit SHA image tags.

For example:

```text
ghcr.io/georgelolu/platform-engineering-lab:<commit-sha>
```

This prevents deployments from depending on a mutable `latest` image.

If a deployment fails, a previously known-good image can be redeployed by passing its SHA:

```bash
nomad job run \
  -var="IMAGE=ghcr.io/georgelolu/platform-engineering-lab:<known-good-sha>" \
  nomad/platform-demo.nomad
```

This provides a straightforward application rollback mechanism.

---

# 🛠️ Troubleshooting

## Check Nomad

```bash
sudo systemctl status nomad
```

```bash
nomad node status
```

```bash
nomad job status platform-demo
```

---

## Check Consul

```bash
consul members
```

```bash
curl -fsS \
  http://127.0.0.1:8500/v1/status/leader
```

---

## Check Docker

```bash
sudo systemctl status docker
```

```bash
docker ps
```

---

## Check APISIX

```bash
cd ~/platform-engineering-lab/apisix
docker compose ps
```

Logs:

```bash
docker logs apisix
```

Test:

```bash
curl http://127.0.0.1/platform-demo/health
```

---

## Check Prometheus

```bash
cd ~/platform-engineering-lab/monitoring
docker compose ps
```

```bash
curl -fsS \
  http://127.0.0.1:9090/-/healthy
```

---

## Check Grafana

```bash
curl -I \
  http://127.0.0.1:3000
```

---

# 🔒 Security Checklist

Before considering the platform production-ready, verify:

* [x] No APISIX admin credential committed to Git
* [x] `.env` ignored
* [x] `.env.example` provided
* [x] APISIX admin credential rotated
* [x] Previous credential rejected
* [x] Immutable image tags used
* [x] Application health checks enabled
* [x] Nomad deployment health verified
* [x] Prometheus metrics exposed
* [x] Infrastructure restart policies configured

### Production improvements

For a production deployment, consider:

* AWS Secrets Manager
* IAM least privilege
* AWS Systems Manager Session Manager
* Private subnets
* Restricted security groups
* TLS for administrative and application traffic
* HTTPS certificates
* APISIX rate limiting
* Centralized logging
* Alertmanager
* Infrastructure as Code
* Multi-node Nomad cluster
* Highly available Consul cluster
* Highly available monitoring
* Automated backup and disaster recovery

---

# 📈 Project Results

The completed laboratory demonstrates an end-to-end platform engineering workflow:

```text
                    GitHub
                       │
                       ▼
                GitHub Actions
                       │
              ┌────────┴────────┐
              │                 │
            pytest           Docker
              │                 │
              │                GHCR
              │                 │
              └────────┬────────┘
                       │
                       ▼
              EC2 Self-Hosted Runner
                       │
                       ▼
                    Nomad
                       │
              ┌────────┴─────────┐
              │                  │
              ▼                  ▼
         Application          Consul
           :8080           Discovery/Health
              │
              ▼
            APISIX
              :80
              │
              ▼
            Users

Application Metrics
       │
       ▼
   Prometheus
       │
       ▼
     Grafana
```

---

# 🎯 Skills Demonstrated

This project demonstrates practical experience with:

### Cloud

* AWS EC2
* Linux administration
* Cloud networking
* Infrastructure operations

### Containers

* Docker
* Docker Compose
* Container image management
* GitHub Container Registry

### Platform Engineering

* HashiCorp Nomad
* Consul
* Service discovery
* Health checks
* Workload orchestration

### CI/CD

* GitHub Actions
* Self-hosted runners
* Automated testing
* Automated Docker builds
* Immutable image deployment
* Automated deployment verification
* Rollback using immutable versions

### API Management

* Apache APISIX
* API routing
* Admin API security
* Environment-based secrets

### Observability

* Prometheus
* Grafana
* Application metrics
* Health monitoring

### Security

* Secret management
* Credential rotation
* Git secret protection
* Least-privilege-oriented architecture
* Administrative access controls

---

# 🧠 Lessons Learned

The project demonstrated several important operational principles:

1. **Deployment should be verified, not assumed.**
2. **Container images should use immutable versions.**
3. **Secrets should never be stored directly in tracked configuration files.**
4. **Service discovery should be separated from application deployment.**
5. **Health checks are essential for automated deployment decisions.**
6. **Monitoring should be part of the platform rather than an afterthought.**
7. **Infrastructure services should survive expected host restarts.**
8. **Rollback requires keeping known-good application versions available.**
9. **Self-hosted runners can tightly integrate CI/CD with infrastructure.**
10. **A platform should automate repetitive operational tasks wherever practical.**

---

# 🔮 Future Improvements

Potential next steps include:

* Terraform-based EC2 provisioning
* Automated Nomad cluster provisioning
* Multi-node Nomad
* Multi-node Consul
* APISIX HTTPS/TLS
* APISIX rate limiting
* Alertmanager
* Node Exporter
* Host-level dashboards
* Centralized logging
* AWS Secrets Manager integration
* Automated infrastructure deployment
* Automated disaster recovery testing
* Blue/green or canary deployments
* Developer self-service deployment templates

---

# 👨‍💻 Author

**George Omololu Akinbi**

Cloud & DevOps Engineer

GitHub:

https://github.com/Georgelolu

---

## License

This project is provided for educational, research, and portfolio purposes.

