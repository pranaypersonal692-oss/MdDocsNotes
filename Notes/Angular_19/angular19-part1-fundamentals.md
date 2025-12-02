# Angular 19 - Part 1: Fundamentals

[← Back to Index](angular19-guide-index.md) | [Next: Templates and Directives →](angular19-part2-templates-directives.md)

## Table of Contents
- [Introduction to Angular 19](#introduction-to-angular-19)
- [Components](#components)
- [Component Lifecycle](#component-lifecycle)
- [Modules vs Standalone Components](#modules-vs-standalone-components)
- [Coding Challenges](#coding-challenges)
- [Interview Questions](#interview-questions)

---

## Introduction to Angular 19

### What is Angular?

Angular is a **TypeScript-based**, open-source web application framework developed by Google. Angular 19 represents the latest evolution with revolutionary features like Signals and enhanced standalone components.

### Key Features of Angular 19

1. **Signals** - New reactivity system
2. **Standalone Components** - No NgModules required
3. **Improved Performance** - Better change detection
4. **Enhanced SSR** - Server-side rendering improvements
5. **Better Developer Experience** - Improved tooling

### Architecture Overview

```
┌─────────────────────────────────────────┐
│           Angular Application           │
├─────────────────────────────────────────┤
│  ┌───────────┐  ┌──────────┐           │
│  │Components │  │  Services│           │
│  └─────┬─────┘  └────┬─────┘           │
│        │             │                  │
│  ┌─────▼─────┐  ┌───▼──────┐           │
│  │ Templates │  │    DI    │           │
│  └───────────┘  └──────────┘           │
│                                         │
│  ┌───────────────────────────┐         │
│  │        Router             │         │
│  └───────────────────────────┘         │
└─────────────────────────────────────────┘
```

### Setting Up Angular 19

```bash
# Install Angular CLI
npm install -g @angular/cli

# Create new project
ng new my-angular19-app

# Run development server
ng serve
```

---

## Components

### What are Components?

Components are the **building blocks** of Angular applications. Each component consists of:
- **TypeScript Class** - Logic and data
- **HTML Template** - View
- **CSS Styles** - Styling
- **Component Metadata** - Configuration via decorator

### Basic Component Structure

```typescript
import { Component } from '@angular/core';

@Component({
  selector: 'app-hello-world',
  standalone: true,  // Angular 19: Standalone by default
  template: `
    <div class="container">
      <h1>{{ title }}</h1>
      <p>{{ message }}</p>
      <button (click)="updateMessage()">Click Me</button>
    </div>
  `,
  styles: [`
    .container {
      padding: 20px;
      background-color: #f0f0f0;
    }
    h1 { color: #333; }
  `]
})
export class HelloWorldComponent {
  title = 'Hello Angular 19!';
  message = 'Welcome to the new era of Angular';

  updateMessage() {
    this.message = 'Button clicked!';
  }
}
```

### Component with External Files

```typescript
// user-profile.component.ts
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './user-profile.component.html',
  styleUrls: ['./user-profile.component.css']
})
export class UserProfileComponent {
  user = {
    name: 'John Doe',
    email: 'john@example.com',
    age: 30,
    isActive: true
  };

  avatarUrl = 'https://via.placeholder.com/150';
}
```

```html
<!-- user-profile.component.html -->
<div class="profile-card">
  <img [src]="avatarUrl" [alt]="user.name">
  <h2>{{ user.name }}</h2>
  <p>{{ user.email }}</p>
  <p>Age: {{ user.age }}</p>
  <span class="status" [class.active]="user.isActive">
    {{ user.isActive ? 'Active' : 'Inactive' }}
  </span>
</div>
```

### Component Communication

#### Parent to Child (@Input)

```typescript
// child.component.ts
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-child',
  standalone: true,
  template: `
    <div class="child">
      <h3>{{ title }}</h3>
      <p>Count: {{ count }}</p>
    </div>
  `
})
export class ChildComponent {
  @Input() title: string = '';
  @Input() count: number = 0;
}

// parent.component.ts
import { Component } from '@angular/core';
import { ChildComponent } from './child.component';

@Component({
  selector: 'app-parent',
  standalone: true,
  imports: [ChildComponent],
  template: `
    <div class="parent">
      <h2>Parent Component</h2>
      <app-child [title]="childTitle" [count]="counter"></app-child>
    </div>
  `
})
export class ParentComponent {
  childTitle = 'Child Component Title';
  counter = 42;
}
```

#### Child to Parent (@Output)

```typescript
// child.component.ts
import { Component, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-child',
  standalone: true,
  template: `
    <button (click)="sendMessage()">Send to Parent</button>
  `
})
export class ChildComponent {
  @Output() messageEvent = new EventEmitter<string>();

  sendMessage() {
    this.messageEvent.emit('Hello from Child!');
  }
}

// parent.component.ts
import { Component } from '@angular/core';
import { ChildComponent } from './child.component';

@Component({
  selector: 'app-parent',
  standalone: true,
  imports: [ChildComponent],
  template: `
    <div>
      <p>Message from child: {{ receivedMessage }}</p>
      <app-child (messageEvent)="receiveMessage($event)"></app-child>
    </div>
  `
})
export class ParentComponent {
  receivedMessage = '';

  receiveMessage($event: string) {
    this.receivedMessage = $event;
  }
}
```

---

## Component Lifecycle

### Lifecycle Hooks Overview

Angular components go through a lifecycle managed by Angular. Here are the lifecycle hooks in order:

```
Constructor
    ↓
ngOnChanges (if @Input properties exist)
    ↓
ngOnInit
    ↓
ngDoCheck
    ↓
ngAfterContentInit
    ↓
ngAfterContentChecked
    ↓
ngAfterViewInit
    ↓
ngAfterViewChecked
    ↓
ngOnDestroy
```

### Lifecycle Hooks Explained

```typescript
import { 
  Component, OnInit, OnChanges, DoCheck, 
  AfterContentInit, AfterContentChecked,
  AfterViewInit, AfterViewChecked, OnDestroy,
  Input, SimpleChanges
} from '@angular/core';

@Component({
  selector: 'app-lifecycle-demo',
  standalone: true,
  template: `<p>{{ message }}</p>`
})
export class LifecycleDemoComponent implements
  OnInit, OnChanges, DoCheck, AfterContentInit,
  AfterContentChecked, AfterViewInit, AfterViewChecked, OnDestroy {

  @Input() data: string = '';
  message = 'Lifecycle Demo';

  constructor() {
    console.log('1. Constructor called');
  }

  ngOnChanges(changes: SimpleChanges) {
    console.log('2. ngOnChanges called', changes);
    // Called before ngOnInit and whenever @Input properties change
  }

  ngOnInit() {
    console.log('3. ngOnInit called');
    // Called once after the first ngOnChanges
    // Best place for initialization logic
  }

  ngDoCheck() {
    console.log('4. ngDoCheck called');
    // Called during every change detection run
    // Use sparingly - performance impact
  }

  ngAfterContentInit() {
    console.log('5. ngAfterContentInit called');
    // Called once after ng-content projection
  }

  ngAfterContentChecked() {
    console.log('6. ngAfterContentChecked called');
    // Called after every check of projected content
  }

  ngAfterViewInit() {
    console.log('7. ngAfterViewInit called');
    // Called once after component's view is initialized
    // Safe to access ViewChild queries here
  }

  ngAfterViewChecked() {
    console.log('8. ngAfterViewChecked called');
    // Called after every check of component's view
  }

  ngOnDestroy() {
    console.log('9. ngOnDestroy called');
    // Called just before component is destroyed
    // Cleanup: unsubscribe observables, detach event handlers
  }
}
```

### Practical Lifecycle Example

```typescript
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription, interval } from 'rxjs';

@Component({
  selector: 'app-timer',
  standalone: true,
  template: `
    <div>
      <h3>Timer: {{ seconds }}s</h3>
      <p>{{ status }}</p>
    </div>
  `
})
export class TimerComponent implements OnInit, OnDestroy {
  seconds = 0;
  status = 'Not started';
  private timerSubscription?: Subscription;

  ngOnInit() {
    // Initialize timer when component is ready
    this.status = 'Running';
    this.timerSubscription = interval(1000).subscribe(() => {
      this.seconds++;
    });
  }

  ngOnDestroy() {
    // Cleanup: prevent memory leaks
    this.status = 'Stopped';
    if (this.timerSubscription) {
      this.timerSubscription.unsubscribe();
    }
  }
}
```

---

## Modules vs Standalone Components

### Traditional NgModules Approach

```typescript
// app.module.ts (Old way)
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';

import { AppComponent } from './app.component';
import { UserComponent } from './user/user.component';
import { ProductComponent } from './product/product.component';

@NgModule({
  declarations: [
    AppComponent,
    UserComponent,
    ProductComponent
  ],
  imports: [
    BrowserModule,
    FormsModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
```

### Standalone Components (Angular 19 Recommended)

```typescript
// app.component.ts (New way)
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserComponent } from './user/user.component';
import { ProductComponent } from './product/product.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    UserComponent,
    ProductComponent
  ],
  template: `
    <h1>My App</h1>
    <app-user></app-user>
    <app-product></app-product>
  `
})
export class AppComponent { }

// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, {
  providers: [
    // App-wide providers here
  ]
});
```

### Benefits of Standalone Components

1. **Simpler Architecture** - No need for NgModules
2. **Better Tree-shaking** - Smaller bundle sizes
3. **Easier Testing** - Less boilerplate
4. **Clearer Dependencies** - Import what you need directly
5. **Lazy Loading** - Simplified lazy loading

### Comparison Example

#### Module-based Component
```typescript
// feature.module.ts
@NgModule({
  declarations: [FeatureComponent],
  imports: [CommonModule, FormsModule],
  exports: [FeatureComponent]
})
export class FeatureModule { }
```

#### Standalone Component (Recommended)
```typescript
// feature.component.ts
@Component({
  selector: 'app-feature',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `...`
})
export class FeatureComponent { }
```

---

## Coding Challenges

### Challenge 1: Create a Counter Component
**Difficulty: Easy**

Create a counter component with increment, decrement, and reset buttons.

**Requirements:**
- Display current count
- Increment button (+1)
- Decrement button (-1)
- Reset button (set to 0)
- Disable decrement when count is 0

<details>
<summary>Solution</summary>

```typescript
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-counter',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="counter">
      <h2>Count: {{ count }}</h2>
      <div class="buttons">
        <button (click)="decrement()" [disabled]="count === 0">
          -
        </button>
        <button (click)="reset()">Reset</button>
        <button (click)="increment()">+</button>
      </div>
    </div>
  `,
  styles: [`
    .counter {
      padding: 20px;
      text-align: center;
    }
    .buttons {
      display: flex;
      gap: 10px;
      justify-content: center;
    }
    button {
      padding: 10px 20px;
      font-size: 16px;
    }
    button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `]
})
export class CounterComponent {
  count = 0;

  increment() {
    this.count++;
  }

  decrement() {
    if (this.count > 0) {
      this.count--;
    }
  }

  reset() {
    this.count = 0;
  }
}
```
</details>

### Challenge 2: Parent-Child Data Flow
**Difficulty: Medium**

Create a parent component that manages a list of todos and a child component that displays each todo with a delete button.

**Requirements:**
- Parent holds todo list
- Child receives todo via @Input
- Child emits delete event via @Output
- Parent handles deletion

<details>
<summary>Solution</summary>

```typescript
// todo-item.component.ts
import { Component, Input, Output, EventEmitter } from '@angular/core';

interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

@Component({
  selector: 'app-todo-item',
  standalone: true,
  template: `
    <div class="todo-item">
      <span [class.completed]="todo.completed">
        {{ todo.title }}
      </span>
      <button (click)="onDelete()">Delete</button>
    </div>
  `,
  styles: [`
    .todo-item {
      display: flex;
      justify-content: space-between;
      padding: 10px;
      border: 1px solid #ddd;
      margin-bottom: 5px;
    }
    .completed {
      text-decoration: line-through;
      color: #999;
    }
  `]
})
export class TodoItemComponent {
  @Input() todo!: Todo;
  @Output() delete = new EventEmitter<number>();

  onDelete() {
    this.delete.emit(this.todo.id);
  }
}

// todo-list.component.ts
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TodoItemComponent } from './todo-item.component';

@Component({
  selector: 'app-todo-list',
  standalone: true,
  imports: [CommonModule, TodoItemComponent],
  template: `
    <div class="todo-list">
      <h2>Todo List</h2>
      <app-todo-item
        *ngFor="let todo of todos"
        [todo]="todo"
        (delete)="deleteTodo($event)"
      ></app-todo-item>
    </div>
  `
})
export class TodoListComponent {
  todos: Todo[] = [
    { id: 1, title: 'Learn Angular', completed: false },
    { id: 2, title: 'Build Project', completed: false },
    { id: 3, title: 'Deploy App', completed: false }
  ];

  deleteTodo(id: number) {
    this.todos = this.todos.filter(todo => todo.id !== id);
  }
}
```
</details>

### Challenge 3: Lifecycle Hook Practice
**Difficulty: Medium**

Create a component that fetches user data on initialization and cleans up on destruction.

**Requirements:**
- Simulate API call in ngOnInit
- Show loading state
- Display data when loaded
- Cleanup subscription in ngOnDestroy

<details>
<summary>Solution</summary>

```typescript
import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, delay, of, takeUntil } from 'rxjs';

interface User {
  id: number;
  name: string;
  email: string;
}

@Component({
  selector: 'app-user-data',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="user-data">
      <h2>User Information</h2>
      
      <div *ngIf="loading" class="loading">Loading...</div>
      
      <div *ngIf="!loading && user" class="user-card">
        <h3>{{ user.name }}</h3>
        <p>Email: {{ user.email }}</p>
        <p>ID: {{ user.id }}</p>
      </div>
      
      <div *ngIf="error" class="error">{{ error }}</div>
    </div>
  `,
  styles: [`
    .user-data { padding: 20px; }
    .loading { color: blue; }
    .error { color: red; }
    .user-card {
      border: 1px solid #ccc;
      padding: 15px;
      border-radius: 8px;
    }
  `]
})
export class UserDataComponent implements OnInit, OnDestroy {
  user: User | null = null;
  loading = false;
  error = '';
  private destroy$ = new Subject<void>();

  ngOnInit() {
    this.fetchUserData();
  }

  fetchUserData() {
    this.loading = true;
    
    // Simulate API call
    of({
      id: 1,
      name: 'John Doe',
      email: 'john@example.com'
    })
      .pipe(
        delay(2000), // Simulate network delay
        takeUntil(this.destroy$) // Auto-unsubscribe on destroy
      )
      .subscribe({
        next: (data) => {
          this.user = data;
          this.loading = false;
        },
        error: (err) => {
          this.error = 'Failed to load user data';
          this.loading = false;
        }
      });
  }

  ngOnDestroy() {
    // Cleanup: complete the subject to unsubscribe all observables
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```
</details>

---

## Interview Questions

### Basic Questions

**Q1: What is a component in Angular?**

**Answer:** A component is a building block of an Angular application that controls a portion of the screen (view). It consists of:
- A TypeScript class with `@Component` decorator
- An HTML template
- CSS styles
- Component metadata (selector, template, styles, etc.)

Components encapsulate data, logic, and view into reusable units.

---

**Q2: Explain the component lifecycle and its hooks.**

**Answer:** Angular components have a lifecycle managed by Angular from creation to destruction:

1. **Constructor** - Class instantiation
2. **ngOnChanges** - When @Input properties change
3. **ngOnInit** - After first ngOnChanges, initialization
4. **ngDoCheck** - Custom change detection
5. **ngAfterContentInit** - After content projection
6. **ngAfterContentChecked** - After content checked
7. **ngAfterViewInit** - After view initialized
8. **ngAfterViewChecked** - After view checked
9. **ngOnDestroy** - Cleanup before destruction

Most commonly used: ngOnInit (initialization) and ngOnDestroy (cleanup).

---

**Q3: What's the difference between constructor and ngOnInit?**

**Answer:**

| Constructor | ngOnInit |
|-------------|----------|
| TypeScript class feature | Angular lifecycle hook |
| Called when class is instantiated | Called after first change detection |
| Limited access to component | Full access to @Input, dependencies |
| For dependency injection | For initialization logic |
| Don't access @Input here | Safe to access @Input here |

**Best Practice:** Use constructor only for DI, use ngOnInit for initialization.

---

**Q4: How do you pass data from parent to child component?**

**Answer:** Use `@Input()` decorator in the child component:

```typescript
// Child
export class ChildComponent {
  @Input() data: string = '';
}

// Parent template
<app-child [data]="parentData"></app-child>
```

---

**Q5: How do you emit events from child to parent?**

**Answer:** Use `@Output()` decorator with `EventEmitter`:

```typescript
// Child
export class ChildComponent {
  @Output() notify = new EventEmitter<string>();
  
  sendData() {
    this.notify.emit('data');
  }
}

// Parent template
<app-child (notify)="handleEvent($event)"></app-child>
```

---

### Intermediate Questions

**Q6: What are standalone components and why use them?**

**Answer:** Standalone components (introduced in Angular 14, refined in 19) don't require NgModules:

```typescript
@Component({
  selector: 'app-example',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `...`
})
```

**Benefits:**
- Simpler architecture
- Better tree-shaking
- Easier lazy loading
- Less boilerplate
- Clearer dependencies

---

**Q7: Explain the difference between ngOnChanges and ngDoCheck.**

**Answer:**

**ngOnChanges:**
- Called when @Input properties change
- Receives SimpleChanges object
- Only for primitive/reference changes
- More efficient

**ngDoCheck:**
- Called on every change detection
- No parameters
- For custom change detection
- Can detect object mutations
- Performance-intensive, use carefully

---

**Q8: What is the purpose of ngOnDestroy?**

**Answer:** ngOnDestroy is for cleanup before component destruction:

```typescript
ngOnDestroy() {
  // Unsubscribe from observables
  this.subscription.unsubscribe();
  
  // Clear timers
  clearInterval(this.timer);
  
  // Remove event listeners
  document.removeEventListener('click', this.handler);
  
  // Release resources
  this.connection.close();
}
```

Prevents memory leaks and unexpected behavior.

---

### Advanced Questions

**Q9: How would you prevent memory leaks in Angular components?**

**Answer:** Multiple approaches:

```typescript
// 1. Manual unsubscribe
export class Component implements OnDestroy {
  private subscription = new Subscription();
  
  ngOnInit() {
    this.subscription.add(
      this.service.getData().subscribe()
    );
  }
  
  ngOnDestroy() {
    this.subscription.unsubscribe();
  }
}

// 2. takeUntil pattern (recommended)
export class Component implements OnDestroy {
  private destroy$ = new Subject<void>();
  
  ngOnInit() {
    this.service.getData()
      .pipe(takeUntil(this.destroy$))
      .subscribe();
  }
  
  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}

// 3. Async pipe (best)
// Template: {{ data$ | async }}
// Automatically unsubscribes
```

---

**Q10: What's the difference between template and templateUrl?**

**Answer:**

**template (inline):**
```typescript
@Component({
  template: `<h1>Inline HTML</h1>`
})
```
- Good for small templates
- Easier for simple components
- All in one file

**templateUrl (external):**
```typescript
@Component({
  templateUrl: './component.html'
})
```
- Better for large templates
- Separation of concerns
- Syntax highlighting in HTML files
- Easier to maintain

---

**Q11: Explain change detection in Angular components.**

**Answer:** Change detection is how Angular keeps the view in sync with component data:

**Default Strategy:**
- Checks entire component tree
- Triggered by events, HTTP, timers
- Top-down check

**OnPush Strategy:**
```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush
})
```
- Only checks when: @Input changes, events in component, async pipe updates, or manual trigger
- Better performance
- Use with immutable data

---

**Q12: How do standalone components affect lazy loading?**

**Answer:** Standalone components simplify lazy loading:

**Old way (NgModule):**
```typescript
{
  path: 'feature',
  loadChildren: () => import('./feature/feature.module')
    .then(m => m.FeatureModule)
}
```

**New way (Standalone):**
```typescript
{
  path: 'feature',
  loadComponent: () => import('./feature/feature.component')
    .then(m => m.FeatureComponent)
}
```

Benefits: Less boilerplate, clearer intent, smaller bundles.

---

[← Back to Index](angular19-guide-index.md) | [Next: Templates and Directives →](angular19-part2-templates-directives.md)
