#!/bin/bash

# SkySense - Actualización Rápida
# Para cuando haces cambios en el código

echo "🔄 Actualizando SkySense..."
echo "=========================="

# Configurar entorno
eval $(minikube docker-env)

echo "¿Qué quieres actualizar?"
echo "1) Solo backend"
echo "2) Solo frontend" 
echo "3) Ambos"
read -p "Selecciona [1-3]: " opcion

case $opcion in
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

echo ""
echo "⏳ Esperando que se actualice..."
sleep 10

echo "✅ Verificando..."
kubectl get pods -n skysense

echo ""
echo "🎉 Actualización completada!"