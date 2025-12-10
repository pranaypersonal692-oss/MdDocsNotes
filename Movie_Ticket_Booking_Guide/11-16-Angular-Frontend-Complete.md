# Module 11-16: Angular 19 Frontend (Combined)

This combined module covers Angular 19 project setup, state management with Signals, components, routing, HTTP services, and forms.

## Part 1: Angular 19 Project Setup

### 1.1 Create Angular Project

```bash
# Install Angular CLI 19
npm install -g @angular/cli@latest

# Create new project
ng new movie-booking-app --standalone --routing --style=scss

cd movie-booking-app

# Install dependencies
npm install @angular/material @angular/cdk
npm install date-fns
npm install jwt-decode
```

### 1.2 Project Structure

```
movie-booking-app/
├── src/
│   ├── app/
│   │   ├── core/
│   │   │   ├── guards/
│   │   │   ├── interceptors/
│   │   │   ├── services/
│   │   │   └── models/
│   │   ├── features/
│   │   │   ├── movies/
│   │   │   ├── bookings/
│   │   │   ├── auth/
│   │   │   └── admin/
│   │   ├── shared/
│   │   │   ├── components/
│   │   │   ├── pipes/
│   │   │   └── directives/
│   │   └── app.component.ts
│   └── environments/
└── angular.json
```

### 1.3 Environment Configuration

`src/environments/environment.ts`:

```typescript
export const environment = {
  production: false,
  apiUrl: 'https://localhost:7001/api',
  apiTimeout: 30000
};
```

---

## Part 2: State Management with Angular Signals

### 2.1 Auth State Service

`src/app/core/services/auth-state.service.ts`:

```typescript
import { Injectable, signal, computed } from '@angular/core';
import { Router } from '@angular/router';

export interface AuthUser {
  id: number;
  email: string;
  name: string;
  role: string;
}

@Injectable({ providedIn: 'root' })
export class AuthStateService {
  private userSignal = signal<AuthUser | null>(null);
  private accessTokenSignal = signal<string | null>(null);

  // Public computed signals
  user = this.userSignal.asReadonly();
  accessToken = this.accessTokenSignal.asReadonly();
  isAuthenticated = computed(() => !!this.userSignal());
  isAdmin = computed(() => this.userSignal()?.role === 'Admin');

  constructor(private router: Router) {
    this.loadFromStorage();
  }

  setAuth(user: AuthUser, accessToken: string, refreshToken: string): void {
    this.userSignal.set(user);
    this.accessTokenSignal.set(accessToken);
    localStorage.setItem('user', JSON.stringify(user));
    localStorage.setItem('accessToken', accessToken);
    localStorage.setItem('refreshToken', refreshToken);
  }

  logout(): void {
    this.userSignal.set(null);
    this.accessTokenSignal.set(null);
    localStorage.removeItem('user');
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    this.router.navigate(['/login']);
  }

  private loadFromStorage(): void {
    const user = localStorage.getItem('user');
    const token = localStorage.getItem('accessToken');
    if (user && token) {
      this.userSignal.set(JSON.parse(user));
      this.accessTokenSignal.set(token);
    }
  }
}
```

### 2.2 Movie State Service

`src/app/features/movies/services/movie-state.service.ts`:

```typescript
import { Injectable, signal, computed } from '@angular/core';
import { Movie } from '../../../core/models/movie.model';

@Injectable({ providedIn: 'root' })
export class MovieStateService {
  private moviesSignal = signal<Movie[]>([]);
  private loadingSignal = signal(false);
  private selectedMovieSignal = signal<Movie | null>(null);

  // Public readonly signals
  movies = this.moviesSignal.asReadonly();
  loading = this.loadingSignal.asReadonly();
  selectedMovie = this.selectedMovieSignal.asReadonly();

  // Computed signals
  nowShowing = computed(() =>
    this.moviesSignal().filter(m => m.status === 'NowShowing')
  );

  comingSoon = computed(() =>
    this.moviesSignal().filter(m => m.status === 'ComingSoon')
  );

  // State mutations
  setMovies(movies: Movie[]): void {
    this.moviesSignal.set(movies);
  }

  setLoading(loading: boolean): void {
    this.loadingSignal.set(loading);
  }

  setSelectedMovie(movie: Movie | null): void {
    this.selectedMovieSignal.set(movie);
  }

  addMovie(movie: Movie): void {
    this.moviesSignal.update(movies => [...movies, movie]);
  }

  updateMovie(id: number, updates: Partial<Movie>): void {
    this.moviesSignal.update(movies =>
      movies.map(m => m.id === id ? { ...m, ...updates } : m)
    );
  }
}
```

