# Angular 19 - Part 2: Templates and Directives

[← Back to Index](angular19-guide-index.md) | [Previous: Fundamentals](angular19-part1-fundamentals.md) | [Next: Services and DI →](angular19-part3-services-di.md)

## Table of Contents
- [Template Syntax](#template-syntax)
- [Data Binding](#data-binding)
- [Built-in Directives](#built-in-directives)
- [Custom Directives](#custom-directives)
- [Pipes](#pipes)
- [Coding Challenges](#coding-challenges)
- [Interview Questions](#interview-questions)

---

## Template Syntax

### Interpolation

```typescript
@Component({
  template: `
    <h1>{{ title }}</h1>
    <p>{{ 2 + 2 }}</p>
    <p>{{ getMessage() }}</p>
    <p>{{ user.name.toUpperCase() }}</p>
  `
})
export class ExampleComponent {
  title = 'Angular 19';
  user = { name: 'John' };
  
  getMessage() {
    return 'Hello World';
  }
}
```

### Template Expressions

```html
<!-- Allowed -->
{{ value + 1 }}
{{ method() }}
{{ condition ? 'yes' : 'no' }}
{{ array[0] }}
{{ object.property }}

<!-- NOT Allowed -->
{{ value = 10 }}  <!-- assignments -->
{{ new Object() }} <!-- new keyword -->
{{ value++ }}      <!-- increment/decrement -->
```

### Template Statements

```html
<button (click)="save()">Save</button>
<button (click)="count = count + 1">Increment</button>
<button (click)="handleClick($event)">Click</button>
```

---

## Data Binding

### One-Way Binding (Component to View)

#### Property Binding
```typescript
@Component({
  template: `
    <img [src]="imageUrl" [alt]="imageAlt">
    <button [disabled]="isDisabled">Click</button>
    <div [class.active]="isActive">Active State</div>
    <div [style.color]="textColor">Colored Text</div>
  `
})
export class PropertyBindingComponent {
  imageUrl = 'https://example.com/image.jpg';
  imageAlt = 'Example image';
  isDisabled = false;
  isActive = true;
  textColor = 'blue';
}
```

#### Attribute Binding
```typescript
@Component({
  template: `
    <button [attr.aria-label]="buttonLabel">Action</button>
    <td [attr.colspan]="columnSpan">Cell</td>
  `
})
export class AttributeBindingComponent {
  buttonLabel = 'Click to perform action';
  columnSpan = 2;
}
```

#### Class Binding
```typescript
@Component({
  template: `
    <!-- Single class -->
    <div [class.active]="isActive">Toggle Active</div>
    
    <!-- Multiple classes -->
    <div [class]="classExpression">Dynamic Classes</div>
    
    <!-- Class object -->
    <div [ngClass]="classObject">Multiple Classes</div>
  `,
  styles: [`
    .active { color: green; }
    .highlight { background-color: yellow; }
    .bold { font-weight: bold; }
  `]
})
export class ClassBindingComponent {
  isActive = true;
  classExpression = 'active highlight';
  classObject = {
    active: true,
    highlight: false,
    bold: true
  };
}
```

#### Style Binding
```typescript
@Component({
  template: `
    <!-- Single style -->
    <div [style.color]="textColor">Colored</div>
    <div [style.font-size.px]="fontSize">Sized</div>
    
    <!-- Multiple styles -->
    <div [style]="styleExpression">Styled</div>
    
    <!-- Style object -->
    <div [ngStyle]="styleObject">Multiple Styles</div>
  `
})
export class StyleBindingComponent {
  textColor = 'red';
  fontSize = 16;
  styleExpression = 'color: blue; font-size: 20px';
  styleObject = {
    color: 'green',
    'font-size': '18px',
    'font-weight': 'bold'
  };
}
```

### One-Way Binding (View to Component)

#### Event Binding
```typescript
@Component({
  template: `
    <button (click)="onClick()">Click Me</button>
    <input (input)="onInput($event)" (blur)="onBlur()">
    <form (submit)="onSubmit($event)">
      <button type="submit">Submit</button>
    </form>
    
    <!-- Custom events -->
    <app-child (customEvent)="onCustomEvent($event)"></app-child>
  `
})
export class EventBindingComponent {
  onClick() {
    console.log('Button clicked');
  }
  
  onInput(event: Event) {
    const value = (event.target as HTMLInputElement).value;
    console.log('Input value:', value);
  }
  
  onBlur() {
    console.log('Input lost focus');
  }
  
  onSubmit(event: Event) {
    event.preventDefault();
    console.log('Form submitted');
  }
  
  onCustomEvent(data: any) {
    console.log('Custom event received:', data);
  }
}
```

### Two-Way Binding

```typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-two-way-binding',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div>
      <h3>Two-Way Binding</h3>
      
      <!-- Using [(ngModel)] -->
      <input [(ngModel)]="name" placeholder="Enter name">
      <p>Hello, {{ name }}!</p>
      
      <!-- Manual two-way binding -->
      <input 
        [value]="email"
        (input)="email = $any($event.target).value"
        placeholder="Enter email"
      >
      <p>Email: {{ email }}</p>
      
      <!-- Custom two-way binding -->
      <app-custom-input [(value)]="customValue"></app-custom-input>
      <p>Custom: {{ customValue }}</p>
    </div>
  `
})
export class TwoWayBindingComponent {
  name = '';
  email = '';
  customValue = '';
}

// Custom two-way binding component
import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-custom-input',
  standalone: true,
  template: `
    <input 
      [value]="value"
      (input)="onInput($event)"
      placeholder="Custom input"
    >
  `
})
export class CustomInputComponent {
  @Input() value = '';
  @Output() valueChange = new EventEmitter<string>();
  
  onInput(event: Event) {
    const newValue = (event.target as HTMLInputElement).value;
    this.valueChange.emit(newValue);
  }
}
```

---

## Built-in Directives

### Structural Directives

#### *ngIf
```typescript
@Component({
  template: `
    <!-- Basic ngIf -->
    <div *ngIf="isVisible">Content is visible</div>
    
    <!-- ngIf with else -->
    <div *ngIf="isLoggedIn; else loggedOut">
      Welcome back!
    </div>
    <ng-template #loggedOut>
      Please log in.
    </ng-template>
    
    <!-- ngIf with then/else -->
    <div *ngIf="status === 'success'; then success else failure"></div>
    <ng-template #success>✓ Success!</ng-template>
    <ng-template #failure>✗ Failed!</ng-template>
    
    <!-- ngIf with as (storing result) -->
    <div *ngIf="user$ | async as user">
      Hello, {{ user.name }}
    </div>
  `
})
export class NgIfExampleComponent {
  isVisible = true;
  isLoggedIn = false;
  status = 'success';
  user$ = of({ name: 'John' });
}
```

#### *ngFor
```typescript
@Component({
  template: `
    <!-- Basic ngFor -->
    <ul>
      <li *ngFor="let item of items">{{ item }}</li>
    </ul>
    
    <!-- ngFor with index -->
    <ul>
      <li *ngFor="let item of items; let i = index">
        {{ i + 1 }}. {{ item }}
      </li>
    </ul>
    
    <!-- ngFor with tracking -->
    <div *ngFor="let user of users; trackBy: trackByUserId">
      {{ user.name }}
    </div>
    
    <!-- ngFor with multiple variables -->
    <div *ngFor="let item of items; 
                 let i = index;
                 let first = first;
                 let last = last;
                 let even = even;
                 let odd = odd">
      <span [class.first]="first" [class.last]="last">
        {{ i }}. {{ item }} ({{ even ? 'even' : 'odd' }})
      </span>
    </div>
  `
})
export class NgForExampleComponent {
  items = ['Apple', 'Banana', 'Cherry'];
  users = [
    { id: 1, name: 'John' },
    { id: 2, name: 'Jane' },
    { id: 3, name: 'Bob' }
  ];
  
  trackByUserId(index: number, user: any) {
    return user.id;  // Use unique identifier for better performance
  }
}
```

#### *ngSwitch
```typescript
@Component({
  template: `
    <div [ngSwitch]="status">
      <p *ngSwitchCase="'loading'">Loading...</p>
      <p *ngSwitchCase="'success'">Data loaded successfully!</p>
      <p *ngSwitchCase="'error'">Error loading data</p>
      <p *ngSwitchDefault>Unknown status</p>
    </div>
    
    <!-- Real-world example -->
    <div [ngSwitch]="userRole">
      <app-admin-view *ngSwitchCase="'admin'"></app-admin-view>
      <app-user-view *ngSwitchCase="'user'"></app-user-view>
      <app-guest-view *ngSwitchCase="'guest'"></app-guest-view>
      <app-default-view *ngSwitchDefault></app-default-view>
    </div>
  `
})
export class NgSwitchExampleComponent {
  status: 'loading' | 'success' | 'error' = 'loading';
  userRole: 'admin' | 'user' | 'guest' = 'user';
}
```

### Attribute Directives

#### ngClass
```typescript
@Component({
  template: `
    <!-- Object syntax -->
    <div [ngClass]="{
      'active': isActive,
      'disabled': isDisabled,
      'highlight': isHighlighted
    }">Dynamic Classes</div>
    
    <!-- Array syntax -->
    <div [ngClass]="['class1', 'class2', conditionalClass]">
      Array Classes
    </div>
    
    <!-- String syntax -->
    <div [ngClass]="classString">String Classes</div>
    
    <!-- Method syntax -->
    <div [ngClass]="getClasses()">Method Classes</div>
  `
})
export class NgClassExampleComponent {
  isActive = true;
  isDisabled = false;
  isHighlighted = true;
  conditionalClass = 'special';
  classString = 'class1 class2 class3';
  
  getClasses() {
    return {
      active: this.isActive,
      disabled: this.isDisabled
    };
  }
}
```

#### ngStyle
```typescript
@Component({
  template: `
    <!-- Object syntax -->
    <div [ngStyle]="{
      'color': textColor,
      'font-size': fontSize + 'px',
      'background-color': bgColor
    }">Styled Text</div>
    
    <!-- Method syntax -->
    <div [ngStyle]="getStyles()">Dynamic Styles</div>
  `
})
export class NgStyleExampleComponent {
  textColor = 'blue';
  fontSize = 16;
  bgColor = '#f0f0f0';
  
  getStyles() {
    return {
      'color': this.textColor,
      'font-size': this.fontSize + 'px',
      'padding': '20px'
    };
  }
}
```

---

## Custom Directives

### Attribute Directive

```typescript
import { Directive, ElementRef, HostListener, Input } from '@angular/core';

@Directive({
  selector: '[appHighlight]',
  standalone: true
})
export class HighlightDirective {
  @Input() appHighlight = 'yellow';
  @Input() defaultColor = 'transparent';
  
  constructor(private el: ElementRef) {
    this.el.nativeElement.style.backgroundColor = this.defaultColor;
  }
  
  @HostListener('mouseenter') onMouseEnter() {
    this.highlight(this.appHighlight);
  }
  
  @HostListener('mouseleave') onMouseLeave() {
    this.highlight(this.defaultColor);
  }
  
  private highlight(color: string) {
    this.el.nativeElement.style.backgroundColor = color;
  }
}

// Usage
@Component({
  template: `
    <p appHighlight>Hover over me (default yellow)</p>
    <p [appHighlight]="'lightblue'">Hover over me (light blue)</p>
    <p appHighlight="pink" defaultColor="#f0f0f0">Custom colors</p>
  `,
  imports: [HighlightDirective]
})
export class AppComponent { }
```

### Structural Directive

```typescript
import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';

@Directive({
  selector: '[appUnless]',
  standalone: true
})
export class UnlessDirective {
  private hasView = false;
  
  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef
  ) { }
  
  @Input() set appUnless(condition: boolean) {
    if (!condition && !this.hasView) {
      this.viewContainer.createEmbeddedView(this.templateRef);
      this.hasView = true;
    } else if (condition && this.hasView) {
      this.viewContainer.clear();
      this.hasView = false;
    }
  }
}

// Usage
@Component({
  template: `
    <p *appUnless="isHidden">This shows when isHidden is false</p>
  `,
  imports: [UnlessDirective]
})
export class AppComponent {
  isHidden = false;
}
```

### Advanced Custom Directive

```typescript
import { Directive, ElementRef, HostBinding, HostListener, Input, Renderer2 } from '@angular/core';

@Directive({
  selector: '[appButton]',
  standalone: true
})
export class ButtonDirective {
  @Input() variant: 'primary' | 'secondary' | 'danger' = 'primary';
  @HostBinding('class') get classes() {
    return `btn btn-${this.variant}`;
  }
  
  @HostBinding('attr.role') role = 'button';
  @HostBinding('style.cursor') cursor = 'pointer';
  
  private isPressed = false;
  
  constructor(
    private el: ElementRef,
    private renderer: Renderer2
  ) { }
  
  @HostListener('click', ['$event'])
  onClick(event: Event) {
    console.log('Button clicked');
  }
  
  @HostListener('mousedown')
  onMouseDown() {
    this.isPressed = true;
    this.renderer.addClass(this.el.nativeElement, 'pressed');
  }
  
  @HostListener('mouseup')
  onMouseUp() {
    this.isPressed = false;
    this.renderer.removeClass(this.el.nativeElement, 'pressed');
  }
}
```

---

## Pipes

### Built-in Pipes

```typescript
@Component({
  template: `
    <!-- String Pipes -->
    <p>{{ 'hello' | uppercase }}</p>  <!-- HELLO -->
    <p>{{ 'WORLD' | lowercase }}</p>  <!-- world -->
    <p>{{ 'hello world' | titlecase }}</p>  <!-- Hello World -->
    
    <!-- Number Pipes -->
    <p>{{ 1234.567 | number }}</p>  <!-- 1,234.567 -->
    <p>{{ 1234.567 | number:'3.1-2' }}</p>  <!-- 1,234.57 -->
    <p>{{ 0.25 | percent }}</p>  <!-- 25% -->
    <p>{{ 123.45 | currency }}</p>  <!-- $123.45 -->
    <p>{{ 123.45 | currency:'EUR':'symbol':'1.2-2' }}</p>  <!-- €123.45 -->
    
    <!-- Date Pipe -->
    <p>{{ today | date }}</p>  <!-- Jan 1, 2024 -->
    <p>{{ today | date:'short' }}</p>  <!-- 1/1/24, 12:00 PM -->
    <p>{{ today | date:'fullDate' }}</p>  <!-- Monday, January 1, 2024 -->
    <p>{{ today | date:'yyyy-MM-dd' }}</p>  <!-- 2024-01-01 -->
    
    <!-- JSON Pipe -->
    <pre>{{ user | json }}</pre>
    
    <!-- Slice Pipe -->
    <p>{{ 'Hello World' | slice:0:5 }}</p>  <!-- Hello -->
    <p>{{ [1,2,3,4,5] | slice:1:4 }}</p>  <!-- 2,3,4 -->
    
    <!-- Async Pipe -->
    <p>{{ message$ | async }}</p>
    <div *ngIf="user$ | async as user">
      {{ user.name }}
    </div>
  `
})
export class PipesExampleComponent {
  today = new Date();
  user = { name: 'John', age: 30 };
  message$ = of('Hello from Observable');
  user$ = of({ name: 'Jane' });
}
```

### Custom Pipes

#### Simple Custom Pipe
```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'exponential',
  standalone: true
})
export class ExponentialPipe implements PipeTransform {
  transform(value: number, exponent: number = 1): number {
    return Math.pow(value, exponent);
  }
}

