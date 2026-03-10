import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PersistenceService } from '../../m-framework/services/persistence.service';
import { MContainerComponent } from '../../m-framework/components/m-container/m-container.component';
import { MCardComponent } from '../../m-framework/components/m-card/m-card.component';
import { MAhaComponent } from '../../m-framework/components/m-aha/m-aha.component';
import { Router } from '@angular/router';
import { AuthService } from '../auth/auth.service';
@Component({
  selector: 'app-ErrorTable',
  standalone: true,
  imports: [CommonModule, MContainerComponent, MAhaComponent],
  templateUrl: './ErrorTable.component.html',
  styleUrls: ['./ErrorTable.component.css']
})
export class ErrorComponent implements OnInit {
  messages: string[] = [];
  loading = false;
  error: string | null = null;

  constructor(private persistenceService: PersistenceService,
     private router:Router,
    private authService:AuthService) {}

  ngOnInit(): void {
    this.loadConflicts();
  }

  async loadConflicts() {
    this.loading = true;
    this.error = null;
    try {
      this.messages = await this.persistenceService.detectConflicts();
    } catch (err) {
      console.error(' Failed to fetch conflicts:', err);
      this.error = 'Failed to load error and warning messages.';
    } finally {
      this.loading = false;
    }
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

  goToLoad() {
    this.router.navigateByUrl("/load");
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
