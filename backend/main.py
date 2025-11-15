from fastapi import FastAPI, WebSocket, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import random
import asyncio
from datetime import datetime

# Importar desde database en lugar de models
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

# Crear tablas al iniciar (solo si no existen)
@app.on_event("startup")
def startup_event():
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created/verified")

@app.websocket("/ws/sensors")
async def websocket_endpoint(websocket: WebSocket, db: Session = Depends(get_db)):
    await websocket.accept()
    print("✅ WebSocket client connected")
    
    try:
        while True:
            # Generar datos reales
            data = {
                "sensor_id": f"sensor_{random.randint(1,5)}",
                "temperature": round(random.uniform(18, 33), 2),
                "humidity": round(random.uniform(40, 75), 2), 
                "pressure": round(random.uniform(990, 1020), 2),
                "timestamp": datetime.now().isoformat()
            }
            
            # Guardar en base de datos
            db_data = SensorData(
                sensor_id=data["sensor_id"],
                temperature=data["temperature"],
                humidity=data["humidity"],
                pressure=data["pressure"]
            )
            db.add(db_data)
            db.commit()
            
            # Enviar por WebSocket
            await websocket.send_json(data)
            await asyncio.sleep(2)
            
    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        print("🔌 WebSocket client disconnected")

@app.get("/")
def root():
    return {"status": "SkySense API running", "version": "2.0.0", "database": "PostgreSQL"}

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/api/sensors")
def get_sensor_data(db: Session = Depends(get_db), limit: int = 100):
    data = db.query(SensorData).order_by(SensorData.timestamp.desc()).limit(limit).all()
    return {
        "count": len(data),
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

@app.get("/api/sensors/{sensor_id}")
def get_sensor_by_id(sensor_id: str, db: Session = Depends(get_db)):
    data = db.query(SensorData).filter(SensorData.sensor_id == sensor_id).order_by(SensorData.timestamp.desc()).limit(50).all()
    return {
        "sensor_id": sensor_id,
        "count": len(data),
        "readings": [
            {
                "temperature": item.temperature,
                "humidity": item.humidity,
                "timestamp": item.timestamp.isoformat()
            } for item in data
        ]
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 SkySense Backend with PostgreSQL starting...")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
