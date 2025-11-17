import { Injectable } from '@angular/core';
import { Observable, BehaviorSubject } from 'rxjs';

export interface SensorData {
  sensor_id: string;
  temperature: number;
  humidity: number;
  pressure: number;
  timestamp: string;
}

@Injectable({
  providedIn: 'root'
})
export class WebsocketService {
  private sensorsSubject = new BehaviorSubject<SensorData | null>(null);
  public sensors$ = this.sensorsSubject.asObservable();
  
  private connectionStatus = new BehaviorSubject<string>('disconnected');
  public connectionStatus$ = this.connectionStatus.asObservable();
  
  private ws: WebSocket | null = null;
  private simulationMode = false;
  private simulationInterval: any = null;

  // ✅ URL CORRECTA - Usar la IP de Minikube y puerto NodePort
  private readonly WS_URL = 'ws://192.168.49.2:30080/ws/sensors';
  private readonly MAX_RETRIES = 3;
  private retryCount = 0;

  constructor() {
    console.log('🔧 WebSocket Service - FIXED VERSION');
    console.log('   - Using DIRECT Minikube IP');
    console.log('   - Target URL:', this.WS_URL);
    this.connectToBackend();
  }

  connectToBackend() {
    try {
      console.log('🔄 CONNECTING to WebSocket...');
      console.log('   - URL:', this.WS_URL);
      
      this.connectionStatus.next('connecting');
      this.ws = new WebSocket(this.WS_URL);

      this.ws.onopen = () => {
        console.log('✅ ✅ ✅ CONNECTED to WebSocket!');
        this.connectionStatus.next('connected');
        this.simulationMode = false;
        this.retryCount = 0; // Reset retry counter
        
        if (this.simulationInterval) {
          clearInterval(this.simulationInterval);
          this.simulationInterval = null;
        }
      };

      this.ws.onmessage = (event) => {
        try {
          const data: SensorData = JSON.parse(event.data);
          console.log('📊 REAL sensor data:', data.sensor_id);
          this.sensorsSubject.next(data);
        } catch (error) {
          console.error('❌ Error parsing message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('❌ WebSocket connection error');
        this.connectionStatus.next('error');
        
        // Intentar reconexión automática
        if (this.retryCount < this.MAX_RETRIES) {
          this.retryCount++;
          console.log(`🔄 Retry ${this.retryCount}/${this.MAX_RETRIES} in 3s...`);
          setTimeout(() => this.connectToBackend(), 3000);
        } else {
          this.startSimulation();
        }
      };

      this.ws.onclose = (event) => {
        console.log('🔌 WebSocket closed');
        this.connectionStatus.next('disconnected');
        
        // Reconexión automática solo si no fue un cierre intencional
        if (event.code !== 1000 && this.retryCount < this.MAX_RETRIES) {
          this.retryCount++;
          console.log(`🔄 Auto-reconnect ${this.retryCount}/${this.MAX_RETRIES}`);
          setTimeout(() => this.connectToBackend(), 2000);
        }
      };

    } catch (error) {
      console.error('❌ Failed to create WebSocket:', error);
      this.connectionStatus.next('error');
      this.startSimulation();
    }
  }

  startSimulation() {
    if (!this.simulationMode) {
      console.log('🎭 Starting simulation mode');
      this.simulationMode = true;
      this.connectionStatus.next('simulation');
      
      this.simulationInterval = setInterval(() => {
        const simulatedData: SensorData = {
          sensor_id: 'simulated_' + Math.floor(5 * Math.random()),
          temperature: parseFloat((20 + 15 * Math.random()).toFixed(1)),
          humidity: parseFloat((40 + 40 * Math.random()).toFixed(1)),
          pressure: parseFloat((990 + 40 * Math.random()).toFixed(1)),
          timestamp: new Date().toISOString()
        };
        console.log('🎭 SIMULATED data:', simulatedData.sensor_id);
        this.sensorsSubject.next(simulatedData);
      }, 2000);
    }
  }

  isSimulationMode(): boolean {
    return this.simulationMode;
  }

  disconnect() {
    if (this.simulationInterval) {
      clearInterval(this.simulationInterval);
      this.simulationMode = false;
      this.simulationInterval = null;
    }
    if (this.ws) {
      this.ws.close(1000, 'Manual disconnect');
      this.ws = null;
    }
  }

  reconnect() {
    console.log('🔄 Manual reconnect requested');
    this.retryCount = 0;
    this.disconnect();
    setTimeout(() => this.connectToBackend(), 1000);
  }
}
