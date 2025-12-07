# Part 3: Directives Basics

## What are Directives?

Directives are markers on DOM elements that tell AngularJS's HTML compiler to attach specified behavior to that element or transform it and its children.

### Types of Directives

1. **Element Directives**: `<my-directive></my-directive>`
2. **Attribute Directives**: `<div my-directive></div>`
3. **Class Directives**: `<div class="my-directive"></div>`
4. **Comment Directives**: `<!-- directive: my-directive -->`

## Built-in Directives

### ng-repeat

The `ng-repeat` directive instantiates a template once per item from a collection.

```html
<div ng-controller="ListController as vm">
    <!-- Basic usage -->
    <ul>
        <li ng-repeat="item in vm.items">
            {{ item }}
        </li>
    </ul>

    <!-- With index -->
    <ul>
        <li ng-repeat="user in vm.users">
            {{ $index + 1 }}. {{ user.name }}
        </li>
    </ul>

    <!-- With object -->
    <ul>
        <li ng-repeat="(key, value) in vm.settings">
            {{ key }}: {{ value }}
        </li>
    </ul>

    <!-- With filter -->
    <ul>
        <li ng-repeat="product in vm.products | filter:vm.searchQuery">
            {{ product.name }} - ${{ product.price }}
        </li>
    </ul>

    <!-- With orderBy -->
    <ul>
        <li ng-repeat="user in vm.users | orderBy:'name'">
            {{ user.name }}
        </li>
    </ul>

    <!-- With limitTo -->
    <ul>
        <li ng-repeat="item in vm.items | limitTo:5">
            {{ item }}
        </li>
    </ul>

    <!-- Track by (for performance) -->
    <ul>
        <li ng-repeat="user in vm.users track by user.id">
            {{ user.name }}
        </li>
    </ul>
</div>
```

#### Special Properties in ng-repeat

```html
<div ng-repeat="item in items">
    <p>Index: {{ $index }}</p>
    <p>First: {{ $first }}</p>
    <p>Last: {{ $last }}</p>
    <p>Middle: {{ $middle }}</p>
    <p>Even: {{ $even }}</p>
    <p>Odd: {{ $odd }}</p>
</div>
```

#### Complete Example

```javascript
angular.module('myApp')
    .controller('ListController', function() {
        var vm = this;

        vm.users = [
            { id: 1, name: 'John Doe', email: 'john@example.com', age: 30, active: true },
            { id: 2, name: 'Jane Smith', email: 'jane@example.com', age: 25, active: false },
            { id: 3, name: 'Bob Johnson', email: 'bob@example.com', age: 35, active: true },
            { id: 4, name: 'Alice Brown', email: 'alice@example.com', age: 28, active: true }
        ];

        vm.searchQuery = '';
        vm.sortField = 'name';
        vm.sortReverse = false;

        vm.setSortField = function(field) {
            if (vm.sortField === field) {
                vm.sortReverse = !vm.sortReverse;
            } else {
                vm.sortField = field;
                vm.sortReverse = false;
            }
        };
    });
```

```html
<div ng-controller="ListController as vm">
    <!-- Search -->
    <input type="text" ng-model="vm.searchQuery" placeholder="Search users...">

    <!-- Sort buttons -->
    <button ng-click="vm.setSortField('name')">Sort by Name</button>
    <button ng-click="vm.setSortField('age')">Sort by Age</button>

    <!-- User table -->
    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>Name</th>
                <th>Email</th>
                <th>Age</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            <tr ng-repeat="user in vm.users | filter:vm.searchQuery | orderBy:vm.sortField:vm.sortReverse track by user.id"
                ng-class="{ 'highlighted': $odd, 'inactive': !user.active }">
                <td>{{ $index + 1 }}</td>
                <td>{{ user.name }}</td>
                <td>{{ user.email }}</td>
                <td>{{ user.age }}</td>
                <td>{{ user.active ? 'Active' : 'Inactive' }}</td>
            </tr>
        </tbody>
    </table>

    <!-- Empty state -->
    <p ng-if="(vm.users | filter:vm.searchQuery).length === 0">
        No users found.
    </p>
</div>
```

### ng-if, ng-show, ng-hide

These directives control element visibility.

