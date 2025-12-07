# Part 2: Core Concepts

## Controllers in Depth

Controllers are the heart of AngularJS applications. They contain the business logic and act as the bridge between the view and the model.

### Basic Controller

```javascript
angular.module('myApp', [])
    .controller('UserController', function($scope) {
        $scope.user = {
            name: 'John Doe',
            email: 'john@example.com',
            age: 30
        };

        $scope.updateUser = function() {
            console.log('User updated:', $scope.user);
        };
    });
```

```html
<div ng-controller="UserController">
    <h2>{{ user.name }}</h2>
    <p>Email: {{ user.email }}</p>
    <p>Age: {{ user.age }}</p>
    <button ng-click="updateUser()">Update</button>
</div>
```

### Controller As Syntax (Recommended)

The "Controller As" syntax is preferred because it:
- Makes it clearer where properties come from
- Avoids scope inheritance issues
- Aligns with ES6 class syntax

```javascript
angular.module('myApp')
    .controller('UserController', function() {
        var vm = this; // vm = ViewModel

        vm.user = {
            name: 'John Doe',
            email: 'john@example.com',
            age: 30
        };

        vm.updateUser = updateUser;
        vm.deleteUser = deleteUser;

        // Initialization
        activate();

        function activate() {
            console.log('Controller initialized');
        }

        function updateUser() {
            console.log('User updated:', vm.user);
        }

        function deleteUser() {
            console.log('User deleted');
        }
    });
```

```html
<div ng-controller="UserController as vm">
    <h2>{{ vm.user.name }}</h2>
    <p>Email: {{ vm.user.email }}</p>
    <p>Age: {{ vm.user.age }}</p>
    <button ng-click="vm.updateUser()">Update</button>
    <button ng-click="vm.deleteUser()">Delete</button>
</div>
```

### Nested Controllers

```javascript
angular.module('myApp')
    .controller('ParentController', function() {
        var vm = this;
        vm.message = 'Hello from Parent';
        vm.parentData = 'Important parent data';
    })
    .controller('ChildController', function() {
        var vm = this;
        vm.message = 'Hello from Child';
        vm.childData = 'Child specific data';
    });
```

```html
<div ng-controller="ParentController as parent">
    <h2>{{ parent.message }}</h2>
    <p>{{ parent.parentData }}</p>

    <div ng-controller="ChildController as child">
        <h3>{{ child.message }}</h3>
        <p>{{ child.childData }}</p>
        <!-- Can still access parent -->
        <p>Parent says: {{ parent.message }}</p>
    </div>
</div>
```

## Understanding $scope

The `$scope` object is fundamental to AngularJS. It's the glue between the controller and the view.

### $scope Lifecycle

```javascript
angular.module('myApp')
    .controller('LifecycleController', function($scope) {
        console.log('1. Controller instantiated');

        $scope.data = 'Initial data';

        // Runs after the controller is instantiated
        $scope.$on('$viewContentLoaded', function() {
            console.log('2. View content loaded');
        });

        // Runs when the scope is destroyed
        $scope.$on('$destroy', function() {
            console.log('3. Scope destroyed - cleanup here');
            // Clean up event listeners, intervals, etc.
        });
    });
```

### $scope Hierarchy

```javascript
angular.module('myApp')
    .controller('GrandparentController', function($scope) {
        $scope.family = 'Smith';
        $scope.grandparentValue = 'Wisdom';

        $scope.showFamily = function() {
            console.log('Family:', $scope.family);
        };
    })
    .controller('ParentController', function($scope) {
        $scope.parentValue = 'Love';
        // Inherits $scope.family from grandparent

        $scope.updateFamily = function() {
            $scope.family = 'Johnson'; // Creates new property on parent scope
        };
    })
    .controller('ChildController', function($scope) {
        $scope.childValue = 'Joy';
        // Inherits from both parent and grandparent
    });
```

