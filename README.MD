# 🚀 SkySense IoT Platform  
**Real-time Sensor Monitoring with Kubernetes, WebSockets & Machine Learning**

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Angular](https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

**Modern IoT Platform for Real-time Sensor Data Processing with Enterprise-Grade Observability**

![GitHub](https://img.shields.io/github/license/pashitox/skysense-iot-platform)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)

## 📋 Table of Contents
- [✨ Features](#-features)
- [🏗️ System Architecture](#️-system-architecture)
- [🚀 Quick Start](#-quick-start)
- [🛠️ Tech Stack](#️-tech-stack)
- [📁 Project Structure](#-project-structure)
- [🔌 API Endpoints](#-api-endpoints)
- [📊 Live Dashboard](#-live-dashboard)
- [🔍 Monitoring & Observability](#-monitoring--observability)
- [🔮 Roadmap](#-roadmap)
- [👨‍💻 Author](#-author)

## ✨ Features

| 🎯 Frontend | 🔧 Backend | 📊 Database | 🛡️ Infrastructure |
|-------------|------------|-------------|-------------------|
| Angular 17 + TypeScript | FastAPI + Python | PostgreSQL 13 | Kubernetes + Istio |
| Real-time WebSocket Dashboard | RESTful API | Time-series Data | Docker Containers |
| Responsive Material UI | WebSocket Server | Automated Backups | Service Mesh |
| Live Data Visualization | Sensor Data Processing | High Performance | GitOps (ArgoCD) |

| 📡 Real-time Features | 🔍 Monitoring | 🚀 DevOps |
|----------------------|---------------|-----------|
| Live Sensor Data Stream | Grafana Dashboards | CI/CD Pipeline |
| WebSocket Connections | Prometheus Metrics | Helm Charts |
| Instant Data Persistence | Kiali Service Mesh | Health Checks |
| Auto-scaling | Jaeger Distributed Tracing | Rolling Updates |

## 🏗️ System Architecture

```mermaid
graph TB
    A[🌐 Web Browser] --> B[🖥️ Frontend<br/>Angular]
    B --> C[🔌 WebSocket<br/>Real-time]
    B --> D[📡 REST API<br/>HTTP]
    
    C --> E[🐍 Backend<br/>FastAPI]
    D --> E
    
    E --> F[🗄️ PostgreSQL<br/>Sensor Data]
    E --> G[📊 Prometheus<br/>Metrics]
    
    H[📱 IoT Sensors] --> I[📡 Message Queue]
    I --> E
    
    E --> J[🔍 Istio<br/>Service Mesh]
    J --> K[📈 Grafana<br/>Monitoring]
    J --> L[🗺️ Kiali<br/>Visualization]
    
    M[⚓ ArgoCD] --> N[☸️ Kubernetes<br/>Orchestration]
    
    style A fill:#ff6b6b
    style B fill:#4ecdc4
    style E fill:#45b7d1
    style F fill:#96ceb4
    style K fill:#feca57
    style L fill:#ff9ff3
```

## 🚀 Quick Start

### Prerequisites
- **Docker & Docker Compose**
- **Minikube** (for local Kubernetes)
- **kubectl** (Kubernetes CLI)

### Installation

```bash
# Clone the repository
git clone https://github.com/pashitox/skysense-iot-platform.git
cd skysense-iot-platform

# Start with Docker Compose (Development)
docker-compose up -d

# Or deploy to Kubernetes (Production)
./deploy-to-k8s.sh
```

### Kubernetes Deployment

```bash
# Create namespace and deploy
kubectl create namespace skysense
kubectl apply -f k8s/ -n skysense

# Check deployment status
kubectl get all -n skysense

# Access the application
echo "🌐 Frontend: http://192.168.49.2:32323"
echo "🔧 Backend API: http://192.168.49.2:30080"
echo "📚 API Docs: http://192.168.49.2:30080/docs"
```

### Environment Configuration

```env
# Database Configuration
POSTGRES_DB=skysense_db
POSTGRES_USER=skysense_user
POSTGRES_PASSWORD=secure_password

# Backend Configuration
DATABASE_URL=postgresql://user:password@postgresql:5432/skysense_db
WEB_CONCURRENCY=4

# Frontend Configuration
API_URL=http://localhost:30080/api
WS_URL=ws://localhost:30080/ws
```

## 🛠️ Tech Stack

### Frontend
- **Angular 17** - Modern TypeScript framework
- **WebSocket API** - Real-time data streaming
- **Material Design** - Professional UI components
- **RxJS** - Reactive programming library

### Backend
- **FastAPI** - High-performance Python API
- **WebSocket** - Bi-directional real-time communication
- **SQLAlchemy** - Database ORM
- **Uvicorn** - ASGI web server

### Database
- **PostgreSQL 13** - Relational database
- **Time-series Data** - Optimized for sensor data
- **Automated Backups** - Data persistence

### Infrastructure
- **Kubernetes** - Container orchestration
- **Istio Service Mesh** - Traffic management & security
- **Docker** - Containerization
- **Prometheus/Grafana** - Monitoring stack

## 📁 Project Structure

```
skysense-iot-platform/
├── 🎨 frontend/                 # Angular 17 Application
│   ├── src/
│   │   ├── app/
│   │   │   ├── components/
│   │   │   │   ├── dashboard/
│   │   │   │   │   ├── dashboard.component.ts
│   │   │   │   │   ├── dashboard.component.html
│   │   │   │   │   └── dashboard.component.css
│   │   │   │   └── sensor-charts/
│   │   │   │       ├── charts.component.ts
│   │   │   │       └── charts.component.html
│   │   │   ├── services/
│   │   │   │   └── websocket.service.ts
│   │   │   └── models/
│   │   │       └── sensor-data.ts
│   │   ├── environments/
│   │   │   ├── environment.ts
│   │   │   └── environment.prod.ts
│   │   └── assets/
│   │       └── env.js
│   ├── package.json
│   ├── angular.json
│   └── Dockerfile
│
├── 🐍 backend/                  # FastAPI Application
│   ├── app/
│   │   ├── main.py              # FastAPI application
│   │   ├── models.py            # SQLAlchemy models
│   │   └── database.py          # Database configuration
│   ├── requirements.txt
│   └── Dockerfile
│
├── ☸️ k8s/                      # Kubernetes Manifests
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── postgresql.yaml
│   └── ingress.yaml
│
├── 📊 monitoring/               # Observability Stack
│   ├── grafana-dashboards/
│   ├── prometheus-alerts/
│   └── kiali-config/
│
├── 🐳 docker-compose.yml        # Development environment
├── 🔧 deploy-to-k8s.sh          # Production deployment script
└── 📄 README.md                 # This file
```

## 🔌 API Endpoints

### WebSocket Endpoints
```bash
# Real-time sensor data stream
ws://localhost:30080/ws/sensors

# Example WebSocket message
{
  "sensor_id": "sensor_1",
  "temperature": 23.5,
  "humidity": 65.2,
  "pressure": 1013.25,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### REST API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | System health check |
| `GET` | `/api/sensors` | Get sensor data (with pagination) |
| `GET` | `/api/sensors/{sensor_id}` | Get data for specific sensor |
| `GET` | `/api/metrics` | System performance metrics |
| `POST` | `/api/sensors` | Submit sensor data (batch) |

### Example API Usage
```bash
# Health check
curl http://localhost:30080/api/health

# Get latest sensor data
curl http://localhost:30080/api/sensors?limit=10

# API Documentation
open http://localhost:30080/docs
```

## 📊 Live Dashboard

![Dashboard Preview](https://via.placeholder.com/800x400/4ECDC4/000?text=SkySense+IOT+Dashboard)

**Real-time Features:**
- 📈 **Live Sensor Metrics** - Temperature, humidity, pressure
- 🔄 **WebSocket Connection** - Real-time data streaming
- 📱 **Responsive Design** - Mobile-first approach
- 🎯 **Data Visualization** - Charts and graphs
- ⚡ **Instant Updates** - Sub-second latency

## 🔍 Monitoring & Observability

### Access Monitoring Tools
```bash
# Kiali - Service Mesh Visualization
kubectl port-forward -n istio-system svc/kiali 20001:20001
# http://localhost:20001 (admin/admin)

# Grafana - Metrics Dashboard
kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80
# http://localhost:3001

# ArgoCD - GitOps Dashboard
kubectl port-forward -n argocd svc/argocd-server 8081:443
# https://localhost:8081
```

### Available Dashboards
- **📊 Kubernetes Cluster Metrics** - Resource usage and performance
- **🔍 SkySense Application Metrics** - Custom application monitoring
- **🗄️ PostgreSQL Performance** - Database health and queries
- **🛡️ Istio Service Mesh** - Traffic flow and security

## 🔮 Roadmap

### ✅ Completed
- [x] Microservices architecture with Kubernetes
- [x] Real-time WebSocket communication
- [x] PostgreSQL database with time-series data
- [x] Angular frontend with live dashboard
- [x] Docker containerization
- [x] Service Mesh with Istio
- [x] Monitoring with Prometheus/Grafana
- [x] GitOps with ArgoCD

### 🚧 In Progress
- [ ] Machine Learning anomaly detection
- [ ] Advanced data visualization
- [ ] Multi-tenant support
- [ ] Advanced alerting system

### 📅 Planned
- [ ] Mobile application (React Native)
- [ ] Edge computing capabilities
- [ ] Advanced analytics dashboard
- [ ] IoT device management
- [ ] Predictive maintenance features

## 👨‍💻 Author

**Pashitox** - Full Stack Developer & IoT Specialist

[![GitHub](https://img.shields.io/badge/GitHub-Pashitox-181717?logo=github)](https://github.com/pashitox)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin)](https://linkedin.com/in/pashitox)

> "Building the future of IoT, one sensor at a time. Transforming real-world data into actionable insights through cutting-edge technology and scalable cloud infrastructure."

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### ⭐ Star us on GitHub!

If this IoT platform helps you in your projects, please give it a star on GitHub!

**SkySense IoT Platform** - Enterprise-grade real-time sensor monitoring 🚀

</div>