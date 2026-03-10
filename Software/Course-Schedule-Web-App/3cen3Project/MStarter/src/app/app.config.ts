import { importProvidersFrom } from '@angular/core';  
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideFirebaseApp, initializeApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';

// 1. ADD THIS IMPORT
import { provideDatabase, getDatabase } from '@angular/fire/database'; 

import { environment } from './environment/environment';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    importProvidersFrom(
      provideFirebaseApp(() => initializeApp(environment.firebase)),
      provideAuth(() => getAuth()),
      provideFirestore(() => getFirestore()),
      // 2. ADD THIS PROVIDER
      provideDatabase(() => getDatabase()) 
    )
  ]
};