```html
<div ng-controller="VisibilityController as vm">
    <!-- ng-if: Adds/removes element from DOM -->
    <div ng-if="vm.isLoggedIn">
        <h2>Welcome, {{ vm.username }}!</h2>
        <button ng-click="vm.logout()">Logout</button>
    </div>

    <div ng-if="!vm.isLoggedIn">
        <h2>Please login</h2>
        <button ng-click="vm.login()">Login</button>
    </div>

    <!-- ng-show: Hides with CSS (display: none) -->
    <div ng-show="vm.showDetails">
        <p>These are the details...</p>
    </div>

    <!-- ng-hide: Opposite of ng-show -->
    <div ng-hide="vm.hideWarning">
        <p>Warning message!</p>
    </div>

    <!-- Multiple conditions with ng-if -->
    <div ng-if="vm.isAdmin && vm.hasPermission">
        <p>Admin panel</p>
    </div>
</div>
```

**When to use which?**

- **ng-if**: When you want to completely remove/add elements (better for performance if element is rarely shown)
- **ng-show/ng-hide**: When you toggle visibility frequently (element stays in DOM)

```javascript
angular.module('myApp')
    .controller('VisibilityController', function() {
        var vm = this;

        vm.isLoggedIn = false;
        vm.username = '';
        vm.showDetails = false;
        vm.hideWarning = false;
        vm.isAdmin = false;
        vm.hasPermission = false;

        vm.login = function() {
            vm.isLoggedIn = true;
            vm.username = 'John Doe';
        };

        vm.logout = function() {
            vm.isLoggedIn = false;
            vm.username = '';
        };
    });
```

### ng-switch

For multiple conditional cases.

```html
<div ng-controller="SwitchController as vm">
    <select ng-model="vm.userRole">
        <option value="admin">Admin</option>
        <option value="editor">Editor</option>
        <option value="viewer">Viewer</option>
        <option value="guest">Guest</option>
    </select>

    <div ng-switch="vm.userRole">
        <div ng-switch-when="admin">
            <h3>Admin Panel</h3>
            <p>You have full access</p>
        </div>
        <div ng-switch-when="editor">
            <h3>Editor Panel</h3>
            <p>You can edit content</p>
        </div>
        <div ng-switch-when="viewer">
            <h3>Viewer Panel</h3>
            <p>You can view content</p>
        </div>
        <div ng-switch-default>
            <h3>Guest</h3>
            <p>Limited access</p>
        </div>
    </div>
</div>
```

### ng-class

Dynamically set CSS classes.

```html
<div ng-controller="ClassController as vm">
    <!-- String syntax -->
    <div ng-class="vm.className">Content</div>

    <!-- Object syntax (recommended) -->
    <div ng-class="{ 
        'active': vm.isActive, 
        'disabled': vm.isDisabled,
        'highlighted': vm.isHighlighted 
    }">
        Content
    </div>

    <!-- Array syntax -->
    <div ng-class="[vm.class1, vm.class2, vm.class3]">Content</div>

    <!-- Expression -->
    <div ng-class="vm.getClassName()">Content</div>

    <!-- Ternary operator -->
    <div ng-class="vm.status === 'error' ? 'error-class' : 'success-class'">
        Status message
    </div>

    <!-- Multiple classes conditionally -->
    <button ng-class="{ 
        'btn': true,
        'btn-primary': vm.type === 'primary',
        'btn-danger': vm.type === 'danger',
        'btn-lg': vm.size === 'large',
        'btn-sm': vm.size === 'small'
    }">
        Button
    </button>
</div>
```

```javascript
angular.module('myApp')
    .controller('ClassController', function() {
        var vm = this;

        vm.isActive = true;
        vm.isDisabled = false;
        vm.isHighlighted = true;

        vm.status = 'success';
        vm.type = 'primary';
        vm.size = 'large';

        vm.getClassName = function() {
            return vm.isActive ? 'active-state' : 'inactive-state';
        };
    });
```

### ng-style

Dynamically set CSS styles.

```html
<div ng-controller="StyleController as vm">
    <!-- Object syntax -->
    <div ng-style="{ 
        'color': vm.textColor, 
        'font-size': vm.fontSize + 'px',
        'background-color': vm.bgColor,
        'padding': '10px',
        'border': '1px solid ' + vm.borderColor
    }">
        Styled content
    </div>

    <!-- From controller property -->
    <div ng-style="vm.customStyles">Content</div>

    <!-- Conditional styles -->
    <div ng-style="vm.isImportant && { 'font-weight': 'bold', 'color': 'red' }">
        Important message
    </div>
</div>
```

```javascript
angular.module('myApp')
    .controller('StyleController', function() {
        var vm = this;

        vm.textColor = '#333';
        vm.fontSize = 16;
        vm.bgColor = '#f0f0f0';
        vm.borderColor = '#ccc';
        vm.isImportant = true;

        vm.customStyles = {
            'color': 'blue',
            'font-size': '18px',
            'text-align': 'center'
        };
    });
```

