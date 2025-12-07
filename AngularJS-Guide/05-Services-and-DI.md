# Part 5: Services and Dependency Injection

## Understanding Services in AngularJS

Services are singleton objects that provide specific functionality to your application. They are instantiated only once and shared across controllers, directives, and other services.

### Types of Service Recipes

1. **Service** - Constructor function
2. **Factory** - Factory function that returns an object
3. **Provider** - Configurable service
4. **Value** - Simple value object
5. **Constant** - Configuration value available during config phase

## Service vs Factory vs Provider

### Service

Services are instantiated with the `new` keyword. Use when you want a constructor function.

```javascript
angular.module('myApp')
    .service('UserService', function($http) {
        var self = this;

        self.users = [];

        self.getAll = function() {
            return $http.get('/api/users')
                .then(function(response) {
                    self.users = response.data;
                    return self.users;
                });
        };

        self.getById = function(id) {
            return $http.get('/api/users/' + id)
                .then(function(response) {
                    return response.data;
                });
        };

        self.create = function(user) {
            return $http.post('/api/users', user)
                .then(function(response) {
                    self.users.push(response.data);
                    return response.data;
                });
        };

        self.update = function(id, user) {
            return $http.put('/api/users/' + id, user)
                .then(function(response) {
                    var index = self.users.findIndex(function(u) {
                        return u.id === id;
                    });
                    if (index !== -1) {
                        self.users[index] = response.data;
                    }
                    return response.data;
                });
        };

        self.delete = function(id) {
            return $http.delete('/api/users/' + id)
                .then(function() {
                    self.users = self.users.filter(function(u) {
                        return u.id !== id;
                    });
                });
        };
    });
```

### Factory

Factories return an object or function. Most commonly used.

```javascript
angular.module('myApp')
    .factory('ProductService', function($http, $q) {
        var products = [];
        var cache = {};

        return {
            getAll: getAll,
            getById: getById,
            search: search,
            create: create,
            update: update,
            delete: deleteProduct
        };

        function getAll() {
            if (products.length > 0) {
                return $q.resolve(products);
            }

            return $http.get('/api/products')
                .then(function(response) {
                    products = response.data;
                    return products;
                });
        }

        function getById(id) {
            // Check cache first
            if (cache[id]) {
                return $q.resolve(cache[id]);
            }

            return $http.get('/api/products/' + id)
                .then(function(response) {
                    cache[id] = response.data;
                    return response.data;
                });
        }

        function search(query) {
            return $http.get('/api/products/search', {
                params: { q: query }
            }).then(function(response) {
                return response.data;
            });
        }

        function create(product) {
            return $http.post('/api/products', product)
                .then(function(response) {
                    products.push(response.data);
                    cache[response.data.id] = response.data;
                    return response.data;
                });
        }

        function update(id, product) {
            return $http.put('/api/products/' + id, product)
                .then(function(response) {
                    updateLocalData(id, response.data);
                    return response.data;
                });
        }

        function deleteProduct(id) {
            return $http.delete('/api/products/' + id)
                .then(function() {
                    removeFromLocal(id);
                });
        }

        function updateLocalData(id, newData) {
            var index = products.findIndex(function(p) {
                return p.id === id;
            });
            if (index !== -1) {
                products[index] = newData;
            }
            cache[id] = newData;
        }

        function removeFromLocal(id) {
            products = products.filter(function(p) {
                return p.id !== id;
            });
            delete cache[id];
        }
    });
```

### Provider

Providers allow configuration during the config phase. Use when you need to configure your service before it's used.

