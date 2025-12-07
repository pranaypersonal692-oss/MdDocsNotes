# Part 7: Routing and Navigation

## Introduction to Routing

Routing enables navigation between different views in a Single Page Application (SPA) without full page reloads.

AngularJS provides two routing modules:
1. **ngRoute** - Basic routing (official, simpler)
2. **UI-Router** - Advanced routing (community, more powerful)

## ngRoute

### Setup

```bash
npm install angular-route
```

```html
<!DOCTYPE html>
<html ng-app="myApp">
<head>
    <script src="node_modules/angular/angular.min.js"></script>
    <script src="node_modules/angular-route/angular-route.min.js"></script>
</head>
<body>
    <nav>
        <a href="#!/home">Home</a>
        <a href="#!/about">About</a>
        <a href="#!/users">Users</a>
    </nav>

    <div ng-view></div>

    <script src="app.js"></script>
</body>
</html>
```

### Basic Configuration

```javascript
angular.module('myApp', ['ngRoute'])
    .config(function($routeProvider, $locationProvider) {
        $routeProvider
            .when('/home', {
                templateUrl: 'views/home.html',
                controller: 'HomeController',
                controllerAs: 'vm'
            })
            .when('/about', {
                templateUrl: 'views/about.html',
                controller: 'AboutController',
                controllerAs: 'vm'
            })
            .when('/users', {
                templateUrl: 'views/users.html',
                controller: 'UsersController',
                controllerAs: 'vm'
            })
            .when('/users/:id', {
                templateUrl: 'views/user-detail.html',
                controller: 'UserDetailController',
                controllerAs: 'vm'
            })
            .otherwise({
                redirectTo: '/home'
            });

        // Enable HTML5 mode (remove # from URL)
        $locationProvider.html5Mode(true);
    });
```

### Route Parameters

```javascript
angular.module('myApp')
    .controller('UserDetailController', function($routeParams, UserService) {
        var vm = this;

        // Access route parameter
        var userId = $routeParams.id;

        UserService.getById(userId).then(function(user) {
            vm.user = user;
        });
    });
```

```html
<!-- views/user-detail.html -->
<div>
    <h2>{{ vm.user.name }}</h2>
    <p>Email: {{ vm.user.email }}</p>
    <a href="#!/users">Back to Users</a>
</div>
```

### Route Resolve

Load data before route activates.

```javascript
angular.module('myApp')
    .config(function($routeProvider) {
        $routeProvider
            .when('/users/:id', {
                templateUrl: 'views/user-detail.html',
                controller: 'UserDetailController',
                controllerAs: 'vm',
                resolve: {
                    user: function($route, UserService) {
                        var userId = $route.current.params.id;
                        return UserService.getById(userId);
                    },
                    permissions: function(AuthService) {
                        return AuthService.getUserPermissions();
                    }
                }
            });
    })
    .controller('UserDetailController', function(user, permissions) {
        var vm = this;
        
        // Data is already loaded via resolve
        vm.user = user;
        vm.permissions = permissions;
    });
```

### Route Events

```javascript
angular.module('myApp')
    .run(function($rootScope, $location, AuthService) {
        // Before route change
        $rootScope.$on('$routeChangeStart', function(event, next, current) {
            console.log('Route changing from', current, 'to', next);

            // Check authentication
            if (next.requiresAuth && !AuthService.isAuthenticated()) {
                event.preventDefault();
                $location.path('/login');
            }
        });

        // After route change (success)
        $rootScope.$on('$routeChangeSuccess', function(event, current, previous) {
            console.log('Route changed successfully');
            
            // Update page title
            $rootScope.pageTitle = current.$$route.title || 'My App';
        });

        // Route change error
        $rootScope.$on('$routeChangeError', function(event, current, previous, rejection) {
            console.error('Route change error:', rejection);
            $location.path('/error');
        });
    });
```

### $location Service

```javascript
angular.module('myApp')
    .controller('NavigationController', function($location) {
        var vm = this;

        // Get current path
        vm.currentPath = $location.path();

        // Navigate to path
        vm.goToHome = function() {
            $location.path('/home');
        };

        // Navigate with query parameters
        vm.search = function() {
            $location.path('/search').search({ q: vm.query, page: 1 });
        };

        // Get query parameters
        vm.getQueryParams = function() {
            return $location.search();
        };

        // Get URL
        vm.getUrl = function() {
            return $location.absUrl();
        };

        // Replace history (no back button)
        vm.replaceUrl = function() {
            $location.path('/new-path').replace();
        };
    });
```

## UI-Router

UI-Router is more powerful and flexible than ngRoute.

### Setup

```bash
npm install @uirouter/angularjs
```

```html
<script src="node_modules/@uirouter/angularjs/release/angular-ui-router.min.js"></script>
```

### Basic Configuration