### ng-click and Event Directives

Handle user interactions.

```html
<div ng-controller="EventController as vm">
    <!-- Click event -->
    <button ng-click="vm.handleClick()">Click Me</button>

    <!-- With $event object -->
    <button ng-click="vm.handleClickWithEvent($event)">
        Click for Event Info
    </button>

    <!-- Multiple statements -->
    <button ng-click="vm.counter = vm.counter + 1; vm.logAction('incremented')">
        Increment: {{ vm.counter }}
    </button>

    <!-- Double click -->
    <div ng-dblclick="vm.handleDoubleClick()">Double click me</div>

    <!-- Mouse events -->
    <div ng-mouseenter="vm.isHovering = true"
         ng-mouseleave="vm.isHovering = false"
         ng-mouseover="vm.handleMouseOver()"
         ng-mousedown="vm.handleMouseDown()"
         ng-mouseup="vm.handleMouseUp()">
        Hover over me
    </div>

    <!-- Keyboard events -->
    <input type="text"
           ng-keydown="vm.handleKeyDown($event)"
           ng-keyup="vm.handleKeyUp($event)"
           ng-keypress="vm.handleKeyPress($event)">

    <!-- Focus/Blur -->
    <input type="text"
           ng-focus="vm.isFocused = true"
           ng-blur="vm.isFocused = false">

    <!-- Form events -->
    <form ng-submit="vm.handleSubmit()">
        <input type="text" ng-model="vm.inputValue">
        <button type="submit">Submit</button>
    </form>

    <!-- Change event -->
    <select ng-change="vm.handleChange()" ng-model="vm.selectedOption">
        <option value="1">Option 1</option>
        <option value="2">Option 2</option>
    </select>

    <!-- Copy/Paste/Cut -->
    <input type="text"
           ng-copy="vm.handleCopy()"
           ng-paste="vm.handlePaste()"
           ng-cut="vm.handleCut()">
</div>
```

```javascript
angular.module('myApp')
    .controller('EventController', function() {
        var vm = this;

        vm.counter = 0;
        vm.isHovering = false;
        vm.isFocused = false;

        vm.handleClick = function() {
            console.log('Button clicked!');
        };

        vm.handleClickWithEvent = function($event) {
            console.log('Event:', $event);
            console.log('Target:', $event.target);
            console.log('Position:', $event.clientX, $event.clientY);
        };

        vm.handleDoubleClick = function() {
            console.log('Double clicked!');
        };

        vm.handleKeyDown = function($event) {
            console.log('Key down:', $event.keyCode);
            
            // Enter key
            if ($event.keyCode === 13) {
                console.log('Enter pressed!');
            }
        };

        vm.handleSubmit = function() {
            console.log('Form submitted with:', vm.inputValue);
        };

        vm.logAction = function(action) {
            console.log('Action:', action);
        };
    });
```

### ng-bind and ng-bind-html

Alternative to `{{ }}` expressions.

```html
<div ng-controller="BindController as vm">
    <!-- ng-bind (alternative to {{ }}) -->
    <p ng-bind="vm.message"></p>
    <p>{{ vm.message }}</p>

    <!-- Prevents flash of {{}} before Angular loads -->
    <p ng-bind="vm.data"></p> <!-- Recommended for initial view -->

    <!-- ng-bind-html (render HTML, requires ngSanitize) -->
    <div ng-bind-html="vm.htmlContent"></div>

    <!-- ng-bind-template (multiple expressions) -->
    <p ng-bind-template="Name: {{vm.firstName}} {{vm.lastName}}"></p>
</div>
```

```javascript
angular.module('myApp', ['ngSanitize'])
    .controller('BindController', function($sce) {
        var vm = this;

        vm.message = 'Hello World';
        vm.firstName = 'John';
        vm.lastName = 'Doe';

        // Mark HTML as safe (use with caution!)
        vm.htmlContent = $sce.trustAsHtml('<strong>Bold text</strong>');
    });
```

### ng-src and ng-href

For dynamic URLs.

```html
<div ng-controller="UrlController as vm">
    <!-- ng-src for images (prevents 404 before Angular loads) -->
    <img ng-src="{{ vm.imageUrl }}" alt="User Avatar">

    <!-- DON'T DO THIS (will cause 404) -->
    <img src="{{ vm.imageUrl }}" alt="Wrong way">

    <!-- ng-href for links -->
    <a ng-href="{{ vm.profileUrl }}">View Profile</a>

    <!-- Conditional URLs -->
    <a ng-href="{{ vm.isExternal ? vm.externalUrl : vm.internalUrl }}">
        Link
    </a>
</div>
```

