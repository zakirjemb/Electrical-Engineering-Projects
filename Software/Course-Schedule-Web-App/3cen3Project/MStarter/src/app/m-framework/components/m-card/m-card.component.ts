import { Component, Input } from '@angular/core';

@Component({
  selector: 'm-card',
  standalone: true,
  imports: [],
  templateUrl: './m-card.component.html',
  styleUrl: './m-card.component.css',
})
export class MCardComponent {
  @Input() header: string;
  @Input() subheader: string;
  @Input() imageurl: string;

  constructor() {
    this.header = '';
    this.subheader = '';
    this.imageurl = '';
  }
}
