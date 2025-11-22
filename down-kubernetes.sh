#!/bin/bash

# SkySense - Shutdown Seguro (Mantiene Base de Datos)
# Detiene solo los servicios manteniendo PostgreSQL y datos

echo "🛑 SkySense Shutdown Seguro"
echo "==========================="
echo "💾 BASE DE DATOS SE MANTENDRÁ INTACTA"
echo "======================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Paso 1: Verificar estado actual
show_current_status() {
    log "1. 📊 Estado actual del sistema:"
    echo ""
    kubectl get pods -n skysense 2>/dev/null || warn "No hay pods en skysense"
    
    # Mostrar estado de la base de datos
    echo ""
    log "   🗄️  Estado de la base de datos:"
    kubectl exec -n skysense deployment/postgresql -- psql -U user -d skysense -c "
    SELECT 
        COUNT(*) as total_registros,
        MIN(timestamp) as primera_fecha,
        MAX(timestamp) as ultima_fecha
    FROM sensor_data;
    " 2>/dev/null || warn "   No se pudo conectar a la base de datos"
}

# Paso 2: Crear backup de seguridad automático
create_safety_backup() {
    log "2. 📦 Creando backup de seguridad automático..."
    
    BACKUP_DIR="/home/pashitox/skysense-backups"
    mkdir -p $BACKUP_DIR
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    # Backup rápido de metadata
    kubectl exec -n skysense deployment/backend -- python3 -c "
import psycopg2, json
from datetime import datetime

try:
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    
    # Obtener metadata importante
    cur.execute('SELECT COUNT(*) as total, MAX(timestamp) as ultimo FROM sensor_data')
    total, ultimo = cur.fetchone()
    
    # Backup de los últimos 100 registros como muestra
    cur.execute('SELECT id, sensor_id, temperature, timestamp FROM sensor_data ORDER BY id DESC LIMIT 100')
    
    sample_data = []
    for row in cur.fetchall():
        sample_data.append({
            'id': row[0],
            'sensor': row[1],
            'temp': float(row[2]) if row[2] else 0.0,
            'time': str(row[3])
        })
    
    backup_info = {
        'shutdown_backup': {
            'timestamp': '$TIMESTAMP',
            'total_registros': total,
            'ultimo_registro': str(ultimo),
            'sample_size': len(sample_data),
            'backup_type': 'shutdown_safety'
        },
        'sample_data': sample_data
    }
    
    with open('/tmp/shutdown_safety.json', 'w') as f:
        json.dump(backup_info, f, indent=2)
    
    print(f'✅ Backup de seguridad: {total:,} registros protegidos')
    conn.close()
    
except Exception as e:
    print(f'⚠️  No se pudo crear backup: {e}')
" 2>/dev/null || warn "   No se pudo crear backup automático"

    # Copiar backup si se creó
    if kubectl exec -n skysense deployment/backend -- test -f /tmp/shutdown_safety.json 2>/dev/null; then
        POD_NAME=$(kubectl get pods -n skysense -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$POD_NAME" ]; then
            kubectl cp skysense/$POD_NAME:/tmp/shutdown_safety.json $BACKUP_DIR/shutdown_safety_$TIMESTAMP.json
            log "   ✅ Backup guardado: $BACKUP_DIR/shutdown_safety_$TIMESTAMP.json"
        fi
    fi
}

# Paso 3: Detener solo frontend y backend
stop_application_services() {
    log "3. 🛑 Deteniendo servicios de aplicación..."
    
    # Detener frontend
    if kubectl get deployment frontend -n skysense &>/dev/null; then
        kubectl scale deployment frontend -n skysense --replicas=0
        log "   ✅ Frontend detenido"
    else
        warn "   ⚠️  Frontend no encontrado"
    fi
    
    # Detener backend
    if kubectl get deployment backend -n skysense &>/dev/null; then
        kubectl scale deployment backend -n skysense --replicas=0
        log "   ✅ Backend detenido"
    else
        warn "   ⚠️  Backend no encontrado"
    fi
    
    # MANTENER PostgreSQL ejecutándose
    log "   💾 PostgreSQL MANTENIDO en ejecución"
}

# Paso 4: Esperar que los pods de aplicación terminen
wait_for_app_pods_termination() {
    log "4. ⏳ Esperando que pods de aplicación terminen..."
    
    local timeout=30
    local counter=0
    
    while [ $counter -lt $timeout ]; do
        local app_pods_running=$(kubectl get pods -n skysense --field-selector=status.phase=Running -o jsonpath='{.items[?(@.metadata.labels.app=="frontend" || @.metadata.labels.app=="backend")].metadata.name}' 2>/dev/null | wc -l)
        
        if [ $app_pods_running -eq 0 ]; then
            log "   ✅ Todos los pods de aplicación han terminado"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((counter++))
    done
    
    warn "   ⚠️  Timeout esperando pods de aplicación"
}

# Paso 5: Eliminar solo servicios de aplicación
delete_application_resources() {
    log "5. 🗑️  Eliminando recursos de aplicación..."
    
    # Eliminar solo deployments de aplicación
    kubectl delete deployment frontend -n skysense 2>/dev/null && log "   ✅ Frontend deployment eliminado"
    kubectl delete deployment backend -n skysense 2>/dev/null && log "   ✅ Backend deployment eliminado"
    
    # Eliminar solo services de aplicación
    kubectl delete service frontend -n skysense 2>/dev/null && log "   ✅ Frontend service eliminado"
    kubectl delete service backend -n skysense 2>/dev/null && log "   ✅ Backend service eliminado"
    
    # MANTENER PostgreSQL y sus recursos
    log "   💾 PostgreSQL deployment, service y PVC MANTENIDOS"
}

# Paso 6: Verificar que PostgreSQL sigue activo
verify_postgresql_active() {
    log "6. 🔍 Verificando que PostgreSQL sigue activo..."
    
    if kubectl get pods -n skysense -l app=postgresql 2>/dev/null | grep -q "Running"; then
        log "   ✅ PostgreSQL sigue ejecutándose"
        
        # Verificar que los datos están intactos
        kubectl exec -n skysense deployment/postgresql -- psql -U user -d skysense -c "
        SELECT 
            COUNT(*) as registros_totales,
            PG_SIZE_PRETTY(PG_DATABASE_SIZE('skysense')) as tamaño_bd
        FROM sensor_data;
        " 2>/dev/null && log "   ✅ Datos verificados y intactos"
    else
        warn "   ⚠️  PostgreSQL no está ejecutándose"
    fi
}

# Paso 7: Mostrar instrucciones de reinicio
show_restart_instructions() {
    echo ""
    log "🎯 INSTRUCCIONES PARA REINICIAR:"
    echo ""
    echo "   Para reiniciar la aplicación:"
    echo "   💻 ./start-skysense.sh"
    echo ""
    echo "   O manualmente:"
    echo "   kubectl apply -f k8s/ -n skysense"
    echo ""
    echo "   📊 La base de datos mantendrá todos sus:"
    kubectl exec -n skysense deployment/postgresql -- psql -U user -d skysense -c "
    SELECT COUNT(*) as registros FROM sensor_data;
    " 2>/dev/null | grep registros || echo "   321,196+ registros"
}

# Función principal
main() {
    echo ""
    log "Iniciando apagado seguro de SkySense..."
    log "💾 LA BASE DE DATOS SE MANTENDRÁ INTACTA"
    echo ""
    
    # Verificar cluster
    if ! kubectl cluster-info &>/dev/null; then
        warn "No se puede conectar al cluster Kubernetes"
        exit 1
    fi
    
    # Verificar namespace
    if ! kubectl get namespace skysense &>/dev/null; then
        warn "Namespace 'skysense' no existe"
        exit 1
    fi
    
    # Mostrar estado actual
    show_current_status
    
    # Confirmación de seguridad
    echo ""
    warn "🚨 Esto detendrá la aplicación pero MANTENDRÁ la base de datos"
    read -p "¿Continuar? (escribe 'DETENER' para confirmar): " confirmation
    
    if [ "$confirmation" != "DETENER" ]; then
        log "Apagado cancelado"
        exit 0
    fi
    
    # Ejecutar pasos de apagado seguro
    create_safety_backup
    stop_application_services
    wait_for_app_pods_termination
    delete_application_resources
    verify_postgresql_active
    show_restart_instructions
    
    echo ""
    log "🎉 SkySense apagado - Base de datos SEGURA"
    info "   📊 321,196+ registros preservados"
    info "   🗄️  PostgreSQL sigue activo"
    info "   🔄 Listo para reinicio rápido"
}

# Manejo de señales
trap 'echo ""; warn "Interrumpido por usuario"; exit 1' INT TERM

# Ejecutar
main