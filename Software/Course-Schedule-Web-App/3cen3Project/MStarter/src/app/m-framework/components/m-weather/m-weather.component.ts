import { Component, Input} from '@angular/core';
import { MCardComponent } from '../m-card/m-card.component';
import { MRainspotComponent } from '../m-rainspot/m-rainspot.component';
import { CommonModule } from '@angular/common';
@Component({
  selector: 'm-weather',
  standalone: true,
  imports: [MCardComponent, MRainspotComponent, CommonModule],
  templateUrl: './m-weather.component.html',
  styleUrl: './m-weather.component.css'
})
export class MWeatherComponent {
  @Input() dayWeather: any;
  getDayOfWeek(dateStr: string): string {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { weekday: 'long' });
  }
  decoderainSpotString(rainString: string){
    let array: number[] = [];
    for(let i = 0; i< rainString.length; i++)
      array.push(+rainString[i]);
    return array;
  }
}
