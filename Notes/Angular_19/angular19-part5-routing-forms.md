# Angular 19 - Part 5: Routing and Forms

[← Back to Index](angular19-guide-index.md) | [Previous: State Management](angular19-part4-state-management.md) | [Next: HTTP and RxJS →](angular19-part6-http-rxjs.md)

## Table of Contents
- [Router Configuration](#router-configuration)
- [Route Parameters](#route-parameters)
- [Route Guards](#route-guards)
- [Lazy Loading](#lazy-loading)
- [Template-Driven Forms](#template-driven-forms)
- [Reactive Forms](#reactive-forms)
- [Form Validation](#form-validation)
- [Coding Challenges](#coding-challenges)
- [Interview Questions](#interview-questions)

---

## Router Configuration

### Basic Setup (Standalone)

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter } from '@angular/router';
import { routes } from './app/app.routes';

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes)
  ]
});

// app.routes.ts
import { Routes } from '@angular/router';
import { HomeComponent } from './home/home.component';
import { AboutComponent } from './about/about.component';

export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'about', component: AboutComponent },
  { path: '**', redirectTo: '' }  // 404 redirect
];

// app.component.ts
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink],
  template: `
    <nav>
      <a routerLink="/">Home</a>
      <a routerLink="/about">About</a>
    </nav>
    <router-outlet></router-outlet>
  `
})
export class AppComponent { }
```

### RouterLink and RouterLinkActive

```typescript
@Component({
  template: `
    <nav>
      <!-- Basic link -->
      <a routerLink="/home">Home</a>
      
      <!-- Link with parameters -->
      <a [routerLink]="['/user', userId]">User Profile</a>
      
      <!-- Active class -->
      <a routerLink="/about" routerLinkActive="active">About</a>
      
      <!-- Active with exact match -->
      <a routerLink="/" routerLinkActive="active" [routerLinkActiveOptions]="{exact: true}">
        Home
      </a>
    </nav>
  `,
  styles: [`.active | color: blue; font-weight: bold; }`]
})
```

### Programmatic Navigation

```typescript
import { Router } from '@angular/router';

@Component({...})
export class ExampleComponent {
  constructor(private router: Router) { }
  
  navigateToUser(id: number) {
    this.router.navigate(['/user', id]);
  }
  
  navigateWithQueryParams() {
    this.router.navigate(['/search'], {
      queryParams: { q: 'angular', page: 1 }
    });
	// Results in: /search?q=angular&page=1
  }
  
  navigateRelative() {
    this.router.navigate(['../sibling'], { relativeTo: this.route });
  }
}
```

---

## Route Parameters

### Path Parameters

```typescript
// routes
{ path: 'user/:id', component: UserComponent }

// component
import { ActivatedRoute } from '@angular/router';

@Component({...})
export class UserComponent implements OnInit {
  userId: string = '';
  
  constructor(private route: ActivatedRoute) { }
  
  ngOnInit() {
    // Snapshot (one-time read)
    this.userId = this.route.snapshot.paramMap.get('id') || '';
    
    // Observable (updates on param change)
    this.route.paramMap.subscribe(params => {
      this.userId = params.get('id') || '';
    });
  }
}
```

### Query Parameters

```typescript
// Navigate with query params
this.router.navigate(['/search'], {
  queryParams: { q: 'angular', category: 'web' }
});

// Read query params
@Component({...})
export class SearchComponent implements OnInit {
  constructor(private route: ActivatedRoute) { }
  
  ngOnInit() {
    // Snapshot
    const query = this.route.snapshot.queryParamMap.get('q');
    
    // Observable
    this.route.queryParamMap.subscribe(params => {
      const query = params.get('q');
      const category = params.get('category');
      this.performSearch(query, category);
    });
  }
}
```

---

## Route Guards

### CanActivate Guard

```typescript
import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { AuthService } from './auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isLoggedIn()) {
    return true;
  }
  
  // Redirect to login
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url }
  });
};

