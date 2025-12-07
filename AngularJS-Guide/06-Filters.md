# Part 6: Filters

## What are Filters?

Filters format the value of an expression for display to the user. They can be used in view templates, controllers, or services.

## Built-in Filters

### currency

Format numbers as currency.

```html
<div ng-controller="FilterCtrl as vm">
    <p>{{ vm.price | currency }}</p>
    <!-- Output: $1,234.56 -->

    <p>{{ vm.price | currency:'€' }}</p>
    <!-- Output: €1,234.56 -->

    <p>{{ vm.price | currency:'£':0 }}</p>
    <!-- Output: £1,235 (rounded) -->
</div>
```

### date

Format dates.

```html
<div ng-controller="FilterCtrl as vm">
    <p>{{ vm.today | date }}</p>
    <!-- Output: Jan 15, 2024 -->

    <p>{{ vm.today | date:'short' }}</p>
    <!-- Output: 1/15/24 3:30 PM -->

    <p>{{ vm.today | date:'medium' }}</p>
    <!-- Output: Jan 15, 2024 3:30:45 PM -->

    <p>{{ vm.today | date:'longDate' }}</p>
    <!-- Output: January 15, 2024 -->

    <p>{{ vm.today | date:'yyyy-MM-dd' }}</p>
    <!-- Output: 2024-01-15 -->

    <p>{{ vm.today | date:'HH:mm:ss' }}</p>
    <!-- Output: 15:30:45 -->

    <p>{{ vm.today | date:'EEEE, MMMM d, y' }}</p>
    <!-- Output: Monday, January 15, 2024 -->
</div>
```

**Common Date Format Patterns:**
- `yyyy` - 4 digit year
- `yy` - 2 digit year
- `MMMM` - Full month name
- `MMM` - Short month name
- `MM` - Month number
- `dd` - Day of month
- `EEEE` - Full day name
- `EEE` - Short day name
- `HH` - Hour (24h format)
- `hh` - Hour (12h format)
- `mm` - Minutes
- `ss` - Seconds

### filter

Filter arrays based on criteria.

```html
<div ng-controller="FilterCtrl as vm">
    <!-- String filter -->
    <input ng-model="vm.searchText">
    <ul>
        <li ng-repeat="user in vm.users | filter:vm.searchText">
            {{ user.name }}
        </li>
    </ul>

    <!-- Object filter -->
    <ul>
        <li ng-repeat="user in vm.users | filter:{name: vm.nameFilter, age: vm.ageFilter}">
            {{ user.name }} - {{ user.age }}
        </li>
    </ul>

    <!-- Function filter -->
    <ul>
        <li ng-repeat="user in vm.users | filter:vm.customFilter">
            {{ user.name }}
        </li>
    </ul>

    <!-- Boolean exact match -->
    <ul>
        <li ng-repeat="user in vm.users | filter:{name: vm.exactName}:true">
            {{ user.name }}
        </li>
    </ul>

    <!-- Negate filter -->
    <ul>
        <li ng-repeat="user in vm.users | filter:!vm.searchText">
            {{ user.name }}
        </li>
    </ul>
</div>
```

```javascript
angular.module('myApp')
    .controller('FilterCtrl', function() {
        var vm = this;

        vm.users = [
            { name: 'John Doe', age: 30, active: true },
            { name: 'Jane Smith', age: 25, active: false },
            { name: 'Bob Johnson', age: 35, active: true }
        ];

        vm.customFilter = function(user) {
            return user.age > 25 && user.active;
        };
    });
```

### json

Convert objects to JSON string.

```html
<div ng-controller="FilterCtrl as vm">
    <pre>{{ vm.user | json }}</pre>
    <!-- Output: Formatted JSON -->

    <pre>{{ vm.user | json:2 }}</pre>
    <!-- Output: JSON with 2-space indentation -->
</div>
```

### limitTo

Limit array or string length.

```html
<div ng-controller="FilterCtrl as vm">
    <!-- Limit array -->
    <ul>
        <li ng-repeat="item in vm.items | limitTo:5">
            {{ item }}
        </li>
    </ul>

    <!-- Limit from end -->
    <ul>
        <li ng-repeat="item in vm.items | limitTo:-3">
            {{ item }}
        </li>
    </ul>

    <!-- Limit string -->
    <p>{{ vm.longText | limitTo:100 }}...</p>

    <!-- With offset (AngularJS 1.4+) -->
    <ul>
        <li ng-repeat="item in vm.items | limitTo:5:10">
            {{ item }}
        </li>
    </ul>
</div>
```