```javascript
angular.module('myApp')
    .provider('ApiService', function() {
        var apiEndpoint = '/api';
        var apiKey = '';
        var timeout = 5000;

        // Configuration method (available in config phase)
        this.setEndpoint = function(endpoint) {
            apiEndpoint = endpoint;
        };

        this.setApiKey = function(key) {
            apiKey = key;
        };

        this.setTimeout = function(ms) {
            timeout = ms;
        };

        // $get method returns the actual service
        this.$get = function($http, $q) {
            return {
                get: get,
                post: post,
                put: put,
                delete: deleteRequest
            };

            function get(path, params) {
                return makeRequest('GET', path, null, params);
            }

            function post(path, data) {
                return makeRequest('POST', path, data);
            }

            function put(path, data) {
                return makeRequest('PUT', path, data);
            }

            function deleteRequest(path) {
                return makeRequest('DELETE', path);
            }

            function makeRequest(method, path, data, params) {
                var config = {
                    method: method,
                    url: apiEndpoint + path,
                    timeout: timeout,
                    headers: {
                        'X-API-Key': apiKey
                    }
                };

                if (data) {
                    config.data = data;
                }

                if (params) {
                    config.params = params;
                }

                return $http(config)
                    .then(function(response) {
                        return response.data;
                    })
                    .catch(function(error) {
                        console.error('API Error:', error);
                        return $q.reject(error);
                    });
            }
        };
    });

// Configuration
angular.module('myApp')
    .config(function(ApiServiceProvider) {
        ApiServiceProvider.setEndpoint('https://api.example.com');
        ApiServiceProvider.setApiKey('your-api-key-here');
        ApiServiceProvider.setTimeout(10000);
    });
```

### Value

Simple value service for sharing constants or configuration.

```javascript
angular.module('myApp')
    .value('AppConfig', {
        appName: 'My Application',
        version: '1.0.0',
        apiUrl: 'https://api.example.com',
        maxRetries: 3,
        pageSize: 20
    })
    .value('UserRoles', {
        ADMIN: 'admin',
        EDITOR: 'editor',
        VIEWER: 'viewer'
    });
```

### Constant

Constants are available in the config phase.

```javascript
angular.module('myApp')
    .constant('API_ENDPOINTS', {
        USERS: '/api/users',
        PRODUCTS: '/api/products',
        ORDERS: '/api/orders'
    })
    .constant('ERROR_MESSAGES', {
        NETWORK_ERROR: 'Network error occurred',
        UNAUTHORIZED: 'Unauthorized access',
        NOT_FOUND: 'Resource not found'
    });

// Can be injected in config phase
angular.module('myApp')
    .config(function(API_ENDPOINTS) {
        console.log('API Endpoints:', API_ENDPOINTS);
    });
```

## Advanced Service Patterns

### Service with Caching

```javascript
angular.module('myApp')
    .factory('CachedDataService', function($http, $q, $timeout) {
        var cache = {};
        var cacheTimeout = 5 * 60 * 1000; // 5 minutes

        return {
            getData: getData,
            clearCache: clearCache,
            invalidateKey: invalidateKey
        };

        function getData(url, forceRefresh) {
            var now = new Date().getTime();
            
            // Check if cached and not expired
            if (!forceRefresh && cache[url] && (now - cache[url].timestamp < cacheTimeout)) {
                return $q.resolve(cache[url].data);
            }

            // Fetch fresh data
            return $http.get(url).then(function(response) {
                cache[url] = {
                    data: response.data,
                    timestamp: now
                };
                
                // Auto-invalidate after timeout
                $timeout(function() {
                    delete cache[url];
                }, cacheTimeout);

                return response.data;
            });
        }

        function clearCache() {
            cache = {};
        }

        function invalidateKey(url) {
            delete cache[url];
        }
    });
```

### Service with Events

```javascript
angular.module('myApp')
    .factory('EventBusService', function($rootScope) {
        return {
            emit: emit,
            on: on,
            once: once,
            off: off
        };

        function emit(eventName, data) {
            $rootScope.$emit(eventName, data);
        }

        function on(eventName, callback, scope) {
            var handler = $rootScope.$on(eventName, callback);
            
            if (scope) {
                scope.$on('$destroy', handler);
            }
            
            return handler;
        }

        function once(eventName, callback) {
            var handler = $rootScope.$on(eventName, function(event, data) {
                callback(event, data);
                handler(); // Unregister
            });
            return handler;
        }

        function off(handler) {
            handler();
        }
    });
```

### Authentication Service

