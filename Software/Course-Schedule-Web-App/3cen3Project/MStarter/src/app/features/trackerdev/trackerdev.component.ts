// trackerdev.component.ts
import { Component, OnInit, ViewChild, NgZone } from '@angular/core';
import {
  GoogleMapsModule,
  MapDirectionsService,
  MapInfoWindow,
  MapMarker,
} from '@angular/google-maps';
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, onSnapshot } from 'firebase/firestore';
import { Observable, of } from 'rxjs';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

declare const __firebase_config: string;

let firebaseConfig: any;

try {
  firebaseConfig = JSON.parse(__firebase_config);
} catch (e) {
  console.error('Invalid Firebase config, using placeholder template:', e);

  /*
  
   * To replicate this project:
   * 1. Create your own Firebase project
   * 2. Enable Firestore Database
   * 3. Replace the fields below with YOUR OWN credentials
   */

  firebaseConfig = {
    // apiKey: 'YOUR_FIREBASE_API_KEY',
    // authDomain: 'YOUR_PROJECT.firebaseapp.com',
    // projectId: 'YOUR_PROJECT_ID',
    // storageBucket: 'YOUR_PROJECT.appspot.com',
    // messagingSenderId: 'YOUR_SENDER_ID',
    // appId: 'YOUR_APP_ID',
    // measurementId: 'YOUR_MEASUREMENT_ID'
  };
}

interface FaultData {
  latitude: number;
  longitude: number;
  faultType: string;
  timestamp: string;
  severity: number;
  severity_confidence: number | null;
  location_m: number;
  isAnomaly: boolean;
  anomaly_score: number;
  environmentalTempC: number;
  environmentalVibrationLevel: number;
  simulatedTrueType?: string;
  simulatedTrueSeverity?: number;
  simulatedTrueLocation_m?: number;
}

interface InformedMarker {
  docId: string;
  position: google.maps.LatLngLiteral;
  title: string;
  subtitle: string;
  severityLabel: string;
  severityNumerical: number;
  severityConfidence: number | null;
  distance: number;
  isAnomaly: boolean;
  anomalyScore: number;
  temperature: number;
  vibrationLevel: number;
}

@Component({
  selector: 'app-trackerdev',
  standalone: true,
  imports: [CommonModule, GoogleMapsModule, FormsModule],
  templateUrl: './trackerdev.component.html',
  styleUrls: ['./trackerdev.component.css'],
})
export class TrackerdevComponent implements OnInit {
  mapcenter: google.maps.LatLngLiteral = { lat: 24.4667, lng: 54.3667 };
  zoom = 12;

  allMarkers: InformedMarker[] = [];
  informedMarkerList: InformedMarker[] = [];
  teamPosition: google.maps.LatLngLiteral = { lat: 24.462, lng: 54.367 };
  directionsResults$: Observable<google.maps.DirectionsResult | undefined> = of(undefined);

  infoWindowContent = '';
  distanceText = '';
  durationText = '';

  selectedSeverity = 'All';
  selectedType = 'All';
  maxDistance = 10000;
  sortOption = 'severity';
  uniqueTypes: string[] = [];
  severityOptions: string[] = ['All', 'Minor', 'Moderate', 'Severe'];

  @ViewChild(MapInfoWindow) infoWindow!: MapInfoWindow;

  private firebaseAppInitialized = false;
  showAlert = false;
  alertMessage = '';
  private alertedFaultIds: Set<string> = new Set();
  private alertTimeoutId: any;

  private audio = new Audio('assets/alert.mp3');

  constructor(
    private directionsService: MapDirectionsService,
    private ngZone: NgZone
  ) {}

  ngOnInit(): void {
    if ((window as any).google?.maps) {
      this.initFirebaseAndLoadData();
    } else {
      window.addEventListener('googleMapsReady', () => {
        this.ngZone.run(() => this.initFirebaseAndLoadData());
      });
    }
  }

