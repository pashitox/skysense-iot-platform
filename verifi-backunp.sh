#!/bin/bash
# verificar-millones.sh

BACKUP_DIR="/home/pashitox/skysense-backups"

echo "=== VERIFICACIÓN ESCALABLE ==="

echo "📁 Buscando backups..."
echo ""

# Verificar backups por lotes
find "$BACKUP_DIR" -name "backup_*_part_*.json" -type f | sort | head -5 | while read file; do
    echo "--- $(basename "$file") ---"
    
    python3 -c "
import json
with open('$file', 'r') as f:
    data = json.load(f)

print(f'📦 Lote {data[\"metadata\"][\"parte\"]}:')
print(f'   • Registros: {data[\"metadata\"][\"total_registros_lote\"]:,}')
print(f'   • Proximo ID: {data[\"metadata\"][\"proximo_id\"]}')
if data['data']:
    print(f'   • Rango: {data[\"data\"][0][\"id\"]} - {data[\"data\"][-1][\"id\"]}')
"
    echo ""
done

# Verificar backups CSV
find "$BACKUP_DIR" -name "backup_csv_*.csv.gz" -type f | sort -r | head -3 | while read file; do
    echo "--- $(basename "$file") ---"
    
    size=$(du -h "$file" | cut -f1)
    lines=$(gunzip -c "$file" 2>/dev/null | wc -l)
    records=$((lines - 1))
    
    echo "🗜️  CSV Comprimido:"
    echo "   💾 Tamaño: $size"
    echo "   📊 Registros: $records"
    
    # Mostrar sample
    echo "   🔍 Muestra:"
    gunzip -c "$file" 2>/dev/null | head -3
    echo ""
done

# Estadísticas generales
echo "📈 ESTADÍSTICAS GENERALES:"
total_parts=$(find "$BACKUP_DIR" -name "backup_*_part_*.json" -type f | wc -l)
total_csv=$(find "$BACKUP_DIR" -name "backup_csv_*.csv.gz" -type f | wc -l)
total_size=$(du -sh "$BACKUP_DIR" | cut -f1)

echo "   📦 Backups por lotes: $total_parts"
echo "   🗜️  Backups CSV: $total_csv"
echo "   💾 Espacio total: $total_size"

echo "✅ Verificación completada"