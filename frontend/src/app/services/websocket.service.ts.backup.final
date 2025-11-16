import { Injectable } from '@angular/core';
import { Observable, Subject, BehaviorSubject } from 'rxjs';
import { environment } from '../../environments/environment';

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
  private sensorsSubject = new Subject<SensorData>();
  public sensors$ = this.sensorsSubject.asObservable();
  
  private connectionStatus = new BehaviorSubject<string>('disconnected');
  public connectionStatus$ = this.connectionStatus.asObservable();
  
  private ws: WebSocket | null = null;
  private simulationMode = false;
  private simulationInterval: any = null;

  // URL para Docker - usa environment
  private readonly wsUrl = environment.wsUrl + '/ws/sensors';

  constructor() {
    console.log('🔧 WebSocket Configuration:');
    console.log('   - Environment:', environment.production ? 'production' : 'development');
    console.log('   - WebSocket URL:', this.wsUrl);
    
    this.connectToBackend();
  }

  // 👇 MÉTODO CONNECT QUE FALTABA
  connect() {
    if (this.simulationMode) {
      this.stopSimulation();
    }
    this.connectToBackend();
  }

  private connectToBackend() {
    if (this.simulationMode) return;

    console.log('🔄 Connecting to backend...');
    this.connectionStatus.next('connecting');

    try {
      this.ws = new WebSocket(this.wsUrl);
      
      this.ws.onopen = () => {
        console.log('✅ CONNECTED to backend WebSocket');
        this.connectionStatus.next('connected');
        this.simulationMode = false;
      };

      this.ws.onmessage = (event) => {
        try {
          const data: SensorData = JSON.parse(event.data);
          console.log('📨 REAL data from backend:', data);
          this.sensorsSubject.next(data);
        } catch (error) {
          console.error('❌ Error parsing message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('❌ WebSocket error:', error);
        this.connectionStatus.next('error');
        this.startSimulationAfterTimeout();
      };

      this.ws.onclose = () => {
        console.log('🔌 WebSocket closed');
        this.connectionStatus.next('disconnected');
        this.startSimulationAfterTimeout();
      };

    } catch (error) {
      console.error('❌ Failed to create WebSocket:', error);
      this.startSimulationAfterTimeout();
    }
  }

  private startSimulationAfterTimeout() {
    // Esperar 3 segundos antes de activar simulación
    setTimeout(() => {
      if (this.connectionStatus.value !== 'connected') {
        console.log('🎭 Backend not available - Starting simulation');
        this.startSimulation();
      }
    }, 3000);
  }

  private startSimulation() {
    if (this.simulationMode) return;
    
    this.simulationMode = true;
    this.connectionStatus.next('simulation');
    
    console.log('🎭 SIMULATION MODE ACTIVE - Generating fake data');
    
    // Generar primer dato inmediatamente
    this.generateSimulatedData();
    
    // Generar datos cada 2 segundos
    this.simulationInterval = setInterval(() => {
      this.generateSimulatedData();
    }, 2000);
  }

  private generateSimulatedData() {
    const mockData: SensorData = {
      sensor_id: 'sensor_' + (1000 + Math.floor(Math.random() * 1000)),
      temperature: parseFloat((20 + Math.random() * 15).toFixed(1)),
      humidity: parseFloat((30 + Math.random() * 50).toFixed(1)),
      pressure: parseFloat((1000 + Math.random() * 50).toFixed(1)),
      timestamp: new Date().toISOString()
    };
    console.log('🎭 SIMULATED data:', mockData);
    this.sensorsSubject.next(mockData);
  }

  private stopSimulation() {
    if (this.simulationMode) {
      this.simulationMode = false;
      if (this.simulationInterval) {
        clearInterval(this.simulationInterval);
        this.simulationInterval = null;
      }
      console.log('🛑 Simulation mode stopped');
    }
  }

  // 👇 MÉTODO TOGGLE SIMULATION QUE FALTABA
  toggleSimulationMode() {
    if (this.simulationMode) {
      this.stopSimulation();
      this.connectionStatus.next('disconnected');
      this.connectToBackend(); // Intentar reconexión real
    } else {
      this.startSimulation();
    }
  }

  disconnect() {
    this.stopSimulation();
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.connectionStatus.next('disconnected');
  }

  isSimulationMode(): boolean {
    return this.simulationMode;
  }
}