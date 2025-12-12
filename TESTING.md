# **TESTING.md**

# Testing Scenarios for Flask + MongoDB Kubernetes Deployment

This document describes how the Flask application and MongoDB StatefulSet were tested after deployment to Minikube.
It includes tests for:

1. MongoDB connectivity
2. Data insertion and retrieval
3. Flask service accessibility
4. Horizontal Pod Autoscaling (HPA)
5. Failure cases and fixes (cookie-point section)

---

# **1. Verify All Pods Are Running**

After applying all Kubernetes manifests:

```bash
kubectl get pods -n flask-mongo
```

**Expected Output:**

```
NAME                          READY   STATUS    RESTARTS   AGE
mongo-0                       1/1     Running   0          XXs
flask-app-xxxxx               1/1     Running   0          XXs
flask-app-yyyyy               1/1     Running   0          XXs
```

This confirms MongoDB + 2 Flask replicas are running.

---

# ✅ **2. Test the Flask Root Endpoint (`/`)**

```
minikube service flask-service -n flask-mongo --url
```

Suppose it gives:

```
http://192.168.49.2:30080
```

Test the root endpoint:

```bash
curl http://192.168.49.2:30080/
```

**Expected Response:**

```
Welcome to the Flask app! The current time is: 2025-03-12 14:21:38.123456
```

---

# ✅ **3. Test Data Insertion (POST /data)**

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"username":"arnav","score":100}' \
  http://192.168.49.2:30080/data
```

**Expected Response:**

```
{"status": "Data inserted"}
```

A new document is now stored inside MongoDB.

---

# ✅ **4. Test Data Retrieval (GET /data)**

```bash
curl http://192.168.49.2:30080/data
```

**Expected Response Example:**

```json
[
  {"username": "arnav", "score": 100},
  {"username": "rahul", "score": 50}
]
```

This confirms successful read/write operations with MongoDB authentication enabled.

---

# ⭐ **5. HPA Autoscaling Test (Cookie Point)**

## **5.1 Verify HPA Installed**

```bash
kubectl get hpa -n flask-mongo
```

Expected:

```
flask-hpa   Deployment/flask-app   2/5   70%   <unknown>   2     2m
```

---

# 🔥 5.2 Generate Load to Trigger Scaling

Start a BusyBox pod:

```bash
kubectl run -i --tty load --image=busybox -n flask-mongo -- /bin/sh
```

Inside the BusyBox shell, run continuous traffic:

```bash
while true; do wget -qO- http://flask-service:5000/ > /dev/null; done
```

This loop generates constant CPU load.

---

# 📈 5.3 Watch HPA Trigger Scaling

In a separate terminal:

```bash
kubectl get hpa -n flask-mongo -w
```

**Expected Behavior:**

```
flask-hpa   Deployment/flask-app   2/5   70%   85%   3     1m
flask-hpa   Deployment/flask-app   3/5   70%   92%   4     2m
flask-hpa   Deployment/flask-app   4/5   70%   91%   5     3m
```

Then check the pods:

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

The HPA successfully autoscaled **from 2 replicas to 5 replicas**.

---

# 🌙 5.4 Observe Scale Down After Load Stops

Stop the BusyBox loop (`Ctrl + C`) and exit:

```
exit
```

Watch HPA again:

```bash
kubectl get hpa -n flask-mongo -w
```

Expected after a few minutes:

```
flask-hpa   Deployment/flask-app   2/5   70%   20%   2     10m
```

Pods return to **2 minimum replicas** as required.

---

# ⚠️ **6. Failure Scenarios & Fixes (Cookie Point)**

### **Issue: macOS port 5000 already in use**

Fix:

```
lsof -i :5000
kill -9 <PID>
```

or use `-p 5001:5000` when running Docker.

---

### **Issue: InvalidImageName / ImagePullBackOff**

Cause: Deployment referenced the wrong image.

Fix:

```
image: arnavguptas/flask-mongo:latest
kubectl rollout restart deployment flask-app -n flask-mongo
```

---

### **Issue: HPA not scaling**

Cause: `metrics-server` was not enabled.

Fix:

```
minikube addons enable metrics-server
```

---

### **Issue: MongoDB failed authentication**

Cause: Wrong credentials or missing `authSource=admin`.

Fix:

```
MONGODB_URI="mongodb://admin:StrongPass123@mongo:27017/?authSource=admin"
```

---

### **Issue: PVC stuck in Pending**

Cause: No matching PV or wrong storageClass.

Fix:

* Use StatefulSet `volumeClaimTemplates` with default Minikube storage class (recommended).

---

# 🧼 **7. Cleanup**

```
kubectl delete namespace flask-mongo
minikube stop
```

---