```html
<div ng-controller="GrandparentController">
    Family: {{ family }} (Grandparent level)
    
    <div ng-controller="ParentController">
        Family: {{ family }} (Parent level)
        <button ng-click="updateFamily()">Change Family Name</button>
        
        <div ng-controller="ChildController">
            Family: {{ family }} (Child level)
            Values: {{ grandparentValue }}, {{ parentValue }}, {{ childValue }}
        </div>
    </div>
</div>
```

### $scope Methods

```javascript
angular.module('myApp')
    .controller('ScopeMethodsController', function($scope, $timeout) {
        $scope.counter = 0;

        // $watch - Monitor changes
        $scope.$watch('counter', function(newValue, oldValue) {
            console.log('Counter changed from', oldValue, 'to', newValue);
        });

        // $watchCollection - Watch array/object changes
        $scope.items = [1, 2, 3];
        $scope.$watchCollection('items', function(newItems, oldItems) {
            console.log('Items changed');
        });

        // $apply - Manually trigger digest cycle
        setTimeout(function() {
            $scope.$apply(function() {
                $scope.counter++;
            });
        }, 1000);

        // Better: use $timeout instead
        $timeout(function() {
            $scope.counter++;
        }, 2000);

        // $broadcast - Send event down the scope chain
        $scope.notifyChildren = function() {
            $scope.$broadcast('parentEvent', { message: 'Hello children' });
        };

        // $emit - Send event up the scope chain
        $scope.notifyParent = function() {
            $scope.$emit('childEvent', { message: 'Hello parent' });
        };

        // Listen for events
        $scope.$on('parentEvent', function(event, data) {
            console.log('Received from parent:', data.message);
        });
    });
```

## Data Binding

Data binding is the automatic synchronization of data between the model and view components.

### One-Way Binding

```html
<!-- Expression binding (one-way) -->
<p>{{ user.name }}</p>

<!-- Bind once (one-time binding) -->
<p>{{ ::user.name }}</p>

<!-- Attribute binding -->
<img ng-src="{{ user.avatar }}">
<a ng-href="{{ user.profileUrl }}">Profile</a>

<!-- Class binding -->
<div ng-class="{ 'active': user.isActive, 'premium': user.isPremium }">
    User Status
</div>

<!-- Style binding -->
<div ng-style="{ 'color': user.favoriteColor, 'font-size': fontSize + 'px' }">
    Styled Text
</div>
```

### Two-Way Binding

```javascript
angular.module('myApp')
    .controller('BindingController', function($scope) {
        $scope.user = {
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@example.com',
            bio: 'Software developer',
            subscribe: true,
            country: 'USA',
            favoriteColor: 'blue'
        };

        $scope.countries = ['USA', 'UK', 'Canada', 'Australia'];
        $scope.colors = ['red', 'blue', 'green', 'yellow'];
    });
```

```html
<div ng-controller="BindingController">
    <!-- Text input -->
    <input type="text" ng-model="user.firstName">
    <p>Hello, {{ user.firstName }}!</p>

    <!-- Textarea -->
    <textarea ng-model="user.bio"></textarea>
    <p>Bio: {{ user.bio }}</p>

    <!-- Checkbox -->
    <label>
        <input type="checkbox" ng-model="user.subscribe">
        Subscribe to newsletter
    </label>
    <p>Subscribed: {{ user.subscribe }}</p>

    <!-- Radio buttons -->
    <label ng-repeat="color in colors">
        <input type="radio" ng-model="user.favoriteColor" ng-value="color">
        {{ color }}
    </label>
    <p>Favorite color: {{ user.favoriteColor }}</p>

    <!-- Select dropdown -->
    <select ng-model="user.country" ng-options="country for country in countries">
        <option value="">Select a country</option>
    </select>
    <p>Country: {{ user.country }}</p>

    <!-- Multiple select -->
    <select ng-model="user.languages" multiple
            ng-options="lang for lang in ['JavaScript', 'Python', 'Java', 'C++']">
    </select>
    <p>Languages: {{ user.languages }}</p>
</div>
```

