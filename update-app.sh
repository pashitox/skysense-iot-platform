#!/bin/bash
echo "🔄 ACTUALIZANDO SKYSENSE IOT PLATFORM"

# Configurar entorno
eval $(minikube docker-env)

# Preguntar qué actualizar
echo "¿Qué quieres actualizar?"
echo "1) Backend (FastAPI)"
echo "2) Frontend (Angular)" 
echo "3) Ambos"
read -p "Selecciona [1-3]: " choice

case $choice in
    1)
        echo "🔨 Actualizando backend..."
        docker build -t skysense-backend:latest ./backend
        kubectl rollout restart deployment/backend -n skysense
        ;;
    2)
        echo "🎨 Actualizando frontend..."
        docker build -t skysense-frontend:latest ./frontend
        kubectl rollout restart deployment/frontend -n skysense
        ;;
    3)
        echo "🚀 Actualizando ambos..."
        docker build -t skysense-backend:latest ./backend
        docker build -t skysense-frontend:latest ./frontend
        kubectl rollout restart deployment/backend -n skysense
        kubectl rollout restart deployment/frontend -n skysense
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

# Verificar
echo "✅ Verificando actualización..."
kubectl get pods -n skysense -w