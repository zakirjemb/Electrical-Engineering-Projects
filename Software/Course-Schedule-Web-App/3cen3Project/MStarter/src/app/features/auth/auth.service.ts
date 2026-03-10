import { Injectable } from '@angular/core';
import { Auth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, onAuthStateChanged } from '@angular/fire/auth';
import { FirebaseError } from 'firebase/app'; 
import { Router } from '@angular/router';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  constructor(private auth: Auth, private router: Router) {
    this.monitorAuthState(); 
  }

  
  login(email: string, password: string) {
    return signInWithEmailAndPassword(this.auth, email, password)
      .then(() => {
        localStorage.setItem('isLoggedIn', 'true'); 
      })
      .catch((error: FirebaseError) => {
        throw new Error(error.message);
      });
  }


  signup(email: string, password: string) {
    return createUserWithEmailAndPassword(this.auth, email, password)
      .then(() => {
        localStorage.setItem('isLoggedIn', 'true'); 
      })
      .catch((error: FirebaseError) => {
        throw new Error(error.message);
      });
  }

  
  logout() {
    return signOut(this.auth)
      .then(() => {
        localStorage.removeItem('isLoggedIn'); 
        this.router.navigate(['/login']); 
      })
      .catch((error: FirebaseError) => {
        throw new Error(error.message);
      });
  }

 
  isLoggedIn(): boolean {
    return localStorage.getItem('isLoggedIn') === 'true';
  }

 
  private monitorAuthState() {
    onAuthStateChanged(this.auth, (user) => {
      if (user) {
        localStorage.setItem('isLoggedIn', 'true');
      } else {
        localStorage.removeItem('isLoggedIn');
      }
    });
  }
}
