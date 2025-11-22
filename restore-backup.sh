#!/bin/bash
# empresa-restaurar-simple.sh

BACKUP_FILE="$1"

echo "=== RESTAURACIÓN SIMPLE DE LOTE ==="

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Archivo de backup no válido: $BACKUP_FILE"
    exit 1
fi

echo "📦 Restaurando: $(basename "$BACKUP_FILE")"

POD_NAME=$(kubectl get pods -n skysense -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Copiar backup al pod
kubectl cp "$BACKUP_FILE" skysense/$POD_NAME:/tmp/backup_lote.json

# Restaurar
kubectl exec -n skysense $POD_NAME -- python3 -c "
import psycopg2, json

print('📊 Iniciando restauración de lote...')

# Leer backup
with open('/tmp/backup_lote.json', 'r') as f:
    backup = json.load(f)

# Conectar a BD
conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
cur = conn.cursor()

# Restaurar registros
registros = backup['data']
insertados = 0

for registro in registros:
    try:
        cur.execute('''
            INSERT INTO sensor_data (id, sensor_id, temperature, timestamp) 
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (id) DO NOTHING
        ''', (
            registro['id'],
            registro['sensor'], 
            registro['temp'],
            registro['time']
        ))
        
        if cur.rowcount == 1:
            insertados += 1
            
    except Exception as e:
        print(f'⚠️  Error con registro {registro[\"id\"]}: {e}')

conn.commit()
conn.close()

print(f'✅ Lote restaurado: {insertados}/{len(registros)} registros insertados')
"

# Limpiar
kubectl exec -n skysense $POD_NAME -- rm -f /tmp/backup_lote.json

echo "✅ LOTE RESTAURADO"