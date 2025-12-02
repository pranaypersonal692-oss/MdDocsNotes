# Angular 19 - Part 6: HTTP and RxJS

[← Back to Index](angular19-guide-index.md) | [Previous: Routing and Forms](angular19-part5-routing-forms.md) | [Next: Advanced Topics →](angular19-part7-advanced.md)

## Table of Contents
- [HttpClient Setup](#httpclient-setup)
- [HTTP Methods](#http-methods)
- [Interceptors](#interceptors)
- [Error Handling](#error-handling)
- [RxJS Operators](#rxjs-operators)
- [Observable Patterns](#observable-patterns)
- [Coding Challenges](#coding-challenges)
- [Interview Questions](#interview-questions)

---

## HttpClient Setup

### Standalone App Setup

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { provideHttpClient } from '@angular/common/http';

bootstrapApplication(AppComponent, {
  providers: [
    provideHttpClient()
  ]
});
```

--- 

## HTTP Methods

### GET Request

```typescript
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface User {
  id: number;
  name: string;
  email: string;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private apiUrl = 'https://api.example.com/users';
  
  constructor(private http: HttpClient) { }
  
  // GET all users
  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl);
  }
  
  // GET single user
  getUser(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }
  
  // GET with query params
  searchUsers(query: string): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl, {
     params: { q: query, limit: '10' }
    });
  }
}
```

### POST, PUT, PATCH, DELETE

```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  // POST - Create
  createUser(user: Omit<User, 'id'>): Observable<User> {
    return this.http.post<User>(this.apiUrl, user);
  }
  
  // PUT - Replace
  updateUser(id: number, user: User): Observable<User> {
    return this.http.put<User>(`${this.apiUrl}/${id}`, user);
  }
  
  // PATCH - Partial update
  patchUser(id: number, updates: Partial<User>): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}`, updates);
  }
  
  // DELETE
  deleteUser(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
```

---

## Interceptors

### Auth Interceptor

```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();
  
  if (token) {
    const cloned = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
    return next(cloned);
  }
  
  return next(req);
};

// Provide in main.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';

bootstrapApplication(AppComponent, {
  providers: [
    provideHttpClient(
      withInterceptors([authInterceptor])
    )
  ]
});
```

### Logging Interceptor

```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { tap } from 'rxjs/operators';

export const loggingInterceptor: HttpInterceptorFn = (req, next) => {
  const started = Date.now();
  console.log(`Request: ${req.method} ${req.url}`);
  
  return next(req).pipe(
    tap({
      next: (event) => {
        if (event.type === 4) {  // Response event
          const elapsed = Date.now() - started;
          console.log(`Response: ${req.url} in ${elapsed}ms`);
        }
      },
      error: (error) => {
        console.error(`Error: ${req.url}`, error);
      }
    })
  );
};
```

---

## Error Handling

### Service-Level Error Handling

```typescript
import { catchError, retry, throwError } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class UserService {
  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl).pipe(
      retry(3),  // Retry 3 times
      catchError(this.handleError)
    );
  }
  
  private handleError(error: HttpErrorResponse) {
    let errorMessage = 'An error occurred';
    
    if (error.error instanceof ErrorEvent) {
      // Client-side error
      errorMessage = `Error: ${error.error.message}`;
    } else {
      // Server-side error
      errorMessage = `Error Code: ${error.status}\nMessage: ${error.message}`;
    }
    
    console.error(errorMessage);
    return throwError(() => new Error(errorMessage));
  }
}
```

### Global Error Interceptor

```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      let errorMsg = '';
      
      if (error.status === 401) {
        errorMsg = 'Unauthorized';
        // Redirect to login
      } else if (error.status === 403) {
        errorMsg = 'Forbidden';
      } else if (error.status === 404) {
        errorMsg = 'Not Found';
      } else {
        errorMsg = `Error: ${error.message}`;
      }
      
      return throwError(() => new Error(errorMsg));
    })
  );
};
```

---

## RxJS Operators

### Transformation Operators

```typescript
 import { map, pluck, switchMap, mergeMap, concatMap } from 'rxjs/operators';

// map - Transform each value
this.http.get<User[]>(url).pipe(
  map(users => users.filter(u => u.isActive))
);

// switchMap - Cancel previous, start new
searchInput$.pipe(
  debounceTime(300),
  switchMap(query => this.http.get(`/search?q=${query}`))
);

// mergeMap - Run in parallel
userIds$.pipe(
  mergeMap(id => this.http.get(`/users/${id}`))
);

// concatMap - Run sequentially
requests$.pipe(
  concatMap(req => this.http.post('/api', req))
);
```

### Combination Operators

```typescript
import { combineLatest, forkJoin, merge, zip } from 'rxjs';

// combineLatest - Emit when any observable emits
combineLatest([
  this.http.get('/users'),
  this.http.get('/posts')
]).pipe(
  map(([users, posts]) => ({ users, posts }))
);

// forkJoin - Wait for all to complete
forkJoin({
  users: this.http.get('/users'),
  posts: this.http.get('/posts'),
  comments: this.http.get('/comments')
}).subscribe(({ users, posts, comments }) => {
  console.log('All loaded:', users, posts, comments);
});

// merge - Emit from any source
merge(
  this.http.get('/api1'),
  this.http.get('/api2')
).subscribe(result => console.log(result));
```

### Filtering Operators

```typescript
import { filter, distinct, distinctUntilChanged, debounceTime } from 'rxjs/operators';

// filter - Only emit matching values
numbers$.pipe(
  filter(n => n % 2 === 0)
);

// distinctUntilChanged - Only when value changes
searchInput$.pipe(
  distinctUntilChanged()
);

// debounceTime - Wait for pause
searchInput$.pipe(
  debounceTime(300)
);
```

---

## Observable Patterns

### Pattern 1: Search with Debounce

```typescript
@Component({
  template: `
    <input [formControl]="searchControl" placeholder="Search...">
    <div *ngIf="loading">Loading...</div>
    <div *ngFor="let result of results$ | async">
      {{ result.name }}
    </div>
  `
})
export class SearchComponent implements OnInit {
  searchControl = new FormControl('');
  results$!: Observable<any[]>;
  loading = false;
  
  ngOnInit() {
    this.results$ = this.searchControl.valueChanges.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      tap(() => this.loading = true),
      switchMap(query => 
        query ? this.searchService.search(query) : of([])
      ),
      tap(() => this.loading = false)
    );
  }
}
```

### Pattern 2: Caching Data

```typescript
@Injectable({ providedIn: 'root' })
export class DataService {
  private cache$ = new BehaviorSubject<Data[] | null>(null);
  
  getData(): Observable<Data[]> {
    // Return cached data if available
    if (this.cache$.value) {
      return this.cache$.asObservable().pipe(
        filter(data => data !== null),
        take(1)
      );
    }
    
    // Otherwise fetch and cache
    return this.http.get<Data[]>(url).pipe(
      tap(data => this.cache$.next(data)),
      shareReplay(1)  // Share result with multiple subscribers
    );
  }
  
  invalidateCache() {
    this.cache$.next(null);
  }
}
```

---

## Coding Challenges

### Challenge: Advanced HTTP Service with Error Handling
**Difficulty: Hard**

<details>
<summary>Solution</summary>

```typescript
import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError, BehaviorSubject } from 'rxjs';
import { catchError, retry, tap, finalize, shareReplay } from 'rxjs/operators';

export interface ApiResponse<T> {
  data: T;
  message: string;
  success: boolean;
}

export interface LoadingState {
  [key: string]: boolean;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private loadingSubject = new BehaviorSubject<LoadingState>({});
  loading$ = this.loadingSubject.asObservable();
  
  private cache = new Map<string, Observable<any>>();
  
  constructor(private http: HttpClient) { }
  
  get<T>(url: string, useCache = false): Observable<ApiResponse<T>> {
    if (useCache && this.cache.has(url)) {
      return this.cache.get(url)!;
    }
    
    this.setLoading(url, true);
    
    const request$ = this.http.get<ApiResponse<T>>(url).pipe(
      retry(2),
      tap(response => console.log('GET Success:', url, response)),
      catchError(error => this.handleError(error, url)),
      finalize(() => this.setLoading(url, false)),
      shareReplay(1)
    );
    
    if (useCache) {
      this.cache.set(url, request$);
      setTimeout(() => this.cache.delete(url), 60000);  // Cache for 1 min
    }
    
    return request$;
  }
  
  post<T>(url: string, body: any): Observable<ApiResponse<T>> {
    this.setLoading(url, true);
    
    return this.http.post<ApiResponse<T>>(url, body).pipe(
      tap(response => console.log('POST Success:', url, response)),
      catchError(error => this.handleError(error, url)),
      finalize(() => this.setLoading(url, false))
    );
  }
  
  private setLoading(key: string, loading: boolean) {
    const current = this.loadingSubject.value;
    this.loadingSubject.next({ ...current, [key]: loading });
  }
  
  private handleError(error: HttpErrorResponse, url: string) {
    let errorMessage = 'An error occurred';
    
    if (error.error instanceof ErrorEvent) {
      errorMessage = `Client Error: ${error.error.message}`;
    } else {
      errorMessage = `Server Error (${error.status}): ${error.message}`;
    }
    
    console.error(`Error for ${url}:`, errorMessage);
    return throwError(() => new Error(errorMessage));
  }
  
  clearCache() {
    this.cache.clear();
  }
}
```
</details>

---

## Interview Questions

**Q1: What is the difference between switchMap, mergeMap, and concatMap?**

**Answer:**

- **switchMap**: Cancels previous, switches to new observable. Use for search/autocomplete.
- **mergeMap**: Runs all in parallel. Use when order doesn't matter.
- **concatMap**: Runs sequentially, waits for each to complete. Use when order matters.

```typescript
// switchMap - Cancel previous
search$.pipe(switchMap(q => this.http.get(`/search?q=${q}`)))

// mergeMap - Parallel
ids$.pipe(mergeMap(id => this.http.get(`/users/${id}`)))

// concatMap - Sequential  
requests$.pipe(concatMap(req => this.http.post('/api', req)))
```

---

**Q2: What are HTTP Interceptors and when would you use them?**

**Answer:** Interceptors intercept HTTP requests/responses to add common functionality:

**Use cases:**
- Add authentication headers
- Logging
- Error handling
- Loading indicators
- Caching
- Request/response transformation

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const cloned = req.clone({
    setHeaders: { Authorization: `Bearer ${token}` }
  });
  return next(cloned);
};
```

---

**Q3: How do you handle errors in HTTP requests?**

**Answer:**

```typescript
this.http.get(url).pipe(
  retry(3),  // Retry failed requests
  catchError(error => {
    // Handle error
    console.error(error);
    return throwError(() => new Error('Failed'));
  })
);
```

---

[← Back to Index](angular19-guide-index.md) | [Previous: Routing and Forms](angular19-part5-routing-forms.md) | [Next: Advanced Topics →](angular19-part7-advanced.md)
