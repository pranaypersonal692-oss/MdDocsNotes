# Angular 19 - Part 4: State Management with BehaviorSubject

[←  Back to Index](angular19-guide-index.md) | [Previous: Services and DI](angular19-part3-services-di.md) | [Next: Routing and Forms →](angular19-part5-routing-forms.md)

## Table of Contents
- [Introduction to State Management](#introduction-to-state-management)
- [RxJS Basics](#rxjs-basics)
- [Subject vs BehaviorSubject vs ReplaySubject](#subject-vs-behaviorsubject-vs-replaysubject)
- [State Management with BehaviorSubject](#state-management-with-behaviorsubject)
- [Real-World Patterns](#real-world-patterns)
- [Best Practices](#best-practices)
- [Coding Challenges](#coding-challenges)
- [Interview Questions](#interview-questions)

---

## Introduction to State Management

### What is State Management?

State management is the practice of managing data flow and state across your application. In Angular, state can be:
- **Local State** - Component-specific data
- **Shared State** - Data shared across components
- **Global State** - Application-wide data

### Why BehaviorSubject?

BehaviorSubject is perfect for state management because it:
- Always has a current value
- Emits last value to new subscribers
- Simple and lightweight
- No external dependencies
- Built into RxJS

---

## RxJS Basics

### Observables

```typescript
import { Observable } from 'rxjs';

// Creating an Observable
const observable$ = new Observable(subscriber => {
  subscriber.next(1);
  subscriber.next(2);
  subscriber.next(3);
  subscriber.complete();
});

// Subscribing
observable$.subscribe({
  next: (value) => console.log(value),
  error: (err) => console.error(err),
  complete: () => console.log('Complete')
});
```

### Common RxJS Operators

```typescript
import { of, interval } from 'rxjs';
import { map, filter, tap, take, debounceTime, distinctUntilChanged } from 'rxjs/operators';

// map - Transform values
of(1, 2, 3).pipe(
  map(x => x * 2)
).subscribe(console.log);  // 2, 4, 6

// filter - Filter values
of(1, 2, 3, 4, 5).pipe(
  filter(x => x % 2 === 0)
).subscribe(console.log);  // 2, 4

// tap - Side effects
of(1, 2, 3).pipe(
  tap(x => console.log('Before:', x)),
  map(x => x * 2),
  tap(x => console.log('After:', x))
).subscribe();

// take - Take first N values
interval(1000).pipe(
  take(3)
).subscribe(console.log);  // 0, 1, 2

// debounceTime - Wait for pause
searchInput$.pipe(
  debounceTime(300)
).subscribe();

// distinctUntilChanged - Only emit when value changes
of(1, 1, 2, 2, 3, 3).pipe(
  distinctUntilChanged()
).subscribe(console.log);  // 1, 2, 3
```

---

## Subject vs BehaviorSubject vs ReplaySubject

### Subject

```typescript
import { Subject } from 'rxjs';

const subject = new Subject<number>();

// Subscribe 1
subject.subscribe(value => console.log('Sub 1:', value));

subject.next(1);  // Sub 1: 1
subject.next(2);  // Sub 1: 2

// Subscribe 2 (doesn't get previous values)
subject.subscribe(value => console.log('Sub 2:', value));

subject.next(3);  // Sub 1: 3, Sub 2: 3
```

**Characteristics:**
- No initial value
- New subscribers don't get previous values
- Only gets values emitted after subscription

### BehaviorSubject

```typescript
import { BehaviorSubject } from 'rxjs';

const behaviorSubject = new BehaviorSubject<number>(0);  // Initial value required

// Subscribe 1
behaviorSubject.subscribe(value => console.log('Sub 1:', value));  // Sub 1: 0

behaviorSubject.next(1);  // Sub 1: 1
behaviorSubject.next(2);  // Sub 1: 2

// Subscribe 2 (gets last value immediately)
behaviorSubject.subscribe(value => console.log('Sub 2:', value));  // Sub 2: 2

behaviorSubject.next(3);  // Sub 1: 3, Sub 2: 3

// Get current value synchronously
console.log(behaviorSubject.value);  // 3
```

**Characteristics:**
- Requires initial value
- New subscribers get last emitted value immediately
- Has `.value` property for synchronous access
- **Perfect for state management!**

### ReplaySubject

```typescript
import { ReplaySubject } from 'rxjs';

const replaySubject = new ReplaySubject<number>(2);  // Buffer size: 2

replaySubject.next(1);
replaySubject.next(2);
replaySubject.next(3);

// New subscriber gets last 2 values
replaySubject.subscribe(value => console.log('Sub:', value));  // Sub: 2, Sub: 3
```

**Characteristics:**
- Replays N previous values
- No initial value required
- Good for event history

### Comparison Table

| Feature | Subject | BehaviorSubject | ReplaySubject |
|---------|---------|-----------------|---------------|
| Initial value | No | Yes (required) | No |
| New subscribers | No previous values | Last value | N previous values |
| .value property | No | Yes | No |
| Use case | Events | State | History |

---

## State Management with BehaviorSubject

### Basic State Service

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface User {
  id: number;
  name: string;
  email: string;
}

@Injectable({
  providedIn: 'root'
})
export class UserStateService {
  // Private subject - only service can emit
  private userSubject = new BehaviorSubject<User | null>(null);
  
  // Public observable - components can subscribe
  user$: Observable<User | null> = this.userSubject.asObservable();
  
  // Get current value
  get currentUser(): User | null {
    return this.userSubject.value;
  }
  
  // Set user
  setUser(user: User): void {
    this.userSubject.next(user);
  }
  
  // Update user
  updateUser(updates: Partial<User>): void {
    const current = this.userSubject.value;
    if (current) {
      this.userSubject.next({ ...current, ...updates });
    }
  }
  
  // Clear user
  clearUser(): void {
    this.userSubject.next(null);
  }
}

// Component usage
@Component({
  selector: 'app-user-profile',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div *ngIf="user$ | async as user; else noUser">
      <h3>{{ user.name }}</h3>
      <p>{{ user.email }}</p>
      <button (click)="updateUsername()">Update Name</button>
      <button (click)="logout()">Logout</button>
    </div>
    <ng-template #noUser>
      <p>No user logged in</p>
      <button (click)="login()">Login</button>
    </ng-template>
  `
})
export class UserProfileComponent {
  user$ = this.userState.user$;
  
  constructor(private userState: UserStateService) { }
  
  login() {
    this.userState.setUser({
      id: 1,
      name: 'John Doe',
      email: 'john@example.com'
    });
  }
  
  updateUsername() {
    this.userState.updateUser({ name: 'Jane Doe' });
  }
  
  logout() {
    this.userState.clearUser();
  }
}
```

### Complex State Service

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface CartItem {
  id: number;
  name: string;
  price: number;
  quantity: number;
}

export interface CartState {
  items: CartItem[];
  loading: boolean;
  error: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class CartStateService {
  private initialState: CartState = {
    items: [],
    loading: false,
    error: null
  };
  
  private stateSubject = new BehaviorSubject<CartState>(this.initialState);
  
  // State observable
  state$ = this.stateSubject.asObservable();
  
  // Derived observables
  items$ = this.state$.pipe(map(state => state.items));
  loading$ = this.state$.pipe(map(state => state.loading));
  error$ = this.state$.pipe(map(state => state.error));
  
  // Computed observables
  totalItems$ = this.items$.pipe(
    map(items => items.reduce((sum, item) => sum + item.quantity, 0))
  );
  
  totalPrice$ = this.items$.pipe(
    map(items => items.reduce((sum, item) => sum + (item.price * item.quantity), 0))
  );
  
  isEmpty$ = this.items$.pipe(
    map(items => items.length === 0)
  );
  
  // Get current state
  private get state(): CartState {
    return this.stateSubject.value;
  }
  
  // Update state
  private setState(newState: Partial<CartState>): void {
    this.stateSubject.next({
      ...this.state,
      ...newState
    });
  }
  
  // Actions
  addItem(product: Omit<CartItem, 'quantity'>): void {
    const items = [...this.state.items];
    const existingIndex = items.findIndex(item => item.id === product.id);
    
    if (existingIndex >= 0) {
      items[existingIndex] = {
        ...items[existingIndex],
        quantity: items[existingIndex].quantity + 1
      };
    } else {
      items.push({ ...product, quantity: 1 });
    }
    
    this.setState({ items });
  }
  
  removeItem(id: number): void {
    const items = this.state.items.filter(item => item.id !== id);
    this.setState({ items });
  }
  
  updateQuantity(id: number, quantity: number): void {
    if (quantity <= 0) {
      this.removeItem(id);
      return;
    }
    
    const items = this.state.items.map(item =>
      item.id === id ? { ...item, quantity } : item
    );
    this.setState({ items });
  }
  
  clearCart(): void {
    this.setState({ items: [] });
  }
  
  setLoading(loading: boolean): void {
    this.setState({ loading });
  }
  
  setError(error: string | null): void {
    this.setState({ error });
  }
  
  // Get item by ID
  getItem(id: number): CartItem | undefined {
    return this.state.items.find(item => item.id === id);
  }
}

// Component
@Component({
  selector: 'app-cart',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="cart">
      <h2>Shopping Cart</h2>
      
      <div *ngIf="loading$ | async" class="loading">
        Loading...
      </div>
      
      <div *ngIf="error$ | async as error" class="error">
        {{ error }}
      </div>
      
      <div *ngIf="isEmpty$ | async; else cartContent">
        <p>Your cart is empty</p>
      </div>
      
      <ng-template #cartContent>
        <div class="cart-items">
          <div *ngFor="let item of items$ | async" class="cart-item">
            <span>{{ item.name }}</span>
            <span>\${{ item.price }}</span>
            <input 
              type="number"
              [value]="item.quantity"
              (change)="updateQuantity(item.id, $any($event.target).value)"
              min="0"
            >
            <span>\${{ item.price * item.quantity }}</span>
            <button (click)="removeItem(item.id)">Remove</button>
          </div>
        </div>
        
        <div class="cart-summary">
          <p>Total Items: {{ totalItems$ | async }}</p>
          <p>Total Price: \${{ totalPrice$ | async }}</p>
          <button (click)="clearCart()">Clear Cart</button>
        </div>
      </ng-template>
    </div>
  `
})
export class CartComponent {
  items$ = this.cartState.items$;
  loading$ = this.cartState.loading$;
  error$ = this.cartState.error$;
  isEmpty$ = this.cartState.isEmpty$;
  totalItems$ = this.cartState.totalItems$;
  totalPrice$ = this.cartState.totalPrice$;
  
  constructor(private cartState: CartStateService) { }
  
  updateQuantity(id: number, quantity: string): void {
    this.cartState.updateQuantity(id, parseInt(quantity, 10));
  }
  
  removeItem(id: number): void {
    this.cartState.removeItem(id);
  }
  
  clearCart(): void {
    this.cartState.clearCart();
  }
}
```

---

## Real-World Patterns

### Pattern 1: Facade Pattern

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

export type FilterType = 'all' | 'active' | 'completed';

@Injectable({
  providedIn: 'root'
})
export class TodoFacadeService {
  private todosSubject = new BehaviorSubject<Todo[]>([]);
  private filterSubject = new BehaviorSubject<FilterType>('all');
  private nextId = 1;
  
  // Observables
  private todos$ = this.todosSubject.asObservable();
  private filter$ = this.filterSubject.asObservable();
  
  // Filtered todos based on current filter
  filteredTodos$ = combineLatest([this.todos$, this.filter$]).pipe(
    map(([todos, filter]) => {
      switch (filter) {
        case 'active':
          return todos.filter(t => !t.completed);
        case 'completed':
          return todos.filter(t => t.completed);
        default:
          return todos;
      }
    })
  );
  
  // Stats
  stats$ = this.todos$.pipe(
    map(todos => ({
      total: todos.length,
      active: todos.filter(t => !t.completed).length,
      completed: todos.filter(t => t.completed).length
    }))
  );
  
  // Actions
  addTodo(title: string): void {
    const todos = this.todosSubject.value;
    this.todosSubject.next([
      ...todos,
      { id: this.nextId++, title, completed: false }
    ]);
  }
  
  toggleTodo(id: number): void {
    const todos = this.todosSubject.value.map(todo =>
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    );
    this.todosSubject.next(todos);
  }
  
  deleteTodo(id: number): void {
    const todos = this.todosSubject.value.filter(t => t.id !== id);
    this.todosSubject.next(todos);
  }
  
  setFilter(filter: FilterType): void {
    this.filterSubject.next(filter);
  }
  
  get currentFilter(): FilterType {
    return this.filterSubject.value;
  }
}
```

### Pattern 2: Immutable State Updates

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface AppState {
  user: {
    name: string;
    email: string;
  } | null;
  settings: {
    theme: 'light' | 'dark';
    notifications: boolean;
  };
  data: any[];
}

@Injectable({
  providedIn: 'root'
})
export class StateService {
  private initialState: AppState = {
    user: null,
    settings: {
      theme: 'light',
      notifications: true
    },
    data: []
  };
  
  private stateSubject = new BehaviorSubject<AppState>(this.initialState);
  state$ = this.stateSubject.asObservable();
  
  // Immutable update helpers
  private updateState(updater: (state: AppState) => AppState): void {
    const currentState = this.stateSubject.value;
    const newState = updater(currentState);
    this.stateSubject.next(newState);
  }
  
  // Update nested properties immutably
  setUser(name: string, email: string): void {
    this.updateState(state => ({
      ...state,
      user: { name, email }
    }));
  }
  
  updateUserName(name: string): void {
    this.updateState(state => ({
      ...state,
      user: state.user ? { ...state.user, name } : null
    }));
  }
  
  setTheme(theme: 'light' | 'dark'): void {
    this.updateState(state => ({
      ...state,
      settings: {
        ...state.settings,
        theme
      }
    }));
  }
  
  toggleNotifications(): void {
    this.updateState(state => ({
      ...state,
      settings: {
        ...state.settings,
        notifications: !state.settings.notifications
      }
    }));
  }
  
  addData(item: any): void {
    this.updateState(state => ({
      ...state,
      data: [...state.data, item]
    }));
  }
  
  resetState(): void {
    this.stateSubject.next(this.initialState);
  }
}
```

### Pattern 3: Loading and Error States

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { catchError, finalize, tap } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';

export interface DataState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class DataStateService<T> {
  private stateSubject = new BehaviorSubject<DataState<T>>({
    data: null,
    loading: false,
    error: null
  });
  
  state$ = this.stateSubject.asObservable();
  
  constructor(private http: HttpClient) { }
  
  loadData(url: string): void {
    // Set loading
    this.stateSubject.next({
      ...this.stateSubject.value,
      loading: true,
      error: null
    });
    
    this.http.get<T>(url)
      .pipe(
        tap(data => {
          // Success
          this.stateSubject.next({
            data,
            loading: false,
            error: null
          });
        }),
        catchError(error => {
          // Error
          this.stateSubject.next({
            data: null,
            loading: false,
            error: error.message || 'An error occurred'
          });
          return throwError(() => error);
        })
      )
      .subscribe();
  }
  
  setData(data: T): void {
    this.stateSubject.next({
      data,
      loading: false,
      error: null
    });
  }
  
  clearData(): void {
    this.stateSubject.next({
      data: null,
      loading: false,
      error: null
    });
  }
}
```

---

## Best Practices

### 1. Private Subject, Public Observable

```typescript
// ✅ Good
private userSubject = new BehaviorSubject<User | null>(null);
user$ = this.userSubject.asObservable();

// ❌ Bad
user$ = new BehaviorSubject<User | null>(null);  // Exposes next()
```

### 2. Immutable State Updates

```typescript
// ✅ Good
updateUser(updates: Partial<User>): void {
  const current = this.userSubject.value;
  this.userSubject.next({ ...current, ...updates });
}

// ❌ Bad
updateUser(updates: Partial<User>): void {
  const current = this.userSubject.value;
  Object.assign(current, updates);  // Mutation!
  this.userSubject.next(current);
}
```

### 3. Cleanup in ngOnDestroy

```typescript
// ✅ Good
private destroy$ = new Subject<void>();

ngOnInit() {
  this.dataService.data$
    .pipe(takeUntil(this.destroy$))
    .subscribe();
}

ngOnDestroy() {
  this.destroy$.next();
  this.destroy$.complete();
}

// ⭐ Better - use async pipe
// Template: {{ data$ | async }}
// Auto-unsubscribes!
```

### 4. Type Safety

```typescript
// ✅ Good
private userSubject = new BehaviorSubject<User | null>(null);

//❌ Bad
private userSubject = new BehaviorSubject<any>(null);
```

### 5. Derive State

```typescript
// ✅ Good - derive from base state
items$ = this.state$.pipe(map(state => state.items));
total$ = this.items$.pipe(map(items => items.length));

// ❌ Bad - separate subjects for derived data
private itemsSubject = new BehaviorSubject([]);
private totalSubject = new BehaviorSubject(0);
```

---

## Coding Challenges

### Challenge 1: Auth State Service
**Difficulty: Medium**

Create an authentication state service with login, logout, and token management.

<details>
<summary>Solution</summary>

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface AuthUser {
  id: number;
  username: string;
  email: string;
  token: string;
}

export interface AuthState {
  user: AuthUser | null;
  isAuthenticated: boolean;
  loading: boolean;
  error: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class AuthStateService {
  private readonly STORAGE_KEY = 'auth_user';
  
  private initialState: AuthState = {
    user: this.loadUserFromStorage(),
    isAuthenticated: !!this.loadUserFromStorage(),
    loading: false,
    error: null
  };
  
  private stateSubject = new BehaviorSubject<AuthState>(this.initialState);
  
  // Observables
  state$ = this.stateSubject.asObservable();
  user$ = this.state$.pipe(map(state => state.user));
  isAuthenticated$ = this.state$.pipe(map(state => state.isAuthenticated));
  loading$ = this.state$.pipe(map(state => state.loading));
  error$ = this.state$.pipe(map(state => state.error));
  
  private get state(): AuthState {
    return this.stateSubject.value;
  }
  
  private setState(newState: Partial<AuthState>): void {
    this.stateSubject.next({ ...this.state, ...newState });
  }
  
  // Load user from localStorage
  private loadUserFromStorage(): AuthUser | null {
    const stored = localStorage.getItem(this.STORAGE_KEY);
    return stored ? JSON.parse(stored) : null;
  }
  
  // Save user to localStorage
  private saveUserToStorage(user: AuthUser): void {
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(user));
  }
  
  // Remove user from localStorage
  private removeUserFromStorage(): void {
    localStorage.removeItem(this.STORAGE_KEY);
  }
  
  // Login
  login(username: string, password: string): Observable<boolean> {
    this.setState({ loading: true, error: null });
    
    // Simulate API call
    return new Observable(observer => {
      setTimeout(() => {
        if (username && password) {
          const user: AuthUser = {
            id: 1,
            username,
            email: `${username}@example.com`,
            token: 'fake-jwt-token'
          };
          
          this.saveUserToStorage(user);
          this.setState({
            user,
            isAuthenticated: true,
            loading: false,
            error: null
          });
          
          observer.next(true);
          observer.complete();
        } else {
          this.setState({
            loading: false,
            error: 'Invalid credentials'
          });
          observer.next(false);
          observer.complete();
        }
      }, 1000);
    });
  }
  
  // Logout
  logout(): void {
    this.removeUserFromStorage();
    this.setState({
      user: null,
      isAuthenticated: false,
      loading: false,
      error: null
    });
  }
  
  // Update user
  updateUser(updates: Partial<AuthUser>): void {
    if (this.state.user) {
      const updatedUser = { ...this.state.user, ...updates };
      this.saveUserToStorage(updatedUser);
      this.setState({ user: updatedUser });
    }
  }
  
  // Get token
  getToken(): string | null {
    return this.state.user?.token || null;
  }
  
  // Check if authenticated
  isLoggedIn(): boolean {
    return this.state.isAuthenticated;
  }
}

// Usage Component
@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="login">
      <h2>Login</h2>
      
      <div *ngIf="loading$ | async" class="loading">
        Logging in...
      </div>
      
      <div *ngIf="error$ | async as error" class="error">
        {{ error }}
      </div>
      
      <div *ngIf="!(isAuthenticated$ | async); else loggedIn">
        <input [(ngModel)]="username" placeholder="Username">
        <input [(ngModel)]="password" type="password" placeholder="Password">
        <button (click)="login()">Login</button>
      </div>
      
      <ng-template #loggedIn>
        <div *ngIf="user$ | async as user">
          <p>Welcome, {{ user.username }}!</p>
          <button (click)="logout()">Logout</button>
        </div>
      </ng-template>
    </div>
  `
})
export class LoginComponent {
  username = '';
  password = '';
  
  loading$ = this.authState.loading$;
  error$ = this.authState.error$;
  isAuthenticated$ = this.authState.isAuthenticated$;
  user$ = this.authState.user$;
  
  constructor(private authState: AuthStateService) { }
  
  login(): void {
    this.authState.login(this.username, this.password).subscribe();
  }
  
  logout(): void {
    this.authState.logout();
  }
}
```
</details>

### Challenge 2: Multi-Feature State Service
**Difficulty: Hard**

Create a state service managing multiple features (users, products, settings) in one centralized state.

<details>
<summary>Solution</summary>

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { map } from 'rxjs/operators';

export interface User {
  id: number;
  name: string;
}

export interface Product {
  id: number;
  name: string;
  price: number;
}

export interface Settings {
  theme: 'light' | 'dark';
  language: string;
}

export interface AppState {
  users: {
    data: User[];
    loading: boolean;
    error: string | null;
  };
  products: {
    data: Product[];
    loading: boolean;
    error: string | null;
  };
  settings: Settings;
}

@Injectable({
  providedIn: 'root'
})
export class AppStateService {
  private initialState: AppState = {
    users: {
      data: [],
      loading: false,
      error: null
    },
    products: {
      data: [],
      loading: false,
      error: null
    },
    settings: {
      theme: 'light',
      language: 'en'
    }
  };
  
  private stateSubject = new BehaviorSubject<AppState>(this.initialState);
  state$ = this.stateSubject.asObservable();
  
  // Feature selectors
  users$ = this.state$.pipe(map(state => state.users.data));
  usersLoading$ = this.state$.pipe(map(state => state.users.loading));
  usersError$ = this.state$.pipe(map(state => state.users.error));
  
  products$ = this.state$.pipe(map(state => state.products.data));
  productsLoading$ = this.state$.pipe(map(state => state.products.loading));
  productsError$ = this.state$.pipe(map(state => state.products.error));
  
  settings$ = this.state$.pipe(map(state => state.settings));
  theme$ = this.state$.pipe(map(state => state.settings.theme));
  language$ = this.state$.pipe(map(state => state.settings.language));
  
  private get state(): AppState {
    return this.stateSubject.value;
  }
  
  private setState(newState: Partial<AppState>): void {
    this.stateSubject.next({ ...this.state, ...newState });
  }
  
  // User actions
  setUsers(users: User[]): void {
    this.setState({
      users: { data: users, loading: false, error: null }
    });
  }
  
  addUser(user: User): void {
    const users = [...this.state.users.data, user];
    this.setUsers(users);
  }
  
  removeUser(id: number): void {
    const users = this.state.users.data.filter(u => u.id !== id);
    this.setUsers(users);
  }
  
  setUsersLoading(loading: boolean): void {
    this.setState({
      users: { ...this.state.users, loading }
    });
  }
  
  // Product actions
  setProducts(products: Product[]): void {
    this.setState({
      products: { data: products, loading: false, error: null }
    });
  }
  
  addProduct(product: Product): void {
    const products = [...this.state.products.data, product];
    this.setProducts(products);
  }
  
  // Settings actions
  setTheme(theme: 'light' | 'dark'): void {
    this.setState({
      settings: { ...this.state.settings, theme }
    });
  }
  
  setLanguage(language: string): void {
    this.setState({
      settings: { ...this.state.settings, language }
    });
  }
}
```
</details>

---

## Interview Questions

**Q1: What is BehaviorSubject and how is it different from Subject?**

**Answer:**

**BehaviorSubject:**
- Requires initial value
- Emits current value to new subscribers
- Has `.value` property
- Perfect for state management

**Subject:**
- No initial value
- Doesn't emit to new subscribers
- No `.value` property
- Good for events

```typescript
// BehaviorSubject
const bs = new BehaviorSubject(0);
bs.subscribe(v => console.log(v));  // Logs: 0

// Subject
const s = new Subject();
s.subscribe(v => console.log(v));  // Logs nothing
```

---

**Q2: Why use BehaviorSubject for state management instead of a library like NgRx?**

**Answer:**

**BehaviorSubject Advantages:**
- Simple and lightweight
- No external dependencies
- Less boilerplate
- Easier learning curve
- Perfect for small to medium apps

**NgRx Advantages:**
- Better for large apps
- Time-travel debugging
- Predictable state mutations
- Dev tools
- Better for teams

**Recommendation:** Use BehaviorSubject unless you need NgRx features.

**Q3: How do you ensure immutability when updating BehaviorSubject state?**

**Answer:**

```typescript
// ✅ Immutable
updateState(updates: Partial<State>): void {
  const current = this.stateSubject.value;
  this.stateSubject.next({ ...current, ...updates });  // New object
}

// ✅ Immutable (arrays)
addItem(item: any): void {
  const current = this.stateSubject.value;
  this.stateSubject.next({
    ...current,
    items: [...current.items, item]  // New array
  });
}

// ❌ Mutable (avoid)
updateState(updates): void {
  const current = this.stateSubject.value;
  Object.assign(current, updates);  // Mutates!
  this.stateSubject.next(current);
}
```

---

**Q4: Should you expose BehaviorSubject directly or as Observable?**

**Answer:**

**Best Practice: Expose as Observable**

```typescript
// ✅ Good
private userSubject = new BehaviorSubject<User | null>(null);
user$ = this.userSubject.asObservable();  // Readonly

// ❌ Bad
user$ = new BehaviorSubject<User | null>(null);  // Exposes next()
```

**Why:** Prevents external code from calling `.next()`, enforcing encapsulation.

---

**Q5: How do you handle memory leaks with BehaviorSubject subscriptions?**

**Answer:**

**Option 1: takeUntil Pattern**
```typescript
private destroy$ = new Subject<void>();

ngOnInit() {
  this.state.user$
    .pipe(takeUntil(this.destroy$))
    .subscribe();
}

ngOnDestroy() {
  this.destroy$.next();
  this.destroy$.complete();
}
```

**Option 2: Async Pipe (Best)**
```html
<div *ngIf="user$ | async as user">{{ user.name }}</div>
```

**Option 3: Manual Unsubscribe**
```typescript
subscription = this.state.user$.subscribe();

ngOnDestroy() {
  this.subscription.unsubscribe();
}
```

---

[← Back to Index](angular19-guide-index.md) | [Previous: Services and DI](angular19-part3-services-di.md) | [Next: Routing and Forms →](angular19-part5-routing-forms.md)
