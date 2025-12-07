# Part 8: Forms and Validation

## Form Basics

AngularJS provides powerful form handling and validation capabilities out of the box.

### Basic Form

```html
<form name="userForm" ng-submit="vm.submitForm()" novalidate>
    <div>
        <label>Name:</label>
        <input type="text" name="username" ng-model="vm.user.name" required>
    </div>

    <div>
        <label>Email:</label>
        <input type="email" name="email" ng-model="vm.user.email" required>
    </div>

    <button type="submit">Submit</button>
</form>
```

```javascript
angular.module('myApp')
    .controller('FormController', function() {
        var vm = this;

        vm.user = {};

        vm.submitForm = function() {
            console.log('Form submitted:', vm.user);
        };
    });
```

## Form States

AngularJS tracks form and input states automatically.

### Form Properties

```html
<form name="myForm">
    <!-- Form states -->
    <p>Pristine (not modified): {{ myForm.$pristine }}</p>
    <p>Dirty (modified): {{ myForm.$dirty }}</p>
    <p>Valid: {{ myForm.$valid }}</p>
    <p>Invalid: {{ myForm.$invalid }}</p>
    <p>Submitted: {{ myForm.$submitted }}</p>
    <p>Pending (async validation): {{ myForm.$pending }}</p>
</form>
```

### Input Properties

```html
<form name="userForm">
    <input type="text" name="username" ng-model="vm.username" required>

    <!-- Input states -->
    <p>Pristine: {{ userForm.username.$pristine }}</p>
    <p>Dirty: {{ userForm.username.$dirty }}</p>
    <p>Touched: {{ userForm.username.$touched }}</p>
    <p>Untouched: {{ userForm.username.$untouched }}</p>
    <p>Valid: {{ userForm.username.$valid }}</p>
    <p>Invalid: {{ userForm.username.$invalid }}</p>

    <!-- Validation errors -->
    <p>Required error: {{ userForm.username.$error.required }}</p>
    <p>Email error: {{ userForm.username.$error.email }}</p>
</form>
```

## Built-in Validation

### Required

```html
<input type="text" name="username" ng-model="vm.user.name" required>

<!-- Show error -->
<span ng-show="userForm.username.$error.required && userForm.username.$touched">
    Name is required
</span>
```

### Email

```html
<input type="email" name="email" ng-model="vm.user.email" required>

<span ng-show="userForm.email.$error.email && userForm.email.$touched">
    Invalid email format
</span>
```

### Min/Max Length

```html
<input type="text" 
       name="username" 
       ng-model="vm.user.name"
       ng-minlength="3"
       ng-maxlength="20"
       required>

<span ng-show="userForm.username.$error.minlength">
    Username must be at least 3 characters
</span>

<span ng-show="userForm.username.$error.maxlength">
    Username must not exceed 20 characters
</span>
```

### Min/Max Value

```html
<input type="number"
       name="age"
       ng-model="vm.user.age"
       min="18"
       max="100"
       required>

<span ng-show="userForm.age.$error.min">
    Must be at least 18
</span>

<span ng-show="userForm.age.$error.max">
    Must not exceed 100
</span>
```

### Pattern

```html
<input type="text"
       name="phone"
       ng-model="vm.user.phone"
       ng-pattern="/^\d{3}-\d{3}-\d{4}$/"
       required>

<span ng-show="userForm.phone.$error.pattern">
    Phone must be in format: 123-456-7890
</span>
```

## Complete Form Example

