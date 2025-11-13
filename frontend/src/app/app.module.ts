import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppRoutingModule } from '../../src/app/app-routing.module';

import { AppComponent } from '../../src/app/app.component';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AboutComponent } from './components/about/about.component';

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
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }