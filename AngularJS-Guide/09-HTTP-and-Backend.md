# Part 9: HTTP and Backend Integration

## $http Service

The `$http` service is Angular JS's primary way to communicate with remote HTTP servers.

### Basic Requests

```javascript
angular.module('myApp')
    .controller('HttpController', function($http) {
        var vm = this;

        // GET request
        $http.get('/api/users')
            .then(function(response) {
                vm.users = response.data;
                console.log('Status:', response.status);
                console.log('Headers:', response.headers());
            })
            .catch(function(error) {
                console.error('Error:', error);
            });

        // GET with parameters
        $http.get('/api/users', {
            params: {
                page: 1,
                limit: 10,
                sort: 'name'
            }
        }).then(function(response) {
            vm.users = response.data;
        });

        // POST request
        vm.createUser = function(user) {
            $http.post('/api/users', user)
                .then(function(response) {
                    console.log('User created:', response.data);
                });
        };

        // PUT request
        vm.updateUser = function(userId, user) {
            $http.put('/api/users/' + userId, user)
                .then(function(response) {
                    console.log('User updated:', response.data);
                });
        };

        // DELETE request
        vm.deleteUser = function(userId) {
            $http.delete('/api/users/' + userId)
                .then(function(response) {
                    console.log('User deleted');
                });
        };

        // PATCH request
        vm.patchUser = function(userId, updates) {
            $http.patch('/api/users/' + userId, updates)
                .then(function(response) {
                    console.log('User patched:', response.data);
                });
        };
    });
```

### Shorthand Methods

```javascript
$http.get(url, config)
$http.post(url, data, config)
$http.put(url, data, config)
$http.delete(url, config)
$http.patch(url, data, config)
$http.head(url, config)
$http.jsonp(url, config)
```

### Full Configuration

```javascript
angular.module('myApp')
    .controller('AdvancedHttpController', function($http) {
        var vm = this;

        $http({
            method: 'POST',
            url: '/api/users',
            data: {
                name: 'John Doe',
                email: 'john@example.com'
            },
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
            },
            params: {
                notify: true
            },
            timeout: 5000,
            transformRequest: function(data) {
                // Transform request data
                return angular.toJson(data);
            },
            transformResponse: function(data) {
                // Transform response data
                return angular.fromJson(data);
            },
            cache: true
        }).then(function(response) {
            console.log('Success:', response);
        }).catch(function(error) {
            console.error('Error:', error);
        });
    });
```

## HTTP Interceptors

Interceptors allow you to globally process HTTP requests and responses.

### Creating an Interceptor

```javascript
angular.module('myApp')
    .factory('AuthInterceptor', function($q, $window, $injector) {
        return {
            // Before request is sent
            request: function(config) {
                console.log('Request:', config);

                // Add auth token
                var token = $window.localStorage.getItem('authToken');
                if (token) {
                    config.headers['Authorization'] = 'Bearer ' + token;
                }

                // Add timestamp
                config.headers['X-Request-Time'] = new Date().toISOString();

                return config;
            },

            // Request error
            requestError: function(rejection) {
                console.error('Request error:', rejection);
                return $q.reject(rejection);
            },

            // Response success
            response: function(response) {
                console.log('Response:', response);

                // Log response time
                var requestTime = new Date(response.config.headers['X-Request-Time']);
                var responseTime = new Date();
                console.log('Response time:', responseTime - requestTime, 'ms');

                return response;
            },

            // Response error
            responseError: function(rejection) {
                console.error('Response error:', rejection);

                // Handle specific errors
                if (rejection.status === 401) {
                    // Unauthorized - redirect to login
                    $window.location.href = '/login';
                } else if (rejection.status === 403) {
                    // Forbidden
                    alert('Access denied');
                } else if (rejection.status === 500) {
                    // Server error
                    alert('Server error occurred');
                }

                // Attempt token refresh for 401
                if (rejection.status === 401) {
                    var $http = $injector.get('$http');
                    var AuthService = $injector.get('AuthService');

                    return AuthService.refreshToken()
                        .then(function(newToken) {
                            // Retry original request with new token
                            rejection.config.headers['Authorization'] = 'Bearer ' + newToken;
                            return $http(rejection.config);
                        })
                        .catch(function() {
                            return $q.reject(rejection);
                        });
                }

                return $q.reject(rejection);
            }
        };
    })
    .config(function($httpProvider) {
        $httpProvider.interceptors.push('AuthInterceptor');
    });
```

### Loading Interceptor

