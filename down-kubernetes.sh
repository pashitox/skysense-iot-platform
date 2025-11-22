#!/bin/bash

# SkySense - Shutdown Script
# Detiene toda la aplicación de forma segura

echo "🛑 SkySense Shutdown"
echo "==================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Verificar si estamos en el namespace correcto
check_skysense_namespace() {
    if ! kubectl get namespace skysense &>/dev/null; then
        error "Namespace 'skysense' no existe"
        return 1
    fi
    return 0
}

# Paso 1: Detener deployments
stop_deployments() {
    log "1. 🛑 Deteniendo deployments..."
    
    deployments=("frontend" "backend" "postgresql")
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" -n skysense &>/dev/null; then
            kubectl scale deployment "$deployment" -n skysense --replicas=0
            log "   ✅ $deployment: replicas establecidas a 0"
        else
            warn "   ⚠️  $deployment: no encontrado"
        fi
    done
}

# Paso 2: Esperar a que los pods terminen
wait_for_pods_termination() {
    log "2. ⏳ Esperando que los pods terminen..."
    
    local timeout=60
    local counter=0
    
    while [ $counter -lt $timeout ]; do
        local running_pods=$(kubectl get pods -n skysense --field-selector=status.phase=Running -o name 2>/dev/null | wc -l)
        
        if [ $running_pods -eq 0 ]; then
            log "   ✅ Todos los pods han terminado"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((counter++))
    done
    
    warn "   ⚠️  Timeout esperando por pods"
    return 1
}

# Paso 3: Eliminar recursos
delete_resources() {
    log "3. 🗑️  Eliminando recursos..."
    
    # Eliminar deployments
    kubectl delete deployment -l app=frontend -n skysense 2>/dev/null && log "   ✅ Frontend deployment eliminado"
    kubectl delete deployment -l app=backend -n skysense 2>/dev/null && log "   ✅ Backend deployment eliminado" 
    kubectl delete deployment -l app=postgresql -n skysense 2>/dev/null && log "   ✅ PostgreSQL deployment eliminado"
    
    # Eliminar services
    kubectl delete service -l app=frontend -n skysense 2>/dev/null && log "   ✅ Frontend service eliminado"
    kubectl delete service -l app=backend -n skysense 2>/dev/null && log "   ✅ Backend service eliminado"
    kubectl delete service -l app=postgresql -n skysense 2>/dev/null && log "   ✅ PostgreSQL service eliminado"
    
    # Eliminar configmaps
    kubectl delete configmap -l app=frontend -n skysense 2>/dev/null
    kubectl delete configmap -l app=backend -n skysense 2>/dev/null
    log "   ✅ ConfigMaps eliminados"
    
    # Eliminar todos los recursos del directorio k8s/
    if [ -d "k8s" ]; then
        kubectl delete -f k8s/ -n skysense 2>/dev/null && log "   ✅ Recursos de k8s/ eliminados"
    fi
}

# Paso 4: Manejar datos persistentes
handle_persistent_data() {
    log "4. 💾 Manejo de datos persistentes..."
    
    echo "   ¿Qué quieres hacer con los datos de PostgreSQL?"
    echo "   1. Mantener datos (recomendado para desarrollo)"
    echo "   2. Eliminar todos los datos (limpieza completa)"
    echo "   3. Crear backup y luego eliminar"
    
    read -p "   Selecciona opción (1-3): " data_option
    
    case $data_option in
        1)
            log "   ✅ Datos persistentes mantenidos"
            ;;
        2)
            warn "   🗑️  ELIMINANDO TODOS LOS DATOS..."
            kubectl delete pvc -l app=postgresql -n skysense 2>/dev/null
            log "   ✅ Volúmenes persistentes eliminados"
            ;;
        3)
            log "   📦 Creando backup antes de eliminar..."
            ./backup-csv-millones.sh 2>/dev/null || warn "   ⚠️  No se pudo crear backup"
            kubectl delete pvc -l app=postgresql -n skysense 2>/dev/null
            log "   ✅ Backup creado y volúmenes eliminados"
            ;;
        *)
            warn "   ⚠️  Opción inválida, manteniendo datos"
            ;;
    esac
}

# Paso 5: Limpiar namespace
cleanup_namespace() {
    log "5. 🧹 Limpiando namespace..."
    
    # Verificar si el namespace está vacío
    local resources=$(kubectl get all -n skysense 2>/dev/null | grep -v "No resources found" | wc -l)
    
    if [ $resources -gt 0 ]; then
        warn "   ⚠️  Todavía hay recursos en el namespace:"
        kubectl get all -n skysense 2>/dev/null
        
        read -p "   ¿Forzar eliminación de todos los recursos? (s/N): " force_delete
        
        if [[ $force_delete =~ ^[Ss]$ ]]; then
            kubectl delete all --all -n skysense 2>/dev/null
            log "   ✅ Todos los recursos eliminados"
        else
            warn "   ⚠️  Algunos recursos pueden quedar en el namespace"
        fi
    else
        log "   ✅ Namespace está vacío"
    fi
}

# Paso 6: Opcional - Eliminar namespace
delete_namespace() {
    echo ""
    read -p "¿Eliminar completamente el namespace 'skysense'? (s/N): " delete_ns
    
    if [[ $delete_ns =~ ^[Ss]$ ]]; then
        warn "🗑️  ELIMINANDO NAMESPACE SKYSENSE..."
        kubectl delete namespace skysense
        log "✅ Namespace 'skysense' eliminado"
    else
        log "ℹ️  Namespace 'skysense' mantenido"
    fi
}

# Paso 7: Detener Minikube (opcional)
stop_minikube() {
    echo ""
    read -p "¿Detener Minikube también? (s/N): " stop_mk
    
    if [[ $stop_mk =~ ^[Ss]$ ]]; then
        log "🛑 Deteniendo Minikube..."
        minikube stop
        log "✅ Minikube detenido"
    else
        log "ℹ️  Minikube sigue ejecutándose"
    fi
}

# Función principal
main() {
    echo ""
    log "Iniciando apagado seguro de SkySense..."
    
    # Verificar que kubectl está configurado
    if ! kubectl cluster-info &>/dev/null; then
        error "No se puede conectar al cluster Kubernetes"
        exit 1
    fi
    
    # Verificar namespace
    if ! check_skysense_namespace; then
        error "SkySense no está desplegado o el namespace no existe"
        exit 1
    fi
    
    # Mostrar estado actual
    info "Estado actual del cluster:"
    kubectl get pods -n skysense 2>/dev/null || warn "No hay pods en el namespace skysense"
    
    # Confirmación de seguridad
    echo ""
    warn "🚨 ESTO APAGARÁ TODOS LOS SERVICIOS DE SKYSENSE"
    read -p "¿Estás seguro de continuar? (escribe 'APAGAR' para confirmar): " confirmation
    
    if [ "$confirmation" != "APAGAR" ]; then
        log "Apagado cancelado"
        exit 0
    fi
    
    # Ejecutar pasos de apagado
    stop_deployments
    wait_for_pods_termination
    delete_resources
    handle_persistent_data
    cleanup_namespace
    delete_namespace
    stop_minikube
    
    echo ""
    log "🎉 SkySense ha sido apagado completamente"
    echo ""
    info "Para reiniciar, ejecuta: ./start-skysense.sh"
}

# Manejo de señales para apagado graceful
trap 'echo ""; warn "Interrumpido por usuario"; exit 1' INT TERM

# Ejecutar función principal
main
