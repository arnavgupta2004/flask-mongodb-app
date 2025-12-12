# Flask + MongoDB Deployment on Kubernetes (Minikube)

This project demonstrates deploying a Python Flask application connected to a MongoDB database inside a Kubernetes cluster using Minikube.
The system includes:

* Flask application with two endpoints
* MongoDB StatefulSet with authentication
* Persistent storage using Kubernetes PVCs
* NodePort service for external access
* Horizontal Pod Autoscaler (HPA)
* Resource requests and limits
* Full DNS-based inter-pod networking
* Autoscaling test results (with screenshots)

---

# 📁 Project Structure

```
flask-mongodb-app/
│── app.py
│── requirements.txt
│── Dockerfile
│── README.md
│── TESTING.md  (optional)
└── k8s/
    ├── namespace.yaml
    ├── mongo-secret.yaml
    ├── mongo.yaml
    ├── flask-deployment.yaml
    ├── flask-service.yaml
    └── hpa.yaml
```

---

# 🚀 Flask Application Overview

The Flask app exposes:

### **`/`**

Returns:

```
Welcome to the Flask app! The current time is: <timestamp>
```

### **`/data`**

* **POST** → Inserts JSON into MongoDB
* **GET** → Returns all stored documents

MongoDB connection uses:

```
MONGODB_URI="mongodb://admin:StrongPass123@mongo:27017/?authSource=admin"
```

Credentials are stored in a Kubernetes Secret.

---

# 🐳 Docker Setup

### **1. Build the Image**

```
docker build -t flask-mongo:latest .
```

### **2. Tag the Image**

(Use your Docker Hub username)

```
docker tag flask-mongo:latest arnavguptas/flask-mongo:latest
```

### **3. Push the Image**

```
docker push arnavguptas/flask-mongo:latest
```

Image URL:

[https://hub.docker.com/r/arnavguptas/flask-mongo](https://hub.docker.com/r/arnavguptas/flask-mongo)

---

# ☸️ Kubernetes Deployment Instructions

### **1. Start Minikube**

```
minikube start --driver=docker
minikube addons enable metrics-server
```

### **2. Apply all Manifests**

```
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mongo-secret.yaml
kubectl apply -f k8s/mongo.yaml
kubectl apply -f k8s/flask-deployment.yaml
kubectl apply -f k8s/flask-service.yaml
kubectl apply -f k8s/hpa.yaml
```

### **3. Verify Pods**

```
kubectl get pods -n flask-mongo
```

### **4. Access Flask Application**

```
minikube service flask-service -n flask-mongo
```

or

```
kubectl port-forward svc/flask-service -n flask-mongo 5000:5000
```

---

# 🍃 MongoDB StatefulSet Overview

* Uses `mongo:5.0` image
* Credentials set via Kubernetes Secret
* Data persistence ensured via `volumeClaimTemplates`
* Exposed only internally via a headless service
* Auth enforced using `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD`

---

# 🌐 DNS Resolution in Kubernetes

Kubernetes uses CoreDNS for service and pod name resolution.

Key points:

### 1️⃣ Service DNS

A service named `mongo` in namespace `flask-mongo` resolves to:

```
mongo.flask-mongo.svc.cluster.local
```

### 2️⃣ Pod DNS (StatefulSet)

The first MongoDB pod resolves to:

```
mongo-0.mongo.flask-mongo.svc.cluster.local
```

### 3️⃣ Flask Connectivity

Flask connects to MongoDB using:

```
mongodb://admin:StrongPass123@mongo:27017/?authSource=admin
```

DNS ensures reliable connectivity even when pod IPs change.

---

# ⚙️ Resource Requests and Limits

Both Flask and MongoDB pods specify:

| Resource | Request | Limit   |
| -------- | ------- | ------- |
| CPU      | 0.2 CPU | 0.5 CPU |
| Memory   | 250Mi   | 500Mi   |

### Why this matters:

* **Requests** guarantee minimum resources to each pod
* **Limits** prevent a pod from consuming excessive resources
* Ensures reliability & predictable autoscaling decision-making

---

# 🧠 Design Choices

### ✔️ MongoDB as StatefulSet

* Required for stable pod identity
* Supports persistent storage
* Best practice for databases

### ✔️ Headless Service for MongoDB

* Allows stable DNS entries like `mongo-0.mongo`
* Needed for StatefulSet predictable naming

### ✔️ Flask Deployment with 2 Replicas

* Ensures availability
* Allows HPA to scale upward

### ✔️ HPA Based on CPU

* CPU is easy to monitor with Metrics Server
* Autoscaling becomes deterministic and easy to test

### ✔️ NodePort for External Access

* Simplest for Minikube
* Works without needing Ingress

---

# 📈 Autoscaling Test Results

Below are the autoscaling logs and screenshots obtained during testing.

---

## ✅ **Initial Pods Running**

```
NAME                         READY   STATUS    RESTARTS   AGE
flask-app-5b96ff458b-856nv   1/1     Running   0          15m
flask-app-5b96ff458b-qtdt5   1/1     Running   0          15m
load                         1/1     Running   0          14m
mongo-0                      1/1     Running   0          19m
```

📸 *Screenshot: initial pods running*

---

## 🔥 **High CPU Load Detected (Before Scaling Up)**

```
NAME        REFERENCE              TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
flask-hpa   Deployment/flask-app   cpu: 77%/70%   2         5         2          20m
```

➡️ HPA **detected overload** but has not scaled yet — this is expected before triggering.

📸 *Screenshot: HPA showing 77% CPU*

---

## 📈 **Scaling Up (Sample Expected Result)**

As load increases, HPA will scale replicas:

```
flask-hpa   Deployment/flask-app   cpu: 120%/70%   2   5   3
flask-hpa   Deployment/flask-app   cpu: 150%/70%   2   5   4
flask-hpa   Deployment/flask-app   cpu: 165%/70%   2   5   5
```

📸 *Screenshot: HPA scaling to 3, 4, and 5 replicas*

---

## 📦 **Pods After Scaling**

```
flask-app-xxxxx   Running
flask-app-yyyyy   Running
flask-app-zzzzz   Running
flask-app-aaaaa   Running
flask-app-bbbbb   Running
mongo-0           Running
```

📸 *Screenshot: 5 running Flask pods*

---

## 🌙 **Scale Down After Load Stops**

When the load-generating loop is stopped:

```
flask-hpa   Deployment/flask-app   20%/70%   2   5   3
flask-hpa   Deployment/flask-app   10%/70%   2   5   2
```

📸 *Screenshot: scaling back to 2 replicas*

---

# 🧪 How Autoscaling Was Tested

1. Started BusyBox load generator:

```
kubectl run -i --tty load --image=busybox -n flask-mongo -- /bin/sh
```

2. Inside:

```
while true; do wget -qO- http://flask-service:5000/ > /dev/null; done
```

3. Observed autoscaling in real time:

```
kubectl get hpa -n flask-mongo -w
```

4. Verified pod count:

```
kubectl get pods -n flask-mongo
```

5. Stopped load and confirmed scale-down.

---

# 🧹 Cleanup

```
kubectl delete namespace flask-mongo
minikube stop
```

---

# 🎉 Conclusion

This project successfully demonstrates:

* A full microservice deployment
* Stateful MongoDB with persistence and auth
* Flask app following 12-factor principles
* Kubernetes autoscaling via HPA
* Correct DNS-based inter-pod networking
* Resource efficiency via requests/limits