---

## Part 3: HTTP Services

### 3.1 Base API Service

`src/app/core/services/api.service.ts`:

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl;

  get<T>(endpoint: string, params?: any): Observable<ApiResponse<T>> {
    const httpParams = this.buildParams(params);
    return this.http.get<ApiResponse<T>>(`${this.apiUrl}/${endpoint}`, { params: httpParams });
  }

  post<T>(endpoint: string, body: any): Observable<ApiResponse<T>> {
    return this.http.post<ApiResponse<T>>(`${this.apiUrl}/${endpoint}`, body);
  }

  put<T>(endpoint: string, body: any): Observable<ApiResponse<T>> {
    return this.http.put<ApiResponse<T>>(`${this.apiUrl}/${endpoint}`, body);
  }

  delete<T>(endpoint: string): Observable<ApiResponse<T>> {
    return this.http.delete<ApiResponse<T>>(`${this.apiUrl}/${endpoint}`);
  }

  private buildParams(params?: any): HttpParams {
    let httpParams = new HttpParams();
    if (params) {
      Object.keys(params).forEach(key => {
        if (params[key] !== null && params[key] !== undefined) {
          httpParams = httpParams.set(key, params[key].toString());
        }
      });
    }
    return httpParams;
  }
}
```

### 3.2 Movie Service

`src/app/features/movies/services/movie.service.ts`:

```typescript
import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { ApiService, ApiResponse } from '../../../core/services/api.service';
import { MovieStateService } from './movie-state.service';
import { Movie, CreateMovieDto } from '../../../core/models/movie.model';

@Injectable({ providedIn: 'root' })
export class MovieService {
  private api = inject(ApiService);
  private state = inject(MovieStateService);

  getNowShowing(): Observable<ApiResponse<Movie[]>> {
    this.state.setLoading(true);
    return this.api.get<Movie[]>('movies/now-showing').pipe(
      tap(response => {
        this.state.setMovies(response.data);
        this.state.setLoading(false);
      })
    );
  }

  getMovieById(id: number): Observable<ApiResponse<Movie>> {
    return this.api.get<Movie>(`movies/${id}`).pipe(
      tap(response => this.state.setSelectedMovie(response.data))
    );
  }

  searchMovies(query: string): Observable<ApiResponse<Movie[]>> {
    return this.api.get<Movie[]>('movies/search', { q: query });
  }

  createMovie(dto: CreateMovieDto): Observable<ApiResponse<Movie>> {
    return this.api.post<Movie>('movies', dto).pipe(
      tap(response => this.state.addMovie(response.data))
    );
  }
}
```

### 3.3 Booking Service

`src/app/features/bookings/services/booking.service.ts`:

```typescript
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from '../../../core/services/api.service';
import { Booking, CreateBookingDto } from '../../../core/models/booking.model';

@Injectable({ providedIn: 'root' })
export class BookingService {
  private api = inject(ApiService);

  createBooking(dto: CreateBookingDto): Observable<ApiResponse<Booking>> {
    return this.api.post<Booking>('bookings', dto);
  }

  getMyBookings(): Observable<ApiResponse<Booking[]>> {
    return this.api.get<Booking[]>('bookings/my-bookings');
  }

  getBooking(bookingCode: string): Observable<ApiResponse<Booking>> {
    return this.api.get<Booking>(`bookings/${bookingCode}`);
  }

