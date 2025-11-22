#!/bin/bash

echo "🧪 INICIANDO PRUEBA COMPLETA DEL SISTEMA - VERSIÓN KUBERNETES"
echo "==========================================================="
echo "SkySense IoT Platform - Prueba Integral Kubernetes"
echo "Fecha: $(date)"
echo "Cluster: $(kubectl config current-context)"
echo "==========================================================="

# Limpiar pods problemáticos si existen
echo "🧹 Limpiando pods problemáticos..."
kubectl delete pod -n skysense --field-selector=status.phase!=Running --force --grace-period=0 2>/dev/null || true

echo ""
echo "1. 🏗️  PRUEBA DE INFRAESTRUCTURA KUBERNETES"
echo "=========================================="

echo "📋 Estado de los pods:"
kubectl get pods -n skysense -o wide

echo ""
echo "📋 Estado de los servicios:"
kubectl get svc -n skysense

echo ""
echo "2. ⚙️  PRUEBA DEL BACKEND Y BASE DE DATOS"
echo "========================================"

echo "🏥 Prueba de salud del backend:"
BACKEND_POD=$(kubectl get pods -n skysense -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n skysense $BACKEND_POD -- curl -s -w "Código HTTP: %{http_code}\nTiempo: %{time_total}s\n" http://localhost:8000/api/health || echo "❌ No se pudo conectar al backend"

echo ""
echo "🗃️  Prueba de base de datos:"
kubectl exec -n skysense $BACKEND_POD -- python3 -c "
import psycopg2
import time
import os

def test_database():
    try:
        start_time = time.time()
        # Usar la conexión desde environment variables
        conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
        cur = conn.cursor()
        
        # Prueba 1: Contar registros
        cur.execute('SELECT COUNT(*) FROM sensor_data')
        total_records = cur.fetchone()[0]
        
        # Prueba 2: Verificar estructura de la tabla
        cur.execute('SELECT column_name, data_type FROM information_schema.columns WHERE table_name = \\'sensor_data\\'')
        columns = cur.fetchall()
        
        # Prueba 3: Insertar registro de prueba
        test_sensor = 'test_sensor_prueba'
        cur.execute('INSERT INTO sensor_data (sensor_id, temperature, humidity, pressure) VALUES (%s, %s, %s, %s)', 
                   (test_sensor, 25.0, 50.0, 1013.25))
        conn.commit()
        
        # Prueba 4: Recuperar el registro insertado
        cur.execute('SELECT * FROM sensor_data WHERE sensor_id = %s', (test_sensor,))
        test_record = cur.fetchone()
        
        # Prueba 5: Eliminar registro de prueba
        cur.execute('DELETE FROM sensor_data WHERE sensor_id = %s', (test_sensor,))
        conn.commit()
        
        end_time = time.time()
        conn.close()
        
        print('✅ PRUEBA BASE DE DATOS EXITOSA')
        print('   📊 Registros totales:', total_records)
        print('   🏗️  Columnas de la tabla:', len(columns))
        print('   ⚡ Tiempo de respuesta: {:.3f}s'.format(end_time - start_time))
        print('   ✅ Inserción/Consulta/Eliminación: FUNCIONA')
        
    except Exception as e:
        print('❌ ERROR en prueba de base de datos:', str(e))

test_database()
"

echo ""
echo "3. 🌐 PRUEBA DE LA API REST - DESDE EXTERNO"
echo "=========================================="

echo "📡 Probando endpoints de la API desde NodePort:"

BACKEND_NODEPORT="192.168.49.2:30080"
echo "🔹 Usando Backend en: $BACKEND_NODEPORT"

echo ""
echo "🔹 GET /api/health:"
curl -s "http://$BACKEND_NODEPORT/api/health" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('   ✅ Health check:', data.get('status', 'N/A'))
    print('   🗄️  Database:', data.get('database', 'N/A'))
except:
    print('   ❌ No se pudo parsear respuesta')
"

echo ""
echo "🔹 GET /api/sensors (últimos registros):"
curl -s "http://$BACKEND_NODEPORT/api/sensors?limit=3" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('   ✅ Sensores recuperados:', data.get('count', 0))
    print('   📊 Últimos sensores:')
    for sensor in data.get('sensors', [])[:2]:
        print('      - {}: {}\u00b0C, {}%'.format(
            sensor.get('sensor_id', 'N/A'),
            sensor.get('temperature', 'N/A'),
            sensor.get('humidity', 'N/A')
        ))
except Exception as e:
    print('   ❌ Error:', str(e))
"

echo ""
echo "4. 🔄 PRUEBA DE WEBSOCKET EN TIEMPO REAL"
echo "========================================"

echo "🔌 Verificando actividad WebSocket en logs..."
WEBSOCKET_LOGS=$(kubectl logs -n skysense deployment/backend --tail=15 2>/dev/null | grep -E "WebSocket|connected|sensor_" | tail -5 || true)

if [ -n "$WEBSOCKET_LOGS" ]; then
    echo "✅ Actividad WebSocket detectada:"
    echo "$WEBSOCKET_LOGS" | while read line; do
        echo "   📝 $line"
    done
else
    echo "⚠️  No se detectó actividad WebSocket reciente"
    echo "   Verificando si el servicio está activo..."
    kubectl logs -n skysense deployment/backend --tail=3 2>/dev/null || echo "   ❌ No se pueden obtener logs"
fi

echo ""
echo "5. 🖥️  PRUEBA DEL FRONTEND"
echo "=========================="

FRONTEND_NODEPORT="192.168.49.2:32323"
echo "🌐 Probando frontend en: http://$FRONTEND_NODEPORT"

# Probamos con timeout para no bloquear
if curl -s --max-time 10 "http://$FRONTEND_NODEPORT" | grep -q "SkySense\|Angular"; then
    echo "✅ Frontend accesible y respondiendo"
    echo "📱 Interfaz web funcionando correctamente"
    
    # Verificar que los assets cargan
    if curl -s --max-time 5 "http://$FRONTEND_NODEPORT/assets/env.js" > /dev/null; then
        echo "✅ Assets cargando correctamente"
    else
        echo "⚠️  Assets podrían no estar cargando"
    fi
else
    echo "❌ Frontend no responde o tarda demasiado"
    echo "   Verificando pods del frontend..."
    kubectl get pods -n skysense -l app=frontend
fi

echo ""
echo "6. ⚡ PRUEBA DE RENDIMIENTO"
echo "=========================="

echo "🔁 Probando 5 requests rápidos al backend externo:"
start_time=$(date +%s)
SUCCESS_COUNT=0
for i in {1..5}; do
    if curl -s -o /dev/null --max-time 5 "http://$BACKEND_NODEPORT/api/health"; then
        echo -n "✅ "
        ((SUCCESS_COUNT++))
    else
        echo -n "❌ "
    fi
    sleep 0.5
done
echo ""
end_time=$(date +%s)
echo "⚡ $SUCCESS_COUNT/5 requests exitosas en $((end_time - start_time)) segundos"

echo ""
echo "7. 📊 PRUEBA DE DATOS EN TIEMPO REAL"
echo "===================================="

echo "📈 Verificando crecimiento de datos en PostgreSQL..."
INITIAL_COUNT=$(kubectl exec -n skysense $BACKEND_POD -- python3 -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) FROM sensor_data')
    print(cur.fetchone()[0])
    conn.close()
except Exception as e:
    print('0')
" 2>/dev/null || echo "0")

echo "   Registros iniciales: $INITIAL_COUNT"
echo "   Esperando 15 segundos para capturar nuevos datos..."
sleep 15

FINAL_COUNT=$(kubectl exec -n skysense $BACKEND_POD -- python3 -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) FROM sensor_data')
    print(cur.fetchone()[0])
    conn.close()
except Exception as e:
    print('0')
" 2>/dev/null || echo "0")

echo "   Registros finales: $FINAL_COUNT"
NEW_RECORDS=$((FINAL_COUNT - INITIAL_COUNT))
echo "   Nuevos registros en 15 segundos: $NEW_RECORDS"

if [ $NEW_RECORDS -gt 0 ]; then
    echo "✅ DATOS FLUYENDO CORRECTAMENTE"
    echo "   📈 Tasa aproximada: $(echo "scale=2; $NEW_RECORDS / 15" | bc) registros/segundo"
else
    echo "⚠️  No se detectaron nuevos registros"
    echo "   Verificando actividad del WebSocket..."
    kubectl logs -n skysense deployment/backend --tail=5 | grep -E "sending|sensor" || echo "   ℹ️  Revisar logs manualmente"
fi

echo ""
echo "8. 📄 INFORME FINAL DE LA PRUEBA"
echo "================================"

echo "🎯 RESUMEN DE LA PRUEBA COMPLETA:"
echo ""

# Estadísticas finales
RUNNING_PODS=$(kubectl get pods -n skysense --no-headers 2>/dev/null | grep -c Running || echo "0")
TOTAL_PODS=$(kubectl get pods -n skysense --no-headers 2>/dev/null | wc -l || echo "0")

echo "📋 COMPONENTES DEL SISTEMA:"
echo "   Kubernetes Pods: $RUNNING_PODS/$TOTAL_PODS en Running"
echo "   Backend API: $( [ $SUCCESS_COUNT -gt 0 ] && echo "✅" || echo "❌" )"
echo "   Base de Datos: $( [ $INITIAL_COUNT -gt 0 ] && echo "✅" || echo "❌" )" 
echo "   WebSocket: $( [ -n "$WEBSOCKET_LOGS" ] && echo "✅" || echo "⚠️" )"
echo "   Frontend: $( curl -s --max-time 5 "http://$FRONTEND_NODEPORT" > /dev/null && echo "✅" || echo "❌" )"
echo "   Datos en Tiempo Real: $( [ $NEW_RECORDS -gt 0 ] && echo "✅" || echo "⚠️" )"

echo ""
echo "📊 ESTADÍSTICAS FINALES DE DATOS:"
kubectl exec -n skysense $BACKEND_POD -- python3 -c "
import psycopg2
from datetime import datetime

try:
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    
    # Total registros
    cur.execute('SELECT COUNT(*) FROM sensor_data')
    total = cur.fetchone()[0]
    
    # Registros por sensor
    cur.execute('SELECT sensor_id, COUNT(*) FROM sensor_data GROUP BY sensor_id ORDER BY COUNT(*) DESC')
    sensor_counts = cur.fetchall()
    
    # Rango de fechas
    cur.execute('SELECT MIN(timestamp), MAX(timestamp) FROM sensor_data')
    min_ts, max_ts = cur.fetchone()
    
    # Últimos registros
    cur.execute('SELECT sensor_id, temperature, humidity, timestamp FROM sensor_data ORDER BY timestamp DESC LIMIT 3')
    latest = cur.fetchall()
    
    conn.close()
    
    print('   📈 Total de registros: {:,}'.format(total))
    print('   🔍 Distribución por sensor:')
    for sensor_id, count in sensor_counts:
        print('      - {}: {:,} registros'.format(sensor_id, count))
    
    if min_ts and max_ts:
        print('   🕐 Rango temporal: {} a {}'.format(
            min_ts.strftime('%H:%M:%S') if hasattr(min_ts, 'strftime') else min_ts,
            max_ts.strftime('%H:%M:%S') if hasattr(max_ts, 'strftime') else max_ts
        ))
    
    print('   📅 Últimas lecturas:')
    for sensor_id, temp, hum, ts in latest:
        print('      - {}: {}\u00b0C, {}% - {}'.format(
            sensor_id, temp, hum, 
            ts.strftime('%H:%M:%S') if hasattr(ts, 'strftime') else ts
        ))
    
except Exception as e:
    print('   ❌ Error al obtener estadísticas:', str(e))
" 2>/dev/null || echo "   ❌ No se pudieron obtener estadísticas"

echo ""
echo "🎉 RESULTADO FINAL:"

if [ $RUNNING_PODS -ge 3 ] && [ $SUCCESS_COUNT -gt 0 ] && [ $INITIAL_COUNT -gt 0 ]; then
    echo "   ✅ ¡SISTEMA COMPLETAMENTE OPERATIVO!"
    echo "   🚀 SkySense IoT Platform funcionando correctamente"
    echo ""
    echo "🌐 URLS DE ACCESO:"
    echo "   Frontend: http://$FRONTEND_NODEPORT"
    echo "   Backend API: http://$BACKEND_NODEPORT/api/health"
    echo "   WebSocket: ws://$BACKEND_NODEPORT/ws/sensors"
    echo "   API Docs: http://$BACKEND_NODEPORT/docs"
else
    echo "   ⚠️  ALGUNOS COMPONENTES NECESITAN ATENCIÓN"
    echo "   Pods ejecutándose: $RUNNING_PODS/$TOTAL_PODS"
    echo "   Requests exitosos: $SUCCESS_COUNT/5"
    echo "   Registros en BD: $INITIAL_COUNT"
fi

echo ""
echo "📝 PRÓXIMOS PASOS RECOMENDADOS:"
echo "   1. Abrir el Frontend: http://$FRONTEND_NODEPORT"
echo "   2. Verificar datos en tiempo real"
echo "   3. Probar la API: http://$BACKEND_NODEPORT/docs"
echo "   4. Monitorear logs: kubectl logs -n skysense deployment/backend --follow"

echo ""
echo "==========================================================="
echo "🧪 PRUEBA COMPLETADA - $(date)"
echo "==========================================================="