// Usage
@Component({
  template: `
    <p>{{ 2 | exponential:3 }}</p>  <!-- 8 -->
    <p>{{ 5 | exponential:2 }}</p>  <!-- 25 -->
  `,
  imports: [ExponentialPipe]
})
export class AppComponent { }
```

#### Advanced Custom Pipe
```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'filter',
  standalone: true,
  pure: false  // Impure pipe - updates on every change detection
})
export class FilterPipe implements PipeTransform {
  transform<T>(items: T[], searchText: string, key: keyof T): T[] {
    if (!items || !searchText) {
      return items;
    }
    
    searchText = searchText.toLowerCase();
    
    return items.filter(item => {
      const value = String(item[key]).toLowerCase();
      return value.includes(searchText);
    });
  }
}

// Usage
@Component({
  template: `
    <input [(ngModel)]="searchTerm" placeholder="Search">
    <ul>
      <li *ngFor="let user of users | filter:searchTerm:'name'">
        {{ user.name }} - {{ user.email }}
      </li>
    </ul>
  `,
  imports: [FilterPipe, FormsModule, CommonModule]
})
export class UserListComponent {
  searchTerm = '';
  users = [
    { name: 'John Doe', email: 'john@example.com' },
    { name: 'Jane Smith', email: 'jane@example.com' },
    { name: 'Bob Johnson', email: 'bob@example.com' }
  ];
}
```

#### Pure vs Impure Pipes

```typescript
// Pure Pipe (default)
@Pipe({
  name: 'purePipe',
  standalone: true,
  pure: true  // Only runs when input reference changes
})
export class PurePipe implements PipeTransform {
  transform(value: any): any {
    console.log('Pure pipe executed');
    return value;
  }
}

