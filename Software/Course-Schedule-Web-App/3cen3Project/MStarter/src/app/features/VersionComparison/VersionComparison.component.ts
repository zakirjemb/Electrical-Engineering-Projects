import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PersistenceService,ScheduleVersion } from '../../m-framework/services/persistence.service';
import { MContainerComponent } from '../../m-framework/components/m-container/m-container.component';
import { MCardComponent } from '../../m-framework/components/m-card/m-card.component'; 
import { Router } from '@angular/router';
import { AuthService } from '../auth/auth.service';

@Component({
  selector: 'app-VersionComparison',
  standalone: true,
  imports: [CommonModule, FormsModule, MContainerComponent, MCardComponent],
  templateUrl: './VersionComparison.component.html',
  styleUrls: ['./VersionComparison.component.css']
})
export class VersionComponent implements OnInit {
  versionName = '';
  versions: ScheduleVersion[] = [];
  versionAId: string = '';
  versionBId: string = '';
  diffResults: string[] = [];
  loading = false;
  error: string | null = null;
  hasCompared = false;
 
  constructor(private persistenceService: PersistenceService
    , private router: Router
    , private authService: AuthService
  ) {}
 
  ngOnInit(): void {
    this.loadVersions();
  }
 
  loadVersions() {
    this.persistenceService.getVersions().subscribe(data => {
      this.versions = data;
    });
  }
 
  async saveVersion() {
    if (!this.versionName.trim()) {
      alert('Please enter a version name.');
      return;
    }
 
    try {
      await this.persistenceService.saveVersion(this.versionName.trim());
      this.versionName = '';
      this.loadVersions();
      alert(' Version saved successfully!');
    } catch (err) {
      console.error('Error saving version:', err);
      alert('Failed to save version.');
    }
  }
 async compareVersions() {
  if (!this.versionAId || !this.versionBId) {
    alert('Please select two versions to compare.');
    return;
  }

  this.loading = true;
  this.error = null;
  this.diffResults = [];
  this.hasCompared = false; 

  try {
    this.diffResults = await this.persistenceService.compareVersions(this.versionAId, this.versionBId);
  } catch (err) {
    console.error('Error comparing versions:', err);
    this.error = 'Failed to compare versions.';
  } finally {
    this.loading = false;
    this.hasCompared = true; 
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

  goToError() {
    this.router.navigateByUrl("/error");
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
 