// routes
{
  path: 'admin',
  component: AdminComponent,
  canActivate: [authGuard]
}
```

### CanDeactivate Guard

```typescript
import { CanDeactivateFn } from '@angular/router';

export interface CanComponentDeactivate {
  canDeactivate: () => boolean | Observable<boolean>;
}

export const unsavedChangesGuard: CanDeactivateFn<CanComponentDeactivate> = 
  (component) => {
    return component.canDeactivate ? component.canDeactivate() : true;
  };

// Component
@Component({...})
export class EditComponent implements CanComponentDeactivate {
  hasUnsavedChanges = false;
  
  canDeactivate(): boolean {
    if (this.hasUnsavedChanges) {
      return confirm('You have unsaved changes. Do you want to leave?');
    }
    return true;
  }
}

// Route
{
  path: 'edit',
  component: EditComponent,
  canDeactivate: [unsavedChangesGuard]
}
```

---

## Lazy Loading

### Lazy Load Routes

```typescript
// app.routes.ts
export const routes: Routes = [
  { path: '', component: HomeComponent },
  {
    path: 'admin',
    loadComponent: () => import('./admin/admin.component')
      .then(m => m.AdminComponent),
    canActivate: [authGuard]
  },
  {
    path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.routes')
      .then(m => m.DASHBOARD_ROUTES)
  }
];

// dashboard/dashboard.routes.ts
import { Routes } from '@angular/router';

export const DASHBOARD_ROUTES: Routes = [
  { path: '', component: DashboardComponent },
  { path: 'stats', component: StatsComponent },
  { path: 'reports', component: ReportsComponent }
];
```

---

## Template-Driven Forms

### Basic Template Form

```typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-contact-form',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <form #contactForm="ngForm" (ngSubmit)="onSubmit(contactForm)">
      <div>
        <label>Name:</label>
        <input 
          type="text"
          name="name"
          [(ngModel)]="model.name"
          #name="ngModel"
          required
          minlength="3"
        >
        <div *ngIf="name.invalid && name.touched" class="error">
          <p *ngIf="name.errors?.['required']">Name is required</p>
          <p *ngIf="name.errors?.['minlength']">Min 3 characters</p>
        </div>
      </div>
      
      <div>
        <label>Email:</label>
        <input 
          type="email"
          name="email"
          [(ngModel)]="model.email"
          #email="ngModel"
          required
          email
        >
        <div *ngIf="email.invalid && email.touched" class="error">
          <p *ngIf="email.errors?.['required']">Email is required</p>
          <p *ngIf="email.errors?.['email']">Invalid email</p>
        </div>
      </div>
      
      <div>
        <label>Message:</label>
        <textarea 
          name="message"
          [(ngModel)]="model.message"
          #message="ngModel"
          required
        ></textarea>
      </div>
      
      <button type="submit" [disabled]="contactForm.invalid">
        Submit
      </button>
    </form>
    
    <div *ngIf="submitted">
      <h3>Submitted Data:</h3>
      <pre>{{ model | json }}</pre>
    </div>
  `
})
export class ContactFormComponent {
  model = {
    name: '',
    email: '',
    message: ''
  };
  
  submitted = false;
  
  onSubmit(form: any) {
    if (form.valid) {
      this.submitted = true;
      console.log('Form data:', this.model);
    }
  }
}
```

---

## Reactive Forms

### Basic Reactive Form

