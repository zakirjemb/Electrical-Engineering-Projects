import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MHeaderComponent } from './m-framework/components/m-header/m-header.component';
import { MCardComponent } from './m-framework/components/m-card/m-card.component';
import { MContainerComponent } from './m-framework/components/m-container/m-container.component';
import { CommonModule } from '@angular/common';


@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    MHeaderComponent,
    RouterOutlet,
    CommonModule,
    MContainerComponent
  ],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent {
  title = 'DeliveryApp';

  constructor() {
  
  }
  features = [
  { name: 'Schedule View', path: 'schedule' },
  { name: 'Session Creation and Deletion', path: 'session' },
  { name: 'Load Calculation', path: 'load' },
  { name: 'Error Table', path: 'error' },
  { name: 'Version History', path: 'version' }
  , { name: 'Tracker', path: 'tracker' },
  { name: 'OBAD', path: 'obad' }
];

}
