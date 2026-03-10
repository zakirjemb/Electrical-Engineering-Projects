import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TrackerdevComponent } from './trackerdev.component';

describe('TrackerdevComponent', () => {
  let component: TrackerdevComponent;
  let fixture: ComponentFixture<TrackerdevComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TrackerdevComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(TrackerdevComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
