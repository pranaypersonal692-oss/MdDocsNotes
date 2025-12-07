# Part 1: Introduction and Setup

## What is AngularJS?

AngularJS (also known as Angular 1.x) is a structural framework for dynamic web applications. It lets you use HTML as your template language and extend HTML's syntax to express your application's components clearly and succinctly.

### Key Features

1. **Two-Way Data Binding**: Automatic synchronization between model and view
2. **MVC Architecture**: Model-View-Controller design pattern
3. **Dependency Injection**: Modular and testable code
4. **Directives**: Extend HTML with custom attributes and elements
5. **Services**: Reusable business logic
6. **Routing**: Single Page Application (SPA) support
7. **Testing**: Built with testability in mind

### Why AngularJS? (Historical Context)

While Angular (2+) is the modern version, AngularJS is still widely used in:
- Legacy applications
- Existing codebases requiring maintenance
- Organizations gradually migrating to newer frameworks

## Setting Up AngularJS

### Method 1: CDN (Quick Start)

```html
<!DOCTYPE html>
<html ng-app="myApp">
<head>
    <meta charset="UTF-8">
    <title>My First AngularJS App</title>
    <!-- Include AngularJS from CDN -->
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.8.2/angular.min.js"></script>
</head>
<body>
    <div ng-controller="MainController">
        <h1>{{ message }}</h1>
    </div>

    <script>
        // Create Angular module
        var app = angular.module('myApp', []);

        // Create controller
        app.controller('MainController', function($scope) {
            $scope.message = 'Hello, AngularJS!';
        });
    </script>
</body>
</html>
```

### Method 2: npm Installation (Recommended for Production)

```bash
# Initialize npm project
npm init -y

# Install AngularJS
npm install angular@1.8.2

# Install additional modules as needed
npm install angular-route@1.8.2
npm install angular-resource@1.8.2
```

**Project Structure:**
```
my-angular-app/
├── node_modules/
├── app/
│   ├── controllers/
│   ├── services/
│   ├── directives/
│   ├── views/
│   └── app.js
├── assets/
│   ├── css/
│   ├── js/
│   └── images/
├── index.html
└── package.json
```

### Method 3: Bower (Legacy)

```bash
# Install Bower globally
npm install -g bower

# Initialize bower
bower init

# Install AngularJS
bower install angular#1.8.2
```

## Your First AngularJS Application

Let's build a simple todo application to understand the basics.

### Step 1: Create index.html

```html
<!DOCTYPE html>
<html ng-app="todoApp">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Todo App - AngularJS</title>
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.8.2/angular.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
        }
        .todo-item {
            padding: 10px;
            margin: 5px 0;
            border: 1px solid #ddd;
            border-radius: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .completed {
            text-decoration: line-through;
            opacity: 0.6;
        }
        button {
            padding: 5px 15px;
            cursor: pointer;
        }
        input[type="text"] {
            padding: 10px;
            width: 70%;
            margin-right: 10px;
        }
    </style>
</head>
<body>
    <div ng-controller="TodoController">
        <h1>My Todo List</h1>
        
        <!-- Add Todo Form -->
        <div>
            <input type="text" 
                   ng-model="newTodo" 
                   placeholder="Enter a new todo"
                   ng-keypress="$event.keyCode == 13 && addTodo()">
            <button ng-click="addTodo()">Add</button>
        </div>

        <!-- Todo List -->
        <div ng-if="todos.length > 0">
            <h3>Tasks: {{ getTotalTodos() }}</h3>
            
            <div ng-repeat="todo in todos" class="todo-item">
                <div>
                    <input type="checkbox" 
                           ng-model="todo.completed"
                           ng-change="updateStats()">
                    <span ng-class="{completed: todo.completed}">
                        {{ todo.text }}
                    </span>
                </div>
                <button ng-click="removeTodo($index)">Delete</button>
            </div>

            <p>
                Completed: {{ getCompletedCount() }} / {{ todos.length }}
            </p>
        </div>

        <!-- Empty State -->
        <div ng-if="todos.length === 0">
            <p>No todos yet. Add one above!</p>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
```

### Step 2: Create app.js

```javascript
// Create the Angular module
var app = angular.module('todoApp', []);

// Create the controller
app.controller('TodoController', function($scope) {
    // Initialize data
    $scope.todos = [
        { text: 'Learn AngularJS', completed: false },
        { text: 'Build an app', completed: false }
    ];
    $scope.newTodo = '';

    // Add new todo
    $scope.addTodo = function() {
        if ($scope.newTodo.trim() !== '') {
            $scope.todos.push({
                text: $scope.newTodo,
                completed: false
            });
            $scope.newTodo = ''; // Clear input
        }
    };

    // Remove todo
    $scope.removeTodo = function(index) {
        $scope.todos.splice(index, 1);
    };

    // Get total todos
    $scope.getTotalTodos = function() {
        return $scope.todos.length;
    };

    // Get completed count
    $scope.getCompletedCount = function() {
        return $scope.todos.filter(function(todo) {
            return todo.completed;
        }).length;
    };

    // Update statistics (could be used for more complex logic)
    $scope.updateStats = function() {
        // This is called when checkbox changes
        // You can add additional logic here
        console.log('Stats updated');
    };
});
```

## Understanding the Code

