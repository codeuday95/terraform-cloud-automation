# 🎯 Hit Counter

A real-time hit counter web application built with **Node.js**, **Express**, **MongoDB**, and **WebSockets**. Deployable via **Docker Compose** or **Kubernetes**.

---

## 📋 Table of Contents

- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Run with Docker Compose](#run-with-docker-compose)
  - [Run with Kubernetes](#run-with-kubernetes)
- [API Endpoints](#api-endpoints)
- [Environment Variables](#environment-variables)
- [Kubernetes Resources](#kubernetes-resources)

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────┐
│                   Browser Client                 │
│          (HTML + jQuery + WebSocket)              │
└──────────┬──────────────────┬────────────────────┘
           │ HTTP (REST)      │ WebSocket (ws://)
           ▼                  ▼
┌──────────────────────────────────────────────────┐
│              Node.js / Express Server            │
│                   (Port 3000)                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
│  │  GET /hits  │  │ POST /hits │  │ GET /stage │ │
│  └────────────┘  └────────────┘  └────────────┘ │
│              WebSocket Server (ws)               │
└──────────────────────┬───────────────────────────┘
                       │ Mongoose
                       ▼
┌──────────────────────────────────────────────────┐
│                 MongoDB (Port 27017)             │
│              Collection: hits                    │
└──────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer       | Technology                 |
| ----------- | -------------------------- |
| Frontend    | HTML, CSS, jQuery          |
| Backend     | Node.js, Express           |
| Database    | MongoDB 4.4.6              |
| Real-time   | WebSocket (`ws` library)   |
| ORM         | Mongoose                   |
| Containers  | Docker, Docker Compose     |
| Orchestration | Kubernetes (AKS-ready)   |
| Secrets     | Azure Key Vault + CSI Driver |

---

## 📁 Project Structure

```
hit-counter/
├── index.js               # Express server + WebSocket + API routes
├── package.json           # Node.js dependencies
├── NodeDockerfile          # Dockerfile for the Node.js app
├── MongoDockerfile         # Dockerfile for MongoDB with init script
├── mongodb-init.js        # MongoDB initialization script (creates user)
├── docker-compose.yaml    # Docker Compose for local development
├── k8-hitcounter.yaml     # Kubernetes manifests (Deployment, Service, HPA, StatefulSet)
├── scprovider.yaml        # Azure Key Vault SecretProviderClass
├── public/
│   ├── index.html         # Frontend UI
│   └── style.css          # Styling
└── Readme.md              # This file
```

---

## 🚀 Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- (Optional) [kubectl](https://kubernetes.io/docs/tasks/tools/) & a Kubernetes cluster for K8s deployment

### Run with Docker Compose

```bash
# Build and start both containers
docker compose up --build -d

# Verify containers are running
docker compose ps

# View application logs
docker compose logs -f node

# Stop the application
docker compose down

# Stop and remove volumes (reset database)
docker compose down -v
```

**Access the app:** Open [http://localhost](http://localhost) in your browser.

| Service  | Host Port | Container Port |
| -------- | --------- | -------------- |
| Node App | `80`      | `3000`         |
| MongoDB  | `27017`   | `27017`        |

### Run with Kubernetes (Generic)

> **Note:** The K8s manifests reference Azure Container Registry images. Update the image names in `k8-hitcounter.yaml` if using a different registry.

```bash
# Apply the SecretProviderClass (Azure Key Vault integration)
kubectl apply -f scprovider.yaml

# Deploy the application
kubectl apply -f k8-hitcounter.yaml

# Check deployment status
kubectl get pods
kubectl get svc hitcounter
```

For Minikube-specific instructions and local Kubernetes hardening, see `minikube/Readme.md`.

---

## 📡 API Endpoints

| Method | Endpoint | Description                    | Response Example      |
| ------ | -------- | ------------------------------ | --------------------- |
| `GET`  | `/`      | Serves the frontend UI         | HTML page             |
| `GET`  | `/hits`  | Returns current hit count      | `{ "hits": 52 }`     |
| `POST` | `/hits`  | Increments and returns count   | `{ "hits": 53 }`     |
| `GET`  | `/stage` | Returns `STAGE` env variable   | `{ "stage": "DEV" }` |

### WebSocket

The server broadcasts the updated hit count to all connected clients in real-time via WebSocket whenever `POST /hits` is called.

---

## ⚙️ Environment Variables

| Variable            | Description                         | Required | Default |
| ------------------- | ----------------------------------- | -------- | ------- |
| `CONNECTION_STRING` | MongoDB connection URI              | ✅       | —       |
| `STAGE`             | Deployment stage label (DEV/PROD)   | ❌       | —       |

**Docker Compose** sets these automatically. For **Kubernetes**, `CONNECTION_STRING` is pulled from Azure Key Vault via the CSI Secrets Store driver.

---

## ☸️ Kubernetes Resources

The `k8-hitcounter.yaml` defines:

| Resource         | Name                    | Description                              |
| ---------------- | ----------------------- | ---------------------------------------- |
| **Deployment**   | `hitcounter`            | Node.js app (1 replica, auto-scales)     |
| **Service**      | `hitcounter`            | LoadBalancer exposing port 80 → 3000     |
| **Service**      | `hitcounter-database`   | ClusterIP for MongoDB on port 27017      |
| **HPA**          | `hitcounter-autoscaler` | Scales 3–10 replicas at 50% CPU          |
| **StatefulSet**  | `hitcounter-database`   | MongoDB with stable storage              |

The `scprovider.yaml` defines:

| Resource                | Name           | Description                                  |
| ----------------------- | -------------- | -------------------------------------------- |
| **SecretProviderClass** | `azure-kvname` | Syncs `CONNECTION_STRING` from Azure Key Vault |

---

## ✅ Production-Hardening (Overview)

This repo includes production-style safeguards (probes, resource limits, non-root security context, autoscaling, and MongoDB replica set). The full Minikube-specific breakdown is documented in `minikube/Readme.md`.

---

## 🔧 Docker Images

### Node App (`NodeDockerfile`)

- **Base:** `node:20`
- Copies `package.json`, installs dependencies, then copies app source
- Exposes port `3000`

### MongoDB (`MongoDockerfile`)

- **Base:** `mongo:4.4.6`
- Copies `mongodb-init.js` into `/docker-entrypoint-initdb.d/` for auto-initialization
- Creates a `hit-counter-user` with `readWrite` access to the `hit-counter` database
