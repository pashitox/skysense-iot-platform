#!/bin/bash

# SkySense IoT Platform - Simple Deployment Script
# Script básico y confiable para desplegar SkySense

set -e

echo "🚀 Iniciando despliegue de SkySense IoT Platform..."
echo "=================================================="

# 1. Verificar que minikube está corriendo
echo ""
echo "1. 🔍 Verificando Minikube..."
if ! minikube status >/dev/null 2>&1; then
    echo "   ⚠️  Minikube no está corriendo, iniciando..."
    minikube start
else
    echo "   ✅ Minikube está corriendo"
fi

# 2. Configurar Docker de Minikube
echo ""
echo "2. 🔧 Configurando Docker de Minikube..."
eval $(minikube docker-env)
echo "   ✅ Docker configurado"

# 3. Construir imágenes Docker
echo ""
echo "3. 📦 Construyendo imágenes Docker..."

echo "   🔨 Construyendo backend..."
if docker build -t skysense-backend:latest ./backend; then
    echo "   ✅ Backend construido"
else
    echo "   ❌ Error construyendo backend"
    exit 1
fi

echo "   🔨 Construyendo frontend..."
if docker build -t skysense-frontend:latest ./frontend; then
    echo "   ✅ Frontend construido"
else
    echo "   ❌ Error construyendo frontend"
    exit 1
fi

# 4. Verificar imágenes
echo ""
echo "4. 🔍 Verificando imágenes..."
docker images | grep skysense

# 5. Crear namespace si no existe
echo ""
echo "5. 🏗️  Creando namespace..."
kubectl create namespace skysense 2>/dev/null || echo "   ✅ Namespace ya existe"

# 6. Aplicar manifiestos básicos
echo ""
echo "6. 📄 Aplicando configuración de Kubernetes..."

# Backend
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: skysense
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: skysense-backend:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: skysense
spec:
  selector:
    app: backend
  ports:
  - port: 8000
    targetPort: 8000
EOF
echo "   ✅ Backend desplegado"

# Frontend
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: skysense
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: skysense-frontend:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: skysense
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF
echo "   ✅ Frontend desplegado"

# 7. Esperar a que los pods estén listos
echo ""
echo "7. ⏳ Esperando a que los pods estén listos..."
sleep 10

# 8. Verificar estado
echo ""
echo "8. ✅ Verificando despliegue..."
echo "   Pods:"
kubectl get pods -n skysense

echo ""
echo "   Servicios:"
kubectl get services -n skysense

# 9. Mostrar información de acceso
echo ""
echo "9. 🌐 Información de acceso:"
FRONTEND_URL=$(minikube service frontend-service -n skysense --url 2>/dev/null || echo "http://192.168.49.2:$(kubectl get service frontend-service -n skysense -o jsonpath='{.spec.ports[0].nodePort}')")
echo "   Frontend: $FRONTEND_URL"
echo ""
echo "   Para acceder: minikube service frontend-service -n skysense"
echo ""
echo "🎉 ¡SkySense IoT Platform desplegado exitosamente!"
echo "=================================================="