#!/bin/bash

echo "🧹 Cleaning up all Kubernetes resources..."

# Set namespace variable
NAMESPACE="flask-mongo"

echo "🗑️ Deleting Namespace (this removes all resources inside)..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo "🛑 Stopping Minikube (optional)..."
# Uncomment if you want to stop cluster too:
# minikube stop

echo "🧼 Cleanup Completed!"