  initFirebaseAndLoadData() {
    if (this.firebaseAppInitialized) return;
    this.firebaseAppInitialized = true;

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    onSnapshot(collection(db, 'fault'), (snapshot) => {
      this.ngZone.run(() => {
        const markers: InformedMarker[] = [];
        const typeSet: Set<string> = new Set();

        snapshot.docs.forEach((doc) => {
          const docId = doc.id;
          const fault = doc.data() as FaultData;

          if (fault.latitude == null || fault.longitude == null) return;

          const severityLabel =
            fault.severity >= 0.66 ? 'Severe' :
            fault.severity >= 0.33 ? 'Moderate' : 'Minor';

          const marker: InformedMarker = {
            docId,
            position: { lat: fault.latitude, lng: fault.longitude },
            title: fault.faultType || 'Unknown',
            subtitle: fault.timestamp || '',
            severityLabel,
            severityNumerical: fault.severity,
            severityConfidence: fault.severity_confidence || null,
            distance: fault.location_m || 0,
            isAnomaly: fault.isAnomaly ?? false,
            anomalyScore: fault.anomaly_score || 0,
            temperature: fault.environmentalTempC || 0,
            vibrationLevel: fault.environmentalVibrationLevel || 0,
          };

          markers.push(marker);
          if (fault.faultType) typeSet.add(fault.faultType);

          if (marker.severityLabel === 'Severe' && !this.alertedFaultIds.has(docId)) {
            this.triggerAlert(marker);
            this.alertedFaultIds.add(docId);
          }
        });

        this.allMarkers = markers;
        this.uniqueTypes = Array.from(typeSet);
        this.applyFilters();
        this.fitMapToBounds();
      });
    });
  }

  triggerAlert(marker: InformedMarker) {
    if (this.alertTimeoutId) clearTimeout(this.alertTimeoutId);
    this.alertMessage = `CRITICAL ALERT: ${marker.title} at ${marker.distance.toFixed(2)} m (Severity ${marker.severityNumerical.toFixed(2)})`;
    this.showAlert = true;
    this.audio.play();
    this.alertTimeoutId = setTimeout(() => this.hideAlert(), 5000);
  }

  hideAlert() {
    this.showAlert = false;
    this.alertMessage = '';
    if (this.alertTimeoutId) clearTimeout(this.alertTimeoutId);
    this.alertTimeoutId = null;
  }

  applyFilters() {
    let filtered = this.allMarkers.filter(marker =>
      (this.selectedSeverity === 'All' || marker.severityLabel === this.selectedSeverity) &&
      (this.selectedType === 'All' || marker.title === this.selectedType) &&
      marker.distance <= this.maxDistance
    );

    if (this.sortOption === 'severity') {
      filtered.sort((a, b) => b.severityNumerical - a.severityNumerical);
    } else {
      filtered.sort((a, b) => a.distance - b.distance);
    }

    this.informedMarkerList = filtered;
  }

  resetFilters() {
    this.selectedSeverity = 'All';
    this.selectedType = 'All';
    this.maxDistance = 10000;
    this.sortOption = 'severity';
    this.applyFilters();
  }

  getMarkerIcon(severityLabel: string): string {
    return {
      Minor: 'http://maps.google.com/mapfiles/ms/icons/green-dot.png',
      Moderate: 'http://maps.google.com/mapfiles/ms/icons/yellow-dot.png',
      Severe: 'http://maps.google.com/mapfiles/ms/icons/red-dot.png',
    }[severityLabel] || 'http://maps.google.com/mapfiles/ms/icons/blue-dot.png';
  }

  openInfoWindow(marker: InformedMarker, mapMarker: MapMarker) {
    this.directionsService.route({
      origin: this.teamPosition,
      destination: marker.position,
      travelMode: google.maps.TravelMode.DRIVING,
    }).subscribe(result => {
      const leg = result?.result?.routes?.[0]?.legs?.[0];
      this.distanceText = leg?.distance?.text || 'N/A';
      this.durationText = leg?.duration?.text || 'N/A';

      this.infoWindowContent = `
        <div>
          <b>Fault:</b> ${marker.title}<br/>
          <b>Time:</b> ${marker.subtitle}<br/>
          <b>Severity:</b> ${marker.severityLabel} (${marker.severityNumerical.toFixed(2)})<br/>
          <b>Location:</b> ${marker.distance.toFixed(2)} m<br/>
          <b>Anomaly:</b> ${marker.isAnomaly ? 'Yes' : 'No'}<br/>
          <b>Temp:</b> ${marker.temperature.toFixed(1)} °C<br/>
          <b>Vibration:</b> ${marker.vibrationLevel.toFixed(2)}<br/>
          <b>From Team:</b> ${this.distanceText} (${this.durationText})
        </div>
      `;

      this.infoWindow.open(mapMarker);
      this.directionsResults$ = of(result.result);
    });
  }

  fitMapToBounds() {
    if (!this.informedMarkerList.length) return;
    const bounds = new google.maps.LatLngBounds();
    this.informedMarkerList.forEach(m => bounds.extend(m.position));
    const mapEl = document.querySelector('google-map') as any;
    mapEl?.getMap?.()?.fitBounds(bounds);
  }

  clearRoute() {
    this.directionsResults$ = of(undefined);
  }

  clearMarkers() {
    this.informedMarkerList = [];
    this.allMarkers = [];
    this.alertedFaultIds.clear();
    this.hideAlert();
  }
}
