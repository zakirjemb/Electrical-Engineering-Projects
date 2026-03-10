export interface TimeSlot {
    id: number;         
    label: string;     
    pattern: 'MW' | 'TR';
    time: string;      
  }
  
  export const TIME_SLOTS: TimeSlot[] = [
    { id: 1, label: 'Slot 1', pattern: 'MW', time: '09:00–10:45' },
    { id: 2, label: 'Slot 2', pattern: 'MW', time: '10:55–12:40' },
    { id: 3, label: 'Slot 3', pattern: 'MW', time: '12:50–14:35' },
    { id: 4, label: 'Slot 4', pattern: 'MW', time: '15:00–16:45' },
    { id: 5, label: 'Slot 5', pattern: 'MW', time: '16:55–18:40' },
    { id: 6, label: 'Slot 6', pattern: 'MW', time: '18:50–20:35' },
    { id: 7, label: 'Slot 7', pattern: 'MW', time: '20:45–22:30' },
    { id: 8, label: 'Slot 8', pattern: 'TR', time: '09:00–10:45' },
    { id: 9, label: 'Slot 9', pattern: 'TR', time: '10:55–12:40' },
    { id: 10, label: 'Slot 10', pattern: 'TR', time: '12:50–14:35' },
    { id: 11, label: 'Slot 11', pattern: 'TR', time: '15:00–16:45' },
    { id: 12, label: 'Slot 12', pattern: 'TR', time: '16:55–18:40' },
    { id: 13, label: 'Slot 13', pattern: 'TR', time: '18:50–20:35' },
    { id: 14, label: 'Slot 14', pattern: 'TR', time: '20:45–22:30' },
  ];
  