  cancelBooking(id: number): Observable<ApiResponse<any>> {
    return this.api.delete(`bookings/${id}`);
  }
}
```

### 3.4 Auth Service

`src/app/features/auth/services/auth.service.ts`:

```typescript
import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { ApiService, ApiResponse } from '../../../core/services/api.service';
import { AuthStateService } from '../../../core/services/auth-state.service';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string;
}

export interface AuthResponse {
  user: any;
  accessToken: string;
  refreshToken: string;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private api = inject(ApiService);
  private authState = inject(AuthStateService);

  login(request: LoginRequest): Observable<ApiResponse<AuthResponse>> {
    return this.api.post<AuthResponse>('auth/login', request).pipe(
      tap(response => {
        const { user, accessToken, refreshToken } = response.data;
        this.authState.setAuth(user, accessToken, refreshToken);
      })
    );
  }

  register(request: RegisterRequest): Observable<ApiResponse<AuthResponse>> {
    return this.api.post<AuthResponse>('auth/register', request).pipe(
      tap(response => {
        const { user, accessToken, refreshToken } = response.data;
        this.authState.setAuth(user, accessToken, refreshToken);
      })
    );
  }

  logout(): void {
    this.authState.logout();
  }
}
```

---

## Part 4: HTTP Interceptors

### 4.1 Auth Interceptor

`src/app/core/interceptors/auth.interceptor.ts`:

```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthStateService } from '../services/auth-state.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authState = inject(AuthStateService);
  const token = authState.accessToken();

  if (token) {
    req = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }

  return next(req);
};
```

### 4.2 Error Interceptor

`src/app/core/interceptors/error.interceptor.ts`:

```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { Router } from '@angular/router';
import { AuthStateService } from '../services/auth-state.service';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const authState = inject(AuthStateService);

  return next(req).pipe(
    catchError(error => {
      if (error.status === 401) {
        authState.logout();
        router.navigate(['/login']);
      }

      const errorMessage = error.error?.message || error.message || 'An error occurred';
      console.error('HTTP Error:', errorMessage);
      
      return throwError(() => new Error(errorMessage));
    })
  );
};
```

### 4.3 Register Interceptors

`src/app/app.config.ts`:

```typescript
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { authInterceptor } from './core/interceptors/auth.interceptor';
import { errorInterceptor } from './core/interceptors/error.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(
      withInterceptors([authInterceptor, errorInterceptor])
    )
  ]
};
```

---

## Part 5: Components

### 5.1 Movie List Component

`src/app/features/movies/components/movie-list/movie-list.component.ts`:

```typescript
import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MovieService } from '../../services/movie.service';
import { MovieStateService } from '../../services/movie-state.service';
import { Movie } from '../../../../core/models/movie.model';

