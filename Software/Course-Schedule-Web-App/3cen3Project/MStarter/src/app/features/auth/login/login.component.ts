import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../auth/auth.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Auth, signOut } from '@angular/fire/auth';
import { MContainerComponent } from '../../../m-framework/components/m-container/m-container.component';
import { MCardComponent } from '../../../m-framework/components/m-card/m-card.component';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, CommonModule, MContainerComponent, MCardComponent],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  isSignUp = false;
  email = '';
  password = '';
  checkingLogin = true;
  signupMessage = '';

  constructor(
    private authService: AuthService,
    private router: Router,
    private ngAuth: Auth
  ) {
    if (this.authService.isLoggedIn()) {
      this.router.navigate(['/home']);
    } else {
      this.checkingLogin = false;
    }
  }

  login() {
    this.authService.login(this.email, this.password)
      .then(() => this.router.navigate(['/home']))
      .catch(error => alert('Login Error: ' + error.message));
  }

  signup() {
    this.authService.signup(this.email, this.password)
      .then(() => {
        return signOut(this.ngAuth); // Force manual login after signup
      })
      .then(() => {
        this.signupMessage = 'Account created successfully. Please sign in.';
        this.isSignUp = false;
        this.email = '';
        this.password = '';
      })
      .catch(error => alert('Sign Up Error: ' + error.message));
  }
}
