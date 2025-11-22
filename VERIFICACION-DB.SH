#!/bin/bash

echo "🔍 VERIFICANDO ESTRUCTURA DE LA BASE DE DATOS"
echo "============================================"

# Conectar a PostgreSQL y mostrar la estructura
kubectl exec -n skysense deployment/postgresql -- psql -U user -d skysense -c "
-- Mostrar todas las tablas
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Mostrar estructura de sensor_data
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'sensor_data' 
ORDER BY ordinal_position;

-- Estadísticas de la tabla
SELECT 
    COUNT(*) as total_registros,
    COUNT(DISTINCT sensor_id) as sensores_unicos,
    MIN(timestamp) as primera_fecha,
    MAX(timestamp) as ultima_fecha,
    ROUND(AVG(temperature)::numeric, 2) as temp_promedio
FROM sensor_data;
"

echo ""
echo "📊 MUESTRA DE DATOS RECIENTES"
echo "============================="

# Mostrar los últimos 5 registros
kubectl exec -n skysense deployment/postgresql -- psql -U user -d skysense -c "
SELECT id, sensor_id, temperature, timestamp 
FROM sensor_data 
ORDER BY timestamp DESC 
LIMIT 5;
"