// Impure Pipe
@Pipe({
  name: 'impurePipe',
  standalone: true,
  pure: false  // Runs on every change detection
})
export class ImpurePipe implements PipeTransform {
  transform(value: any): any {
    console.log('Impure pipe executed');
    return value;
  }
}
```

---

## Coding Challenges

### Challenge 1: Dynamic Form with Validation Display
**Difficulty: Medium**

Create a registration form that shows/hides validation messages dynamically using *ngIf.

**Requirements:**
- Username, email, password fields
- Show validation messages only when field is touched and invalid
- Use structural directives for conditional rendering

<details>
<summary>Solution</summary>

``typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-registration-form',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <form #registrationForm="ngForm" (ngSubmit)="onSubmit()">
      <div class="form-group">
        <label>Username:</label>
        <input 
          type="text"
          name="username"
          [(ngModel)]="formData.username"
          #username="ngModel"
          required
          minlength="3"
        >
        <div *ngIf="username.invalid && username.touched" class="error">
          <p *ngIf="username.errors?.['required']">Username is required</p>
          <p *ngIf="username.errors?.['minlength']">
            Username must be at least 3 characters
          </p>
        </div>
      </div>

      <div class="form-group">
        <label>Email:</label>
        <input 
          type="email"
          name="email"
          [(ngModel)]="formData.email"
          #email="ngModel"
          required
          pattern="[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$"
        >
        <div *ngIf="email.invalid && email.touched" class="error">
          <p *ngIf="email.errors?.['required']">Email is required</p>
          <p *ngIf="email.errors?.['pattern']">Invalid email format</p>
        </div>
      </div>

      <div class="form-group">
        <label>Password:</label>
        <input 
          type="password"
          name="password"
          [(ngModel)]="formData.password"
          #password="ngModel"
          required
          minlength="6"
        >
        <div *ngIf="password.invalid && password.touched" class="error">
          <p *ngIf="password.errors?.['required']">Password is required</p>
          <p *ngIf="password.errors?.['minlength']">
            Password must be at least 6 characters
          </p>
        </div>
      </div>

      <button 
        type="submit" 
        [disabled]="registrationForm.invalid"
      >
        Register
      </button>
    </form>

    <div *ngIf="submitted" class="success">
      Registration successful!
    </div>
  `,
  styles: [`
    .form-group { margin-bottom: 15px; }
    .error { color: red; font-size: 12px; }
    .success { color: green; margin-top: 10px; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
  `]
})
export class RegistrationFormComponent {
  formData = {
    username: '',
    email: '',
    password: ''
  };
  submitted = false;