### lowercase / uppercase

Convert text case.

```html
<div ng-controller="FilterCtrl as vm">
    <p>{{ vm.text | lowercase }}</p>
    <!-- Output: hello world -->

    <p>{{ vm.text | uppercase }}</p>
    <!-- Output: HELLO WORLD -->
</div>
```

### number

Format numbers.

```html
<div ng-controller="FilterCtrl as vm">
    <p>{{ vm.number | number }}</p>
    <!-- Output: 1,234.568 -->

    <p>{{ vm.number | number:2 }}</p>
    <!-- Output: 1,234.57 -->

    <p>{{ vm.number | number:0 }}</p>
    <!-- Output: 1,235 -->
</div>
```

### orderBy

Sort arrays.

```html
<div ng-controller="FilterCtrl as vm">
    <!-- Sort by property -->
    <ul>
        <li ng-repeat="user in vm.users | orderBy:'name'">
            {{ user.name }}
        </li>
    </ul>

    <!-- Reverse order -->
    <ul>
        <li ng-repeat="user in vm.users | orderBy:'name':true">
            {{ user.name }}
        </li>
    </ul>

    <!-- Sort by multiple properties -->
    <ul>
        <li ng-repeat="user in vm.users | orderBy:['age', 'name']">
            {{ user.name }} - {{ user.age }}
        </li>
    </ul>

    <!-- Custom comparator function -->
    <ul>
        <li ng-repeat="user in vm.users | orderBy:vm.sortFunction">
            {{ user.name }}
        </li>
    </ul>

    <!-- Dynamic sorting -->
    <button ng-click="vm.sortField = 'name'">Sort by Name</button>
    <button ng-click="vm.sortField = 'age'">Sort by Age</button>
    <button ng-click="vm.reverse = !vm.reverse">Toggle Order</button>
    <ul>
        <li ng-repeat="user in vm.users | orderBy:vm.sortField:vm.reverse">
            {{ user.name }} - {{ user.age }}
        </li>
    </ul>
</div>
```

## Creating Custom Filters

### Basic Custom Filter

```javascript
angular.module('myApp')
    .filter('capitalize', function() {
        return function(input) {
            if (!input) return '';
            return input.charAt(0).toUpperCase() + input.slice(1).toLowerCase();
        };
    });
```

```html
<p>{{ 'hello world' | capitalize }}</p>
<!-- Output: Hello world -->
```

### Filter with Parameters

```javascript
angular.module('myApp')
    .filter('truncate', function() {
        return function(input, length, suffix) {
            if (!input) return '';
            
            length = length || 10;
            suffix = suffix || '...';

            if (input.length <= length) {
                return input;
            }

            return input.substring(0, length - suffix.length) + suffix;
        };
    });
```

```html
<p>{{ vm.longText | truncate:50 }}</p>
<p>{{ vm.longText | truncate:50:'...' }}</p>
<p>{{ vm.longText | truncate:100:'[read more]' }}</p>
```

### Advanced Custom Filters

#### Phone Number Filter

```javascript
angular.module('myApp')
    .filter('phoneNumber', function() {
        return function(input, format) {
            if (!input) return '';

            var cleaned = ('' + input).replace(/\D/g, '');
            
            format = format || 'us';

            if (format === 'us') {
                var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
                if (match) {
                    return '(' + match[1] + ') ' + match[2] + '-' + match[3];
                }
            } else if (format === 'international') {
                var match = cleaned.match(/^(\d{1,3})(\d{3})(\d{3})(\d{4})$/);
                if (match) {
                    return '+' + match[1] + ' ' + match[2] + ' ' + match[3] + ' ' + match[4];
                }
            }

            return input;
        };
    });
```

```html
<p>{{ '1234567890' | phoneNumber }}</p>
<!-- Output: (123) 456-7890 -->

<p>{{ '11234567890' | phoneNumber:'international' }}</p>
<!-- Output: +1 123 456 7890 -->
```

#### Time Ago Filter