### 1. ng-app Directive
```html
<html ng-app="todoApp">
```
- Defines the root element of the AngularJS application
- Initializes the Angular application with the module name "todoApp"

### 2. Creating a Module
```javascript
var app = angular.module('todoApp', []);
```
- First parameter: module name
- Second parameter: array of dependencies (empty for now)

### 3. ng-controller Directive
```html
<div ng-controller="TodoController">
```
- Attaches a controller to the view
- Creates a new scope for this section

### 4. $scope Object
```javascript
app.controller('TodoController', function($scope) {
    $scope.todos = [...];
});
```
- The glue between controller and view
- Data and functions bound to $scope are accessible in the view

### 5. Two-Way Data Binding
```html
<input type="text" ng-model="newTodo">
```
- `ng-model` creates two-way binding
- Changes in input update $scope.newTodo
- Changes in $scope.newTodo update the input

### 6. Event Handling
```html
<button ng-click="addTodo()">Add</button>
```
- `ng-click` binds click event to controller function

### 7. Conditionals
```html
<div ng-if="todos.length > 0">
```
- `ng-if` adds/removes element based on condition

### 8. Loops
```html
<div ng-repeat="todo in todos">
```
- `ng-repeat` creates a template for each item in the array

### 9. Expressions
```html
<h3>Tasks: {{ getTotalTodos() }}</h3>
```
- `{{ }}` evaluates expressions and displays the result

## Development Tools

### 1. Browser DevTools Extensions

**AngularJS Batarang** (Chrome)
- Inspect scopes
- Monitor performance
- Track dependencies

### 2. Code Editors

**Visual Studio Code**
- Install "Angular Language Service" extension
- Syntax highlighting
- IntelliSense

**WebStorm**
- Built-in AngularJS support
- Advanced refactoring

### 3. Debugging Tips

```javascript
// Console logging
console.log($scope.todos);

// Angular's debug info
angular.element(document.querySelector('[ng-controller]')).scope();

// Get controller instance
angular.element(document.querySelector('[ng-controller]')).controller();
```

## Project Setup Best Practices

### 1. Organized File Structure

```
app/
├── app.js                 # Main module and config
├── controllers/
│   ├── home.controller.js
│   ├── user.controller.js
│   └── product.controller.js
├── services/
│   ├── api.service.js
│   ├── auth.service.js
│   └── storage.service.js
├── directives/
│   ├── user-card.directive.js
│   └── date-picker.directive.js
├── filters/
│   └── capitalize.filter.js
├── views/
│   ├── home.html
│   ├── user.html
│   └── product.html
└── constants/
    └── api-endpoints.js
```

### 2. Module Organization

```javascript
// app.js
(function() {
    'use strict';

    angular.module('myApp', [
        'ngRoute',
        'ngResource',
        'myApp.controllers',
        'myApp.services',
        'myApp.directives'
    ]);

    // Controllers module
    angular.module('myApp.controllers', []);

    // Services module
    angular.module('myApp.services', []);

    // Directives module
    angular.module('myApp.directives', []);
})();
```

### 3. Using IIFE (Immediately Invoked Function Expression)

```javascript
(function() {
    'use strict';

    angular
        .module('myApp')
        .controller('HomeController', HomeController);

    HomeController.$inject = ['$scope', '$http'];

    function HomeController($scope, $http) {
        var vm = this;
        
        vm.title = 'Home Page';
        vm.loadData = loadData;

        activate();

        function activate() {
            loadData();
        }

        function loadData() {
            // Load data logic
        }
    }
})();
```

## Build Tools Setup

### Using Gulp

```bash
npm install --save-dev gulp gulp-concat gulp-uglify gulp-ng-annotate
```

**gulpfile.js:**
```javascript
const gulp = require('gulp');
const concat = require('gulp-concat');
const uglify = require('gulp-uglify');
const ngAnnotate = require('gulp-ng-annotate');

gulp.task('scripts', function() {
    return gulp.src(['app/**/*.js'])
        .pipe(concat('app.min.js'))
        .pipe(ngAnnotate())
        .pipe(uglify())
        .pipe(gulp.dest('dist'));
});

gulp.task('watch', function() {
    gulp.watch('app/**/*.js', ['scripts']);
});
```

### Using Webpack

```bash
npm install --save-dev webpack webpack-cli angular
```

**webpack.config.js:**
```javascript
const path = require('path');

module.exports = {
    entry: './app/app.js',
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'bundle.js'
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader'
                }
            }
        ]
    }
};
```

## Next Steps

Now that you have AngularJS set up and understand the basics:

1. ✅ Understood what AngularJS is
2. ✅ Set up development environment
3. ✅ Created your first application
4. ✅ Learned basic directives

**Continue to:** [02-Core-Concepts](./02-Core-Concepts.md) to dive deeper into Controllers, Scope, and Data Binding.

---

## Quick Reference

### Essential Directives
- `ng-app` - Define AngularJS application
- `ng-controller` - Attach controller to view
- `ng-model` - Two-way data binding
- `ng-click` - Click event handler
- `ng-repeat` - Loop through arrays
- `ng-if` - Conditional rendering

### Common Patterns
```javascript
// Module
angular.module('myApp', []);

// Controller
app.controller('MyController', function($scope) {});

// Service
app.service('MyService', function() {});

// Factory
app.factory('MyFactory', function() {});
```