  onSubmit() {
    this.submitted = true;
    console.log('Form submitted:', this.formData);
  }
}
```
</details>

### Challenge 2: Custom Tooltip Directive
**Difficulty: Medium**

Create a custom directive that shows a tooltip on hover.

<details>
<summary>Solution</summary>

```typescript
import { Directive, ElementRef, HostListener, Input, Renderer2 } from '@angular/core';

@Directive({
  selector: '[appTooltip]',
  standalone: true
})
export class TooltipDirective {
  @Input() appTooltip = '';
  @Input() tooltipPosition: 'top' | 'bottom' | 'left' | 'right' = 'top';
  
  private tooltipElement?: HTMLElement;
  
  constructor(
    private el: ElementRef,
    private renderer: Renderer2
  ) { }
  
  @HostListener('mouseenter')
  onMouseEnter() {
    if (!this.tooltipElement) {
      this.createTooltip();
    }
  }
  
  @HostListener('mouseleave')
  onMouseLeave() {
    if (this.tooltipElement) {
      this.renderer.removeChild(document.body, this.tooltipElement);
      this.tooltipElement = undefined;
    }
  }
  
  private createTooltip() {
    this.tooltipElement = this.renderer.createElement('div');
    this.renderer.appendChild(
      this.tooltipElement,
      this.renderer.createText(this.appTooltip)
    );
    this.renderer.appendChild(document.body, this.tooltipElement);
    
    // Style tooltip
    this.renderer.setStyle(this.tooltipElement, 'position', 'absolute');
    this.renderer.setStyle(this.tooltipElement, 'background', '#333');
    this.renderer.setStyle(this.tooltipElement, 'color', 'white');
    this.renderer.setStyle(this.tooltipElement, 'padding', '5px 10px');
    this.renderer.setStyle(this.tooltipElement, 'border-radius', '4px');
    this.renderer.setStyle(this.tooltipElement, 'font-size', '12px');
    this.renderer.setStyle(this.tooltipElement, 'z-index', '1000');
    
    // Position tooltip
    const hostPos = this.el.nativeElement.getBoundingClientRect();
    let top = 0;
    let left = 0;
    
    switch (this.tooltipPosition) {
      case 'top':
        top = hostPos.top - 30;
        left = hostPos.left + hostPos.width / 2;
        break;
      case 'bottom':
        top = hostPos.bottom + 5;
        left = hostPos.left + hostPos.width / 2;
        break;
      case 'left':
        top = hostPos.top + hostPos.height / 2;
        left = hostPos.left - 10;
        break;
      case 'right':
        top = hostPos.top + hostPos.height / 2;
        left = hostPos.right + 10;
        break;
    }
    
    this.renderer.setStyle(this.tooltipElement, 'top', `${top}px`);
    this.renderer.setStyle(this.tooltipElement, 'left', `${left}px`);
  }
}

