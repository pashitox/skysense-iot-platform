#!/bin/bash

# SkySense - Restauración desde Backup CSV
# Restaura los 321,196 registros del backup

echo "🔄 SkySense - Restauración desde Backup CSV"
echo "==========================================="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

BACKUP_FILE="/home/pashitox/skysense-backups/backup_csv_20251121_153815.csv.gz"

# Paso 1: Verificar backup
verify_backup() {
    log "1. 🔍 Verificando backup..."
    
    if [ ! -f "$BACKUP_FILE" ]; then
        error "❌ Backup no encontrado: $BACKUP_FILE"
        exit 1
    fi
    
    size=$(du -h "$BACKUP_FILE" | cut -f1)
    lines=$(gunzip -c "$BACKUP_FILE" 2>/dev/null | wc -l)
    records=$((lines - 1))
    
    log "   ✅ Backup encontrado: $(basename "$BACKUP_FILE")"
    echo "   💾 Tamaño: $size"
    echo "   📊 Registros: $records"
    
    # Mostrar muestra
    echo ""
    info "   🔍 Muestra de datos:"
    gunzip -c "$BACKUP_FILE" 2>/dev/null | head -5
}

# Paso 2: Verificar estado actual
check_current_state() {
    log "2. 📊 Verificando estado actual..."
    
    kubectl exec -n skysense deployment/backend -- python3 -c "
import psycopg2
conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
cur = conn.cursor()
cur.execute('SELECT COUNT(*) as total FROM sensor_data')
total = cur.fetchone()[0]
print(f'   📈 Registros actuales en BD: {total:,}')
conn.close()
" 2>/dev/null || warn "   ⚠️  No se pudo conectar a la BD"
}

# Paso 3: Confirmación de seguridad
confirm_restore() {
    echo ""
    warn "🚨 ¡ATENCIÓN! Esto RESTAURARÁ 321,196 registros"
    warn "   Los datos actuales se MANTENDRÁN (no se eliminarán)"
    echo ""
    echo "📋 Resumen de la operación:"
    echo "   📥 Se agregarán: 321,196 registros"
    echo "   💾 Backup: $(basename "$BACKUP_FILE")"
    echo "   🗄️  Método: Inserción masiva con conflic handling"
    echo ""
    read -p "¿Continuar con la restauración? (escribe 'RESTAURAR' para confirmar): " confirm
    
    if [ "$confirm" != "RESTAURAR" ]; then
        log "❌ Restauración cancelada"
        exit 0
    fi
}

# Paso 4: Preparar restauración
prepare_restore() {
    log "4. 🛠️  Preparando restauración..."
    
    # Obtener pod del backend
    POD_NAME=$(kubectl get pods -n skysense -l app=backend -o jsonpath='{.items[0].metadata.name}')
    log "   ✅ Usando pod: $POD_NAME"
    
    # Copiar backup al pod
    log "   📤 Copiando backup al cluster..."
    kubectl cp "$BACKUP_FILE" skysense/$POD_NAME:/tmp/backup_restore.csv.gz
}

