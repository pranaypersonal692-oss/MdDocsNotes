# Angular 19 - Part 3: Services and Dependency Injection

[← Back to Index](angular19-guide-index.md) | [Previous: Templates and Directives](angular19-part2-templates-directives.md) | [Next: State Management →](angular19-part4-state-management.md)

## Table of

 Contents
- [Services](#services)
- [Dependency Injection](#dependency-injection)
- [Providers](#providers)
- [Injection Tokens](#injection-tokens)
- [Coding Challenges](#coding-challenges)
- [Interview Questions](#interview-questions)

---

## Services

### What are Services?

Services are **singleton** classes that encapsulate business logic, data access, and shared functionality. They promote:
- Code reusability
- Separation of concerns
- Testability
- Centralized logic

### Creating a Service

```typescript
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'  // Singleton across entire app
})
export class DataService {
  private data: string[] = [];
  
  addItem(item: string) {
    this.data.push(item);
  }
  
  getItems(): string[] {
    return this.data;
  }
  
  clearItems() {
    this.data = [];
  }
}
```

### Using a Service in Components

```typescript
import { Component, OnInit } from '@angular/core';
import { DataService } from './data.service';

@Component({
  selector: 'app-data-display',
  standalone: true,
  template: `
    <div>
      <h3>Items:</h3>
      <ul>
        <li *ngFor="let item of items">{{ item }}</li>
      </ul>
      <input #input type="text">
      <button (click)="addItem(input.value); input.value=''">Add</button>
    </div>
  `
})
export class DataDisplayComponent implements OnInit {
  items: string[] = [];
  
  constructor(private dataService: DataService) { }
  
  ngOnInit() {
    this.items = this.dataService.getItems();
  }
  
  addItem(item: string) {
    if (item.trim()) {
      this.dataService.addItem(item);
      this.items = this.dataService.getItems();
    }
  }
}
```

### Service with HTTP

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface User {
  id: number;
  name: string;
  email: string;
}

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private apiUrl = 'https://api.example.com/users';
  
  constructor(private http: HttpClient) { }
  
  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl);
  }
  
  getUser(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }
  
  createUser(user: Omit<User, 'id'>): Observable<User> {
    return this.http.post<User>(this.apiUrl, user);
  }
  
  updateUser(id: number, user: Partial<User>): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}`, user);
  }
  
  deleteUser(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
```

---

## Dependency Injection

### What is DI?

Dependency Injection is a design pattern where a class receives its dependencies from external sources rather than creating them itself.

**Benefits:**
- Loose coupling
- Easy testing (mock dependencies)
- Flexibility
- Maintainability

### Constructor Injection

```typescript
// Service
@Injectable({ providedIn: 'root' })
export class LoggerService {
  log(message: string) {
    console.log(`[LOG]: ${message}`);
  }
}

// Component
@Component({
  selector: 'app-example',
  standalone: true,
  template: `<button (click)="onClick()">Click</button>`
})
export class ExampleComponent {
  // Dependency injected via constructor
  constructor(private logger: LoggerService) { }
  
  onClick() {
    this.logger.log('Button clicked');
  }
}
```

### inject() Function (Angular 14+)

```typescript
import { Component } from '@angular/core';
import { inject } from '@angular/core';
import { LoggerService } from './logger.service';

@Component({
  selector: 'app-modern',
  standalone: true,
  template: `<button (click)="onClick()">Click</button>`
})
export class ModernComponent {
  // Alternative to constructor injection
  private logger = inject(LoggerService);
  private http = inject(HttpClient);
  
  onClick() {
    this.logger.log('Clicked');
  }
}
```

### Hierarchical Injectors

Angular has a multi-level injector hierarchy:

```
┌─────────────────────────┐
│   Platform Injector     │ (Singleton for entire platform)
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│    Root Injector        │ (providedIn: 'root')
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│  Component Injector     │ (providers: [...])
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│ Element Injector        │ (Directive providers)
└─────────────────────────┘
```

Example:

```typescript
// Root level - Singleton
@Injectable({ providedIn: 'root' })
export class RootService { }

// Component level - New instance per component
@Component({
  selector: 'app-example',
  standalone: true,
  providers: [ComponentService]  // New instance for this component
})
export class ExampleComponent {
  constructor(
    private rootService: RootService,        // Shared instance
    private componentService: ComponentService  // Unique instance
  ) { }
}
```

---

## Providers

### providedIn: 'root'

```typescript
@Injectable({
  providedIn: 'root'  // Singleton, tree-shakeable
})
export class GlobalService { }
```

**Benefits:**
- Tree-shakeable (removed if not used)
- Singleton across app
- Recommended approach

### Component/Module Providers

```typescript
// Component-level provider
@Component({
  selector: 'app-example',
  standalone: true,
  providers: [LocalService]  // New instance per component
})
export class ExampleComponent { }

// Standalone component imports
@Component({
  standalone: true,
  providers: [
    { provide: API_URL, useValue: 'https://api.example.com' },
    { provide: LoggerService, useClass: ConsoleLogger }
  ]
})
export class ConfiguredComponent { }
```

### Provider Types

#### useClass
```typescript
@Injectable({ providedIn: 'root' })
export abstract class Logger {
  abstract log(message: string): void;
}

@Injectable()
export class ConsoleLogger extends Logger {
  log(message: string) {
    console.log(message);
  }
}

// Provider
providers: [
  { provide: Logger, useClass: ConsoleLogger }
]

// Usage
constructor(private logger: Logger) { }
```

#### useValue
```typescript
export const APP_CONFIG = {
  apiUrl: 'https://api.example.com',
  timeout: 5000
};

providers: [
  { provide: 'APP_CONFIG', useValue: APP_CONFIG }
]

// Usage
constructor(@Inject('APP_CONFIG') private config: any) { }
```

#### useFactory
```typescript
export function loggerFactory(isDev: boolean) {
  return isDev ? new DevLogger() : new ProdLogger();
}

providers: [
  {
    provide: Logger,
    useFactory: loggerFactory,
    deps: [IS_DEV_MODE]
  }
]
```

#### useExisting
```typescript
providers: [
  NewService,
  { provide: OldService, useExisting: NewService }  // Alias
]
```

---

## Injection Tokens

### String Tokens (Not Recommended)

```typescript
// Avoid - no type safety
providers: [
  { provide: 'API_URL', useValue: 'https://api.example.com' }
]

constructor(@Inject('API_URL') private apiUrl: string) { }
```

### InjectionToken (Recommended)

```typescript
import { InjectionToken } from '@angular/core';

// Define token
export const API_URL = new InjectionToken<string>('API URL');

export interface AppConfig {
  apiUrl: string;
  timeout: number;
}

export const APP_CONFIG = new InjectionToken<AppConfig>('App Config');

// Provide
import { bootstrapApplication } from '@angular/platform-browser';

bootstrapApplication(AppComponent, {
  providers: [
    { provide: API_URL, useValue: 'https://api.example.com' },
    {
      provide: APP_CONFIG,
      useValue: {
        apiUrl: 'https://api.example.com',
        timeout: 5000
      }
    }
  ]
});

// Inject
constructor(
  @Inject(API_URL) private apiUrl: string,
  @Inject(APP_CONFIG) private config: AppConfig
) { }
```

### Optional Dependencies

```typescript
import { Optional } from '@angular/core';

constructor(
  @Optional() private logger?: LoggerService
) {
  if (this.logger) {
    this.logger.log('Logger available');
  }
}
```

### Self and SkipSelf

```typescript
import { Self, SkipSelf } from '@angular/core';

constructor(
  @Self() private localService: LocalService,        // Only from current injector
  @SkipSelf() private parentService: ParentService   // Only from parent injectors
) { }
```

---

## Coding Challenges

### Challenge 1: CRUD Service
**Difficulty: Medium**

Create a service for managing a todo list with CRUD operations.

<details>
<summary>Solution</summary>

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface Todo {
  id: number;
  title: string;
  completed: boolean;
  createdAt: Date;
}

@Injectable({
  providedIn: 'root'
})
export class TodoService {
  private todos: Todo[] = [];
  private nextId = 1;
  private todosSubject = new BehaviorSubject<Todo[]>([]);
  
  todos$ = this.todosSubject.asObservable();
  
  // Create
  addTodo(title: string): Todo {
    const todo: Todo = {
      id: this.nextId++,
      title,
      completed: false,
      createdAt: new Date()
    };
    this.todos.push(todo);
    this.todosSubject.next([...this.todos]);
    return todo;
  }
  
  // Read
  getTodos(): Todo[] {
    return [...this.todos];
  }
  
  getTodo(id: number): Todo | undefined {
    return this.todos.find(t => t.id === id);
  }
  
  // Update
  updateTodo(id: number, updates: Partial<Todo>): boolean {
    const index = this.todos.findIndex(t => t.id === id);
    if (index !== -1) {
      this.todos[index] = { ...this.todos[index], ...updates };
      this.todosSubject.next([...this.todos]);
      return true;
    }
    return false;
  }
  
  toggleComplete(id: number): boolean {
    const todo = this.getTodo(id);
    if (todo) {
      return this.updateTodo(id, { completed: !todo.completed });
    }
    return false;
  }
  
  // Delete
  deleteTodo(id: number): boolean {
    const index = this.todos.findIndex(t => t.id === id);
    if (index !== -1) {
      this.todos.splice(index, 1);
      this.todosSubject.next([...this.todos]);
      return true;
    }
    return false;
  }
  
  // Utility
  clearCompleted(): void {
    this.todos = this.todos.filter(t => !t.completed);
    this.todosSubject.next([...this.todos]);
  }
  
  getStats() {
    return {
      total: this.todos.length,
      completed: this.todos.filter(t => t.completed).length,
      pending: this.todos.filter(t => !t.completed).length
    };
  }
}

// Component using the service
@Component({
  selector: 'app-todo-app',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="todo-app">
      <h2>Todo App</h2>
      
      <div class="stats">
        <span>Total: {{ stats.total }}</span>
        <span>Completed: {{ stats.completed }}</span>
        <span>Pending: {{ stats.pending }}</span>
      </div>
      
      <div class="add-todo">
        <input [(ngModel)]="newTodoTitle" (keyup.enter)="addTodo()">
        <button (click)="addTodo()">Add</button>
      </div>
      
      <ul class="todo-list">
        <li *ngFor="let todo of todos$ | async" [class.completed]="todo.completed">
          <input 
            type="checkbox"
            [checked]="todo.completed"
            (change)="toggleTodo(todo.id)"
          >
          <span>{{ todo.title }}</span>
          <button (click)="deleteTodo(todo.id)">Delete</button>
        </li>
      </ul>
      
      <button (click)="clearCompleted()">Clear Completed</button>
    </div>
  `
})
export class TodoAppComponent {
  newTodoTitle = '';
  todos$ = this.todoService.todos$;
  
  constructor(private todoService: TodoService) { }
  
  get stats() {
    return this.todoService.getStats();
  }
  
  addTodo() {
    if (this.newTodoTitle.trim()) {
      this.todoService.addTodo(this.newTodoTitle);
      this.newTodoTitle = '';
    }
  }
  
  toggleTodo(id: number) {
    this.todoService.toggleComplete(id);
  }
  
  deleteTodo(id: number) {
    this.todoService.deleteTodo(id);
  }
  
  clearCompleted() {
    this.todoService.clearCompleted();
  }
}
```
</details>

### Challenge 2: Service with Factory Provider
**Difficulty: Hard**

Create a  logger service that uses different implementations based on the environment.

<details>
<summary>Solution</summary>

```typescript
// Logger interface
export abstract class Logger {
  abstract log(message: string): void;
  abstract error(message: string): void;
  abstract warn(message: string): void;
}

// Development logger
@Injectable()
export class DevLogger extends Logger {
  log(message: string) {
    console.log(`[DEV LOG] ${new Date().toISOString()}: ${message}`);
  }
  
  error(message: string) {
    console.error(`[DEV ERROR] ${new Date().toISOString()}: ${message}`);
  }
  
  warn(message: string) {
    console.warn(`[DEV WARN] ${new Date().toISOString()}: ${message}`);
  }
}

// Production logger
@Injectable()
export class ProdLogger extends Logger {
  private logs: string[] = [];
  
  log(message: string) {
    this.logs.push(`LOG: ${message}`);
    // Could send to logging service
  }
  
  error(message: string) {
    this.logs.push(`ERROR: ${message}`);
    // Send to error tracking service
    console.error(message);
  }
  
  warn(message: string) {
    this.logs.push(`WARN: ${message}`);
  }
  
  getLogs() {
    return this.logs;
  }
}

// Environment token
export const IS_PRODUCTION = new InjectionToken<boolean>('Is Production');

// Factory function
export function loggerFactory(isProduction: boolean): Logger {
  return isProduction ? new ProdLogger() : new DevLogger();
}

// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { environment } from './environments/environment';

bootstrapApplication(AppComponent, {
  providers: [
    { provide: IS_PRODUCTION, useValue: environment.production },
    {
      provide: Logger,
      useFactory: loggerFactory,
      deps: [IS_PRODUCTION]
    }
  ]
});

// Usage in component
@Component({
  selector: 'app-root',
  standalone: true,
  template: `
    <button (click)="testLogger()">Test Logger</button>
  `
})
export class AppComponent {
  constructor(private logger: Logger) { }
  
  testLogger() {
    this.logger.log('This is a log message');
    this.logger.warn('This is a warning');
    this.logger.error('This is an error');
  }
}
```
</details>

---

## Interview Questions

### Basic Questions

**Q1: What is a service in Angular?**

**Answer:** A service is a class with a focused purpose, typically used for:
- Business logic
- Data access
- Sharing data between components
- External communication (HTTP)

Services are singletons (when provided in root) and promote code reuse and separation of concerns.

```typescript
@Injectable({ providedIn: 'root' })
export class DataService {
  getData() { return this.data; }
}
```

---

**Q2: What is Dependency Injection?**

**Answer:** DI is a design pattern where classes receive dependencies from external sources instead of creating them:

**Without DI:**
```typescript
class Component {
  service = new Service();  // Tight coupling
}
```

**With DI:**
```typescript
class Component {
  constructor(private service: Service) { }  // Loose coupling
}
```

Benefits: Testability, flexibility, maintainability.

---

**Q3: What does providedIn: 'root' mean?**

**Answer:**
```typescript
@Injectable({ providedIn: 'root' })
export class MyService { }
```

- Service is registered in root injector
- Singleton across entire application
- Tree-shakeable (removed if unused)
- Recommended approach
- No need to add to providers array

---

**Q4: How do you inject a service in a component?**

**Answer:** Two ways:

**Constructor injection:**
```typescript
constructor(private myService: MyService) { }
```

**inject() function (Angular 14+):**
```typescript
private myService = inject(MyService);
```

Both create the same result.

---

**Q5: What's the difference between providing a service at root vs component level?**

**Answer:**

| Root Level | Component Level |
|------------|-----------------|
| providedIn: 'root' | providers: [...] |
| Singleton across app | New instance per component |
| Shared data | Isolated data |
| Tree-shakeable | Not tree-shakeable |

```typescript
// Root - shared instance
@Injectable({ providedIn: 'root' })

// Component - separate instance
@Component({
  providers: [MyService]
})
```

---

### Intermediate Questions

**Q6: Explain the different types of providers.**

**Answer:**

**1. useClass:**
```typescript
{ provide: Logger, useClass: ConsoleLogger }
```

**2. useValue:**
```typescript
{ provide: API_URL, useValue: 'https://api.com' }
```

**3. useFactory:**
```typescript
{
  provide: Service,
  useFactory: () => new Service(config),
  deps: [Config]
}
```

**4. useExisting:**
```typescript
{ provide: OldService, useExisting: NewService }
```

---

**Q7: What is an InjectionToken and why use it?**

**Answer:** InjectionToken provides type-safe dependency injection for non-class dependencies:

```typescript
// Define
export const API_URL = new InjectionToken<string>('API URL');

//  Provide
providers: [
  { provide: API_URL, useValue: 'https://api.com' }
]

// Inject
constructor(@Inject(API_URL) private apiUrl: string) { }
```

**Benefits:**
- Type safety
- Better than string tokens
- Prevents naming collisions
- IDE autocomplete

---

**Q8: Explain @Optional, @Self, and @SkipSelf decorators.**

**Answer:**

**@Optional** - Dependency is optional:
```typescript
constructor(@Optional() private logger?: Logger) {
  if (this.logger) this.logger.log('Available');
}
```

**@Self** - Only look in current injector:
```typescript
constructor(@Self() private service: Service) { }
```

**@SkipSelf** - Skip current, look in parent:
```typescript
constructor(@SkipSelf() private parentService: Service) { }
```

---

### Advanced Questions

**Q9: Explain Angular's hierarchical dependency injection.**

**Answer:** Angular has multi-level injector hierarchy:

```
Platform Injector (Singleton for platform)
    ↓
Root Injector (providedIn: 'root')
    ↓
Module Injector (NgModule providers)
    ↓
Component Injector (Component providers)
    ↓
Element Injector (Directive providers)
```

**Resolution:**
- Starts at requested level
- Bubbles up to parent
- Throws error if not found (unless @Optional)

**Example:**
```typescript
// Root level
@Injectable({ providedIn: 'root' })
export class GlobalService { }

// Component level
@Component({
  providers: [LocalService]  // Shadows parent if same token
})
```

---

**Q10: How does tree-shaking work with providedIn?**

**Answer:**

**Tree-shakeable:**
```typescript
@Injectable({ providedIn: 'root' })
export class MyService { }
```

- Service registered in root
- If never injected anywhere, removed from bundle
- Reduces bundle size

**Not tree-shakeable:**
```typescript
// Module
@NgModule({
  providers: [MyService]  // Always included
})
```

- Service always included in bundle
- Even if not used

**Recommendation:** Always use `providedIn: 'root'` unless you need component-specific instances.

---

**Q11: How would you create a plugin system using DI?**

**Answer:**
```typescript
// Plugin interface
export abstract class Plugin {
  abstract name: string;
  abstract execute(): void;
}

// Plugins token
export const PLUGINS = new InjectionToken<Plugin[]>('Plugins');

// Plugin implementations
@Injectable()
export class LogPlugin extends Plugin {
  name = 'Logger';
  execute() { console.log('Logging...'); }
}

@Injectable()
export class AnalyticsPlugin extends Plugin {
  name = 'Analytics';
  execute() { console.log('Tracking...'); }
}

// Provide multiple
providers: [
  LogPlugin,
  AnalyticsPlugin,
  {
    provide: PLUGINS,
    useFactory: (log: LogPlugin, analytics: AnalyticsPlugin) => [log, analytics],
    deps: [LogPlugin, AnalyticsPlugin]
  }
]

// Usage
constructor(@Inject(PLUGINS) private plugins: Plugin[]) {
  plugins.forEach(p => p.execute());
}
```

---

[← Back to Index](angular19-guide-index.md) | [Previous: Templates and Directives](angular19-part2-templates-directives.md) | [Next: State Management →](angular19-part4-state-management.md)