### ng-model Options

```html
<div ng-controller="OptionsController">
    <!-- Debounce input -->
    <input type="text" 
           ng-model="searchQuery"
           ng-model-options="{ debounce: 500 }">
    
    <!-- Update on blur instead of on change -->
    <input type="text"
           ng-model="username"
           ng-model-options="{ updateOn: 'blur' }">
    
    <!-- Combine options -->
    <input type="text"
           ng-model="email"
           ng-model-options="{ 
               updateOn: 'default blur',
               debounce: { 'default': 500, 'blur': 0 }
           }">
    
    <!-- Get reference to the form controller -->
    <input type="text"
           ng-model="data"
           ng-model-options="{ allowInvalid: true }">
</div>
```

## Expressions

Expressions are JavaScript-like code snippets that are evaluated in the context of the current scope.

### Basic Expressions

```html
<div ng-controller="ExpressionController">
    <!-- Simple expressions -->
    <p>{{ 1 + 1 }}</p>
    <p>{{ 'Hello ' + 'World' }}</p>
    <p>{{ user.firstName + ' ' + user.lastName }}</p>

    <!-- Mathematical operations -->
    <p>Total: {{ price * quantity }}</p>
    <p>Tax: {{ price * quantity * 0.1 }}</p>
    <p>Grand Total: {{ (price * quantity) * 1.1 }}</p>

    <!-- Ternary operator -->
    <p>{{ age >= 18 ? 'Adult' : 'Minor' }}</p>
    <p>{{ isLoggedIn ? 'Welcome ' + username : 'Please login' }}</p>

    <!-- Array access -->
    <p>First item: {{ items[0] }}</p>
    <p>Last item: {{ items[items.length - 1] }}</p>

    <!-- Object access -->
    <p>{{ user.address.city }}</p>
    <p>{{ user['email'] }}</p>

    <!-- Function calls -->
    <p>{{ getFullName() }}</p>
    <p>{{ formatDate(user.birthday) }}</p>
</div>
```

### Expression Limitations

```javascript
// These WON'T work in expressions:
// - Conditionals (if/else)
// - Loops (for, while)
// - Throw statements
// - Bitwise operators
// - new, var, return keywords

// Instead, use controller functions
angular.module('myApp')
    .controller('ExpressionController', function($scope) {
        $scope.items = [1, 2, 3, 4, 5];

        // Good: Use controller function for complex logic
        $scope.getEvenNumbers = function() {
            return $scope.items.filter(function(item) {
                return item % 2 === 0;
            });
        };

        $scope.calculateDiscount = function(price, discountPercent) {
            if (price > 100) {
                return price * (discountPercent / 100);
            }
            return 0;
        };
    });
```

## Dependency Injection

Dependency Injection (DI) is a design pattern that deals with how components get their dependencies.

### Understanding DI

```javascript
// Without DI (tightly coupled)
function UserController() {
    this.http = new HttpService();
    this.storage = new StorageService();
}

// With DI (loosely coupled)
function UserController($http, $localStorage) {
    this.http = $http;
    this.storage = $localStorage;
}
```

### Injection Methods

#### 1. Implicit Annotation (Not recommended for production)

```javascript
angular.module('myApp')
    .controller('UserController', function($scope, $http, $timeout) {
        // Will break with minification!
    });
```

#### 2. Inline Array Annotation (Safe for minification)

```javascript
angular.module('myApp')
    .controller('UserController', [
        '$scope',
        '$http',
        '$timeout',
        function($scope, $http, $timeout) {
            $scope.loadData = function() {
                $http.get('/api/users')
                    .then(function(response) {
                        $timeout(function() {
                            $scope.users = response.data;
                        }, 100);
                    });
            };
        }
    ]);
```

#### 3. $inject Property (Recommended)

