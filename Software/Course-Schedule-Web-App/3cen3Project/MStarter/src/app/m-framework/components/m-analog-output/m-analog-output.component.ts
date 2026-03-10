import { Component, ViewChild, ElementRef, OnInit, Input } from '@angular/core';
@Component({
  selector: 'm-analog-output',
  standalone: true,
  imports: [],
  templateUrl: './m-analog-output.component.html',
  styleUrl: './m-analog-output.component.css'
})
export class MAnalogOutputComponent implements OnInit{
  @ViewChild('canvasElement', { static: true }) canvasElement!: ElementRef<HTMLCanvasElement>;
  @Input() Type!: 'motor' | 'servo' | 'led'; 
  private _canvasWidth: number = 10; // Default canvas width
  frameCount: number = 0;
  private _level: number = 0;

  @Input()
  set Level(value: string) { // Setter for the Level property
    // Ensure that the value is between 0 and 100
    this._level = Math.min(Math.max(+value, 0), 100);
    // Redraw the canvas with the new level
    this.drawCanvas();
  }

  get Level(): number { // Getter for the Level property
    return this._level;
  }

  @Input()
  set canvasWidth(value: number) { // Setter for the canvasWidth property
    this._canvasWidth = value;
  }

  get canvasWidth(): number { // Getter for the canvasWidth property
    return this._canvasWidth;
  }


  ngOnInit(): void {
      this.drawCanvas();
  }
  drawCanvas() {
    let src: string;
    switch (this.Type) {
      case 'motor':
        src = 'assets/motor-';
        this.frameCount = 48;
        break;
      case 'servo':
        src = 'assets/servo-';
        this.frameCount = 50; 
        break;
      case 'led':
        src = 'assets/led-';
        this.frameCount = 145; 
        break;
      default:
        console.error('Invalid Type specified.');
        return;
    }
    const frameNumber: number = Math.round((this._level / 100) * (this.frameCount - 1));
      
    const canvas: HTMLCanvasElement = this.canvasElement.nativeElement;
    const ctx: CanvasRenderingContext2D | null = canvas.getContext('2d');
    
    if (!ctx) {
      console.error('Canvas context is not supported.');
      return;
    }
    const image = new Image();
    image.src = src+frameNumber+".jpg"; 
    image.onload = () => {
      canvas.width = image.width;
      canvas.height = image.height;
      ctx.drawImage(image, 0, 0);
    };
  }
}