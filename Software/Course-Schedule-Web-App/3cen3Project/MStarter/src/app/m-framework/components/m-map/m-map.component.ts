import { Component, Input, Output, EventEmitter, OnInit,SimpleChanges } from '@angular/core';
//@ts-ignore
declare var google;

@Component({
  selector: 'm-map',
  standalone: true,
  imports: [],
  templateUrl: './m-map.component.html',
  styleUrl: './m-map.component.css'
})
export class MMapComponent implements OnInit {
  @Input() initialZoomLevel: number = 8; 
  @Input() initialLat: number = 0; 
  @Input() initialLng: number = 0; 
  @Output() mapInstance: EventEmitter<any> = new EventEmitter();

  map: any;

  ngOnInit(){
    if (this.initialLat === 0 && this.initialLng === 0) 
      this.getLocation();
    else 
      this.initMap(); 
  }

  async initMap() {
    const { Map } = await google.maps.importLibrary("maps");
 
    this.map = new Map(document.getElementById("map"),
      {
        zoom:   this.initialZoomLevel,
        center: {lat: this.initialLat, lng: this.initialLng},
        disableDoubleClickZoom: true,
        mapId: "Demo Map"
      }
    );
    this.mapInstance.emit(this.map);
  }
  getLocation(){
    navigator.geolocation.getCurrentPosition((data)=>{
      this.initialLat = data.coords.latitude;
      this.initialLng = data.coords.longitude;
      this.initMap();
    });
  }

  ngOnChanges(changes: SimpleChanges): void {
      this.initMap();
  }
  
}
