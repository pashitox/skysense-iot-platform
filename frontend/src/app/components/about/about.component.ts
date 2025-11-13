import { Component } from '@angular/core';
import { Router } from '@angular/router'; // 👈 Import necesario para navegar

@Component({
  selector: 'app-about',
  templateUrl: './about.component.html',
  styleUrls: ['./about.component.css']
})
export class AboutComponent {
  constructor(private router: Router) {}

  // 🔹 Datos básicos del proyecto
  projectInfo = {
    name: 'SkySense IoT Dashboard',
    version: '1.0.0',
    description: 'Sistema de monitoreo en tiempo real para sensores IoT',
    features: [
      'Visualización en tiempo real',
      'Estadísticas automáticas',
      'Modo simulación integrado',
      'Interfaz responsive'
    ],
    technologies: [
      'Angular 16+',
      'TypeScript',
      'WebSocket',
      'FastAPI',
      'Docker'
    ]
  };

  // 🔹 Contador de visitas
  visitCount: number = 0;

  // Incrementar contador
  incrementCounter() {
    this.visitCount++;
  }

  // Resetear contador
  resetCounter() {
    this.visitCount = 0;
  }

  // 🔹 Mostrar/ocultar detalles técnicos
  showTechDetails: boolean = false;

  toggleTechDetails() {
    this.showTechDetails = !this.showTechDetails;
  }

  // 🔹 Método para volver al dashboard
  navigateToDashboard() {
    this.router.navigate(['/dashboard']);
  }
}