@Component({
  selector: 'app-movie-list',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="movie-list">
      <h2>Now Showing</h2>
      
      @if (state.loading()) {
        <div class="loading">Loading movies...</div>
      }

      <div class="movies-grid">
        @for (movie of state.movies(); track movie.id) {
          <div class="movie-card" [routerLink]="['/movies', movie.id]">
            <img [src]="movie.posterUrl" [alt]="movie.title">
            <h3>{{ movie.title }}</h3>
            <p>{{ movie.genre }}</p>
            <div class="rating">
              <span>⭐ {{ movie.rating }}</span>
            </div>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .movies-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 20px;
      padding: 20px;
    }

    .movie-card {
      cursor: pointer;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: transform 0.2s;
    }

    .movie-card:hover {
      transform: scale(1.05);
    }

    .movie-card img {
      width: 100%;
      height: 300px;
      object-fit: cover;
    }

    .movie-card h3 {
      padding: 10px;
      margin: 0;
    }
  `]
})
export class MovieListComponent implements OnInit {
  private movieService = inject(MovieService);
  state = inject(MovieStateService);

  ngOnInit(): void {
    this.movieService.getNowShowing().subscribe();
  }
}
```

### 5.2 Login Component

`src/app/features/auth/components/login/login.component.ts`:

```typescript
import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  template: `
    <div class="login-container">
      <form [formGroup]="loginForm" (ngSubmit)="onSubmit()">
        <h2>Login</h2>

        <div class="form-group">
          <label>Email</label>
          <input type="email" formControlName="email" />
          @if (loginForm.get('email')?.touched && loginForm.get('email')?.errors?.['required']) {
            <span class="error">Email is required</span>
          }
        </div>

        <div class="form-group">
          <label>Password</label>
          <input type="password" formControlName="password" />
          @if (loginForm.get('password')?.touched && loginForm.get('password')?.errors?.['required']) {
            <span class="error">Password is required</span>
          }
        </div>

        @if (errorMessage()) {
          <div class="alert alert-error">{{ errorMessage() }}</div>
        }

        <button type="submit" [disabled]="!loginForm.valid || loading()">
          {{ loading() ? 'Logging in...' : 'Login' }}
        </button>

        <p>Don't have an account? <a routerLink="/register">Register</a></p>
      </form>
    </div>
  `,
  styles: [`
    .login-container {
      max-width: 400px;
      margin: 50px auto;
      padding: 20px;
    }

    .form-group {
      margin-bottom: 15px;
    }

    .form-group label {
      display: block;
      margin-bottom: 5px;
    }

    .form-group input {
      width: 100%;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
    }

    button {
      width: 100%;
      padding: 10px;
      background: #007bff;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }

    button:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .error {
      color: red;
      font-size: 12px;
    }
  `]
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);

  loading = signal(false);
  errorMessage = signal('');

  loginForm = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]]
  });

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.loading.set(true);
      this.errorMessage.set('');

      this.authService.login(this.loginForm.value as any).subscribe({
        next: () => {
          this.loading.set(false);
          this.router.navigate(['/movies']);
        },
        error: (error) => {
          this.loading.set(false);
          this.errorMessage.set(error.message);
        }
      });
    }
  }
}
```

---

## Part 6: Routing & Guards

### 6.1 Auth Guard

`src/app/core/guards/auth.guard.ts`:

```typescript
import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { AuthStateService } from '../services/auth-state.service';

export const authGuard: CanActivateFn = () => {
  const authState = inject(AuthStateService);
  const router = inject(Router);

  if (authState.isAuthenticated()) {
    return true;
  }

  router.navigate(['/login']);
  return false;
};

export const adminGuard: CanActivateFn = () => {
  const authState = inject(AuthStateService);
  const router = inject(Router);

  if (authState.isAdmin()) {
    return true;
  }

  router.navigate(['/']);
  return false;
};
```

### 6.2 Routes

`src/app/app.routes.ts`:

```typescript
import { Routes } from '@angular/router';
import { authGuard, adminGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'movies',
    pathMatch: 'full'
  },
  {
    path: 'movies',
    loadComponent: () => import('./features/movies/components/movie-list/movie-list.component')
      .then(m => m.MovieListComponent)
  },
  {
    path: 'movies/:id',
    loadComponent: () => import('./features/movies/components/movie-detail/movie-detail.component')
      .then(m => m.MovieDetailComponent)
  },
  {
    path: 'login',
    loadComponent: () => import('./features/auth/components/login/login.component')
      .then(m => m.LoginComponent)
  },
  {
    path: 'register',
    loadComponent: () => import('./features/auth/components/register/register.component')
      .then(m => m.RegisterComponent)
  },
  {
    path: 'bookings',
    canActivate: [authGuard],
    loadComponent: () => import('./features/bookings/components/booking-list/booking-list.component')
      .then(m => m.BookingListComponent)
  },
  {
    path: 'admin',
    canActivate: [adminGuard],
    loadChildren: () => import('./features/admin/admin.routes')
      .then(m => m.adminRoutes)
  }
];
```

---

**Modules 11-16 Complete** ✅  
**Progress**: 16/18 modules (88.9%)

👉 **Next: Testing & Deployment Modules (17-18)**