```javascript
angular.module('myApp')
    .factory('AuthService', function($http, $q, $window, EventBusService) {
        var currentUser = null;
        var token = $window.localStorage.getItem('authToken');

        return {
            login: login,
            logout: logout,
            register: register,
            isAuthenticated: isAuthenticated,
            getCurrentUser: getCurrentUser,
            hasRole: hasRole,
            refreshToken: refreshToken
        };

        function login(credentials) {
            return $http.post('/api/auth/login', credentials)
                .then(function(response) {
                    setAuthData(response.data);
                    EventBusService.emit('user:loggedIn', currentUser);
                    return currentUser;
                })
                .catch(function(error) {
                    return $q.reject(error);
                });
        }

        function logout() {
            return $http.post('/api/auth/logout')
                .finally(function() {
                    clearAuthData();
                    EventBusService.emit('user:loggedOut');
                });
        }

        function register(userData) {
            return $http.post('/api/auth/register', userData)
                .then(function(response) {
                    return response.data;
                });
        }

        function isAuthenticated() {
            return !!token && !!currentUser;
        }

        function getCurrentUser() {
            if (currentUser) {
                return $q.resolve(currentUser);
            }

            if (token) {
                return $http.get('/api/auth/me')
                    .then(function(response) {
                        currentUser = response.data;
                        return currentUser;
                    })
                    .catch(function() {
                        clearAuthData();
                        return $q.reject('Not authenticated');
                    });
            }

            return $q.reject('Not authenticated');
        }

        function hasRole(role) {
            return currentUser && currentUser.roles && currentUser.roles.indexOf(role) !== -1;
        }

        function refreshToken() {
            return $http.post('/api/auth/refresh', { token: token })
                .then(function(response) {
                    token = response.data.token;
                    $window.localStorage.setItem('authToken', token);
                    return token;
                });
        }

        function setAuthData(data) {
            token = data.token;
            currentUser = data.user;
            $window.localStorage.setItem('authToken', token);
        }

        function clearAuthData() {
            token = null;
            currentUser = null;
            $window.localStorage.removeItem('authToken');
        }
    });
```

### Storage Service

```javascript
angular.module('myApp')
    .factory('StorageService', function($window) {
        var storage = $window.localStorage;

        return {
            set: set,
            get: get,
            remove: remove,
            clear: clear,
            has: has
        };

        function set(key, value) {
            try {
                storage.setItem(key, JSON.stringify(value));
                return true;
            } catch (e) {
                console.error('Storage error:', e);
                return false;
            }
        }

        function get(key, defaultValue) {
            try {
                var item = storage.getItem(key);
                return item ? JSON.parse(item) : defaultValue;
            } catch (e) {
                console.error('Storage error:', e);
                return defaultValue;
            }
        }

        function remove(key) {
            storage.removeItem(key);
        }

        function clear() {
            storage.clear();
        }

        function has(key) {
            return storage.getItem(key) !== null;
        }
    });
```

### HTTP Interceptor Service

```javascript
angular.module('myApp')
    .factory('AuthInterceptor', function($q, $window, $injector) {
        return {
            request: function(config) {
                // Add auth token to requests
                var token = $window.localStorage.getItem('authToken');
                if (token) {
                    config.headers['Authorization'] = 'Bearer ' + token;
                }
                return config;
            },

            requestError: function(rejection) {
                console.error('Request error:', rejection);
                return $q.reject(rejection);
            },

            response: function(response) {
                // Handle successful responses
                return response;
            },

            responseError: function(rejection) {
                // Handle errors
                if (rejection.status === 401) {
                    // Unauthorized - redirect to login
                    var AuthService = $injector.get('AuthService');
                    AuthService.logout();
                    $window.location.href = '/login';
                } else if (rejection.status === 403) {
                    // Forbidden
                    console.error('Access denied');
                } else if (rejection.status === 500) {
                    // Server error
                    console.error('Server error');
                }
                
                return $q.reject(rejection);
            }
        };
    })
    .config(function($httpProvider) {
        $httpProvider.interceptors.push('AuthInterceptor');
    });
```

## Service Communication Patterns

### Publisher-Subscriber Pattern

