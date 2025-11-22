#!/bin/bash
# backup-csv-millones.sh

set -e

BACKUP_DIR="/home/pashitox/skysense-backups"
mkdir -p $BACKUP_DIR

echo "=== BACKUP CSV COMPRIMIDO (EFICIENTE) ==="

POD_NAME=$(kubectl get pods -n skysense -l app=backend -o jsonpath='{.items[0].metadata.name}')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_csv_${TIMESTAMP}.csv.gz"

echo "🗜️ Creando backup comprimido..."
kubectl exec -n skysense $POD_NAME -- python3 -c "
import psycopg2, csv, gzip

conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
cur = conn.cursor()

print('📊 Iniciando exportación a CSV comprimido...')

# Obtener total para progreso
cur.execute('SELECT COUNT(*) FROM sensor_data')
total = cur.fetchone()[0]
print(f'📈 Total a exportar: {total:,} registros')

# Exportar en chunks para no saturar memoria
with gzip.open('/tmp/backup_large.csv.gz', 'wt', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['id', 'sensor_id', 'temperature', 'timestamp'])  # Header
    
    CHUNK_SIZE = 50000
    offset = 0
    processed = 0
    
    while True:
        cur.execute('''
            SELECT id, sensor_id, temperature, timestamp 
            FROM sensor_data 
            ORDER BY id 
            LIMIT %s OFFSET %s
        ''', (CHUNK_SIZE, offset))
        
        chunk = cur.fetchall()
        if not chunk:
            break
            
        for row in chunk:
            writer.writerow(row)
            processed += 1
        
        offset += CHUNK_SIZE
        if processed % 100000 == 0:
            print(f'📦 Exportados: {processed:,} / {total:,} registros')

conn.close()
print(f'✅ Exportación completada: {processed:,} registros')
"

# Copiar a local
kubectl cp skysense/$POD_NAME:/tmp/backup_large.csv.gz $BACKUP_FILE

# Verificar
echo "🔍 Verificando backup comprimido..."
size=$(du -h "$BACKUP_FILE" | cut -f1)
lines=$(gunzip -c "$BACKUP_FILE" | wc -l)
records=$((lines - 1))

echo "✅ BACKUP CSV COMPRIMIDO:"
echo "   📁 Archivo: $(basename $BACKUP_FILE)"
echo "   💾 Tamaño: $size"
echo "   📊 Registros: $records"
echo "   🗜️  Compresión: $(echo "scale=2; $(gunzip -c "$BACKUP_FILE" | wc -c) / $(wc -c < "$BACKUP_FILE")" | bc)x"

echo "🎉 Backup eficiente completado"