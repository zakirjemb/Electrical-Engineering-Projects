import { Injectable } from '@angular/core';
import { Firestore, collection, query, getDocs, addDoc, deleteDoc, updateDoc, doc, getDoc } from '@angular/fire/firestore';
import { Observable, from } from 'rxjs';
import { map } from 'rxjs/operators';




export interface Session {
  id?: string;
  course: string;
  instructor: string;
  section: number;
  slot: number;
  campus: 'Abu Dhabi' | 'Al Ain';
  capacity: 'Regular' | 'Large' | 'Mega';
  pattern?: 'MW' | 'TR';  
   room?: string; 
}



export interface LoadItem {
  instructor: string;
  count: number;
}


export interface ScheduleVersion{
  id?: string;
  name: string;
  createdAt: Date;
  sessions: Session[];
}


@Injectable({
  providedIn: 'root',
})
export class PersistenceService {

  constructor(public firestore: Firestore) {}

 
  addSession(session: Session): Promise<void> {
    const sessionRef = collection(this.firestore, 'sessions');
    const fixedSession: Session = {
      ...session,
      slot: Number(session.slot),
    };
    return addDoc(sessionRef, fixedSession).then(() => {
      console.log(' Session added!');
    });
  }

  getSessions(): Observable<Session[]> {
    const sessionRef = collection(this.firestore, 'sessions');
    const sessionQuery = query(sessionRef); 

    
    return from(getDocs(sessionQuery)).pipe(
      map((snapshot) => {
        return snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        } as Session));
      })
    );
  }


  deleteSession(sessionId: string): Promise<void> {
    return deleteDoc(doc(this.firestore, `sessions/${sessionId}`)).then(() => {
      console.log(' Session deleted!');
    });
  }

  
  updateSession(sessionId: string, data: Partial<Session>): Promise<void> {
    return updateDoc(doc(this.firestore, `sessions/${sessionId}`), data).then(() => {
      console.log(' Session updated!');
    });
  }

  

  
  async calculateLoad(): Promise<LoadItem[]> {
    const sessionRef = collection(this.firestore, 'sessions');
    const snap = await getDocs(sessionRef);
    const loadMap = new Map<string, number>();

    snap.forEach((doc) => {
      const session = doc.data() as Session;
      const current = loadMap.get(session.instructor) || 0;
      loadMap.set(session.instructor, current + 1);
    });

    return Array.from(loadMap.entries()).map(([instructor, count]) => ({ instructor, count }));
  }


 
  async detectConflicts(): Promise<string[]> {
    const sessionRef = collection(this.firestore, 'sessions');
    const snap = await getDocs(sessionRef);
    const allSessions: Session[] = [];

    snap.forEach((doc) => {
      const data = doc.data();
      allSessions.push({
        id: doc.id,
        ...data,
        slot: Number((data as any).slot),
      } as Session);
    });

    const slotMap = new Map<string, Session[]>();
    const courseMap = new Map<string, Set<string>>();

    for (const session of allSessions) {
      const key = `${session.instructor}-${session.slot}`;
      if (!slotMap.has(key)) slotMap.set(key, []);
      slotMap.get(key)!.push(session);

      if (!courseMap.has(session.course)) courseMap.set(session.course, new Set());
      courseMap.get(session.course)!.add(session.campus);
    }

    const messages: string[] = [];

    slotMap.forEach((sessions, key) => {
      if (sessions.length > 1) {
        const campuses = new Set(sessions.map((s) => s.campus));
        const instructor = sessions[0].instructor;
        const slot = sessions[0].slot;

        if (campuses.size > 1) {
          messages.push(`Time conflict: ${instructor} assigned in different campuses during Slot ${slot}`);
        } else {
          messages.push(`Time conflict: ${instructor} has double sessions in ${sessions[0].campus} during Slot ${slot}`);
        }
      }
    });

    courseMap.forEach((campuses, course) => {
      if (campuses.size === 1) {
        const campus = Array.from(campuses)[0];
        const missing = campus === 'Abu Dhabi' ? 'Al Ain' : 'Abu Dhabi';
        messages.push(`Warning: ${course} is offered in ${campus} but not in ${missing}. Please verify.`);
      }
    });

    return messages;
  }


 
  async saveVersion(name: string): Promise<void> {
    const sessionRef = collection(this.firestore, 'sessions');
    const snap = await getDocs(sessionRef);
    const sessions: Session[] = [];

    snap.forEach((doc) => {
      const data = doc.data();
      sessions.push({
        id: doc.id,
        ...data,
        slot: Number((data as any).slot),
      } as Session);
    });

    const versionRef = collection(this.firestore, 'scheduleVersions');
    await addDoc(versionRef, {
      name,
      createdAt: new Date(),
      sessions,
    });
  }


  getVersions(): Observable<ScheduleVersion[]> {
    const versionRef = collection(this.firestore, 'scheduleVersions');
    const versionQuery = query(versionRef); 

    return from(getDocs(versionQuery)).pipe(
      map((snapshot) => {
        return snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        } as ScheduleVersion));
      })
    );
  }

 
  async compareVersions(versionAId: string, versionBId: string): Promise<string[]> {
    const docA = await getDoc(doc(this.firestore, `scheduleVersions/${versionAId}`));
    const docB = await getDoc(doc(this.firestore, `scheduleVersions/${versionBId}`));

    const a = (docA.data() as ScheduleVersion)?.sessions ?? [];
    const b = (docB.data() as ScheduleVersion)?.sessions ?? [];

    const diff: string[] = [];

    const mapA = new Map(a.map((s: Session) => [s.course + s.slot + s.instructor, s]));
    const mapB = new Map(b.map((s: Session) => [s.course + s.slot + s.instructor, s]));

    mapB.forEach((val, key) => {
      if (!mapA.has(key)) {
        diff.push(`Added or changed session: ${val.course} (Slot ${val.slot}, ${val.instructor})`);
      }
    });

    mapA.forEach((val, key) => {
      if (!mapB.has(key)) {
        diff.push(` Removed session: ${val.course} (Slot ${val.slot}, ${val.instructor})`);
      }
    });

    return diff;
  }
}
