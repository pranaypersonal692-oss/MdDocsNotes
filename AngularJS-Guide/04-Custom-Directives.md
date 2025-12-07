# Part 4: Custom Directives

## Creating Custom Directives

Custom directives allow you to create reusable components and extend HTML with new functionality.

### Basic Directive Structure

```javascript
angular.module('myApp')
    .directive('myDirective', function() {
        return {
            restrict: 'E',  // Element, Attribute, Class, or Comment
            template: '<div>Hello from directive</div>',
            link: function(scope, element, attrs) {
                // DOM manipulation and event handling
            }
        };
    });
```

```html
<my-directive></my-directive>
```

### Directive Definition Object (DDO)

```javascript
angular.module('myApp')
    .directive('completeDirective', function() {
        return {
            // Restrict types: 'E' (element), 'A' (attribute), 'C' (class), 'M' (comment)
            restrict: 'EA',
            
            // Template
            template: '<div>Inline template</div>',
            // OR
            templateUrl: 'templates/my-directive.html',
            
            // Replace host element (deprecated in 1.3+)
            replace: false,
            
            // Transclude content
            transclude: false,
            
            // Scope options
            scope: false, // Use parent scope
            // OR
            scope: true,  // Inherit parent scope (new scope)
            // OR
            scope: {},    // Isolated scope
            
            // Controller
            controller: function($scope) {},
            controllerAs: 'vm',
            bindToController: false,
            
            // Require other directives
            require: '^parentDirective',
            
            // Compile and Link functions
            compile: function(tElement, tAttrs) {
                return {
                    pre: function(scope, element, attrs) {},
                    post: function(scope, element, attrs) {}
                };
            },
            
            // OR just link function
            link: function(scope, element, attrs, ctrl, transcludeFn) {
                // DOM manipulation
            },
            
            // Priority (default 0)
            priority: 0,
            
            // Terminal
            terminal: false
        };
    });
```

## Directive Restrictions

### Element Directive (E)

```javascript
angular.module('myApp')
    .directive('userCard', function() {
        return {
            restrict: 'E',
            template: `
                <div class="user-card">
                    <h3>{{ name }}</h3>
                    <p>{{ email }}</p>
                </div>
            `,
            scope: {
                name: '@',
                email: '@'
            }
        };
    });
```

```html
<user-card name="John Doe" email="john@example.com"></user-card>
```

### Attribute Directive (A)

```javascript
angular.module('myApp')
    .directive('highlight', function() {
        return {
            restrict: 'A',
            link: function(scope, element, attrs) {
                element.on('mouseenter', function() {
                    element.css('background-color', attrs.highlight || 'yellow');
                });
                
                element.on('mouseleave', function() {
                    element.css('background-color', '');
                });
            }
        };
    });
```

```html
<div highlight="lightblue">Hover over me</div>
```

### Combined (EA)

```javascript
angular.module('myApp')
    .directive('tooltip', function() {
        return {
            restrict: 'EA',  // Can be used as element or attribute
            template: '<span class="tooltip">{{ message }}</span>',
            scope: {
                message: '@'
            }
        };
    });
```

```html
<!-- As element -->
<tooltip message="Helpful tip"></tooltip>

<!-- As attribute -->
<button tooltip message="Click me">Button</button>
```

## Directive Scope

### Shared Scope (scope: false)

Uses parent scope directly.

```javascript
angular.module('myApp')
    .directive('sharedScope', function() {
        return {
            restrict: 'E',
            scope: false,
            template: '<div>Count: {{ count }}</div>',
            link: function(scope) {
                scope.increment = function() {
                    scope.count++;
                };
            }
        };
    });
```

### Inherited Scope (scope: true)

Creates a new scope that inherits from parent.

```javascript
angular.module('myApp')
    .directive('inheritedScope', function() {
        return {
            restrict: 'E',
            scope: true,
            template: '<div>Local count: {{ localCount }}</div>',
            link: function(scope) {
                scope.localCount = 0;
                scope.increment = function() {
                    scope.localCount++;
                };
            }
        };
    });
```

### Isolated Scope (scope: {})

Creates a completely isolated scope with explicit bindings.

