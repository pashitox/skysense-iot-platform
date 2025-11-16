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
  private reconnectTimeout: any = null;

  constructor() {
    console.log('🔧 WebSocket Configuration:');
    console.log('   - Environment:', environment.production ? 'production' : 'development');
    console.log('   - WebSocket URL:', environment.wsUrl);
    
    this.connectToBackend();
  }

  private connectToBackend(): void {
    try {
      console.log('🔄 Connecting to backend...');
      console.log('   - Target URL:', environment.wsUrl);
      this.connectionStatus.next('connecting');
      
      // Usar EXCLUSIVAMENTE la URL del environment
      this.ws = new WebSocket(environment.wsUrl);

      this.ws.onopen = () => {
        console.log('✅ CONNECTED to backend WebSocket');
        this.connectionStatus.next('connected');
        this.simulationMode = false;
        if (this.simulationInterval) {
          clearInterval(this.simulationInterval);
          this.simulationInterval = null;
        }
      };

      this.ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          console.log('📊 Received real sensor data:', data.sensor_id);
          this.sensorsSubject.next(data);
        } catch (error) {
          console.error('❌ Error parsing WebSocket message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('❌ WebSocket error:', error);
        this.connectionStatus.next('error');
        this.startSimulation();
      };

      this.ws.onclose = (event) => {
        console.log('🔌 WebSocket closed');
        this.connectionStatus.next('disconnected');
        
        // Intentar reconectar después de 5 segundos
        if (!this.simulationMode) {
          console.log('🔄 Will attempt reconnect in 5 seconds...');
          this.reconnectTimeout = setTimeout(() => {
            this.connectToBackend();
          }, 5000);
        }
      };

    } catch (error) {
      console.error('❌ Failed to create WebSocket:', error);
      this.connectionStatus.next('error');
      this.startSimulation();
    }
  }

  private startSimulation(): void {
    if (this.simulationMode) return;
    
    console.log('🎭 Backend not available - Starting simulation');
    this.simulationMode = true;
    this.connectionStatus.next('simulation');
    
    this.simulationInterval = setInterval(() => {
      const simulatedData: SensorData = {
        sensor_id: 'simulated_' + Math.floor(Math.random() * 5),
        temperature: 20 + Math.random() * 15,
        humidity: 40 + Math.random() * 40,
        pressure: 990 + Math.random() * 40,
        timestamp: new Date().toISOString()
      };
      console.log('🎭 SIMULATED data:', simulatedData);
      this.sensorsSubject.next(simulatedData);
    }, 2000);
  }

  // Métodos públicos que el dashboard espera
  public isSimulationMode(): boolean {
    return this.simulationMode;
  }

  public disconnect(): void {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
    }
    if (this.simulationInterval) {
      clearInterval(this.simulationInterval);
      this.simulationMode = false;
    }
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  public connect(): void {
    this.disconnect();
    this.connectToBackend();
  }

  public toggleSimulationMode(): void {
    if (this.simulationMode) {
      this.disconnect();
      this.connectToBackend();
    } else {
      this.disconnect();
      this.startSimulation();
    }
  }

  public reconnect(): void {
    this.connect();
  }

  public close(): void {
    this.disconnect();
  }
}
