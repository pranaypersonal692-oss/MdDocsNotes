# Angular 19 - Part 7: Advanced Topics

[← Back to Index](angular19-guide-index.md) | [Previous: HTTP and RxJS](angular19-part6-http-rxjs.md)

## Table of Contents
- [Angular Signals](#angular-signals)
- [Change Detection](#change-detection)
- [Performance Optimization](#performance-optimization)
- [Testing](#testing)
- [Best Practices](#best-practices)
- [Security](#security)
- [Coding Challenges](#coding-challenges)
- [Interview Questions](#interview-questions)

---

## Angular Signals

### What are Signals?

Signals are Angular 19's new reactivity system - a simpler alternative to RxJS for managing state.

### Basic Signal Usage

```typescript
import { Component, signal, computed, effect } from '@angular/core';

@Component({
  selector: 'app-counter',
  standalone: true,
  template: `
    <div>
      <p>Count: {{ count() }}</p>
      <p>Double: {{ double() }}</p>
      <button (click)="increment()">+</button>
      <button (click)="decrement()">-</button>
      <button (click)="reset()">Reset</button>
    </div>
  `
})
export class CounterComponent {
  // Writable signal
  count = signal(0);
  
  // Computed signal (derived state)
  double = computed(() => this.count() * 2);
  
  constructor() {
    // Effect runs when dependencies change
    effect(() => {
      console.log('Count changed to:', this.count());
    });
  }
  
  increment() {
    this.count.update(value => value + 1);
  }
  
  decrement() {
    this.count.update(value => value - 1);
  }
  
  reset() {
    this.count.set(0);
  }
}
```

### Signals vs BehaviorSubject

```typescript
// Signals (Angular 19+)
count = signal(0);
double = computed(() => this.count() * 2);
// Template: {{ count() }}

// BehaviorSubject (Traditional)
private countSubject = new BehaviorSubject(0);
count$ = this.countSubject.asObservable();
double$ = this.count$.pipe(map(c => c * 2));
// Template: {{ count$ | async }} 
```

**When to use:**
- **Signals**: Simple state, synchronous, better performance  
- **BehaviorSubject**: Async operations, complex streams, HTTP

---

## Change Detection

### Change Detection Strategies

```typescript
import { ChangeDetectionStrategy } from '@angular/core';

// Default strategy
@Component({
  changeDetection: ChangeDetectionStrategy.Default
  // Checks entire component tree on every event
})

// OnPush strategy
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush
  // Only checks when:
  // 1. @Input reference changes
  // 2. Event in component
  // 3. Async pipe updates
  // 4. Manual trigger
})
export class OptimizedComponent {
  @Input() data: any;  // Must pass new reference to trigger
}
```

### Manual Change Detection

```typescript
import { ChangeDetectorRef } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ManualComponent {
  constructor(private cdr: ChangeDetectorRef) { }
  
  updateData() {
    this.data = newData;
    this.cdr.markForCheck();  // Mark for check
    // or
    this.cdr.detectChanges();  // Run immediately
  }
}
```

---

## Performance Optimization

### 1. trackBy in *ngFor

```typescript
@Component({
  template: `
    <div *ngFor="let item of items; trackBy: trackByFn">
      {{ item.name }}
    </div>
  `
})
export class ListComponent {
  items = [/* large array */];
  
  trackByFn(index: number, item: any) {
    return item.id;  // Track by unique ID
  }
}
```

### 2. Lazy Loading

```typescript
// Route-level lazy loading
{
  path: 'admin',
  loadComponent: () => import('./admin/admin.component')
    .then(m => m.AdminComponent)
}
```

### 3. Pure Pipes

```typescript
@Pipe({ name: 'expensive', pure: true })  // Cached
export class ExpensivePipe implements PipeTransform {
  transform(value: any): any {
    // Expensive calculation
    return result;
  }
}
```

### 4. Async Pipe

```typescript
// ✅ Good - Auto unsubscribe
<div *ngIf="data$ | async as data">{{ data }}</div>

// ❌ Bad - Manual subscription
data: any;
ngOnInit() {
  this.service.getData().subscribe(d => this.data = d);
}
```

### 5. Virtual Scrolling

```typescript
import { ScrollingModule } from '@angular/cdk/scrolling';

@Component({
  imports: [ScrollingModule],
  template: `
    <cdk-virtual-scroll-viewport [itemSize]="50" style="height: 400px">
      <div *cdkVirtualFor="let item of items">{{ item }}</div>
    </cdk-virtual-scroll-viewport>
  `
})
```

---

## Testing

### Unit Testing Component

```typescript
import { TestBed } from '@angular/core/testing';
import { CounterComponent } from './counter.component';

describe('CounterComponent', () => {
  let component: CounterComponent;
  let fixture: ComponentFixture<CounterComponent>;
  
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CounterComponent]
    }).compileComponents();
    
    fixture = TestBed.createComponent(CounterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });
  
  it('should create', () => {
    expect(component).toBeTruthy();
  });
  
  it('should increment count', () => {
    component.increment();
    expect(component.count()).toBe(1);
  });
  
  it('should display count', () => {
    const compiled = fixture.nativeElement;
    expect(compiled.querySelector('p').textContent).toContain('Count: 0');
  });
});
```

### Testing Services

```typescript
import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';

describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;
  
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UserService]
    });
    
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });
  
  it('should fetch users', () => {
    const mockUsers = [{ id: 1, name: 'John' }];
    
    service.getUsers().subscribe(users => {
      expect(users).toEqual(mockUsers);
    });
    
    const req = httpMock.expectOne('/api/users');
    expect(req.request.method).toBe('GET');
    req.flush(mockUsers);
  });
  
  afterEach(() => {
    httpMock.verify();
  });
});
```

---

## Best Practices

### 1. Component Structure

```typescript
@Component({
  selector: 'app-best-practice',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './best-practice.component.html',
  styleUrls: ['./best-practice.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BestPracticeComponent implements OnInit, OnDestroy {
  // Public properties
  @Input() data: any;
  @Output() action = new EventEmitter();
  
  // Public observables
  users$ = this.userService.users$;
  
  // Private properties
  private destroy$ = new Subject<void>();
  
  constructor(private userService: UserService) { }
  
  ngOnInit() {
    // Initialization
  }
  
  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
  
  // Public methods
  handleClick() { }
  
  // Private methods
  private helper() { }
}
```

### 2. Naming Conventions

```typescript
// Components: PascalCase + Component suffix
UserListComponent

// Services: PascalCase + Service suffix
AuthService

// Interfaces: PascalCase
export interface User { }

// Observables: $ suffix
user$: Observable<User>

// BehaviorSubjects: Subject suffix, private
private userSubject = new BehaviorSubject<User | null>(null);
user$ = this.userSubject.asObservable();

// Methods: camelCase, descriptive
getUserById(id: number) { }

// Constants: UPPER_SNAKE_CASE
const API_URL = 'https://api.example.com';
```

### 3. Folder Structure

```
src/app/
├── core/
│   ├── services/
│   ├── guards/
│   ├── interceptors/
│   └── models/
├── shared/
│   ├── components/
│   ├── directives/
│   └── pipes/
├── features/
│   ├── user/
│   │   ├── components/
│   │   ├── services/
│   │   └── user.routes.ts
│   └── admin/
└── app.component.ts
```

---

## Security

### 1. XSS Prevention

```typescript
// ✅ Angular sanitizes by default
<div>{{ userInput }}</div>

// ⚠️ Bypass (only if you trust the content)
import { DomSanitizer } from '@angular/platform-browser';

constructor(private sanitizer: DomSanitizer) { }

getTrustedHtml() {
  return this.sanitizer.bypassSecurityTrustHtml(this.htmlContent);
}
```

### 2. CSRF Protection

```typescript
// Angular HttpClient includes CSRF protection by default
// Reads XSRF-TOKEN cookie and sets X-XSRF-TOKEN header
```

### 3. Authentication

```typescript
// Store JWT securely
localStorage.setItem('token', token);  // Vulnerable to XSS

// Better: Use HttpOnly cookies (set by server)
// JavaScript cannot access HttpOnly cookies
```

---

## Coding Challenges

### Challenge: Performance-Optimized List
**Difficulty: Hard**

Create a list component with 10,000 items that performs well.

<details>
<summary>Solution</summary>

```typescript
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ScrollingModule } from '@angular/cdk/scrolling';
import { ChangeDetectionStrategy } from '@angular/core';

interface Item {
  id: number;
  name: string;
  value: number;
}

@Component({
  selector: 'app-optimized-list',
  standalone: true,
  imports: [CommonModule, ScrollingModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="container">
      <input 
        #searchInput
        (input)="search(searchInput.value)"
        placeholder="Search..."
      >
      
      <cdk-virtual-scroll-viewport 
        [itemSize]="50" 
        class="viewport"
      >
        <div 
          *cdkVirtualFor="let item of filteredItems; trackBy: trackById"
          class="item"
        >
          <span>{{ item.id }}</span>
          <span>{{ item.name }}</span>
          <span>{{ item.value }}</span>
        </div>
      </cdk-virtual-scroll-viewport>
    </div>
  `,
  styles: [`
    .viewport {
      height: 500px;
      border: 1px solid #ccc;
    }
    .item {
      height: 50px;
      display: flex;
      justify-content: space-between;
      padding: 10px;
      border-bottom: 1px solid #eee;
    }
  `]
})
export class OptimizedListComponent {
  items: Item[] = [];
  filteredItems: Item[] = [];
  
  constructor() {
    // Generate 10,000 items
    this.items = Array.from({ length: 10000 }, (_, i) => ({
      id: i + 1,
      name: `Item ${i + 1}`,
      value: Math.random() * 1000
    }));
    this.filteredItems = this.items;
  }
  
  search(query: string) {
    const lower = query.toLowerCase();
    this.filteredItems = this.items.filter(item =>
      item.name.toLowerCase().includes(lower)
    );
  }
  
  trackById(index: number, item: Item) {
    return item.id;
  }
}
```
</details>

---

## Interview Questions

**Q1: What are Signals and how do they differ from Observables?**

**Answer:**

| Signals | Observables |
|---------|-------------|
| Synchronous | Async & Sync |
| Always has value | May not emit |
| Simpler API | More powerful |
| Better performance | More flexible |
| Built-in | Requires RxJS |

**Use Signals for:** Simple state, UI updates  
**Use Observables for:** HTTP, events, complex streams

---

**Q2: Explain OnPush change detection strategy.**

**Answer:** OnPush only checks component when:
1. @Input reference changes (not mutation)
2. Event triggered in component
3. Async pipe emits
4. Manual `markForCheck()`

**Benefits:** Better performance, fewer checks

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush
})
```

---

**Q3: What are the main performance optimization techniques in Angular?**

**Answer:**
1. **OnPush change detection**
2. **trackBy in *ngFor**
3. **Lazy loading routes**
4. **Pure pipes**
5. **Virtual scrolling**
6. **Async pipe** (auto-unsubscribe)
7. **PreloadAllModules**
8. **AOT compilation**

---

**Q4: How do you prevent memory leaks in Angular?**

**Answer:**

```typescript
// 1. takeUntil pattern
private destroy$ = new Subject<void>();

ngOnInit() {
  this.obs$.pipe(takeUntil(this.destroy$)).subscribe();
}

ngOnDestroy() {
  this.destroy$.next();
  this.destroy$.complete();
}

// 2. Async pipe (automatic)
template: `{{ data$ | async }}`

// 3. Manual unsubscribe
subscription = this.obs$.subscribe();
ngOnDestroy() {
  this.subscription.unsubscribe();
}
```

---

**Q5: What security measures does Angular provide?**

**Answer:**

1. **XSS Protection**: Auto-sanitizes untrusted values
2. **CSRF Protection**: XSRF tokens in HTTP
3. **Content Security Policy**: Prevents inline scripts
4. **Trusted Types**: DOM sinks validation
5. **DomSanitizer**: Manual sanitization when needed

**Best Practices:**
- Never use `bypassSecurityTrust` unless necessary
- Validate user input
- Use HttpOnly cookies for tokens
- Enable CSP headers

---

## Summary

Congratulations! You've completed the comprehensive Angular 19 guide covering:

✅ Components and Lifecycle  
✅ Templates, Directives, and Pipes  
✅ Services and Dependency Injection  
✅ **State Management with BehaviorSubject**  
✅ Routing and Forms  
✅ HTTP and RxJS  
✅ Signals, Performance, Testing, and Best Practices

### Next Steps

1. Build real projects
2. Contribute to open source
3. Explore Angular Material
4. Learn NgRx (for large apps)
5. Practice coding challenges

---

[← Back to Index](angular19-guide-index.md) | [Previous: HTTP and RxJS](angular19-part6-http-rxjs.md)