```javascript
angular.module('myApp')
    .directive('userProfile', function() {
        return {
            restrict: 'E',
            scope: {
                userId: '@',           // One-way binding (string)
                userName: '=',         // Two-way binding
                onDelete: '&'          // Expression binding (function)
            },
            template: `
                <div class="user-profile">
                    <p>ID: {{ userId }}</p>
                    <p>Name: {{ userName }}</p>
                    <button ng-click="onDelete()">Delete</button>
                </div>
            `
        };
    });
```

```html
<user-profile 
    user-id="123"
    user-name="currentUser.name"
    on-delete="deleteUser(userId)">
</user-profile>
```

### Scope Binding Types

#### @ (One-way string binding)

```javascript
angular.module('myApp')
    .directive('displayText', function() {
        return {
            restrict: 'E',
            scope: {
                text: '@',
                color: '@textColor'  // Different attribute name
            },
            template: '<p style="color: {{ color }}">{{ text }}</p>'
        };
    });
```

```html
<display-text text="Hello World" text-color="red"></display-text>
```

#### = (Two-way binding)

```javascript
angular.module('myApp')
    .directive('editableField', function() {
        return {
            restrict: 'E',
            scope: {
                value: '='
            },
            template: `
                <div>
                    <input ng-model="value">
                    <p>Current value: {{ value }}</p>
                </div>
            `
        };
    });
```

```html
<div ng-controller="MainCtrl as vm">
    <editable-field value="vm.name"></editable-field>
    <p>Parent scope: {{ vm.name }}</p>
</div>
```

#### & (Expression binding)

```javascript
angular.module('myApp')
    .directive('confirmButton', function() {
        return {
            restrict: 'E',
            scope: {
                onConfirm: '&',
                message: '@'
            },
            template: `
                <button ng-click="handleClick()">
                    {{ message || 'Confirm' }}
                </button>
            `,
            link: function(scope) {
                scope.handleClick = function() {
                    if (confirm('Are you sure?')) {
                        scope.onConfirm();
                    }
                };
            }
        };
    });
```

```html
<confirm-button 
    message="Delete User"
    on-confirm="vm.deleteUser()">
</confirm-button>
```

#### < (One-way binding, AngularJS 1.5+)

```javascript
angular.module('myApp')
    .directive('readOnlyDisplay', function() {
        return {
            restrict: 'E',
            scope: {
                data: '<'
            },
            template: '<div>{{ data }}</div>'
        };
    });
```

## Link Function

The link function is used for DOM manipulation and event handling.

```javascript
angular.module('myApp')
    .directive('customButton', function() {
        return {
            restrict: 'E',
            template: '<button>Click me</button>',
            link: function(scope, element, attrs, ctrl, transcludeFn) {
                // scope: Directive's scope
                // element: jqLite/jQuery wrapped element
                // attrs: Element attributes
                // ctrl: Required controller(s)
                // transcludeFn: Transclusion function

                // Add event listener
                element.on('click', function() {
                    console.log('Button clicked');
                    scope.$apply(function() {
                        scope.clickCount++;
                    });
                });

                // Modify element
                element.css({
                    'background-color': attrs.bgColor || 'blue',
                    'color': 'white',
                    'padding': '10px'
                });

                // Watch attribute changes
                attrs.$observe('bgColor', function(newValue) {
                    element.css('background-color', newValue);
                });

                // Cleanup on destroy
                scope.$on('$destroy', function() {
                    element.off('click');
                });
            }
        };
    });
```

### Pre and Post Link

```javascript
angular.module('myApp')
    .directive('linkedDirective', function() {
        return {
            restrict: 'E',
            compile: function(tElement, tAttrs) {
                console.log('Compile phase');

                return {
                    pre: function(scope, element, attrs) {
                        console.log('Pre-link phase');
                        // Runs before child directives are linked
                    },
                    post: function(scope, element, attrs) {
                        console.log('Post-link phase');
                        // Runs after child directives are linked
                        // Most common phase for DOM manipulation
                    }
                };
            }
        };
    });
```

## Directive Controllers

Controllers provide an API for directive-to-directive communication.

