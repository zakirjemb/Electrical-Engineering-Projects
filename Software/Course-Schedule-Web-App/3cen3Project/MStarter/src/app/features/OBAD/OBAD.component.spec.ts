import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ObadComponent } from './OBAD.component';

describe('ComponentNameComponent', () => {
  let component: ObadComponent;
  let fixture: ComponentFixture<ObadComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ObadComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(ObadComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