```javascript
angular.module('myApp')
    .controller('UserController', UserController);

UserController.$inject = ['$scope', '$http', '$timeout'];

function UserController($scope, $http, $timeout) {
    $scope.loadData = function() {
        $http.get('/api/users')
            .then(function(response) {
                $timeout(function() {
                    $scope.users = response.data;
                }, 100);
            });
    };
}
```

### Common Injectable Services

```javascript
angular.module('myApp')
    .controller('ServicesController', ServicesController);

ServicesController.$inject = [
    '$scope',      // Scope object
    '$http',       // HTTP requests
    '$timeout',    // Delayed execution
    '$interval',   // Periodic execution
    '$q',          // Promises
    '$window',     // Window object
    '$document',   // Document object
    '$location',   // URL in the address bar
    '$route',      // Current route
    '$routeParams',// Route parameters
    '$filter',     // Filters
    '$log'         // Logging
];

function ServicesController($scope, $http, $timeout, $interval, $q, 
                          $window, $document, $location, $route, 
                          $routeParams, $filter, $log) {
    
    var vm = this;

    // $http - Make HTTP requests
    vm.loadUsers = function() {
        $http.get('/api/users').then(function(response) {
            vm.users = response.data;
        });
    };

    // $timeout - Delay execution
    vm.delayedAction = function() {
        $timeout(function() {
            vm.message = 'This appeared after 2 seconds';
        }, 2000);
    };

    // $interval - Periodic execution
    var counter = 0;
    var intervalPromise = $interval(function() {
        vm.counter = counter++;
    }, 1000);

    // Clean up interval
    $scope.$on('$destroy', function() {
        $interval.cancel(intervalPromise);
    });

    // $q - Promises
    vm.asyncOperation = function() {
        var deferred = $q.defer();
        
        $timeout(function() {
            deferred.resolve('Operation completed');
        }, 1000);

        return deferred.promise;
    };

    // $window - Browser window
    vm.redirectToGoogle = function() {
        $window.location.href = 'https://google.com';
    };

    vm.getWindowSize = function() {
        return {
            width: $window.innerWidth,
            height: $window.innerHeight
        };
    };

    // $location - URL manipulation
    vm.getCurrentPath = function() {
        return $location.path();
    };

    vm.navigateTo = function(path) {
        $location.path(path);
    };

    // $filter - Use filters in controller
    vm.filteredDate = $filter('date')(new Date(), 'yyyy-MM-dd');
    vm.uppercased = $filter('uppercase')('hello world');

    // $log - Logging
    $log.info('Controller initialized');
    $log.debug('Debug information');
    $log.warn('Warning message');
    $log.error('Error message');
}
```

## The Digest Cycle

Understanding the digest cycle is crucial for building performant AngularJS applications.

### How It Works

```
User Action → $apply() → $digest() → Watchers → Update View
```

### Manual Digest Triggering

```javascript
angular.module('myApp')
    .controller('DigestController', function($scope, $timeout) {
        var vm = this;

        // Automatic $apply (AngularJS built-in directives)
        vm.autoUpdate = function() {
            vm.message = 'Updated automatically';
            // No need to call $apply
        };

        // Manual $apply (non-Angular events)
        setTimeout(function() {
            $scope.$apply(function() {
                vm.message = 'Updated with $apply';
            });
        }, 1000);

        // Use $timeout instead (automatically calls $apply)
        $timeout(function() {
            vm.message = 'Updated with $timeout';
        }, 2000);

        // External library integration
        $(document).on('customEvent', function() {
            $scope.$apply(function() {
                vm.eventTriggered = true;
            });
        });
    });
```

### Watchers