```javascript
angular.module('myApp')
    .directive('tabs', function() {
        return {
            restrict: 'E',
            transclude: true,
            scope: {},
            controller: function($scope) {
                var panes = $scope.panes = [];

                $scope.select = function(pane) {
                    angular.forEach(panes, function(p) {
                        p.selected = false;
                    });
                    pane.selected = true;
                };

                this.addPane = function(pane) {
                    if (panes.length === 0) {
                        $scope.select(pane);
                    }
                    panes.push(pane);
                };
            },
            template: `
                <div class="tabs">
                    <ul class="tabs-header">
                        <li ng-repeat="pane in panes" 
                            ng-click="select(pane)"
                            ng-class="{active: pane.selected}">
                            {{ pane.title }}
                        </li>
                    </ul>
                    <div class="tabs-content" ng-transclude></div>
                </div>
            `
        };
    })
    .directive('pane', function() {
        return {
            restrict: 'E',
            require: '^tabs',
            transclude: true,
            scope: {
                title: '@'
            },
            link: function(scope, element, attrs, tabsCtrl) {
                tabsCtrl.addPane(scope);
            },
            template: `
                <div class="pane" ng-show="selected" ng-transclude></div>
            `
        };
    });
```

```html
<tabs>
    <pane title="Tab 1">
        <p>Content for tab 1</p>
    </pane>
    <pane title="Tab 2">
        <p>Content for tab 2</p>
    </pane>
    <pane title="Tab 3">
        <p>Content for tab 3</p>
    </pane>
</tabs>
```

## Transclusion

Transclusion allows you to wrap existing content.

### Basic Transclusion

```javascript
angular.module('myApp')
    .directive('panel', function() {
        return {
            restrict: 'E',
            transclude: true,
            scope: {
                title: '@'
            },
            template: `
                <div class="panel">
                    <div class="panel-header">{{ title }}</div>
                    <div class="panel-body" ng-transclude></div>
                </div>
            `
        };
    });
```

```html
<panel title="User Information">
    <p>Name: John Doe</p>
    <p>Email: john@example.com</p>
</panel>
```

### Multi-slot Transclusion (AngularJS 1.5+)

```javascript
angular.module('myApp')
    .directive('card', function() {
        return {
            restrict: 'E',
            transclude: {
                'header': '?cardHeader',
                'body': 'cardBody',
                'footer': '?cardFooter'
            },
            template: `
                <div class="card">
                    <div class="card-header" ng-transclude="header"></div>
                    <div class="card-body" ng-transclude="body"></div>
                    <div class="card-footer" ng-transclude="footer"></div>
                </div>
            `
        };
    });
```

```html
<card>
    <card-header>
        <h3>Card Title</h3>
    </card-header>
    <card-body>
        <p>Card content goes here</p>
    </card-body>
    <card-footer>
        <button>Action</button>
    </card-footer>
</card>
```

## Component Architecture (AngularJS 1.5+)

The `.component()` method is a simplified way to create directives.

### Basic Component

```javascript
angular.module('myApp')
    .component('userCard', {
        bindings: {
            user: '<',
            onDelete: '&'
        },
        template: `
            <div class="user-card">
                <h3>{{ $ctrl.user.name }}</h3>
                <p>{{ $ctrl.user.email }}</p>
                <button ng-click="$ctrl.onDelete({ user: $ctrl.user })">
                    Delete
                </button>
            </div>
        `,
        controller: function() {
            var ctrl = this;

            ctrl.$onInit = function() {
                console.log('Component initialized');
            };

            ctrl.$onChanges = function(changes) {
                if (changes.user) {
                    console.log('User changed:', changes.user.currentValue);
                }
            };

            ctrl.$onDestroy = function() {
                console.log('Component destroyed');
            };
        }
    });
```

```html
<user-card user="vm.currentUser" on-delete="vm.handleDelete(user)"></user-card>
```

### Component Lifecycle Hooks

```javascript
angular.module('myApp')
    .component('lifecycleExample', {
        bindings: {
            data: '<'
        },
        controller: function($element, $timeout) {
            var ctrl = this;

            // Called when bindings are initialized
            ctrl.$onInit = function() {
                console.log('1. $onInit - Component initialized');
                ctrl.localData = angular.copy(ctrl.data);
            };

            // Called when bindings change
            ctrl.$onChanges = function(changesObj) {
                console.log('2. $onChanges - Bindings changed', changesObj);
                
                if (changesObj.data && !changesObj.data.isFirstChange()) {
                    ctrl.localData = angular.copy(changesObj.data.currentValue);
                }
            };

            // Called after $onInit and $onChanges
            ctrl.$doCheck = function() {
                // Called on every digest cycle
                // Use sparingly for performance
            };

            // Called after all child links are created
            ctrl.$postLink = function() {
                console.log('3. $postLink - DOM ready');
                $element.find('button').on('click', function() {
                    console.log('Button clicked');
                });
            };

            // Called when component is destroyed
            ctrl.$onDestroy = function() {
                console.log('4. $onDestroy - Cleanup');
                $element.find('button').off('click');
            };
        },
        template: `
            <div>
                <p>{{ $ctrl.localData }}</p>
                <button>Click</button>
            </div>
        `
    });
```

