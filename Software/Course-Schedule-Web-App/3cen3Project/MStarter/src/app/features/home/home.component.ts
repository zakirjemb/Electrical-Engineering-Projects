import { Component } from '@angular/core';
import { MContainerComponent } from '../../m-framework/components/m-container/m-container.component';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MCardComponent } from '../../m-framework/components/m-card/m-card.component';
import { MAhaComponent } from '../../m-framework/components/m-aha/m-aha.component';
import { MAnalogOutputComponent } from '../../m-framework/components/m-analog-output/m-analog-output.component';
import { MMainMenuComponent } from '../../m-framework/components/m-main-menu/m-main-menu.component';
import { AuthService } from '../../features/auth/auth.service'; 
import { Firestore, collection, addDoc } from '@angular/fire/firestore';
import { MLoginComponent } from "../../m-framework/components/m-login/m-login.component";

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [
  
    CommonModule,
    FormsModule,
    MContainerComponent,
   
],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css',
})
export class HomeComponent {

  constructor(
    public router: Router,
    private authService: AuthService 
  ) {}

  goToSchedule() {
    this.router.navigateByUrl("/schedule");
  }

  goToSession() {
    this.router.navigateByUrl("/session");
  }

  goToLoad() {
    this.router.navigateByUrl("/load");
  }

  goToError() {
    this.router.navigateByUrl("/error");
  }

  goToVersion() {
    this.router.navigateByUrl("/version");
  }
  goToTracker() {
    this.router.navigateByUrl("/tracker");
  }
   goToOBAD() {
    this.router.navigateByUrl("/obad");
  }

async logout() {
  try {
    await this.authService.logout();
    this.router.navigate(['/login']);
  } catch (error) {
    console.error('Logout Error:', error);
  }
}

}