```javascript
angular.module('myApp')
    .filter('timeAgo', function() {
        return function(input) {
            if (!input) return '';

            var date = new Date(input);
            var now = new Date();
            var seconds = Math.floor((now - date) / 1000);

            var intervals = [
                { label: 'year', seconds: 31536000 },
                { label: 'month', seconds: 2592000 },
                { label: 'week', seconds: 604800 },
                { label: 'day', seconds: 86400 },
                { label: 'hour', seconds: 3600 },
                { label: 'minute', seconds: 60 },
                { label: 'second', seconds: 1 }
            ];

            for (var i = 0; i < intervals.length; i++) {
                var interval = intervals[i];
                var count = Math.floor(seconds / interval.seconds);
                
                if (count >= 1) {
                    return count + ' ' + interval.label + (count > 1 ? 's' : '') + ' ago';
                }
            }

            return 'just now';
        };
    });
```

```html
<p>{{ vm.postDate | timeAgo }}</p>
<!-- Output: 2 hours ago -->
```

#### File Size Filter

```javascript
angular.module('myApp')
    .filter('fileSize', function() {
        return function(bytes, precision) {
            if (bytes === 0) return '0 Bytes';
            if (isNaN(parseFloat(bytes)) || !isFinite(bytes)) return '-';

            precision = precision || 2;

            var units = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
            var number = Math.floor(Math.log(bytes) / Math.log(1024));

            return (bytes / Math.pow(1024, Math.floor(number))).toFixed(precision) + ' ' + units[number];
        };
    });
```

```html
<p>{{ 1024 | fileSize }}</p>
<!-- Output: 1.00 KB -->

<p>{{ 1234567 | fileSize:1 }}</p>
<!-- Output: 1.2 MB -->
```

#### Highlight Filter

```javascript
angular.module('myApp')
    .filter('highlight', function($sce) {
        return function(text, phrase) {
            if (!phrase) return text;
            
            var regex = new RegExp('(' + phrase + ')', 'gi');
            var highlighted = text.replace(regex, '<mark>$1</mark>');
            
            return $sce.trustAsHtml(highlighted);
        };
    });
```

```html
<div ng-bind-html="vm.text | highlight:vm.searchTerm"></div>
```

#### Mask Filter

```javascript
angular.module('myApp')
    .filter('mask', function() {
        return function(input, visibleChars, maskChar) {
            if (!input) return '';

            visibleChars = visibleChars || 4;
            maskChar = maskChar || '*';

            var inputStr = String(input);
            
            if (inputStr.length <= visibleChars) {
                return inputStr;
            }

            var visible = inputStr.slice(-visibleChars);
            var masked = maskChar.repeat(inputStr.length - visibleChars);

            return masked + visible;
        };
    });
```

```html
<p>{{ vm.creditCard | mask:4 }}</p>
<!-- Output: ************1234 -->

<p>{{ vm.ssn | mask:4:'X' }}</p>
<!-- Output: XXXXX1234 -->
```

## Using Filters in Controllers and Services

### $filter Service

```javascript
angular.module('myApp')
    .controller('FilterInControllerCtrl', function($filter) {
        var vm = this;

        vm.users = [
            { name: 'John', age: 30 },
            { name: 'Jane', age: 25 },
            { name: 'Bob', age: 35 }
        ];

        // Use currency filter
        vm.price = 1234.56;
        vm.formattedPrice = $filter('currency')(vm.price);

        // Use date filter
        vm.today = new Date();
        vm.formattedDate = $filter('date')(vm.today, 'yyyy-MM-dd');

        // Use orderBy filter
        vm.sortedUsers = $filter('orderBy')(vm.users, 'age');

        // Use filter filter
        vm.filteredUsers = $filter('filter')(vm.users, { age: 30 });

        // Use custom filter
        vm.capitalizedText = $filter('capitalize')('hello world');

        // Chain multiple filters
        vm.processData = function() {
            var data = vm.users;
            data = $filter('filter')(data, vm.searchQuery);
            data = $filter('orderBy')(data, vm.sortField);
            data = $filter('limitTo')(data, 10);
            return data;
        };
    });
```

## Filter Performance Optimization

### Stateful Filters

By default, filters are stateless. For expensive operations, you can create stateful filters.