// Usage
@Component({
  template: `
    <button appTooltip="Click to save" tooltipPosition="top">Save</button>
    <button appTooltip="Delete item" tooltipPosition="right">Delete</button>
  `,
  imports: [TooltipDirective]
})
export class AppComponent { }
```
</details>

### Challenge 3: Custom Sort Pipe
**Difficulty: Hard**

Create a pipe that sorts an array by a specified property in ascending or descending order.

<details>
<summary>Solution</summary>

```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'sort',
  standalone: true,
  pure: false
})
export class SortPipe implements PipeTransform {
  transform<T>(
    array: T[],
    field: keyof T,
    order: 'asc' | 'desc' = 'asc'
  ): T[] {
    if (!array || array.length === 0 || !field) {
      return array;
    }
    
    const sorted = [...array].sort((a, b) => {
      const aValue = a[field];
      const bValue = b[field];
      
      if (aValue === bValue) return 0;
      
      let comparison = 0;
      if (aValue > bValue) {
        comparison = 1;
      } else if (aValue < bValue) {
        comparison = -1;
      }
      
      return order === 'desc' ? comparison * -1 : comparison;
    });
    
    return sorted;
  }
}

// Usage
@Component({
  selector: 'app-user-list',
  standalone: true,
  imports: [CommonModule, SortPipe],
  template: `
    <div>
      <h3>User List</h3>
      <div class="controls">
        <button (click)="sortField = 'name'">Sort by Name</button>
        <button (click)="sortField = 'age'">Sort by Age</button>
        <button (click)="toggleOrder()">
          {{ sortOrder === 'asc' ? '↑' : '↓' }}
        </button>
      </div>
      
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Age</th>
            <th>Email</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let user of users | sort:sortField:sortOrder">
            <td>{{ user.name }}</td>
            <td>{{ user.age }}</td>
            <td>{{ user.email }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 10px; text-align: left; border: 1px solid #ddd; }
    .controls { margin-bottom: 10px; }
    button { margin-right: 5px; }
  `]
})
export class UserListComponent {
  sortField: 'name' | 'age' = 'name';
  sortOrder: 'asc' | 'desc' = 'asc';
  
