#!/bin/bash

# SkySense - Monitor Avanzado en Tiempo Real
# Versión Mejorada con Métricas Avanzadas

echo "🚀 SKYSENSE IOT PLATFORM - MONITOR EN TIEMPO REAL"
echo "=================================================="
echo "Iniciando monitorización... (Ctrl+C para salir)"
echo ""

# Variables de configuración
NAMESPACE="skysense"
UPDATE_INTERVAL=5
MAX_LOG_LINES=3

# Función para mostrar header con timestamp
show_header() {
    echo "=== 📊 SKYSENSE MONITOR - $(date '+%H:%M:%S') ==="
    echo "Namespace: $NAMESPACE | Cluster: $(kubectl config current-context)"
    echo ""
}

# Función para verificar si los comandos están disponibles
check_dependencies() {
    local missing=()
    
    for cmd in kubectl grep awk; do
        if ! command -v $cmd &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "❌ Faltan dependencias: ${missing[*]}"
        exit 1
    fi
}

# Función para obtener estado del cluster
get_cluster_status() {
    echo "🏗️  ESTADO DEL CLUSTER"
    echo "-------------------"
    
    # Estado de nodos
    local ready_nodes=$(kubectl get nodes 2>/dev/null | grep -c "Ready")
    local total_nodes=$(kubectl get nodes 2>/dev/null | grep -c "NAME" -v)
    
    if [ $total_nodes -gt 0 ]; then
        echo "✅ Nodos: $ready_nodes/$total_nodes listos"
    else
        echo "❌ No se pueden obtener nodos"
    fi
    
    # Uso de recursos del cluster
    echo "📦 Namespaces: $(kubectl get namespaces --no-headers 2>/dev/null | wc -l)"
    echo ""
}

# Función para obtener estado de los pods
get_pods_status() {
    echo "📦 ESTADO DE LOS PODS"
    echo "-------------------"
    
    # Contar pods por estado
    kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | awk '
    {
        status = $3
        if (status ~ /Running/) { running++ }
        else if (status ~ /Pending/) { pending++ }
        else if (status ~ /Failed/) { failed++ }
        else if (status ~ /Succeeded/) { succeeded++ }
        else if (status ~ /CrashLoopBackOff/) { crash++ }
        else if (status ~ /ContainerCreating/) { creating++ }
        else { other++ }
        total++
    }
    END {
        if (total > 0) {
            printf "✅ Running:    %d\n", running
            printf "🟡 Pending:    %d\n", pending  
            printf "🔴 Failed:     %d\n", failed
            printf "🟢 Succeeded:  %d\n", succeeded
            printf "🔄 Creating:   %d\n", creating
            printf "💥 CrashLoop:  %d\n", crash
            printf "❓ Other:      %d\n", other
            printf "📊 Total:      %d\n", total
        } else {
            print "❌ No hay pods en el namespace"
        }
    }'
    
    echo ""
}

# Función para mostrar recursos de CPU/Memoria
get_resources_usage() {
    echo "💾 USO DE RECURSOS"
    echo "-------------------"
    
    # Intentar obtener métricas
    if kubectl top pods -n $NAMESPACE 2>/dev/null; then
        echo ""
    else
        echo "📋 Instala metrics-server para ver uso en tiempo real:"
        echo "   minikube addons enable metrics-server"
        echo ""
    fi
}

# Función para mostrar servicios y URLs
get_services_info() {
    echo "🌐 SERVICIOS Y ACCESO"
    echo "-------------------"
    
    # Obtener servicios
    kubectl get services -n $NAMESPACE --no-headers 2>/dev/null | while read line; do
        local name=$(echo $line | awk '{print $1}')
        local type=$(echo $line | awk '{print $2}')
        local port_info=$(echo $line | awk '{print $5}')
        
        case $type in
            "NodePort")
                local nodeport=$(echo $port_info | cut -d':' -f2 | cut -d'/' -f1)
                echo "🔗 $name: http://192.168.49.2:$nodeport"
                ;;
            "ClusterIP")
                local cluster_ip=$(echo $line | awk '{print $3}')
                echo "🏠 $name: $cluster_ip (interno)"
                ;;
            "LoadBalancer")
                echo "🌍 $name: LoadBalancer (externo)"
                ;;
            *)
                echo "⚙️  $name: $type"
                ;;
        esac
    done
    
    echo ""
}

