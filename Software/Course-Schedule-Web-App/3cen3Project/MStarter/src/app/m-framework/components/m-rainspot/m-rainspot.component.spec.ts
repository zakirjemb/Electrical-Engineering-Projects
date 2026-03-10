import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MRainspotComponent } from './m-rainspot.component';

describe('MRainspotComponent', () => {
  let component: MRainspotComponent;
  let fixture: ComponentFixture<MRainspotComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MRainspotComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(MRainspotComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