  users = [
    { name: 'John', age: 30, email: 'john@example.com' },
    { name: 'Alice', age: 25, email: 'alice@example.com' },
    { name: 'Bob', age: 35, email: 'bob@example.com' },
    { name: 'Charlie', age: 28, email: 'charlie@example.com' }
  ];
  
  toggleOrder() {
    this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
  }
}
```
</details>

---

## Interview Questions

### Basic Questions

**Q1: What is data binding in Angular? List all types.**

**Answer:** Data binding is the automatic synchronization of data between model and view.

**Types:**
1. **Interpolation** - `{{ value }}` - Component to View
2. **Property Binding** - `[property]="value"` - Component to View
3. **Event Binding** - `(event)="handler()"` - View to Component
4. **Two-way Binding** - `[(ngModel)]="value"` - Both directions

---

**Q2: What's the difference between *ngIf and [hidden]?**

**Answer:**

| *ngIf | [hidden] |
|-------|----------|
| Removes/adds DOM element | Toggles CSS display property |
| Better for large templates | Better for small elements |
| No DOM overhead when false | Element stays in DOM |
| Re-initializes when shown | Maintains state |

```html
<!-- ngIf: element removed from DOM -->
<div *ngIf="show">Content</div>

<!-- hidden: element stays in DOM with display:none -->
<div [hidden]="!show">Content</div>
```

---

**Q3: Explain trackBy in *ngFor.**

**Answer:** `trackBy` improves performance by tracking items by unique identifier instead of object reference.

**Without trackBy:**
```typescript
// Re-renders all items when array changes
<div *ngFor="let item of items">{{ item.name }}</div>
```

**With trackBy:**
```typescript
<div *ngFor"let item of items; trackBy: trackByFn">
  {{ item.name }}
