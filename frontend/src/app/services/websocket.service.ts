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

  constructor() {
    console.log('🚀 WebSocket Service - KUBERNETES FIXED V2');
    console.log('   - Using Kubernetes service URL');
    this.connectToBackend();
  }

  connectToBackend() {
    try {
      // ✅ URL ABSOLUTAMENTE CORRECTA para Kubernetes
      const wsUrl = 'ws://backend-service.skysense.svc.cluster.local:8000/ws/sensors';
      
      console.log('🔄 CONNECTING to Kubernetes WebSocket...');
      console.log('   - Target URL:', wsUrl);
      console.log('   - Browser location:', window.location.href);
      
      this.connectionStatus.next('connecting');
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log('✅ ✅ ✅ SUCCESS! Connected to Kubernetes WebSocket');
        console.log('   - Backend service is reachable');
        this.connectionStatus.next('connected');
        this.simulationMode = false;
        if (this.simulationInterval) {
          clearInterval(this.simulationInterval);
          this.simulationInterval = null;
        }
      };

      this.ws.onmessage = (event) => {
        try {
          const data: SensorData = JSON.parse(event.data);
          console.log('📊 REAL DATA from backend:', {
            sensor: data.sensor_id,
            temperature: data.temperature + '°C',
            humidity: data.humidity + '%',
            pressure: data.pressure + ' hPa'
          });
          this.sensorsSubject.next(data);
        } catch (error) {
          console.error('❌ Error parsing message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('❌ WebSocket ERROR - Cannot reach backend in Kubernetes');
        console.error('   - URL attempted:', wsUrl);
        console.error('   - This means:');
        console.error('     1. Backend service is not running');
        console.error('     2. Network connectivity issue');
        console.error('     3. Backend not exposing WebSocket port');
        this.connectionStatus.next('error');
        this.startSimulation();
      };

      this.ws.onclose = (event) => {
        console.log('🔌 WebSocket connection closed');
        console.log('   - Code:', event.code, 'Reason:', event.reason);
        this.connectionStatus.next('disconnected');
        if (!this.simulationMode) {
          console.log('🔄 Will retry in 5 seconds...');
          setTimeout(() => this.connectToBackend(), 5000);
        }
      };

    } catch (error) {
      console.error('❌ CRITICAL: Failed to create WebSocket:', error);
      this.connectionStatus.next('error');
      this.startSimulation();
    }
  }

  startSimulation() {
    if (!this.simulationMode) {
      console.log('🎭 STARTING SIMULATION MODE');
      console.log('   - Backend WebSocket is not available');
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
        console.log('🎭 SIMULATED data (fallback):', {
          sensor: simulatedData.sensor_id,
          temp: simulatedData.temperature + '°C'
        });
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
      this.ws.close();
      this.ws = null;
    }
  }

  reconnect() {
    console.log('🔄 Manual reconnect requested');
    this.disconnect();
    this.connectToBackend();
  }
}