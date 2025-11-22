#!/bin/bash

# SkySense - Quick Start Script
# Levanta toda la aplicación con un solo comando

echo "🚀 SkySense Quick Start"
echo "======================"

# Función para verificar comandos
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 no está instalado"
        return 1
    fi
    return 0
}

# Verificar dependencias
echo "🔍 Verificando dependencias..."
check_command minikube || exit 1
check_command kubectl || exit 1
check_command docker || exit 1

# Paso 1: Iniciar Minikube
echo ""
echo "1. 🏗️  Iniciando Minikube..."
minikube status &>/dev/null || minikube start

# Paso 2: Configurar entorno Docker
echo ""
echo "2. 🔧 Configurando entorno Docker..."
eval $(minikube docker-env)

# Paso 3: Crear namespace
echo ""
echo "3. 📁 Creando namespace..."
kubectl create namespace skysense --dry-run=client -o yaml | kubectl apply -f -

# Paso 4: Construir imágenes si es necesario
echo ""
echo "4. 🐳 Construyendo imágenes..."
docker build -t skysense-frontend:latest frontend/ 2>/dev/null && echo "✅ Frontend image built" || echo "⚠️  Frontend image already exists"
docker build -t skysense-backend:latest backend/ 2>/dev/null && echo "✅ Backend image built" || echo "⚠️  Backend image already exists"

# Paso 5: Desplegar aplicación
echo ""
echo "5. 📦 Desplegando SkySense..."
kubectl apply -f k8s/ -n skysense

# Paso 6: Esperar a que esté listo
echo ""
echo "6. ⏳ Esperando a que los servicios estén listos..."
for i in {1..30}; do
    if kubectl get pods -n skysense 2>/dev/null | grep -q "Running"; then
        echo "✅ Servicios listos!"
        break
    fi
    echo -n "."
    sleep 2
done

# Paso 7: Mostrar estado final
echo ""
echo "7. 📊 Estado final:"
echo ""
kubectl get pods -n skysense
echo ""
kubectl get services -n skysense

# Paso 8: URLs de acceso
echo ""
echo "8. 🌐 URLs de acceso:"
MINIKUBE_IP=$(minikube ip)
echo "   📊 Dashboard: http://$MINIKUBE_IP:32323"
echo "   🔧 API Docs: http://$MINIKUBE_IP:30080/docs"
echo "   🗄️  Backend: http://$MINIKUBE_IP:30080"

# Paso 9: Verificar WebSocket
echo ""
echo "9. 🔄 Verificando WebSocket..."
BACKEND_POD=$(kubectl get pods -n skysense -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$BACKEND_POD" ]; then
    echo "   ✅ Backend pod: $BACKEND_POD"
    echo "   📡 WebSocket: ws://$MINIKUBE_IP:30080/ws/sensors"
else
    echo "   ⚠️  Backend no disponible aún"
fi

echo ""
echo "🎉 SkySense está listo!"
echo "💡 Abre http://$MINIKUBE_IP:32323 en tu navegador"