```javascript
angular.module('myApp', ['ui.router'])
    .config(function($stateProvider, $urlRouterProvider) {
        // Default route
        $urlRouterProvider.otherwise('/home');

        $stateProvider
            .state('home', {
                url: '/home',
                templateUrl: 'views/home.html',
                controller: 'HomeController',
                controllerAs: 'vm'
            })
            .state('about', {
                url: '/about',
                templateUrl: 'views/about.html',
                controller: 'AboutController',
                controllerAs: 'vm'
            })
            .state('users', {
                url: '/users',
                templateUrl: 'views/users.html',
                controller: 'UsersController',
                controllerAs: 'vm'
            })
            .state('userDetail', {
                url: '/users/:id',
                templateUrl: 'views/user-detail.html',
                controller: 'UserDetailController',
                controllerAs: 'vm'
            });
    });
```

```html
<nav>
    <a ui-sref="home" ui-sref-active="active">Home</a>
    <a ui-sref="about" ui-sref-active="active">About</a>
    <a ui-sref="users" ui-sref-active="active">Users</a>
</nav>

<div ui-view></div>
```

### Nested States

```javascript
angular.module('myApp')
    .config(function($stateProvider) {
        $stateProvider
            .state('app', {
                abstract: true,
                template: `
                    <header>
                        <nav>Navigation</nav>
                    </header>
                    <div ui-view></div>
                    <footer>Footer</footer>
                `
            })
            .state('app.home', {
                url: '/home',
                template: '<h1>Home Page</h1>'
            })
            .state('app.dashboard', {
                url: '/dashboard',
                template: '<div ui-view></div>',
                abstract: true
            })
            .state('app.dashboard.overview', {
                url: '/overview',
                template: '<h2>Dashboard Overview</h2>'
            })
            .state('app.dashboard.analytics', {
                url: '/analytics',
                template: '<h2>Analytics</h2>'
            });
    });
```

### Multiple Named Views

```javascript
angular.module('myApp')
    .config(function($stateProvider) {
        $stateProvider
            .state('dashboard', {
                url: '/dashboard',
                views: {
                    '': {
                        templateUrl: 'views/dashboard-main.html',
                        controller: 'DashboardController'
                    },
                    'sidebar@dashboard': {
                        templateUrl: 'views/dashboard-sidebar.html',
                        controller: 'SidebarController'
                    },
                    'topbar@dashboard': {
                        templateUrl: 'views/dashboard-topbar.html',
                        controller: 'TopbarController'
                    }
                }
            });
    });
```

```html
<!-- views/dashboard-main.html -->
<div>
    <div ui-view="topbar"></div>
    <div class="content-area">
        <div ui-view="sidebar"></div>
        <div class="main">
            Main content
        </div>
    </div>
</div>
```

### State Parameters

```javascript
angular.module('myApp')
    .config(function($stateProvider) {
        $stateProvider
            .state('userDetail', {
                url: '/users/:userId?tab&filter',
                templateUrl: 'views/user-detail.html',
                controller: 'UserDetailController',
                controllerAs: 'vm',
                params: {
                    userId: null,
                    tab: 'profile',  // Default value
                    filter: {
                        value: null,
                        squash: true  // Remove from URL if null
                    }
                }
            });
    })
    .controller('UserDetailController', function($stateParams) {
        var vm = this;

        vm.userId = $stateParams.userId;
        vm.activeTab = $stateParams.tab;
        vm.filter = $stateParams.filter;
    });
```

```html
<!-- Navigate with parameters -->
<a ui-sref="userDetail({ userId: 123, tab: 'settings' })">User Settings</a>
```

### State Resolve

```javascript
angular.module('myApp')
    .config(function($stateProvider) {
        $stateProvider
            .state('userDetail', {
                url: '/users/:userId',
                templateUrl: 'views/user-detail.html',
                controller: 'UserDetailController',
                controllerAs: 'vm',
                resolve: {
                    user: function($stateParams, UserService) {
                        return UserService.getById($stateParams.userId);
                    },
                    posts: function($stateParams, PostService) {
                        return PostService.getByUserId($stateParams.userId);
                    }
                }
            });
    })
    .controller('UserDetailController', function(user, posts) {
        var vm = this;

        vm.user = user;
        vm.posts = posts;
    });
```

### State Events

```javascript
angular.module('myApp')
    .run(function($rootScope, $state, AuthService) {
        // State change start
        $rootScope.$on('$stateChangeStart', function(event, toState, toParams, fromState, fromParams) {
            console.log('Changing state from', fromState.name, 'to', toState.name);

            // Check authentication
            if (toState.data && toState.data.requiresAuth) {
                if (!AuthService.isAuthenticated()) {
                    event.preventDefault();
                    $state.go('login');
                }
            }
        });

        // State change success
        $rootScope.$on('$stateChangeSuccess', function(event, toState, toParams, fromState, fromParams) {
            console.log('State changed successfully to', toState.name);
        });

        // State change error
        $rootScope.$on('$stateChangeError', function(event, toState, toParams, fromState, fromParams, error) {
            console.error('State change error:', error);
            $state.go('error');
        });

        // State not found
        $rootScope.$on('$stateNotFound', function(event, unfoundState, fromState, fromParams) {
            console.error('State not found:', unfoundState.to);
        });
    });
```

