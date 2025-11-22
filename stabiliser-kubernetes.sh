#!/bin/bash

echo "🔧 SkySense Stabilizer"
echo "======================"

# 1. Reiniciar los deployments problemáticos
echo "🔄 Reiniciando deployments..."
kubectl rollout restart deployment/frontend -n skysense
kubectl rollout restart deployment/backend -n skysense

echo "⏳ Esperando a que se estabilicen..."
sleep 20

# 2. Verificar estado
echo "📊 Estado actual:"
kubectl get pods -n skysense

# 3. Verificar que todo funcione
echo ""
echo "🌐 Verificando servicios..."
curl -s http://192.168.49.2:32323 > /dev/null && echo "✅ Frontend funcionando" || echo "❌ Frontend con problemas"
curl -s http://192.168.49.2:30080/api/health > /dev/null && echo "✅ Backend funcionando" || echo "❌ Backend con problemas"

# 4. Mostrar datos actuales
echo ""
echo "📈 Datos en tiempo real:"
kubectl exec -n skysense deployment/backend -- python3 -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://user:password@postgresql:5432/skysense')
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) as total, MAX(timestamp) as last FROM sensor_data')
    total, last = cur.fetchone()
    print(f'✅ {total:,} registros | Último: {last}')
    conn.close()
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "🎉 Sistema estabilizado!"
echo "💡 Abre: http://192.168.49.2:32323"