```typescript
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-register-form',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  template: `
    <form [formGroup]="registerForm" (ngSubmit)="onSubmit()">
      <div>
        <label>Username:</label>
        <input formControlName="username">
        <div *ngIf="username?.invalid && username?.touched" class="error">
          <p *ngIf="username?.errors?.['required']">Username required</p>
          <p *ngIf="username?.errors?.['minlength']">Min 3 characters</p>
        </div>
      </div>
      
      <div>
        <label>Email:</label>
        <input formControlName="email">
        <div *ngIf="email?.invalid && email?.touched" class="error">
          <p *ngIf="email?.errors?.['required']">Email required</p>
          <p *ngIf="email?.errors?.['email']">Invalid email</p>
        </div>
      </div>
      
      <div formGroupName="passwords">
        <div>
          <label>Password:</label>
          <input type="password" formControlName="password">
          <div *ngIf="password?.invalid && password?.touched" class="error">
            <p *ngIf="password?.errors?.['required']">Password required</p>
            <p *ngIf="password?.errors?.['minlength']">Min 6 characters</p>
          </div>
        </div>
        
        <div>
          <label>Confirm Password:</label>
          <input type="password" formControlName="confirmPassword">
        </div>
        
        <div *ngIf="passwords?.errors?.['mismatch'] && passwords?.touched" class="error">
          Passwords don't match
        </div>
      </div>
      
      <button type="submit" [disabled]="registerForm.invalid">
        Register
      </button>
    </form>
  `
})
export class RegisterFormComponent implements OnInit {
  registerForm!: FormGroup;
  
  constructor(private fb: FormBuilder) { }
  
  ngOnInit() {
    this.registerForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      passwords: this.fb.group({
        password: ['', [Validators.required, Validators.minLength(6)]],
        confirmPassword: ['', Validators.required]
      }, { validators: this.passwordMatchValidator })
    });
  }
  
  // Custom validator
  passwordMatchValidator(group: FormGroup) {
    const pass = group.get('password')?.value;
    const confirm = group.get('confirmPassword')?.value;
    return pass === confirm ? null : { mismatch: true };
  }
  
  // Convenience getters
  get username() { return this.registerForm.get('username'); }
  get email() { return this.registerForm.get('email'); }
  get passwords() { return this.registerForm.get('passwords'); }
  get password() { return this.registerForm.get('passwords.password'); }
  
  onSubmit() {
    if (this.registerForm.valid) {
      console.log(this.registerForm.value);
    }
  }
}
```

### FormArray Example

```typescript
import { Component } from '@angular/core';
import { FormBuilder, FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-dynamic-form',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  template: `
    <form [formGroup]="form">
      <div formArrayName="skills">
        <div *ngFor="let skill of skills.controls; let i=index">
          <input [formControlName]="i" placeholder="Skill {{i+1}}">
          <button type="button" (click)="removeSkill(i)">Remove</button>
        </div>
      </div>
      <button type="button" (click)="addSkill()">Add Skill</button>
    </form>
  `
})
export class DynamicFormComponent {
  form: FormGroup;
  
  constructor(private fb: FormBuilder) {
    this.form = this.fb.group({
      skills: this.fb.array([this.fb.control('')])
    });
  }
  
  get skills() {
    return this.form.get('skills') as FormArray;
  }
  
  addSkill() {
    this.skills.push(this.fb.control(''));
  }
  
  removeSkill(index: number) {
    this.skills.removeAt(index);
  }
}
```

---

## Form Validation

### Custom Validators

```typescript
import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

// Synchronous validator
export function forbiddenNameValidator(nameRe: RegExp): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const forbidden = nameRe.test(control.value);
    return forbidden ? { forbiddenName: { value: control.value } } : null;
  };
}

// Async validator
export function uniqueUsernameValidator(userService: UserService): AsyncValidatorFn {
  return (control: AbstractControl): Observable<ValidationErrors | null> => {
    return userService.checkUsername(control.value).pipe(
      map(isTaken => isTaken ? { usernameTaken: true } : null),
      catchError(() => of(null))
    );
  };
}

// Usage
this.form = this.fb.group({
  username: ['', 
    [Validators.required, forbiddenNameValidator(/admin/i)],
    [uniqueUsernameValidator(this.userService)]
  ]
});
```

---

## Coding Challenges

