from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import random
import asyncio
from datetime import datetime

app = FastAPI(title="SkySense API")

# CORS para desarrollo
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.websocket("/ws/sensors")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("✅ WebSocket client connected")
    
    try:
        while True:
            # DATOS REALES del backend
            data = {
                "sensor_id": f"sensor_{random.randint(1,5)}",
                "temperature": round(random.uniform(18, 33), 2),
                "humidity": round(random.uniform(40, 75), 2),
                "pressure": round(random.uniform(990, 1020), 2),
                "timestamp": datetime.now().isoformat()
            }
            await websocket.send_json(data)
            await asyncio.sleep(2)
    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        print("🔌 WebSocket client disconnected")

@app.get("/")
def root():
    return {"status": "SkySense API running", "version": "1.0.0"}

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    print("🚀 SkySense Backend starting...")
    print("🌐 HTTP: http://0.0.0.0:8000")
    print("📡 WebSocket: ws://0.0.0.0:8000/ws/sensors")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")