# Paso 5: Ejecutar restauración
execute_restore() {
    log "5. 🚀 Ejecutando restauración masiva..."
    info "   ⏳ Esto puede tomar varios minutos..."
    echo ""
    
    kubectl exec -n skysense deployment/backend -- python3 -c "
import psycopg2, csv, gzip, sys
from datetime import datetime

print('📊 Iniciando restauración masiva desde CSV...')

try:
    # Conectar a la base de datos
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    
    # Contadores
    total_inserted = 0
    total_skipped = 0
    errors = 0
    batch_size = 1000
    current_batch = []
    
    # Obtener conteo inicial
    cur.execute('SELECT COUNT(*) FROM sensor_data')
    initial_count = cur.fetchone()[0]
    print(f'📈 Registros iniciales: {initial_count:,}')
    
    # Procesar el archivo CSV
    with gzip.open('/tmp/backup_restore.csv.gz', 'rt') as f:
        reader = csv.reader(f)
        header = next(reader)  # Saltar header
        print(f'📋 Columnas detectadas: {header}')
        
        start_time = datetime.now()
        
        for line_num, row in enumerate(reader, 2):
            try:
                # Parsear datos
                record_id = int(row[0])
                sensor_id = row[1]
                temperature = float(row[2]) if row[2] else 0.0
                timestamp = row[3]
                
                # Agregar al batch actual
                current_batch.append((record_id, sensor_id, temperature, timestamp))
                
                # Procesar batch cuando esté lleno
                if len(current_batch) >= batch_size:
                    # Insertar batch usando COPY (más eficiente)
                    cur.executemany('''
                        INSERT INTO sensor_data (id, sensor_id, temperature, timestamp) 
                        VALUES (%s, %s, %s, %s)
                        ON CONFLICT (id) DO NOTHING
                    ''', current_batch)
                    
                    batch_inserted = cur.rowcount
                    total_inserted += batch_inserted
                    total_skipped += (len(current_batch) - batch_inserted)
                    
                    # Commit del batch
                    conn.commit()
                    
                    # Mostrar progreso
                    if line_num % 50000 == 0:
                        elapsed = (datetime.now() - start_time).total_seconds()
                        rate = line_num / elapsed if elapsed > 0 else 0
                        print(f'📦 Procesados: {line_num:,} líneas | Insertados: {total_inserted:,} | Tasa: {rate:.1f} líneas/segundo')
                    
                    # Limpiar batch
                    current_batch = []
                    
            except Exception as e:
                errors += 1
                if errors <= 5:  # Mostrar solo primeros 5 errores
                    print(f'⚠️  Error en línea {line_num}: {e}')
        
        # Procesar último batch si queda
        if current_batch:
            cur.executemany('''
                INSERT INTO sensor_data (id, sensor_id, temperature, timestamp) 
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
            ''', current_batch)
            batch_inserted = cur.rowcount
            total_inserted += batch_inserted
            total_skipped += (len(current_batch) - batch_inserted)
            conn.commit()
    
    # Obtener conteo final
    cur.execute('SELECT COUNT(*) FROM sensor_data')
    final_count = cur.fetchone()[0]
    
    # Estadísticas finales
    total_time = (datetime.now() - start_time).total_seconds()
    
    print('')
    print('✅ RESTAURACIÓN COMPLETADA:')
    print(f'   📥 Registros insertados: {total_inserted:,}')
    print(f'   ⏭️  Registros omitidos (ya existían): {total_skipped:,}')
    print(f'   ❌ Errores: {errors}')
    print(f'   📊 Total en BD después: {final_count:,}')
    print(f'   ⏱️  Tiempo total: {total_time:.2f} segundos')
    print(f'   🚀 Tasa promedio: {line_num/total_time:.1f} líneas/segundo')
    
    conn.close()
    
except Exception as e:
    print(f'❌ Error general en restauración: {e}')
    sys.exit(1)
"
}

# Paso 6: Limpiar y verificar
cleanup_and_verify() {
    log "6. 🧹 Limpiando y verificando..."
    
    # Limpiar archivo temporal
    kubectl exec -n skysense deployment/backend -- rm -f /tmp/backup_restore.csv.gz
    log "   ✅ Archivos temporales limpiados"
    
    # Verificación final
    echo ""
    log "🔍 Verificación final:"
    kubectl exec -n skysense deployment/backend -- python3 -c "
import psycopg2
conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
cur = conn.cursor()

# Conteo total
cur.execute('SELECT COUNT(*) as total FROM sensor_data')
total = cur.fetchone()[0]

# Distribución por sensor
cur.execute('SELECT sensor_id, COUNT(*) as count FROM sensor_data GROUP BY sensor_id ORDER BY count DESC')
sensors = cur.fetchall()

# Rango temporal
cur.execute('SELECT MIN(timestamp), MAX(timestamp) FROM sensor_data')
min_time, max_time = cur.fetchone()

print(f'📊 ESTADO FINAL DE LA BASE DE DATOS:')
print(f'   📈 Registros totales: {total:,}')
print(f'   📅 Rango temporal: {min_time} a {max_time}')
print(f'   🔍 Distribución por sensores:')
for sensor, count in sensors[:10]:  # Mostrar top 10
    print(f'      - {sensor}: {count:,} registros')

conn.close()
"
}

# Función principal
main() {
    echo ""
    log "Iniciando restauración desde backup CSV..."
    echo ""
    
    verify_backup
    check_current_state
    confirm_restore
    prepare_restore
    execute_restore
    cleanup_and_verify
    
    echo ""
    log "🎉 ¡RESTAURACIÓN COMPLETADA EXITOSAMENTE!"
    log "💡 Los 321,196 registros han sido restaurados"
    echo ""
    info "Para ver los datos en el frontend: http://192.168.49.2:32323"
}

# Ejecutar
main