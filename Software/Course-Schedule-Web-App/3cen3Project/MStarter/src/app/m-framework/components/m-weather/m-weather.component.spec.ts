import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MWeatherComponent } from './m-weather.component';

describe('MWeatherComponent', () => {
  let component: MWeatherComponent;
  let fixture: ComponentFixture<MWeatherComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MWeatherComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(MWeatherComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
