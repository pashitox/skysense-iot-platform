-- Script de inicialización AUTOMÁTICO de PostgreSQL
-- Se ejecuta SOLO la primera vez que se crea la base de datos

-- Crear la tabla principal
CREATE TABLE IF NOT EXISTS sensor_data (
    id SERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    pressure DECIMAL(7,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices para mejor performance
CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON sensor_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_sensor_data_sensor_id ON sensor_data(sensor_id);

-- Insertar datos de prueba iniciales (opcional)
INSERT INTO sensor_data (sensor_id, temperature, humidity, pressure) 
VALUES 
  ('sensor_1', 22.5, 65.0, 1013.25),
  ('sensor_2', 23.1, 62.5, 1012.80),
  ('sensor_3', 21.8, 68.2, 1013.75)
ON CONFLICT DO NOTHING;

-- Verificar que todo se creó correctamente
DO $$ 
BEGIN
    RAISE NOTICE '✅ Base de datos SkySense inicializada correctamente';
    RAISE NOTICE '📊 Tabla sensor_data creada/verificada';
END $$;