```html
<div ng-controller="RegistrationController as vm">
    <form name="registrationForm" ng-submit="vm.register()" novalidate>
        <!-- Username -->
        <div class="form-group" 
             ng-class="{ 'has-error': registrationForm.username.$invalid && registrationForm.username.$touched }">
            <label>Username:</label>
            <input type="text"
                   name="username"
                   class="form-control"
                   ng-model="vm.user.username"
                   ng-minlength="3"
                   ng-maxlength="20"
                   required>
            
            <div ng-messages="registrationForm.username.$error" 
                 ng-if="registrationForm.username.$touched">
                <div ng-message="required">Username is required</div>
                <div ng-message="minlength">Username must be at least 3 characters</div>
                <div ng-message="maxlength">Username must not exceed 20 characters</div>
            </div>
        </div>

        <!-- Email -->
        <div class="form-group"
             ng-class="{ 'has-error': registrationForm.email.$invalid && registrationForm.email.$touched }">
            <label>Email:</label>
            <input type="email"
                   name="email"
                   class="form-control"
                   ng-model="vm.user.email"
                   required>
            
            <div ng-messages="registrationForm.email.$error"
                 ng-if="registrationForm.email.$touched">
                <div ng-message="required">Email is required</div>
                <div ng-message="email">Invalid email format</div>
            </div>
        </div>

        <!-- Password -->
        <div class="form-group"
             ng-class="{ 'has-error': registrationForm.password.$invalid && registrationForm.password.$touched }">
            <label>Password:</label>
            <input type="password"
                   name="password"
                   class="form-control"
                   ng-model="vm.user.password"
                   ng-minlength="8"
                   required>
            
            <div ng-messages="registrationForm.password.$error"
                 ng-if="registrationForm.password.$touched">
                <div ng-message="required">Password is required</div>
                <div ng-message="minlength">Password must be at least 8 characters</div>
            </div>
        </div>

        <!-- Confirm Password -->
        <div class="form-group"
             ng-class="{ 'has-error': registrationForm.confirmPassword.$invalid && registrationForm.confirmPassword.$touched }">
            <label>Confirm Password:</label>
            <input type="password"
                   name="confirmPassword"
                   class="form-control"
                   ng-model="vm.user.confirmPassword"
                   match-password="vm.user.password"
                   required>
            
            <div ng-messages="registrationForm.confirmPassword.$error"
                 ng-if="registrationForm.confirmPassword.$touched">
                <div ng-message="required">Please confirm your password</div>
                <div ng-message="matchPassword">Passwords do not match</div>
            </div>
        </div>

        <!-- Submit -->
        <button type="submit" 
                class="btn btn-primary"
                ng-disabled="registrationForm.$invalid || vm.isSubmitting">
            {{ vm.isSubmitting ? 'Submitting...' : 'Register' }}
        </button>

        <!-- Form summary -->
        <div ng-show="registrationForm.$submitted && registrationForm.$invalid" 
             class="alert alert-danger">
            Please fix the errors above
        </div>
    </form>
</div>
```

```javascript
angular.module('myApp')
    .controller('RegistrationController', function($http) {
        var vm = this;

        vm.user = {};
        vm.isSubmitting = false;

        vm.register = function() {
            if (registrationForm.$invalid) {
                // Mark all fields as touched to show errors
                angular.forEach(registrationForm.$error, function(field) {
                    angular.forEach(field, function(errorField) {
                        errorField.$setTouched();
                    });
                });
                return;
            }

            vm.isSubmitting = true;

            $http.post('/api/register', vm.user)
                .then(function(response) {
                    console.log('Registration successful');
                    vm.user = {};
                    registrationForm.$setPristine();
                    registrationForm.$setUntouched();
                })
                .catch(function(error) {
                    console.error('Registration failed:', error);
                })
                .finally(function() {
                    vm.isSubmitting = false;
                });
        };
    });
```

## Custom Validators

### Directive-based Validator

```javascript
angular.module('myApp')
    .directive('matchPassword', function() {
        return {
            require: 'ngModel',
            scope: {
                matchPassword: '='
            },
            link: function(scope, element, attrs, ngModel) {
                ngModel.$validators.matchPassword = function(modelValue, viewValue) {
                    var value = modelValue || viewValue;
                    return value === scope.matchPassword;
                };

                // Re-validate when the password changes
                scope.$watch('matchPassword', function() {
                    ngModel.$validate();
                });
            }
        };
    });
```

### Async Validator

