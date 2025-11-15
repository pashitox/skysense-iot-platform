#!/bin/bash

# SkySense - Monitor Avanzado
# Muestra el estado real-time de la aplicación

echo "📊 MONITOREO EN TIEMPO REAL - SKYSENSE"
echo "======================================"

while true; do
    clear
    
    # Obtener información del cluster
    echo "=== 🏗️  ESTADO DEL CLUSTER ==="
    echo "Nodos: $(kubectl get nodes | grep Ready | wc -l)/$(kubectl get nodes | wc -l)"
    echo ""
    
    # Pods por estado
    echo "=== 📦 PODS POR ESTADO ==="
    kubectl get pods -n skysense --no-headers | awk '
    {count[$3]++} 
    END {
        for (status in count) {
            printf "   %s: %d pods\n", status, count[status]
        }
    }'
    
    # Recursos utilizados
    echo ""
    echo "=== 💾 RECURSOS ==="
    kubectl top pods -n skysense 2>/dev/null || echo "   Instala metrics-server: minikube addons enable metrics-server"
    
    # Eventos recientes
    echo ""
    echo "=== 📝 EVENTOS RECIENTES ==="
    kubectl get events -n skysense --sort-by=.lastTimestamp | tail -3
    
    # Servicios
    echo ""
    echo "=== 🌐 SERVICIOS ==="
    kubectl get services -n skysense
    
    # URLs de acceso
    echo ""
    echo "=== 🚀 ACCESO ==="
    echo "   Frontend: http://192.168.49.2:$(kubectl get service frontend-service -n skysense -o jsonpath='{.spec.ports[0].nodePort}')"
    
    echo ""
    echo "⏰ Actualizando en 5 segundos... (Ctrl+C para salir)"
    sleep 5
done