</div>

trackByFn(index: number, item: any) {
  return item.id;  // Track by unique ID
}
```

Benefits: Fewer DOM manipulations, better performance, preserved component state.

---

**Q4: What are structural directives? How are they different from attribute directives?**

**Answer:**

**Structural Directives:**
- Change DOM structure (add/remove elements)
- Use asterisk (*) syntax
- Examples: *ngIf, *ngFor, *ngSwitch

**Attribute Directives:**
- Change appearance or behavior
- No asterisk
- Examples: ngClass, ngStyle, custom directives

---

### Intermediate Questions

**Q5: How do you create a custom attribute directive?**

**Answer:**
```typescript
import { Directive, ElementRef, Input, HostListener } from '@angular/core';

@Directive({
  selector: '[appHighlight]',
  standalone: true
})
export class HighlightDirective {
  @Input() highlightColor = 'yellow';
  
  constructor(private el: ElementRef) { }
  
  @HostListener('mouseenter') onMouseEnter() {
    this.highlight(this.highlightColor);
  }
  
  @HostListener('mouseleave') onMouseLeave() {
    this.highlight('');
  }
  
  private highlight(color: string) {
    this.el.nativeElement.style.backgroundColor = color;
  }
}

// Usage:
<p appHighlight highlightColor="lightblue">Hover me</p>
```

---

**Q6: What is the difference between pure and impure pipes?**

**Answer:**

**Pure Pipe (default):**
- Executes only when input value/reference changes
- Better performance
- Pure: true (default)
- Most built-in pipes are pure

**Impure Pipe:**
- Executes on every change detection cycle
- Can detect changes within objects/arrays
- Pure: false
- Use sparingly (performance impact)
- Example: async pipe

```typescript
// Pure
@Pipe({ name: 'pure', pure: true })

