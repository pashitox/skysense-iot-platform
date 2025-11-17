from fastapi import FastAPI, WebSocket, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy.exc import OperationalError
from sqlalchemy import text
import random
import asyncio
from datetime import datetime
import time
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Importar desde database
from database import get_db, SensorData, engine, Base

app = FastAPI(title="SkySense API")

# CORS para desarrollo
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Crear tablas con reintentos
@app.on_event("startup")
def startup_event():
    max_retries = 10
    retry_delay = 5
    
    for attempt in range(max_retries):
        try:
            logger.info(f"🔄 Database connection attempt {attempt + 1}/{max_retries}")
            Base.metadata.create_all(bind=engine)
            
            # Test connection
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                
            logger.info("✅ Database tables created/verified")
            return
        except OperationalError as e:
            logger.warning(f"⚠️ Database not ready: {e}")
            if attempt < max_retries - 1:
                logger.info(f"⏳ Retrying in {retry_delay}s...")
                time.sleep(retry_delay)
            else:
                logger.error("💥 Failed to connect to database after all retries")

# Lista para mantener múltiples conexiones WebSocket
active_connections = []

@app.websocket("/ws/sensors")
async def websocket_endpoint(websocket: WebSocket, db: Session = Depends(get_db)):
    await websocket.accept()
    logger.info(f"✅ WebSocket client connected. Total connections: {len(active_connections) + 1}")
    
    # Agregar a conexiones activas
    active_connections.append(websocket)
    
    try:
        # Enviar mensaje de bienvenida
        welcome_msg = {
            "type": "connection",
            "status": "connected", 
            "message": "Conectado al servidor de sensores",
            "timestamp": datetime.now().isoformat()
        }
        await websocket.send_json(welcome_msg)
        
        # Enviar datos históricos recientes
        recent_data = db.query(SensorData).order_by(SensorData.timestamp.desc()).limit(5).all()
        if recent_data:
            history_msg = {
                "type": "history",
                "data": [
                    {
                        "sensor_id": item.sensor_id,
                        "temperature": float(item.temperature),
                        "humidity": float(item.humidity),
                        "pressure": float(item.pressure),
                        "timestamp": item.timestamp.isoformat()
                    } for item in recent_data
                ]
            }
            await websocket.send_json(history_msg)
        
        # Bucle principal de datos en tiempo real
        while True:
            # Generar datos de sensores
            data = {
                "type": "sensor_data",
                "sensor_id": f"sensor_{random.randint(1,5)}",
                "temperature": round(random.uniform(18, 33), 2),
                "humidity": round(random.uniform(40, 75), 2), 
                "pressure": round(random.uniform(990, 1020), 2),
                "timestamp": datetime.now().isoformat()
            }
            
            try:
                # Guardar en base de datos
                db_data = SensorData(
                    sensor_id=data["sensor_id"],
                    temperature=data["temperature"],
                    humidity=data["humidity"],
                    pressure=data["pressure"]
                )
                db.add(db_data)
                db.commit()
                logger.info(f"💾 Data saved: {data['sensor_id']}")
            except Exception as db_error:
                logger.error(f"⚠️ Error saving to DB: {db_error}")
                db.rollback()
            
            # Enviar a TODAS las conexiones activas
            for connection in active_connections:
                try:
                    await connection.send_json(data)
                except Exception as e:
                    logger.warning(f"⚠️ Error sending to client: {e}")
                    # Remover conexiones muertas
                    if connection in active_connections:
                        active_connections.remove(connection)
            
            await asyncio.sleep(2)
            
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        # Remover conexión al desconectarse
        if websocket in active_connections:
            active_connections.remove(websocket)
        logger.info(f"🔌 WebSocket client disconnected. Remaining: {len(active_connections)}")

@app.get("/")
def root():
    return {
        "status": "SkySense API running", 
        "version": "3.0.0",
        "active_websockets": len(active_connections),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"
    
    return {
        "status": "healthy", 
        "database": db_status,
        "active_connections": len(active_connections),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/sensors")
def get_sensor_data(db: Session = Depends(get_db), limit: int = 100):
    try:
        data = db.query(SensorData).order_by(SensorData.timestamp.desc()).limit(limit).all()
        return {
            "count": len(data),
            "active_connections": len(active_connections),
            "sensors": [
                {
                    "id": item.id,
                    "sensor_id": item.sensor_id,
                    "temperature": item.temperature,
                    "humidity": item.humidity,
                    "pressure": item.pressure,
                    "timestamp": item.timestamp.isoformat()
                } for item in data
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database unavailable: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