```javascript
angular.module('myApp')
    .controller('WatcherController', function($scope) {
        $scope.user = {
            name: 'John',
            age: 30,
            address: {
                city: 'New York'
            }
        };

        // Simple watch (reference check)
        $scope.$watch('user.name', function(newValue, oldValue) {
            if (newValue !== oldValue) {
                console.log('Name changed to:', newValue);
            }
        });

        // Watch with comparison function
        $scope.$watch(
            function() { return $scope.user.age; },
            function(newValue, oldValue) {
                console.log('Age changed to:', newValue);
            }
        );

        // Deep watch (compares by value, expensive!)
        $scope.$watch('user', function(newValue, oldValue) {
            console.log('User object changed');
        }, true);

        // Watch collection (for arrays/objects, medium cost)
        $scope.$watchCollection('items', function(newItems, oldItems) {
            console.log('Items array changed');
        });

        // Cleanup watcher
        var unwatch = $scope.$watch('someProperty', function() {
            // ...
        });

        // Later, remove the watcher
        unwatch();
    });
```

## Best Practices

### 1. Use Controller As Syntax

```javascript
// Good
angular.module('myApp')
    .controller('UserController', function() {
        var vm = this;
        vm.name = 'John';
    });
```

```html
<div ng-controller="UserController as vm">
    {{ vm.name }}
</div>
```

### 2. Keep Controllers Thin

```javascript
// Bad - Fat controller
angular.module('myApp')
    .controller('BadController', function($scope, $http) {
        $scope.loadUsers = function() {
            $http.get('/api/users').then(function(response) {
                $scope.users = response.data.map(function(user) {
                    user.fullName = user.firstName + ' ' + user.lastName;
                    return user;
                });
            });
        };
    });

// Good - Thin controller with service
angular.module('myApp')
    .service('UserService', function($http) {
        this.getUsers = function() {
            return $http.get('/api/users')
                .then(function(response) {
                    return response.data.map(transformUser);
                });
        };

        function transformUser(user) {
            user.fullName = user.firstName + ' ' + user.lastName;
            return user;
        }
    })
    .controller('GoodController', function(UserService) {
        var vm = this;
        
        vm.loadUsers = function() {
            UserService.getUsers().then(function(users) {
                vm.users = users;
            });
        };
    });
```

### 3. Use One-Time Binding When Appropriate

```html
<!-- Bad - Creates watcher -->
<p>{{ staticValue }}</p>

<!-- Good - No watcher, better performance -->
<p>{{ ::staticValue }}</p>
```

### 4. Avoid $scope When Possible

```javascript
// Use Controller As instead of $scope
// Only use $scope for:
// - $watch, $emit, $broadcast
// - Event handling
```

### 5. Clean Up Resources

```javascript
angular.module('myApp')
    .controller('CleanupController', function($scope, $interval) {
        var vm = this;
        
        var intervalPromise = $interval(function() {
            vm.counter++;
        }, 1000);

        // Always clean up
        $scope.$on('$destroy', function() {
            $interval.cancel(intervalPromise);
        });
    });
```

## Practice Exercise

Create a contact management application with the following features:

```javascript
angular.module('contactApp', [])
    .controller('ContactController', ContactController);

ContactController.$inject = ['$scope', '$filter'];

function ContactController($scope, $filter) {
    var vm = this;
    
    vm.contacts = [];
    vm.newContact = {};
    vm.searchQuery = '';
    
    vm.addContact = addContact;
    vm.removeContact = removeContact;
    vm.editContact = editContact;
    vm.getFilteredContacts = getFilteredContacts;

    activate();

    function activate() {
        vm.contacts = [
            { name: 'John Doe', email: 'john@example.com', phone: '123-456-7890' },
            { name: 'Jane Smith', email: 'jane@example.com', phone: '098-765-4321' }
        ];
    }

    function addContact() {
        if (vm.newContact.name && vm.newContact.email) {
            vm.contacts.push(angular.copy(vm.newContact));
            vm.newContact = {};
        }
    }

    function removeContact(index) {
        vm.contacts.splice(index, 1);
    }

    function editContact(contact) {
        vm.editingContact = angular.copy(contact);
    }

    function getFilteredContacts() {
        return $filter('filter')(vm.contacts, vm.searchQuery);
    }
}
```

## Next Steps

Continue to [03-Directives-Basics](./03-Directives-Basics.md) to learn about built-in directives and how to use them effectively.
