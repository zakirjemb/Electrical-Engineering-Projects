import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PersistenceService, Session } from '../../m-framework/services/persistence.service';
import { TIME_SLOTS, TimeSlot } from '../../data/model';
import { MContainerComponent } from '../../m-framework/components/m-container/m-container.component';
import * as XLSX from 'xlsx';
;
import { Router } from '@angular/router';
import { AuthService } from '../auth/auth.service';

@Component({
  selector: 'app-ScheduleView',
  standalone: true,
  imports: [CommonModule, MContainerComponent],
  templateUrl: './ScheduleView.component.html',
  styleUrls: ['./ScheduleView.component.css']
})
export class ScheduleComponent implements OnInit {
  sessions: Session[] = [];
  campuses = ['Abu Dhabi', 'Al Ain'];

  mwSlots: TimeSlot[] = [];
  trSlots: TimeSlot[] = [];

  constructor(public persistenceService: PersistenceService
    , private router: Router
    , private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.mwSlots = TIME_SLOTS.filter(s => s.pattern === 'MW');
    this.trSlots = TIME_SLOTS.filter(s => s.pattern === 'TR');
    this.loadSessions();
  }

  loadSessions() {
    this.persistenceService.getSessions().subscribe(data => {
      this.sessions = data.map(s => ({
        ...s,
        slot: Number(s.slot)
      }));
    });
  }
     getSessionsForSlot(slotId: number, campus: string): Session[] {
    return this.sessions.filter(
      s => s.slot === slotId && s.campus === campus
    );
  }


  async deleteSessionById(sessionId: string) {
    if (confirm('Are you sure you want to delete this session?')) {
      try {
        await this.persistenceService.deleteSession(sessionId);
         console.log(' Deleted session with ID:', sessionId);
        this.loadSessions();
      } catch (err) {
        console.error('Failed to delete session:', err);
      }
   }
  }


  exportToExcel(): void {
    const exportData = this.sessions.map(s => {
      const slotTime = TIME_SLOTS.find(t => t.id === s.slot && t.pattern === s.pattern);
      return {
        Course: s.course,
        Instructor: s.instructor,
        Section: s.section,
        Campus: s.campus,
        Capacity: s.capacity,
        Pattern: s.pattern,
        Slot: s.slot,
        Time: slotTime ? slotTime.time : 'N/A'
      };
    });

    const worksheet = XLSX.utils.json_to_sheet(exportData);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Schedule');
    XLSX.writeFile(workbook, 'Schedule.xlsx');
  }

 exportToGoogleCalendar(sessions: Session[]): void {
  if (!sessions.length) {
    alert('No sessions to export');
    return;
  }

 
  if (!confirm(`Export ${sessions.length} sessions to Google Calendar?`)) {
    return;
  }

  
  const groupedEvents = this.groupSessionsByDay(sessions);


  Object.entries(groupedEvents).forEach(([date, daySessions], index) => {
    setTimeout(() => {
      this.exportDayToCalendar(date, daySessions);
    }, index * 1000); 
  });
}

private groupSessionsByDay(sessions: Session[]): {[date: string]: Session[]} {
  const grouped: {[date: string]: Session[]} = {};
  

  const today = new Date().toISOString().split('T')[0];
  
  sessions.forEach(session => {
    if (!grouped[today]) {
      grouped[today] = [];
    }
    grouped[today].push(session);
  });
  
  return grouped;
}

private exportDayToCalendar(date: string, sessions: Session[]): void {
 
  const url = this.buildCalendarUrl(date, sessions);
  

  const newWindow = window.open(url, '_blank');
  
  
  if (!newWindow || newWindow.closed || typeof newWindow.closed === 'undefined') {
    alert('Popup was blocked. Please allow popups for this site to export to Google Calendar.');

  }
}

private buildCalendarUrl(date: string, sessions: Session[]): string {
  const baseUrl = 'https://www.google.com/calendar/render?action=TEMPLATE';
  
  
  const title = `Course Sessions (${sessions.length})`;
  
  let description = '';
  sessions.forEach((session, i) => {
    const slotTime = TIME_SLOTS.find(
      t => t.id === session.slot && t.pattern === session.pattern
    );
    
    description += `${i+1}. ${session.course} (Sec ${session.section})\n`;
    description += `   Instructor: ${session.instructor}\n`;
    description += `   Campus: ${session.campus}\n`;
    description += `   Time: ${slotTime?.time || 'N/A'}\n\n`;
  });

 
  const firstSession = sessions[0];
  const slotTime = TIME_SLOTS.find(
    t => t.id === firstSession.slot && t.pattern === firstSession.pattern
  );

  if (!slotTime || !slotTime.time.includes(' - ')) {
    return `${baseUrl}&text=${encodeURIComponent(title)}&details=${encodeURIComponent(description)}`;
  }

  const [startTime, endTime] = slotTime.time.split(' - ');
  const startDateTime = this.convertToCalendarDateTime(date, startTime);
  const endDateTime = this.convertToCalendarDateTime(date, endTime);

  return `${baseUrl}&text=${encodeURIComponent(title)}` +
         `&details=${encodeURIComponent(description)}` +
         `&dates=${startDateTime}/${endDateTime}`;
}

private convertToCalendarDateTime(date: string, time: string): string {
 
  time = time.trim();
  const isAMPM = time.includes('AM') || time.includes('PM');
  
  let hours: number, minutes: number;
  
  if (isAMPM) {
    const [hourMin, modifier] = time.split(' ');
    [hours, minutes] = hourMin.split(':').map(Number);
    
    if (modifier === 'PM' && hours < 12) hours += 12;
    if (modifier === 'AM' && hours === 12) hours = 0;
  } else {
    [hours, minutes] = time.split(':').map(Number);
  }
  
  return `${date}T${hours.toString().padStart(2, '0')}${minutes.toString().padStart(2, '0')}00`;
}

  get slotIndices(): number[] {
    return Array.from({ length: Math.max(this.mwSlots.length, this.trSlots.length) }, (_, i) => i);
  }

  goToHome(){
    this.router.navigateByUrl("/''")
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
 
  async logout() {
  try {
    await this.authService.logout();
    this.router.navigate(['/login']);
  } catch (error) {
    console.error('Logout Error:', error);
  }
}
  
}