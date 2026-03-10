import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PersistenceService,Session } from '../../m-framework/services/persistence.service';
import { MContainerComponent } from '../../m-framework/components/m-container/m-container.component';
import { MCardComponent } from '../../m-framework/components/m-card/m-card.component';
import { Router } from '@angular/router';
import { AuthService } from '../auth/auth.service';

@Component({
  selector: 'app-SessionCreation',
  standalone: true,
  imports: [CommonModule, FormsModule, MContainerComponent, MCardComponent],
  templateUrl: './SessionCreation.component.html',
  styleUrls: ['./SessionCreation.component.css']
})
export class SessionComponent implements OnInit {
  courses = [
    'CEN201', 'CEN333', 'EEN210', 'EEN466',
    'CE0101', 'MTT102', 'MTT200', 'MTT201',
    'MTT202', 'MTT204', 'MTT205', 'EEN340',
    'PHY102', 'PHY201', 'CHE205', 'EEN33O',
    'EEN360', 'EEN325', 'EEN320', 'CSC101'
  ];

  slotOptions = [
    { id: 1, label: 'Slot 1: MW 09:00–10:45' },
    { id: 2, label: 'Slot 2: MW 10:55–12:40' },
    { id: 3, label: 'Slot 3: MW 12:50–14:35' },
    { id: 4, label: 'Slot 4: MW 15:00–16:45' },
    { id: 5, label: 'Slot 5: MW 16:55–18:40' },
    { id: 6, label: 'Slot 6: MW 18:50–20:35' },
    { id: 7, label: 'Slot 7: MW 20:45–22:30' },
    { id: 8, label: 'Slot 8: TR 09:00–10:45' },
    { id: 9, label: 'Slot 9: TR 10:55–12:40' },
    { id: 10, label: 'Slot 10: TR 12:50–14:35' },
    { id: 11, label: 'Slot 11: TR 15:00–16:45' },
    { id: 12, label: 'Slot 12: TR 16:55–18:40' },
    { id: 13, label: 'Slot 13: TR 18:50–20:35' },
    { id: 14, label: 'Slot 14: TR 20:45–22:30' }
  ];

  sessions: Session[] = [];

  newSession: Session = {
    course: '',
    instructor: '',
    section: 1,
    slot: 1,
    campus: 'Abu Dhabi',
    capacity: 'Regular'
  };

  deleteData = {
    course: '',
    instructor: '',
    section: 1,
    slot: 1,
  };

  constructor(private persistenceService: PersistenceService, 
    public router: Router,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.loadSessions();
  }

  loadSessions() {
    this.persistenceService.getSessions().subscribe(data => {
      
      this.sessions = data.map(s => ({
        ...s,
        slot: Number(s.slot)
      }));
      console.log(' Sessions loaded:', this.sessions);
    });
  }

  async addSession() {
    try {
      await this.persistenceService.addSession({
        ...this.newSession,
        slot: Number(this.newSession.slot) 
      });
      console.log(' Session added!');
      alert(' Session added successfully!');

      this.newSession = {
        course: '',
        instructor: '',
        section: 1,
        slot: 1,
        campus: 'Abu Dhabi',
        capacity: 'Regular'
      };
      this.loadSessions();
    } catch (err) {
      console.error(' Failed to add session:', err);
      alert(' Failed to add session!');
    }
  }

  async deleteSession() {
    try {
      const matchingSession = this.sessions.find(s =>
        s.course === this.deleteData.course &&
        s.instructor === this.deleteData.instructor &&
        s.section === this.deleteData.section &&
        s.slot === Number(this.deleteData.slot)
      );

      if (!matchingSession?.id) {
        alert(' No matching session found.');
        return;
      }

      if (confirm(`Are you sure you want to delete ${matchingSession.course} - ${matchingSession.instructor}?`)) {
        await this.persistenceService.deleteSession(matchingSession.id);
        console.log('Session deleted!');
        alert('Session deleted successfully!');
        this.deleteData = {
          course: '',
          instructor: '',
          section: 1,
          slot: 1
        };
        this.loadSessions();
      }
    } catch (err) {
      console.error(' Failed to delete session:', err);
      alert(' Failed to delete session!');
    }
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

  goToVersion() {
    this.router.navigateByUrl("/version");
  }
  goToHome(){
    this.router.navigateByUrl("/''")
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