```javascript
angular.module('myApp')
    .controller('UrlController', function() {
        var vm = this;

        vm.imageUrl = 'https://example.com/avatar.jpg';
        vm.profileUrl = '/user/123/profile';
        vm.isExternal = false;
        vm.externalUrl = 'https://external.com';
        vm.internalUrl = '/internal';
    });
```

### ng-disabled, ng-readonly, ng-checked

Control form element states.

```html
<div ng-controller="FormStateController as vm">
    <!-- ng-disabled -->
    <button ng-disabled="vm.isProcessing">
        {{ vm.isProcessing ? 'Processing...' : 'Submit' }}
    </button>

    <input type="text" 
           ng-model="vm.username"
           ng-disabled="!vm.canEdit">

    <!-- ng-readonly -->
    <input type="text"
           ng-model="vm.email"
           ng-readonly="vm.emailLocked">

    <!-- ng-checked -->
    <input type="checkbox"
           ng-model="vm.agree"
           ng-checked="vm.forceAgree">

    <!-- ng-required -->
    <input type="text"
           ng-model="vm.optionalField"
           ng-required="vm.isRequired">

    <!-- ng-pattern -->
    <input type="text"
           ng-model="vm.zipCode"
           ng-pattern="/^\d{5}$/">
</div>
```

### ng-include

Include external templates.

```html
<div ng-controller="IncludeController as vm">
    <!-- Basic include -->
    <div ng-include="'templates/header.html'"></div>

    <!-- Dynamic template -->
    <div ng-include="vm.templateUrl"></div>

    <!-- With onload callback -->
    <div ng-include="'templates/content.html'" 
         onload="vm.templateLoaded()"></div>

    <!-- Conditional include -->
    <div ng-if="vm.showTemplate">
        <div ng-include="'templates/optional.html'"></div>
    </div>
</div>
```

```javascript
angular.module('myApp')
    .controller('IncludeController', function() {
        var vm = this;

        vm.templateUrl = 'templates/default.html';
        vm.showTemplate = true;

        vm.changeTemplate = function(template) {
            vm.templateUrl = 'templates/' + template + '.html';
        };

        vm.templateLoaded = function() {
            console.log('Template loaded!');
        };
    });
```

### ng-cloak

Prevent Flash of Unstyled Content (FOUC).

```html
<style>
    [ng-cloak] {
        display: none !important;
    }
</style>

<div ng-cloak ng-controller="DataController as vm">
    <!-- This won't show until Angular is ready -->
    <h1>{{ vm.title }}</h1>
    <p>{{ vm.description }}</p>
</div>
```

## Directive Best Practices

### 1. Use ng-repeat with track by

```html
<!-- Bad: Performance issues with large lists -->
<li ng-repeat="item in items">{{ item.name }}</li>

<!-- Good: Tracks items by unique ID -->
<li ng-repeat="item in items track by item.id">{{ item.name }}</li>

<!-- For primitive arrays -->
<li ng-repeat="item in items track by $index">{{ item }}</li>
```

### 2. Use one-time binding for static data

```html
<!-- Creates watcher (updates on change) -->
<p>{{ user.name }}</p>

<!-- One-time binding (no watcher) -->
<p>{{ ::user.name }}</p>
```

### 3. Prefer ng-if over ng-show for rarely shown content

```html
<!-- Good: Completely removes from DOM -->
<div ng-if="showComplexWidget">
    <!-- Complex widget with many watchers -->
</div>

<!-- Bad: Hides but keeps in DOM (watchers still active) -->
<div ng-show="showComplexWidget">
    <!-- Complex widget with many watchers -->
</div>
```

### 4. Avoid complex expressions in templates

```html
<!-- Bad -->
<div ng-if="(user.role === 'admin' || user.role === 'superadmin') && user.active && !user.suspended">
    Admin content
</div>

<!-- Good -->
<div ng-if="vm.isActiveAdmin()">
    Admin content
</div>
```

```javascript
vm.isActiveAdmin = function() {
    return (vm.user.role === 'admin' || vm.user.role === 'superadmin') 
        && vm.user.active 
        && !vm.user.suspended;
};
```

## Next Steps

Continue to [04-Custom-Directives](./04-Custom-Directives.md) to learn how to create your own custom directives and build reusable components.
