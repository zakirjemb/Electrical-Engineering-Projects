import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
export interface Feature {
  name: string;
  path: string;
}

@Component({
  selector: 'm-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './m-header.component.html',
  styleUrl: './m-header.component.css'
})
export class MHeaderComponent {
  @Input() title: string ;
  @Input() homename: string ;
  private featureList: Feature[];

  constructor(private router: Router) {
     this.title = "";
      this.homename = "Home";
    this.featureList = [];
   
  }

  @Input()
  set features(value: Feature[]) {
    this.featureList = value;
  }

  get features(): Feature[] {
    return this.featureList;
  }

  isActive(path: string): boolean {
    return this.router.url.toLowerCase() === `/${path.toLowerCase()}`;
  }
}