### $state Service

```javascript
angular.module('myApp')
    .controller('NavigationController', function($state, $stateParams) {
        var vm = this;

        // Current state
        vm.currentState = $state.current.name;

        // Navigate to state
        vm.goToHome = function() {
            $state.go('home');
        };

        // Navigate with parameters
        vm.goToUser = function(userId) {
            $state.go('userDetail', { userId: userId });
        };

        // Reload current state
        vm.reload = function() {
            $state.reload();
        };

        // Go back
        vm.goBack = function() {
            window.history.back();
        };

        // Check if state is active
        vm.isActive = function(stateName) {
            return $state.is(stateName);
        };

        // Check if state includes (for nested states)
        vm.includes = function(stateName) {
            return $state.includes(stateName);
        };

        // Get state parameters
        vm.getParams = function() {
            return $stateParams;
        };
    });
```

## Advanced Routing Patterns

### Route Guards/Authentication

```javascript
angular.module('myApp')
    .config(function($stateProvider) {
        $stateProvider
            .state('admin', {
                url: '/admin',
                templateUrl: 'views/admin.html',
                controller: 'AdminController',
                data: {
                    requiresAuth: true,
                    requiredRoles: ['admin']
                }
            });
    })
    .run(function($rootScope, $state, AuthService) {
        $rootScope.$on('$stateChangeStart', function(event, toState, toParams) {
            var requiresAuth = toState.data && toState.data.requiresAuth;
            var requiredRoles = toState.data && toState.data.requiredRoles;

            if (requiresAuth && !AuthService.isAuthenticated()) {
                event.preventDefault();
                $state.go('login', { returnTo: toState.name });
                return;
            }

            if (requiredRoles) {
                var hasRole = requiredRoles.some(function(role) {
                    return AuthService.hasRole(role);
                });

                if (!hasRole) {
                    event.preventDefault();
                    $state.go('unauthorized');
                }
            }
        });
    });
```

### Lazy Loading

```javascript
angular.module('myApp')
    .config(function($stateProvider, $ocLazyLoadProvider) {
        $stateProvider
            .state('admin', {
                url: '/admin',
                templateUrl: 'views/admin.html',
                resolve: {
                    loadModule: function($ocLazyLoad) {
                        return $ocLazyLoad.load({
                            name: 'adminModule',
                            files: [
                                'modules/admin/admin.module.js',
                                'modules/admin/admin.controller.js',
                                'modules/admin/admin.service.js'
                            ]
                        });
                    }
                }
            });
    });
```

### Breadcrumbs

```javascript
angular.module('myApp')
    .config(function($stateProvider) {
        $stateProvider
            .state('home', {
                url: '/home',
                template: '<h1>Home</h1>',
                data: {
                    breadcrumb: 'Home'
                }
            })
            .state('users', {
                url: '/users',
                template: '<h1>Users</h1>',
                data: {
                    breadcrumb: 'Users'
                }
            })
            .state('userDetail', {
                url: '/users/:id',
                template: '<h1>User Detail</h1>',
                data: {
                    breadcrumb: function($stateParams, user) {
                        return user.name;
                    }
                },
                resolve: {
                    user: function($stateParams, UserService) {
                        return UserService.getById($stateParams.id);
                    }
                }
            });
    })
    .directive('breadcrumbs', function($state) {
        return {
            restrict: 'E',
            template: `
                <ul class="breadcrumbs">
                    <li ng-repeat="crumb in breadcrumbs">
                        <a ui-sref="{{ crumb.state }}">{{ crumb.label }}</a>
                    </li>
                </ul>
            `,
            link: function(scope) {
                function updateBreadcrumbs() {
                    var breadcrumbs = [];
                    var currentState = $state.$current;

                    while (currentState) {
                        if (currentState.data && currentState.data.breadcrumb) {
                            var label = currentState.data.breadcrumb;
                            
                            if (typeof label === 'function') {
                                label = label(currentState.locals.globals);
                            }

                            breadcrumbs.unshift({
                                label: label,
                                state: currentState.name
                            });
                        }
                        currentState = currentState.parent;
                    }

                    scope.breadcrumbs = breadcrumbs;
                }

                scope.$on('$stateChangeSuccess', updateBreadcrumbs);
                updateBreadcrumbs();
            }
        };
    });
```

## Best Practices

1. **Use UI-Router** for complex applications
2. **Use ngRoute** for simple applications
3. **Organize routes** in separate configuration files
4. **Use resolve** to load data before route activation
5. **Implement route guards** for authentication/authorization
6. **Use HTML5 mode** when possible
7. **Handle route errors** gracefully
8. **Use state parameters** instead of query strings for important data
9. **Keep state names consistent** with URL structure
10. **Document route structure** for team understanding

## Next Steps

Continue to [08-Forms-and-Validation](./08-Forms-and-Validation.md) to learn about form handling, validation, and user input.
