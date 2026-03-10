import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MMapComponent } from './m-map.component';

describe('MMapComponent', () => {
  let component: MMapComponent;
  let fixture: ComponentFixture<MMapComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MMapComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(MMapComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