```javascript
angular.module('myApp')
    .factory('LoadingInterceptor', function($q, $rootScope) {
        var requestCount = 0;

        function decrementRequestCount() {
            requestCount--;
            if (requestCount === 0) {
                $rootScope.$broadcast('loading:finished');
            }
        }

        function incrementRequestCount() {
            if (requestCount === 0) {
                $rootScope.$broadcast('loading:started');
            }
            requestCount++;
        }

        return {
            request: function(config) {
                if (config.showLoading !== false) {
                    incrementRequestCount();
                }
                return config;
            },

            requestError: function(rejection) {
                decrementRequestCount();
                return $q.reject(rejection);
            },

            response: function(response) {
                decrementRequestCount();
                return response;
            },

            responseError: function(rejection) {
                decrementRequestCount();
                return $q.reject(rejection);
            }
        };
    })
    .directive('loadingSpinner', function($rootScope) {
        return {
            restrict: 'E',
            template: '<div class="spinner" ng-show="loading">Loading...</div>',
            link: function(scope) {
                scope.loading = false;

                $rootScope.$on('loading:started', function() {
                    scope.loading = true;
                });

                $rootScope.$on('loading:finished', function() {
                    scope.loading = false;
                });
            }
        };
    })
    .config(function($httpProvider) {
        $httpProvider.interceptors.push('LoadingInterceptor');
    });
```

## Promises

AngularJS uses the $q service for promises.

### Basic Promises

```javascript
angular.module('myApp')
    .factory('DataService', function($http, $q) {
        return {
            getData: getData,
            getMultipleData: getMultipleData,
            getSequentialData: getSequentialData
        };

        function getData() {
            var deferred = $q.defer();

            $http.get('/api/data')
                .then(function(response) {
                    deferred.resolve(response.data);
                })
                .catch(function(error) {
                    deferred.reject(error);
                });

            return deferred.promise;
        }

        function getMultipleData() {
            var promises = {
                users: $http.get('/api/users'),
                posts: $http.get('/api/posts'),
                comments: $http.get('/api/comments')
            };

            return $q.all(promises)
                .then(function(results) {
                    return {
                        users: results.users.data,
                        posts: results.posts.data,
                        comments: results.comments.data
                    };
                });
        }

        function getSequentialData() {
            return $http.get('/api/users')
                .then(function(usersResponse) {
                    var userId = usersResponse.data[0].id;
                    return $http.get('/api/users/' + userId + '/posts');
                })
                .then(function(postsResponse) {
                    return postsResponse.data;
                });
        }
    });
```

### Promise Chaining

```javascript
angular.module('myApp')
    .factory('UserService', function($http, $q) {
        return {
            getUserWithPosts: getUserWithPosts
        };

        function getUserWithPosts(userId) {
            var user;

            return $http.get('/api/users/' + userId)
                .then(function(response) {
                    user = response.data;
                    return $http.get('/api/users/' + userId + '/posts');
                })
                .then(function(response) {
                    user.posts = response.data;
                    return $http.get('/api/users/' + userId + '/comments');
                })
                .then(function(response) {
                    user.comments = response.data;
                    return user;
                })
                .catch(function(error) {
                    console.error('Error loading user data:', error);
                    return $q.reject(error);
                });
        }
    });
```

## $resource Service

$resource provides a higher-level abstraction for RESTful APIs.

### Setup

```bash
npm install angular-resource
```

```javascript
angular.module('myApp', ['ngResource']);
```

### Basic Usage

```javascript
angular.module('myApp')
    .factory('User', function($resource) {
        return $resource('/api/users/:id', { id: '@id' }, {
            update: {
                method: 'PUT'
            },
            query: {
                method: 'GET',
                isArray: true
            }
        });
    })
    .controller('UserController', function(User) {
        var vm = this;

        // GET /api/users
        vm.users = User.query();

        // GET /api/users/123
        vm.user = User.get({ id: 123 });

        // POST /api/users
        vm.createUser = function() {
            var newUser = new User({
                name: 'John Doe',
                email: 'john@example.com'
            });

            newUser.$save()
                .then(function(user) {
                    console.log('User created:', user);
                });
        };

        // PUT /api/users/123
        vm.updateUser = function(user) {
            user.$update()
                .then(function(updatedUser) {
                    console.log('User updated:', updatedUser);
                });
        };

        // DELETE /api/users/123
        vm.deleteUser = function(user) {
            user.$delete()
                .then(function() {
                    console.log('User deleted');
                });
        };

        // Alternative class methods
        User.save({ name: 'Jane' }, function(user) {
            console.log('Created:', user);
        });

        User.update({ id: 123 }, { name: 'Updated Name' }, function(user) {
            console.log('Updated:', user);
        });

        User.delete({ id: 123 }, function() {
            console.log('Deleted');
        });
    });
```

### Advanced $resource

```javascript
angular.module('myApp')
    .factory('Post', function($resource) {
        return $resource('/api/posts/:id', { id: '@id' }, {
            update: {
                method: 'PUT'
            },
            publish: {
                method: 'POST',
                url: '/api/posts/:id/publish'
            },
            getByUser: {
                method: 'GET',
                url: '/api/users/:userId/posts',
                isArray: true,
                params: { userId: '@userId' }
            },
            search: {
                method: 'GET',
                url: '/api/posts/search',
                isArray: true
            }
        });
    })
    .controller('PostController', function(Post) {
        var vm = this;

        // Custom actions
        vm.publishPost = function(postId) {
            Post.publish({ id: postId }).$promise
                .then(function(post) {
                    console.log('Post published:', post);
                });
        };

        vm.getUserPosts = function(userId) {
            vm.posts = Post.getByUser({ userId: userId });
        };

        vm.searchPosts = function(query) {
            vm.searchResults = Post.search({ q: query });
        };
    });
```