```javascript
angular.module('myApp')
    .directive('uniqueUsername', function($http, $q) {
        return {
            require: 'ngModel',
            link: function(scope, element, attrs, ngModel) {
                ngModel.$asyncValidators.uniqueUsername = function(modelValue, viewValue) {
                    var value = modelValue || viewValue;

                    if (!value) {
                        return $q.resolve();
                    }

                    return $http.get('/api/check-username', {
                        params: { username: value }
                    }).then(function(response) {
                        if (response.data.available) {
                            return true;
                        } else {
                            return $q.reject('Username already taken');
                        }
                    });
                };
            }
        };
    });
```

```html
<input type="text"
       name="username"
       ng-model="vm.user.username"
       unique-username
       required>

<span ng-show="registrationForm.username.$pending">
    Checking availability...
</span>

<span ng-show="registrationForm.username.$error.uniqueUsername">
    Username already taken
</span>
```

### Complex Custom Validator

```javascript
angular.module('myApp')
    .directive('strongPassword', function() {
        return {
            require: 'ngModel',
            link: function(scope, element, attrs, ngModel) {
                ngModel.$validators.strongPassword = function(modelValue, viewValue) {
                    var value = modelValue || viewValue;

                    if (!value) {
                        return true; // Let required validator handle empty
                    }

                    var hasUppercase = /[A-Z]/.test(value);
                    var hasLowercase = /[a-z]/.test(value);
                    var hasNumber = /[0-9]/.test(value);
                    var hasSpecial = /[!@#$%^&*]/.test(value);
                    var isLongEnough = value.length >= 8;

                    return hasUppercase && hasLowercase && hasNumber && hasSpecial && isLongEnough;
                };
            }
        };
    });
```

## ng-messages

Enhanced error messaging (requires ngMessages module).

```bash
npm install angular-messages
```

```html
<script src="node_modules/angular-messages/angular-messages.min.js"></script>
```

```javascript
angular.module('myApp', ['ngMessages']);
```

```html
<form name="myForm">
    <input type="text"
           name="username"
           ng-model="vm.username"
           required
           ng-minlength="3"
           ng-maxlength="20">

    <div ng-messages="myForm.username.$error" 
         ng-if="myForm.username.$touched"
         role="alert">
        <div ng-message="required">This field is required</div>
        <div ng-message="minlength">Too short</div>
        <div ng-message="maxlength">Too long</div>
    </div>
</form>
```

### Reusable ng-messages Template

```html
<!-- error-messages.html -->
<div ng-message="required">This field is required</div>
<div ng-message="email">Invalid email format</div>
<div ng-message="minlength">Value is too short</div>
<div ng-message="maxlength">Value is too long</div>
<div ng-message="min">Value is too small</div>
<div ng-message="max">Value is too large</div>
<div ng-message="pattern">Invalid format</div>
```

```html
<form name="myForm">
    <input type="email" name="email" ng-model="vm.email" required>
    
    <div ng-messages="myForm.email.$error" ng-if="myForm.email.$touched">
        <div ng-messages-include="error-messages.html"></div>
    </div>
</form>
```

## Form Manipulation

### Programmatic Validation

```javascript
angular.module('myApp')
    .controller('FormController', function($scope) {
        var vm = this;

        vm.submit = function(form) {
            // Set all fields as touched to show errors
            if (form.$invalid) {
                angular.forEach(form, function(field, fieldName) {
                    if (fieldName[0] !== '$') {
                        field.$setTouched();
                    }
                });
                return;
            }

            // Form is valid, proceed with submission
            console.log('Form submitted');
        };

        vm.reset = function(form) {
            vm.user = {};
            form.$setPristine();
            form.$setUntouched();
        };

        vm.setFieldError = function(form, fieldName, errorKey) {
            form[fieldName].$setValidity(errorKey, false);
        };
    });
```

### Dynamic Forms