```javascript
angular.module('myApp')
    .factory('PubSubService', function() {
        var subscribers = {};

        return {
            publish: publish,
            subscribe: subscribe,
            unsubscribe: unsubscribe
        };

        function publish(event, data) {
            if (!subscribers[event]) {
                return;
            }

            subscribers[event].forEach(function(callback) {
                callback(data);
            });
        }

        function subscribe(event, callback) {
            if (!subscribers[event]) {
                subscribers[event] = [];
            }

            subscribers[event].push(callback);

            // Return unsubscribe function
            return function() {
                unsubscribe(event, callback);
            };
        }

        function unsubscribe(event, callback) {
            if (!subscribers[event]) {
                return;
            }

            subscribers[event] = subscribers[event].filter(function(cb) {
                return cb !== callback;
            });
        }
    });

// Usage
angular.module('myApp')
    .controller('PublisherCtrl', function(PubSubService) {
        var vm = this;

        vm.sendMessage = function() {
            PubSubService.publish('message:sent', {
                text: vm.message,
                timestamp: new Date()
            });
        };
    })
    .controller('SubscriberCtrl', function($scope, PubSubService) {
        var vm = this;
        vm.messages = [];

        var unsubscribe = PubSubService.subscribe('message:sent', function(data) {
            vm.messages.push(data);
            $scope.$apply(); // Trigger digest if called outside Angular
        });

        $scope.$on('$destroy', unsubscribe);
    });
```

### Promise-based Service

```javascript
angular.module('myApp')
    .factory('DataLoaderService', function($http, $q, $timeout) {
        return {
            loadWithRetry: loadWithRetry,
            loadMultiple: loadMultiple,
            loadSequential: loadSequential
        };

        function loadWithRetry(url, maxRetries) {
            maxRetries = maxRetries || 3;
            
            function attempt(retriesLeft) {
                return $http.get(url)
                    .catch(function(error) {
                        if (retriesLeft <= 0) {
                            return $q.reject(error);
                        }

                        console.log('Retrying... (' + retriesLeft + ' attempts left)');
                        return $timeout(function() {
                            return attempt(retriesLeft - 1);
                        }, 1000);
                    });
            }

            return attempt(maxRetries);
        }

        function loadMultiple(urls) {
            var promises = urls.map(function(url) {
                return $http.get(url);
            });

            return $q.all(promises)
                .then(function(responses) {
                    return responses.map(function(response) {
                        return response.data;
                    });
                });
        }

        function loadSequential(urls) {
            var results = [];

            return urls.reduce(function(promise, url) {
                return promise.then(function() {
                    return $http.get(url);
                }).then(function(response) {
                    results.push(response.data);
                });
            }, $q.resolve()).then(function() {
                return results;
            });
        }
    });
```

## Dependency Injection Deep Dive

### Circular Dependencies

```javascript
// BAD: Circular dependency
angular.module('myApp')
    .factory('ServiceA', function(ServiceB) {
        return {
            doSomething: function() {
                ServiceB.doSomethingElse();
            }
        };
    })
    .factory('ServiceB', function(ServiceA) {
        return {
            doSomethingElse: function() {
                ServiceA.doSomething();
            }
        };
    });

// GOOD: Use $injector to break circular dependency
angular.module('myApp')
    .factory('ServiceA', function($injector) {
        return {
            doSomething: function() {
                var ServiceB = $injector.get('ServiceB');
                ServiceB.doSomethingElse();
            }
        };
    })
    .factory('ServiceB', function() {
        return {
            doSomethingElse: function() {
                // Implementation
            }
        };
    });
```

### Decorator Pattern

```javascript
angular.module('myApp')
    .factory('LoggingService', function() {
        return {
            log: function(message) {
                console.log('[LOG]', message);
            }
        };
    })
    .config(function($provide) {
        $provide.decorator('LoggingService', function($delegate) {
            var originalLog = $delegate.log;

            $delegate.log = function(message) {
                // Add timestamp
                var timestamp = new Date().toISOString();
                originalLog.call(this, timestamp + ' - ' + message);
                
                // Could also send to remote logging service
            };

            return $delegate;
        });
    });
```

## Best Practices

1. **Use Factories** for most services
2. **Use Services** when you need inheritance
3. **Use Providers** only when configuration is needed
4. **Keep Services Focused** - Single Responsibility Principle
5. **Return Promises** for asynchronous operations
6. **Use Dependency Injection** properly
7. **Avoid $rootScope** in services
8. **Name Services Descriptively** (e.g., UserService, not UserData)
9. **Document Public APIs**
10. **Write Testable Code**

## Next Steps

Continue to [06-Filters](./06-Filters.md) to learn about built-in filters and creating custom filters.
