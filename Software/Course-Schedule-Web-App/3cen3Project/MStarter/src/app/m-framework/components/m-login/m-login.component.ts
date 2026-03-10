import { Component } from '@angular/core';

@Component({
  selector: 'm-login',
  standalone: true,
  imports: [],
  templateUrl: './m-login.component.html',
  styleUrl: './m-login.component.css'
})
export class MLoginComponent {
  rightPanelActive: boolean = false;

  activateRightPanel(): void {
    this.rightPanelActive = true;
  }

  deactivateRightPanel(): void {
    this.rightPanelActive = false;
  }
}