// Impure
@Pipe({ name: 'impure', pure: false })
```

---

**Q7: Explain the async pipe and its benefits.**

**Answer:** The async pipe subscribes to Observables/Promises and automatically unsubscribes.

```typescript
@Component({
  template: `
    <!-- Auto-subscribe and unsubscribe -->
    <div>{{ data$ | async }}</div>
    
    <!-- With ngIf to avoid null -->
    <div *ngIf="user$ | async as user">
      {{ user.name }}
    </div>
  `
})
export class Component {
  data$ = this.http.get('/api/data');
  user$ = this.userService.getUser();
}
```

**Benefits:**
- Auto-unsubscribe (prevents memory leaks)
- Cleaner template code
- OnPush friendly
- Handles errors gracefully

---

### Advanced Questions

**Q8: How would you create a custom structural directive?**

**Answer:**
```typescript
import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';

@Directive({
  selector: '[appRepeat]',
  standalone: true
})
export class RepeatDirective {
  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef
  ) { }
  
  @Input() set appRepeat(times: number) {
    this.viewContainer.clear();
    for (let i = 0; i < times; i++) {
      this.viewContainer.createEmbeddedView(this.templateRef, {
        $implicit: i,
        index: i
      });
    }
  }
}

// Usage:
<div *appRepeat="3; let i = index">
  Item {{ i }}
</div>
```

**Key concepts:**
- `TemplateRef`: Reference to template
- `ViewContainerRef`: Container for views
- `createEmbeddedView`: Creates view from template

---

**Q9: How does Angular's change detection work with pipes?**

**Answer:**

**Pure Pipes:**
- Angular checks if input reference changed
- If same reference, cached result returned
- Array/object mutations not detected
- Must create new reference to trigger

```typescript
// Won't trigger pure pipe
this.items.push(newItem);

// Will trigger pure pipe
this.items = [...this.items, newItem];
```

**Impure Pipes:**
- Run on every change detection
- Detect mutations
- Performance cost
- Use for dynamic filtering/sorting

---

**Q10: Explain @HostListener and @HostBinding.**

**Answer:**

**@HostListener** - Listen to host element events:
```typescript
@Directive({ selector: '[appClick]' })
export class ClickDirective {
  @HostListener('click', ['$event'])
  onClick(event: Event) {
    console.log('Clicked!', event);
  }
  
  @HostListener('window:resize', ['$event'])
  onResize(event: Event) {
    console.log('Window resized');
  }
}
```

**@HostBinding** - Bind to host properties:
```typescript
@Directive({ selector: '[appActive]' })
export class ActiveDirective {
  @HostBinding('class.active') isActive = true;
  @HostBinding('style.color') color = 'blue';
  @HostBinding('attr.role') role = 'button';
}
```

---

[← Back to Index](angular19-guide-index.md) | [Previous: Fundamentals](angular19-part1-fundamentals.md) | [Next: Services and DI →](angular19-part3-services-di.md)