### Challenge 1: Multi-Step Form
**Difficulty: Hard**

Create a multi-step registration form with navigation and validation.

<details>
<summary>Solution</summary>

```typescript
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-multi-step-form',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  template: `
    <div class="wizard">
      <!-- Step indicator -->
      <div class="steps">
        <div *ngFor="let step of steps; let i=index" 
             [class.active]="currentStep === i"
             [class.completed]="i < currentStep">
          {{ step }}
        </div>
      </div>
      
      <!-- Form -->
      <form [formGroup]="form">
        <!-- Step 1: Personal Info -->
        <div *ngIf="currentStep === 0">
          <h3>Personal Information</h3>
          <input formControlName="firstName" placeholder="First Name">
          <input formControlName="lastName" placeholder="Last Name">
          <input formControlName="email" type="email" placeholder="Email">
        </div>
        
        <!-- Step 2: Address -->
        <div *ngIf="currentStep === 1">
          <h3>Address</h3>
          <input formControlName="street" placeholder="Street">
          <input formControlName="city" placeholder="City">
          <input formControlName="zipcode" placeholder="Zipcode">
        </div>
        
        <!-- Step 3: Review -->
        <div *ngIf="currentStep === 2">
          <h3>Review</h3>
          <pre>{{ form.value | json }}</pre>
        </div>
      </form>
      
      <!-- Navigation -->
      <div class="navigation">
        <button (click)="previousStep()" [disabled]="currentStep === 0">
          Previous
        </button>
        <button *ngIf="currentStep < 2" 
                (click)="nextStep()"
                [disabled]="!isStepValid(currentStep)">
          Next
        </button>
        <button *ngIf="currentStep === 2" 
                (click)="submit()"
                [disabled]="form.invalid">
          Submit
        </button>
      </div>
    </div>
  `
})
export class MultiStepFormComponent {
  currentStep = 0;
  steps = ['Personal', 'Address', 'Review'];
  
  form: FormGroup;
  
  constructor(private fb: FormBuilder) {
    this.form = this.fb.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      street: ['', Validators.required],
      city: ['', Validators.required],
      zipcode: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]]
    });
  }
  
  nextStep() {
    if (this.isStepValid(this.currentStep)) {
      this.currentStep++;
    }
  }
  
  previousStep() {
    this.currentStep--;
  }
  
  isStepValid(step: number): boolean {
    switch (step) {
      case 0:
        return this.form.get('firstName')?.valid &&
               this.form.get('lastName')?.valid &&
               this.form.get('email')?.valid || false;
      case 1:
        return this.form.get('street')?.valid &&
               this.form.get('city')?.valid &&
               this.form.get('zipcode')?.valid || false;
      default:
        return true;
    }
  }
  
  submit() {
    if (this.form.valid) {
      console.log('Submitted:', this.form.value);
    }
  }
}
```
</details>

---

## Interview Questions

**Q1: What's the difference between template-driven and reactive forms?**

**Answer:**

| Template-Driven | Reactive |
|-----------------|----------|
| FormsModule | ReactiveFormsModule |
| HTML-heavy | TypeScript-heavy |
| [(ngModel)] | FormControl |
| Async | Sync |
| Simple forms | Complex forms |
| Less testable | More testable |

---

**Q2: How do route guards work?**

**Answer:** Guards control navigation to/from routes:

- **CanActivate**: Before entering route
- **CanDeactivate**: Before leaving route  
- **CanActivateChild**: Before child routes
- **Resolve**: Load data before route

Return true/false or UrlTree for redirect.

---

**Q3: Explain lazy loading benefits.**

**Answer:**
- Smaller initial bundle
- Faster startup
- Load on demand
- Better performance
- Code splitting

---

[← Back to Index](angular19-guide-index.md) | [Previous: State Management](angular19-part4-state-management.md) | [Next: HTTP and RxJS →](angular19-part6-http-rxjs.md)