```javascript
angular.module('myApp')
    .filter('expensiveFilter', function() {
        function filterFn(input, param) {
            // Expensive operation
            console.log('Running expensive filter');
            
            return input.filter(function(item) {
                return item.value > param;
            });
        }

        // Mark as stateful (will be called every digest)
        filterFn.$stateful = true;

        return filterFn;
    });
```

### Memoization

```javascript
angular.module('myApp')
    .filter('memoizedFilter', function() {
        var cache = {};

        return function(input, param) {
            var cacheKey = JSON.stringify({ input: input, param: param });

            if (cache[cacheKey]) {
                console.log('Returning cached result');
                return cache[cacheKey];
            }

            console.log('Computing result');
            var result = expensiveComputation(input, param);
            cache[cacheKey] = result;

            return result;
        };

        function expensiveComputation(input, param) {
            // Expensive operation
            return input;
        }
    });
```

## Chaining Filters

Filters can be chained together.

```html
<div ng-controller="FilterCtrl as vm">
    <!-- Chain multiple filters -->
    <p>{{ vm.text | lowercase | capitalize }}</p>

    <p>{{ vm.price | number:2 | currency }}</p>

    <ul>
        <li ng-repeat="user in vm.users | filter:vm.search | orderBy:'name' | limitTo:5">
            {{ user.name | uppercase }}
        </li>
    </ul>

    <!-- Complex chaining -->
    <p>{{ vm.date | date:'medium' | lowercase }}</p>
</div>
```

## Real-World Filter Examples

### Search and Filter Table

```html
<div ng-controller="TableCtrl as vm">
    <!-- Search -->
    <input type="text" ng-model="vm.searchQuery" placeholder="Search...">

    <!-- Sorting -->
    <button ng-click="vm.sortBy('name')">Sort by Name</button>
    <button ng-click="vm.sortBy('age')">Sort by Age</button>
    <button ng-click="vm.sortBy('email')">Sort by Email</button>

    <!-- Pagination -->
    <select ng-model="vm.pageSize">
        <option value="5">5 per page</option>
        <option value="10">10 per page</option>
        <option value="20">20 per page</option>
    </select>

    <!-- Table -->
    <table>
        <thead>
            <tr>
                <th>Name</th>
                <th>Age</th>
                <th>Email</th>
            </tr>
        </thead>
        <tbody>
            <tr ng-repeat="user in vm.users | filter:vm.searchQuery | orderBy:vm.sortField:vm.reverse | limitTo:vm.pageSize:vm.offset">
                <td>{{ user.name }}</td>
                <td>{{ user.age }}</td>
                <td>{{ user.email }}</td>
            </tr>
        </tbody>
    </table>

    <!-- Pagination controls -->
    <button ng-click="vm.previousPage()" ng-disabled="vm.currentPage === 0">
        Previous
    </button>
    <span>Page {{ vm.currentPage + 1 }}</span>
    <button ng-click="vm.nextPage()">Next</button>
</div>
```

```javascript
angular.module('myApp')
    .controller('TableCtrl', function($filter) {
        var vm = this;

        vm.users = [/* user data */];
        vm.searchQuery = '';
        vm.sortField = 'name';
        vm.reverse = false;
        vm.pageSize = 10;
        vm.currentPage = 0;

        vm.sortBy = function(field) {
            if (vm.sortField === field) {
                vm.reverse = !vm.reverse;
            } else {
                vm.sortField = field;
                vm.reverse = false;
            }
        };

        vm.nextPage = function() {
            vm.currentPage++;
            vm.offset = vm.currentPage * vm.pageSize;
        };

        vm.previousPage = function() {
            if (vm.currentPage > 0) {
                vm.currentPage--;
                vm.offset = vm.currentPage * vm.pageSize;
            }
        };
    });
```

## Best Practices

1. **Keep Filters Pure** - Same input should always produce same output
2. **Avoid Heavy Computations** in filters (called frequently)
3. **Use Filters in Views** for formatting
4. **Use $filter Service** in controllers/services for data manipulation
5. **Name Descriptively** - Clear what the filter does
6. **Document Parameters** - Especially for custom filters
7. **Consider Performance** - Filters run on every digest cycle
8. **Use One-Time Binding** when data doesn't change: `{{ ::data | filter }}`

## Next Steps

Continue to [07-Routing-and-Navigation](./07-Routing-and-Navigation.md) to learn about routing, navigation, and building single-page applications.