## Real-World Examples

### Dropdown Component

```javascript
angular.module('myApp')
    .component('dropdown', {
        bindings: {
            options: '<',
            selected: '=',
            onSelect: '&',
            placeholder: '@'
        },
        template: `
            <div class="dropdown" ng-class="{ 'open': $ctrl.isOpen }">
                <button class="dropdown-toggle" ng-click="$ctrl.toggle()">
                    {{ $ctrl.getDisplayText() }}
                    <span class="caret"></span>
                </button>
                <ul class="dropdown-menu" ng-show="$ctrl.isOpen">
                    <li ng-repeat="option in $ctrl.options"
                        ng-click="$ctrl.selectOption(option)">
                        {{ option.label || option }}
                    </li>
                </ul>
            </div>
        `,
        controller: function($document, $element, $scope) {
            var ctrl = this;

            ctrl.isOpen = false;

            ctrl.toggle = function() {
                ctrl.isOpen = !ctrl.isOpen;
            };

            ctrl.selectOption = function(option) {
                ctrl.selected = option;
                ctrl.isOpen = false;
                ctrl.onSelect({ option: option });
            };

            ctrl.getDisplayText = function() {
                if (ctrl.selected) {
                    return ctrl.selected.label || ctrl.selected;
                }
                return ctrl.placeholder || 'Select...';
            };

            // Close dropdown when clicking outside
            var documentClickHandler = function(event) {
                if (!$element[0].contains(event.target)) {
                    $scope.$apply(function() {
                        ctrl.isOpen = false;
                    });
                }
            };

            ctrl.$postLink = function() {
                $document.on('click', documentClickHandler);
            };

            ctrl.$onDestroy = function() {
                $document.off('click', documentClickHandler);
            };
        }
    });
```

### Modal Component

```javascript
angular.module('myApp')
    .component('modal', {
        transclude: {
            'header': '?modalHeader',
            'body': 'modalBody',
            'footer': '?modalFooter'
        },
        bindings: {
            isOpen: '=',
            onClose: '&'
        },
        template: `
            <div class="modal-backdrop" ng-if="$ctrl.isOpen" ng-click="$ctrl.close()"></div>
            <div class="modal" ng-if="$ctrl.isOpen">
                <div class="modal-content" ng-click="$event.stopPropagation()">
                    <div class="modal-header">
                        <ng-transclude ng-transclude-slot="header"></ng-transclude>
                        <button class="close" ng-click="$ctrl.close()">&times;</button>
                    </div>
                    <div class="modal-body" ng-transclude="body"></div>
                    <div class="modal-footer" ng-transclude="footer"></div>
                </div>
            </div>
        `,
        controller: function() {
            var ctrl = this;

            ctrl.close = function() {
                ctrl.isOpen = false;
                ctrl.onClose();
            };
        }
    });
```

```html
<modal is-open="vm.showModal" on-close="vm.handleClose()">
    <modal-header>
        <h3>Confirm Action</h3>
    </modal-header>
    <modal-body>
        <p>Are you sure you want to proceed?</p>
    </modal-body>
    <modal-footer>
        <button ng-click="vm.confirm()">Confirm</button>
        <button ng-click="vm.showModal = false">Cancel</button>
    </modal-footer>
</modal>
```

## Best Practices

1. **Use Components over Directives** (AngularJS 1.5+)
2. **Use Isolated Scope** for reusable directives
3. **Keep Link Functions Simple** - complex logic belongs in controllers
4. **Clean Up Resources** in `$onDestroy` or `$destroy` event
5. **Use `controllerAs` syntax**
6. **Avoid DOM Manipulation in Controllers**
7. **Use `bindToController`** with isolated scope
8. **Prefix Custom Directives** to avoid conflicts

## Next Steps

Continue to [05-Services-and-DI](./05-Services-and-DI.md) to learn about services, factories, providers, and advanced dependency injection.
