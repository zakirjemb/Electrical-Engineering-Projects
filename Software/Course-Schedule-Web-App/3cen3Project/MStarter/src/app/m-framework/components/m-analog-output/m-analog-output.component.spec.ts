import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MAnalogOutputComponent } from './m-analog-output.component';

describe('MAnalogOutputComponent', () => {
  let component: MAnalogOutputComponent;
  let fixture: ComponentFixture<MAnalogOutputComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MAnalogOutputComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(MAnalogOutputComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
