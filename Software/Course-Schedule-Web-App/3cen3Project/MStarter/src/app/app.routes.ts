import { Routes } from '@angular/router';
import { HomeComponent } from './features/home/home.component';
import { ScheduleComponent } from './features/ScheduleView/ScheduleView.component';
import { SessionComponent } from './features/SessionCreation/SessionCreation.component';
import { LoadComponent } from './features/LoadTable/LoadTable.component';
import { ErrorComponent } from './features/ErrorTable/ErrorTablecomponent';
import { VersionComponent } from './features/VersionComparison/VersionComparison.component';
import { LoginComponent } from './features/auth/login/login.component';
import { TrackerdevComponent } from './features/trackerdev/trackerdev.component';
import { ObadComponent } from './features/OBAD/OBAD.component'; 
import { authGuard } from './features/auth/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'signup', component: LoginComponent },
  { path: 'home', component: HomeComponent, canActivate: [authGuard] },
  { path: 'schedule', component: ScheduleComponent, canActivate: [authGuard] },
  { path: 'session', component: SessionComponent, canActivate: [authGuard] },
  { path: 'load', component: LoadComponent, canActivate: [authGuard] },
  { path: 'error', component: ErrorComponent, canActivate: [authGuard] },
  { path: 'version', component: VersionComponent, canActivate: [authGuard] },
  { path: 'tracker', component: TrackerdevComponent, canActivate: [authGuard] },
  { path: 'obad', component: ObadComponent }, 
  { path: '**', redirectTo: 'login' }
];