## Error Handling

### Global Error Handler

```javascript
angular.module('myApp')
    .factory('ErrorService', function($log) {
        return {
            handleError: handleError,
            logError: logError
        };

        function handleError(error) {
            var message = getErrorMessage(error);
            
            // Log to console
            $log.error('Error:', message, error);

            // Could send to remote logging service
            // sendToLoggingService(error);

            // Display to user
            alert('An error occurred: ' + message);
        }

        function logError(error) {
            var message = getErrorMessage(error);
            $log.error(message, error);
        }

        function getErrorMessage(error) {
            if (error.data && error.data.message) {
                return error.data.message;
            }
            
            if (error.statusText) {
                return error.statusText;
            }

            if (error.message) {
                return error.message;
            }

            return 'An unknown error occurred';
        }
    })
    .factory('ErrorInterceptor', function($q, ErrorService) {
        return {
            responseError: function(rejection) {
                ErrorService.logError(rejection);
                return $q.reject(rejection);
            }
        };
    })
    .config(function($httpProvider) {
        $httpProvider.interceptors.push('ErrorInterceptor');
    });
```

### Retry Logic

```javascript
angular.module('myApp')
    .factory('RetryService', function($http, $q, $timeout) {
        return {
            request: requestWithRetry
        };

        function requestWithRetry(config, maxRetries) {
            maxRetries = maxRetries || 3;

            function attempt(retriesLeft) {
                return $http(config).catch(function(error) {
                    if (retriesLeft <= 0) {
                        return $q.reject(error);
                    }

                    console.log('Request failed, retrying...', retriesLeft, 'attempts left');

                    return $timeout(function() {
                        return attempt(retriesLeft - 1);
                    }, 1000);
                });
            }

            return attempt(maxRetries);
        }
    });
```

## Caching

### HTTP Cache

```javascript
angular.module('myApp')
    .factory('CachedHttpService', function($http, $cacheFactory) {
        var cache = $cacheFactory('httpCache');

        return {
            get: get,
            clearCache: clearCache
        };

        function get(url, useCache) {
            var config = { url: url };

            if (useCache !== false) {
                config.cache = cache;
            }

            return $http.get(url, config);
        }

        function clearCache() {
            cache.removeAll();
        }
    })
    .run(function($http, $cacheFactory) {
        // Use default cache
        $http.defaults.cache = $cacheFactory('defaultCache');
    });
```

## WebSocket Integration

```javascript
angular.module('myApp')
    .factory('WebSocketService', function($rootScope, $q) {
        var ws;
        var listeners = {};

        return {
            connect: connect,
            send: send,
            on: on,
            off: off,
            disconnect: disconnect
        };

        function connect(url) {
            var deferred = $q.defer();

            ws = new WebSocket(url);

            ws.onopen = function() {
                console.log('WebSocket connected');
                $rootScope.$apply(function() {
                    deferred.resolve();
                });
            };

            ws.onmessage = function(event) {
                var data = JSON.parse(event.data);
                $rootScope.$apply(function() {
                    if (listeners[data.type]) {
                        listeners[data.type].forEach(function(callback) {
                            callback(data.payload);
                        });
                    }
                });
            };

            ws.onerror = function(error) {
                console.error('WebSocket error:', error);
                $rootScope.$apply(function() {
                    deferred.reject(error);
                });
            };

            ws.onclose = function() {
                console.log('WebSocket disconnected');
            };

            return deferred.promise;
        }

        function send(type, payload) {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: type, payload: payload }));
            }
        }

        function on(type, callback) {
            if (!listeners[type]) {
                listeners[type] = [];
            }
            listeners[type].push(callback);
        }

        function off(type, callback) {
            if (listeners[type]) {
                listeners[type] = listeners[type].filter(function(cb) {
                    return cb !== callback;
                });
            }
        }

        function disconnect() {
            if (ws) {
                ws.close();
            }
        }
    });
```

## Best Practices

1. **Use Services** for HTTP logic, not controllers
2. **Handle Errors Globally** with interceptors
3. **Use Promises** for async operations
4. **Implement Retry Logic** for transient errors
5. **Cache Responses** when appropriate
6. **Use Loading Indicators** for better UX
7. **Validate Data** before sending to server
8. **Use $resource** for RESTful APIs
9. **Implement Request Cancellation** when needed
10. **Test HTTP Services** thoroughly

## Next Steps

Continue to [10-Advanced-Patterns](./10-Advanced-Patterns.md) to learn about design patterns, architecture, and advanced techniques for scalable AngularJS applications.