```html
<div ng-controller="DynamicFormController as vm">
    <form name="dynamicForm">
        <div ng-repeat="field in vm.fields">
            <label>{{ field.label }}:</label>
            
            <input ng-if="field.type === 'text'"
                   type="text"
                   name="{{ field.name }}"
                   ng-model="vm.formData[field.name]"
                   ng-required="field.required">

            <input ng-if="field.type === 'email'"
                   type="email"
                   name="{{ field.name }}"
                   ng-model="vm.formData[field.name]"
                   ng-required="field.required">

            <select ng-if="field.type === 'select'"
                    name="{{ field.name }}"
                    ng-model="vm.formData[field.name]"
                    ng-options="option.value as option.label for option in field.options"
                    ng-required="field.required">
            </select>

            <div ng-messages="dynamicForm[field.name].$error"
                 ng-if="dynamicForm[field.name].$touched">
                <div ng-message="required">{{ field.label }} is required</div>
                <div ng-message="email">Invalid email format</div>
            </div>
        </div>

        <button ng-click="vm.submit(dynamicForm)">Submit</button>
    </form>
</div>
```

```javascript
angular.module('myApp')
    .controller('DynamicFormController', function() {
        var vm = this;

        vm.fields = [
            {
                name: 'username',
                label: 'Username',
                type: 'text',
                required: true
            },
            {
                name: 'email',
                label: 'Email',
                type: 'email',
                required: true
            },
            {
                name: 'country',
                label: 'Country',
                type: 'select',
                required: true,
                options: [
                    { value: 'us', label: 'United States' },
                    { value: 'uk', label: 'United Kingdom' },
                    { value: 'ca', label: 'Canada' }
                ]
            }
        ];

        vm.formData = {};

        vm.submit = function(form) {
            if (form.$invalid) {
                // Mark all as touched
                Object.keys(vm.formData).forEach(function(key) {
                    if (form[key]) {
                        form[key].$setTouched();
                    }
                });
                return;
            }

            console.log('Form data:', vm.formData);
        };
    });
```

## File Upload

```html
<form name="uploadForm">
    <input type="file" 
           file-model="vm.file"
           accept="image/*">
    
    <button ng-click="vm.upload()"
            ng-disabled="!vm.file">
        Upload
    </button>

    <div ng-if="vm.uploadProgress">
        Uploading: {{ vm.uploadProgress }}%
    </div>
</form>
```

```javascript
angular.module('myApp')
    .directive('fileModel', function($parse) {
        return {
            restrict: 'A',
            link: function(scope, element, attrs) {
                var model = $parse(attrs.fileModel);
                var modelSetter = model.assign;

                element.bind('change', function() {
                    scope.$apply(function() {
                        modelSetter(scope, element[0].files[0]);
                    });
                });
            }
        };
    })
    .controller('UploadController', function($http) {
        var vm = this;

        vm.upload = function() {
            var formData = new FormData();
            formData.append('file', vm.file);

            $http.post('/api/upload', formData, {
                transformRequest: angular.identity,
                headers: { 'Content-Type': undefined },
                uploadEventHandlers: {
                    progress: function(e) {
                        if (e.lengthComputable) {
                            vm.uploadProgress = Math.round((e.loaded / e.total) * 100);
                        }
                    }
                }
            }).then(function(response) {
                console.log('Upload successful');
                vm.uploadProgress = 0;
            }).catch(function(error) {
                console.error('Upload failed:', error);
            });
        };
    });
```

## Best Practices

1. **Always use novalidate** attribute on forms to disable browser validation
2. **Use ng-messages** for cleaner error handling
3. **Show errors only after field is touched**
4. **Disable submit button** when form is invalid
5. **Reset form state** after successful submission
6. **Validate on blur** for better UX
7. **Use custom validators** for business logic
8. **Provide clear error messages**
9. **Handle server-side validation errors**
10. **Test form validation thoroughly**

## Next Steps

Continue to [09-HTTP-and-Backend](./09-HTTP-and-Backend.md) to learn about making HTTP requests, working with APIs, and backend integration.
