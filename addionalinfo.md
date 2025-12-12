# ✅ **1. Benefits of Using a Virtual Environment for Python Applications**

Using a virtual environment (`venv`) provides several key advantages when developing Python applications:

### **1️⃣ Dependency Isolation**

Each project has its own isolated Python packages.
This prevents version conflicts between projects (e.g., Flask 2.x in one project vs. Flask 3.x in another).

### **2️⃣ Reproducibility**

A virtual environment ensures everyone working on the project installs the **exact same dependencies**, which makes deployments more stable and predictable.

### **3️⃣ Cleaner System Python**

It prevents installing packages globally, avoiding:

* Breaking system tools
* Conflicting package versions
* Permission issues

### **4️⃣ Simplified Deployment**

You can generate a `requirements.txt` from the virtual environment, making it easy to recreate the same environment on servers, containers, or CI pipelines.

### **5️⃣ Industry Best Practice**

Every modern Python project (Django, Flask, ML notebooks, etc.) uses virtual environments because they improve reliability and maintainability.

---

# ✅ **2. Explanation of Resource Requests and Limits in Kubernetes**

Kubernetes resource management helps ensure fair usage of CPU and memory across pods.

### **Resource Requests**

A *request* specifies the **minimum amount of CPU and memory** a pod needs to run reliably.

* The Kubernetes scheduler uses requests to place the pod on a suitable node.
* It guarantees that this amount of resource will always be available to the pod.

Example used in this project:

```
requests:
  cpu: "200m"
  memory: "250Mi"
```

### **Resource Limits**

A *limit* specifies the **maximum** amount of CPU and memory a pod is allowed to use.

* If a pod exceeds its CPU limit, it gets throttled.
* If it exceeds its memory limit, it can be terminated (OOMKilled).

Example used:

```
limits:
  cpu: "500m"
  memory: "500Mi"
```

### **Why this matters**

* Prevents a single container from consuming all node resources
* Ensures predictable performance
* Allows autoscaling (HPA) to make decisions
* Protects cluster stability

---

# ✅ **3. Design Choices — Explanation & Alternatives Considered**

This section explains *why each major component was chosen*.

---

## **1️⃣ Flask App in a Deployment (Not StatefulSet)**

**Why chosen:**

* Stateless application
* Should scale horizontally
* Pods are interchangeable, no stable identity needed

**Alternatives:**

* StatefulSet (not chosen because Flask does not require persistent identity)

---

## **2️⃣ MongoDB in a StatefulSet (Not Deployment)**

**Why chosen:**

* Databases require stable hostnames (e.g., `mongo-0`)
* Data must persist across restarts
* StatefulSet provides:

  * Persistent Volume Claims per pod
  * Stable DNS names
  * Predictable scaling behavior

**Alternatives:**

* Deployment + PVC (not chosen due to lack of stable pod identity)

---

## **3️⃣ Headless Service for MongoDB**

**Why chosen:**

* Allows predictable DNS hostnames like:

  ```
  mongo-0.mongo.flask-mongo.svc.cluster.local
  ```
* Required for StatefulSets.
* Keeps MongoDB internal and secure.

**Alternative:**

* ClusterIP (simpler but not ideal for StatefulSets)

---

## **4️⃣ NodePort Service for Flask**

**Why chosen:**

* Easiest way to expose the app on Minikube
* Works locally without extra tools
* No need for Ingress controller for this assignment

**Alternative:**

* Ingress (not chosen because it adds complexity)

---

## **5️⃣ Horizontal Pod Autoscaler (HPA) Based on CPU**

**Why chosen:**

* Easy to test and monitor
* CPU is a stable metric provided by Metrics Server
* Works well for web applications

**Alternatives:**

* Autoscale on custom metrics (more complex and not required)

---

## **6️⃣ Resource Requests & Limits**

**Why chosen:**

* Ensures cluster stability
* Prevents pods from using excessive CPU/memory
* Required for proper autoscaling decisions

---

## **7️⃣ Dockerfile using Gunicorn**

**Why chosen:**

* Production-ready WSGI server
* Handles concurrency better than Flask’s built-in server

**Alternatives:**

* Flask’s dev server (not chosen because it is not suitable for production)

---

# ✅ **4. Cookie Point — Testing Scenarios (Autoscaling + Database)**

Below is a ready-to-submit section describing your testing.

---

# ⭐ **Testing Scenarios**

## **1️⃣ MongoDB Connectivity Test**

Command:

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"name": "Arnav", "value": 123}' \
  http://<minikube-ip>:30080/data
```

Expected result:

```
{"status": "Data inserted"}
```

Retrieval:

```
curl http://<minikube-ip>:30080/data
```

Expected:

```json
[ {"name":"Arnav", "value":123} ]
```

---

## **2️⃣ Autoscaling Test (HPA)**

### Step 1 — Start Load Generator

```bash
kubectl run -i --tty load --image=busybox -n flask-mongo -- /bin/sh
```

Inside BusyBox:

```bash
while true; do wget -qO- http://flask-service:5000/ > /dev/null; done
```

### Step 2 — Observe HPA

```bash
kubectl get hpa -n flask-mongo -w
```

Expected sample scaling:

```
cpu: 77%/70% → 3 replicas
cpu: 120%/70% → 4 replicas
cpu: 150%/70% → 5 replicas
```

### Step 3 — Verify Pods Increased

```bash
kubectl get pods -n flask-mongo
```

Expected:

```
flask-app-xxxxx   Running
flask-app-yyyyy   Running
flask-app-zzzzz   Running
flask-app-aaaaa   Running
flask-app-bbbbb   Running
```

---

## **3️⃣ Scale Down Test**

Stop load generator (`Ctrl + C`)

Observe:

```
flask-hpa: cpu dropped to <20%, replicas reduced back to 2
```

---

## Issues Encountered & Fixes

| Issue                       | Cause                          | Fix                                         |
| --------------------------- | ------------------------------ | ------------------------------------------- |
| `InvalidImageName`          | Wrong image name in Deployment | Updated to `arnavguptas/flask-mongo:latest` |
| HPA not scaling             | Metrics Server not enabled     | `minikube addons enable metrics-server`     |
| Port 5000 conflict on macOS | ControlCenter using port 5000  | Used NodePort / different host port         |
| MongoDB auth failures       | Missing `authSource=admin`     | Updated `MONGODB_URI`                       |

