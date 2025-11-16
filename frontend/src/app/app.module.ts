import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppRoutingModule } from '../../src/app/app-routing.module';

import { AppComponent } from './app.component';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AboutComponent } from './components/about/about.component';
import { environment } from '../environments/environment.prod';

@NgModule({
  declarations: [
    AppComponent,
    DashboardComponent,
    AboutComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule  // 👈 Esto incluye RouterModule
  ],
  providers: [
    {
      provide: 'WS_URL',
      useValue: environment.wsUrl
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }