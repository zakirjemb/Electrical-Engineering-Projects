import { Component, OnInit} from '@angular/core';
import { Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ElementRef, ViewChild } from '@angular/core';

@Component({
  selector: 'm-rainspot',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './m-rainspot.component.html',
  styleUrl: './m-rainspot.component.css'
})
export class MRainspotComponent  implements OnInit{
  private rainSPOTData: number[];
  @ViewChild('canvas', { static: true }) canvasRef!: ElementRef<HTMLCanvasElement>;
  private ctx!: CanvasRenderingContext2D;
  constructor(){
    this.rainSPOTData = [];
  }

  @Input()
  set rainSPOT(value: number[]){
    this.rainSPOTData = value; 
  }
  get rainSPOT(): number[]{
    return this.rainSPOTData;
  }

  ngOnInit(): void {
    this.ctx = this.canvasRef.nativeElement.getContext('2d')!;
    this.drawCanvas();
    this.updateCanvas(this.rainSPOT);
    this.drawCircles();
  }

  drawCanvas(): void {
    const canvas = this.canvasRef.nativeElement;
    const size = Math.min(window.innerWidth * 0.7, window.innerHeight * 0.7);
    canvas.width = size;
    canvas.height = size;

    // Center the canvas
    const offsetX = (window.innerWidth - size) / 2;
    const offsetY = (window.innerHeight - size) / 2;
    canvas.style.left = offsetX + 'px';
    canvas.style.top = offsetY + 'px';

    // Draw gray square area with rounded edges
    const radius = 20;
    this.ctx.fillStyle = '#d3d3d3';
    this.roundedRect(this.ctx, radius, radius, size - 2 * radius, size - 2 * radius, radius);
    this.ctx.fill();

    // Draw colored portions
    const dataArray = new Array(49).fill(0);
    this.updateCanvas(dataArray);
  }
  drawCircles(){
    const size = Math.min(window.innerWidth * 0.7, window.innerHeight * 0.7);
    // Draw three concentric black circles
    const centerX = size / 2;
    const centerY = size / 2;
    const circleRadius = size / 2.2;

    this.ctx.lineWidth = 5;
    this.ctx.beginPath();
    this.ctx.arc(centerX, centerY, circleRadius, 0, 2 * Math.PI);
    this.ctx.strokeStyle = '#000000';
    this.ctx.stroke();

    this.ctx.beginPath();
    this.ctx.arc(centerX, centerY, circleRadius * 2 / 3, 0, 2 * Math.PI);
    this.ctx.stroke();

    this.ctx.beginPath();
    this.ctx.arc(centerX, centerY, circleRadius / 3, 0, 2 * Math.PI);
    this.ctx.stroke();
  }

  roundedRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, radius: number) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.arcTo(x + width, y, x + width, y + height, radius);
    ctx.arcTo(x + width, y + height, x, y + height, radius);
    ctx.arcTo(x, y + height, x, y, radius);
    ctx.arcTo(x, y, x + width, y, radius);
    ctx.closePath();
  }

  drawColoredPortions(data: number[]) {
    const cellWidth = this.canvasRef.nativeElement.width / 7;
    const cellHeight = this.canvasRef.nativeElement.height / 7;

    for (let i = 0; i < 7; i++) {
      for (let j = 0; j < 7; j++) {
        const value = data[i * 7 + j];
        let color = '';
        switch (value) {
          case 0:
            color = '#d3d3d3';
            break;
          case 1:
            color = '#26d791';
            break;
          case 2:
            color = '#0ef0fc';
            break;
          case 3:
            color = '#3ea9da';
            break;
          case 4:
            color = '#1574c8';
            break;
        }
        this.ctx.fillStyle = color;
        this.ctx.fillRect(j * cellWidth, i * cellHeight, cellWidth, cellHeight);
      }
    }
  }

  reshapeArray(data: number[]): number[][] {
    const matrix = [];
    while (data.length) matrix.push(data.splice(0, 7));
    return matrix;
  }

  updateCanvas(data: number[]) {
    this.ctx.clearRect(0, 0, this.canvasRef.nativeElement.width, this.canvasRef.nativeElement.height);
    this.drawColoredPortions(data);
  }
}
