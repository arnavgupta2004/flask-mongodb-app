#!/bin/bash

echo "🚀 Deploying Flask + MongoDB Application to Kubernetes..."

# Set namespace variable for convenience
NAMESPACE="flask-mongo"

echo "📌 Applying Namespace..."
kubectl apply -f k8s/namespace.yaml

echo "🔐 Applying MongoDB Secret..."
kubectl apply -f k8s/mongo-secret.yaml

echo "🍃 Deploying MongoDB StatefulSet and Service..."
kubectl apply -f k8s/mongo.yaml

echo "🐍 Deploying Flask Application..."
kubectl apply -f k8s/flask-deployment.yaml

echo "🌐 Applying Flask Service..."
kubectl apply -f k8s/flask-service.yaml

echo "📈 Applying Horizontal Pod Autoscaler..."
kubectl apply -f k8s/hpa.yaml

echo "⏳ Waiting for Pods to become ready..."
kubectl wait --for=condition=available deployment/flask-app -n $NAMESPACE --timeout=120s

echo "✅ Deployment Completed Successfully!"
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
