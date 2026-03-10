import { ComponentFixture, TestBed } from '@angular/core/testing';

import {Schedulecomponent} from './ScheduleView.component';

describe('ScheduleComponent', () => {
  let component: Schedulecomponent;
  let fixture: ComponentFixture<Schedulecomponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Schedulecomponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(Schedulecomponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
