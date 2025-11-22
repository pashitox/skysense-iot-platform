#!/bin/bash
echo "🔍 Verificando backup..."
if [ -f ~/skysense-backup.json ]; then
    python3 -c "import json; d=json.load(open('skysense-backup.json')); print(f'📊 {len(d)} registros guardados')"
else
    echo "❌ No hay backup. Ejecuta: ./save-backup.sh"
fi
