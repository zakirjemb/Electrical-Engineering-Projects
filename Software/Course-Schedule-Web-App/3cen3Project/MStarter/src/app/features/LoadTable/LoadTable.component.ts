import { Component, OnInit, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PersistenceService,LoadItem } from '../../m-framework/services/persistence.service';
import { MContainerComponent } from '../../m-framework/components/m-container/m-container.component';
import { MAhaComponent } from '../../m-framework/components/m-aha/m-aha.component';
import { MCardComponent } from "../../m-framework/components/m-card/m-card.component";
import { Router } from '@angular/router';
import { AuthService } from '../auth/auth.service';

@Component({
  selector: 'app-LoadTable',
  standalone: true,
  imports: [CommonModule, MContainerComponent, MAhaComponent, MCardComponent],
  templateUrl: './LoadTable.component.html',
  styleUrls: ['./LoadTable.component.css']
})
export class LoadComponent implements OnInit {
  instructorLoads: LoadItem[] = [];
  loading = false;
  error: string | null = null;

  constructor(
    private persistenceService: PersistenceService, 
    private  router:Router,
    private ngZone: NgZone,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    console.log('LoadComponent initialized');
    this.fetchInstructorLoads();
  }

  async fetchInstructorLoads() {
    this.loading = true;
    this.error = null;

    try {
      const data = await this.persistenceService.calculateLoad();
      this.ngZone.run(() => {
        this.instructorLoads = data;
        console.log('Instructor Loads:', this.instructorLoads);
      });
    } catch (err) {
      console.error('Failed to fetch instructor loads:', err);
      this.error = 'Failed to load instructor data.';
    } finally {
      this.loading = false;
    }
  }

  getLoadClass(count: number): string {
    if (count < 4) return 'underload';
    if (count === 4) return 'balanced';
    return 'overload';
  }
  goToHome(){
    this.router.navigateByUrl("/''")
  }

   goToSchedule() {
    this.router.navigateByUrl("/schedule");
  }

  goToSession() {
    this.router.navigateByUrl("/session");
  }

  goToError() {
    this.router.navigateByUrl("/error");
  }

  goToVersion() {
    this.router.navigateByUrl("/version");
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