# Función para mostrar logs recientes
get_recent_logs() {
    echo "📝 ACTIVIDAD RECIENTE"
    echo "-------------------"
    
    # Obtener pods principales
    local backend_pod=$(kubectl get pods -n $NAMESPACE -l app=backend --no-headers 2>/dev/null | grep Running | head -1 | awk '{print $1}')
    local frontend_pod=$(kubectl get pods -n $NAMESPACE -l app=frontend --no-headers 2>/dev/null | grep Running | head -1 | awk '{print $1}')
    
    if [ -n "$backend_pod" ]; then
        echo "🔧 Backend ($backend_pod):"
        kubectl logs -n $NAMESPACE $backend_pod --tail=$MAX_LOG_LINES 2>/dev/null | grep -E "sensor_|WebSocket|connected" | tail -2 || echo "   No hay actividad reciente"
    fi
    
    if [ -n "$frontend_pod" ]; then
        echo "🎨 Frontend ($frontend_pod):"
        kubectl logs -n $NAMESPACE $frontend_pod --tail=1 2>/dev/null 2>/dev/null | head -1 || echo "   Serviendo aplicación"
    fi
    
    echo ""
}

# Función para mostrar eventos recientes
get_recent_events() {
    echo "⚡ EVENTOS DEL SISTEMA"
    echo "-------------------"
    
    local events=$(kubectl get events -n $NAMESPACE --sort-by=.lastTimestamp --field-selector type!=Normal 2>/dev/null | tail -3)
    
    if [ -n "$events" ]; then
        echo "$events" | while read line; do
            echo "⚠️  $line"
        done
    else
        echo "✅ Sin eventos críticos recientes"
    fi
    
    echo ""
}

# Función para verificar salud de la aplicación
get_health_status() {
    echo "❤️  SALUD DE LA APLICACIÓN"
    echo "-------------------"
    
    local backend_url="http://192.168.49.2:30080/api/health"
    
    # Verificar backend
    if curl -s --max-time 3 "$backend_url" > /dev/null; then
        echo "✅ Backend API: Respondiendo"
        
        # Obtener datos de salud
        local health_data=$(curl -s --max-time 3 "$backend_url")
        if echo "$health_data" | grep -q "healthy"; then
            echo "✅ Estado: Saludable"
        fi
        
        # Verificar base de datos
        if echo "$health_data" | grep -q "database"; then
            local db_status=$(echo "$health_data" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)
            echo "🗄️  Base de datos: $db_status"
        fi
    else
        echo "❌ Backend API: No responde"
    fi
    
    # Verificar frontend
    local frontend_url="http://192.168.49.2:32323"
    if curl -s --max-time 3 "$frontend_url" > /dev/null; then
        echo "✅ Frontend: Accesible"
    else
        echo "❌ Frontend: No accesible"
    fi
    
    echo ""
}

# Función para mostrar datos en tiempo real
get_realtime_data() {
    echo "📈 DATOS EN TIEMPO REAL"
    echo "-------------------"
    
    local backend_pod=$(kubectl get pods -n $NAMESPACE -l app=backend --no-headers 2>/dev/null | grep Running | head -1 | awk '{print $1}')
    
    if [ -n "$backend_pod" ]; then
        # Obtener conteo de registros
        local count=$(kubectl exec -n $NAMESPACE $backend_pod -- python3 -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) FROM sensor_data')
    print(cur.fetchone()[0])
    conn.close()
except:
    print('0')
" 2>/dev/null || echo "0")
        
        echo "📊 Registros en BD: $count"
        
        # Obtener últimos sensores
        local recent_sensors=$(kubectl exec -n $NAMESPACE $backend_pod -- python3 -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    cur.execute('SELECT sensor_id FROM sensor_data GROUP BY sensor_id ORDER BY MAX(timestamp) DESC LIMIT 3')
    sensors = [row[0] for row in cur.fetchall()]
    print(','.join(sensors))
    conn.close()
except:
    print('')
" 2>/dev/null || echo "")
        
        if [ -n "$recent_sensors" ]; then
            echo "🔍 Sensores activos: $recent_sensors"
        fi
    else
        echo "❌ No se puede conectar a la base de datos"
    fi
    
    echo ""
}

# Función principal del monitor
main_monitor() {
    # Verificar dependencias
    check_dependencies
    
    # Bucle principal
    while true; do
        clear
        show_header
        
        # Mostrar todas las secciones
        get_cluster_status
        get_pods_status
        get_resources_usage
        get_services_info
        get_health_status
        get_realtime_data
        get_recent_logs
        get_recent_events
        
        # Footer con información de control
        echo "=================================================="
        echo "🔄 Actualizando en $UPDATE_INTERVAL segundos..."
        echo "💡 Tips:"
        echo "   • Ver logs completos: kubectl logs -n $NAMESPACE -f deployment/backend"
        echo "   • Acceder al dashboard: http://192.168.49.2:32323"
        echo "   • API Documentation: http://192.168.49.2:30080/docs"
        echo ""
        
        sleep $UPDATE_INTERVAL
    done
}

# Manejar señal de interrupción
trap 'echo ""; echo "👋 Monitor detenido. Hasta pronto!"; exit 0' INT

# Ejecutar monitor
main_monitor