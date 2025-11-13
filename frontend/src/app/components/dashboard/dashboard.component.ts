import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router'; // 👈 Importar Router
import { Subscription } from 'rxjs';
import { WebsocketService, SensorData } from '../../services/websocket.service';

interface DashboardStats {
  avgTemperature: number;
  avgHumidity: number;
  avgPressure: number;
  maxTemperature: number;
  minTemperature: number;
  totalReadings: number;
  activeSensors: number;
  dataSource: string;
  lastUpdate: string;
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit, OnDestroy {
  sensors: SensorData[] = [];
  connectionStatus: string = 'disconnected';
  connectionStatusText: string = '🔴 Desconectado';
  isSimulation: boolean = false;
  stats: DashboardStats = this.getInitialStats();
  
  private subscription: Subscription = new Subscription();

  constructor(
    private websocketService: WebsocketService,
    private router: Router // 👈 Inyectar el Router
  ) {}

  // =========================================================
  // 🔹 CICLO DE VIDA
  // =========================================================
  ngOnInit() {
    this.subscription.add(
      this.websocketService.connectionStatus$.subscribe(status => {
        this.connectionStatus = status;
        this.isSimulation = this.websocketService.isSimulationMode();
        this.updateConnectionStatusText();
        this.updateStats();
      })
    );

    this.subscription.add(
      this.websocketService.sensors$.subscribe({
        next: (data) => {
          this.handleNewSensorData(data);
          this.updateStats();
        },
        error: (error) => {
          console.error('Error en el flujo de datos de sensores:', error);
        }
      })
    );
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
    this.websocketService.disconnect();
  }

  // =========================================================
  // 🔹 FUNCIONES PRINCIPALES
  // =========================================================
  private getInitialStats(): DashboardStats {
    return {
      avgTemperature: 0,
      avgHumidity: 0,
      avgPressure: 0,
      maxTemperature: 0,
      minTemperature: 0,
      totalReadings: 0,
      activeSensors: 0,
      dataSource: 'Sin datos',
      lastUpdate: new Date().toLocaleTimeString()
    };
  }

  private handleNewSensorData(data: SensorData) {
    this.sensors.unshift(data);
    if (this.sensors.length > 10) {
      this.sensors = this.sensors.slice(0, 10);
    }
  }

  updateStats() {
    if (this.sensors.length === 0) {
      this.stats = this.getInitialStats();
      return;
    }

    const temperatures = this.sensors.map(s => s.temperature);
    const humidities = this.sensors.map(s => s.humidity);
    const pressures = this.sensors.map(s => s.pressure);
    const uniqueSensors = new Set(this.sensors.map(s => s.sensor_id));

    this.stats = {
      avgTemperature: Number((temperatures.reduce((a, b) => a + b, 0) / temperatures.length).toFixed(1)),
      avgHumidity: Number((humidities.reduce((a, b) => a + b, 0) / humidities.length).toFixed(1)),
      avgPressure: Number((pressures.reduce((a, b) => a + b, 0) / pressures.length).toFixed(1)),
      maxTemperature: Number(Math.max(...temperatures).toFixed(1)),
      minTemperature: Number(Math.min(...temperatures).toFixed(1)),
      totalReadings: this.sensors.length,
      activeSensors: uniqueSensors.size,
      dataSource: this.isSimulation ? 'Simulación' : 'Backend Real',
      lastUpdate: new Date().toLocaleTimeString()
    };
  }

  private updateConnectionStatusText() {
    const statusMap: { [key: string]: string } = {
      'connected': '🟢 Conectado a Sensores Reales',
      'connecting': '🟡 Conectando...',
      'disconnected': '🔴 Desconectado',
      'error': '🔴 Error de Conexión',
      'simulation': '🎭 Modo Simulación',
      'failed': '🔴 Conexión Fallida'
    };
    this.connectionStatusText = statusMap[this.connectionStatus] || '⚪ Desconocido';
  }

  // =========================================================
  // 🔹 ACCIONES
  // =========================================================
  reconnect() {
    console.log('🔄 Reconexión manual solicitada');
    this.websocketService.disconnect();
    setTimeout(() => this.websocketService.connect(), 1000);
  }

  toggleSimulation() {
    this.websocketService.toggleSimulationMode();
  }

  clearData(): void {
    this.sensors = [];
    this.updateStats();
  }

  navigateToAbout() {
    console.log('➡️ Navegando a /about');
    this.router.navigate(['/about']);
  }

  // =========================================================
  // 🔹 UTILIDADES VISUALES
  // =========================================================
  trackBySensorId(index: number, sensor: SensorData): string {
    return sensor.sensor_id + sensor.timestamp;
  }

  isNewSensor(sensor: SensorData): boolean {
    return this.sensors[0] === sensor;
  }

  getConnectionColor(): string {
    const colorMap: { [key: string]: string } = {
      'connected': '#10b981',
      'connecting': '#f59e0b',
      'disconnected': '#ef4444',
      'error': '#ef4444',
      'simulation': '#8b5cf6',
      'failed': '#ef4444'
    };
    return colorMap[this.connectionStatus] || '#6b7280';
  }

  getTemperatureColor(temp: number): string {
    if (temp < 20) return '#3b82f6'; // Azul - frío
    if (temp < 26) return '#10b981'; // Verde - normal
    if (temp < 30) return '#f59e0b'; // Amarillo - cálido
    return '#ef4444'; // Rojo - caliente
  }

  getHumidityColor(humidity: number): string {
    if (humidity < 40) return '#f59e0b'; // Amarillo - seco
    if (humidity < 70) return '#10b981'; // Verde - normal
    return '#3b82f6'; // Azul - húmedo
  }
}
