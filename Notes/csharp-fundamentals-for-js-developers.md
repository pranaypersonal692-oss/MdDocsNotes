# C# Fundamentals for JavaScript Developers

## 📚 Table of Contents
1. [Understanding Task and Async/Await](#understanding-task-and-asyncawait)
2. [Generics Explained](#generics-explained)
3. [Class Keywords - virtual, abstract, override, sealed](#class-keywords)
4. [Access Modifiers - public, private, protected, internal](#access-modifiers)
5. [Static vs Instance Members](#static-vs-instance-members)
6. [Interfaces vs Abstract Classes](#interfaces-vs-abstract-classes)
7. [Delegates and Events](#delegates-and-events)
8. [LINQ Deep Dive](#linq-deep-dive)
9. [Nullable Types](#nullable-types)
10. [Collections - List, Array, IEnumerable](#collections)

---

## Understanding Task and Async/Await

### What is Task?

In JavaScript, you have **Promises**:
```javascript
// A Promise represents a future value
const promise = fetch('/api/users');  // Returns Promise<Response>

promise.then(response => {
    console.log(response);
});

// Or with async/await
async function getUsers() {
    const response = await fetch('/api/users'); // Waits for Promise to resolve
    return response.json();
}
```

In C#, **Task** is like a **Promise**:
```csharp
// Task represents an asynchronous operation
Task<HttpResponseMessage> task = httpClient.GetAsync("/api/users");

task.ContinueWith(response => {
    Console.WriteLine(response);
});

// Or with async/await
public async Task<List<User>> GetUsers()
{
    var response = await httpClient.GetAsync("/api/users"); // Waits for Task to complete
    return await response.Content.ReadAsAsync<List<User>>();
}
```

### Task vs Task<T>

**In JavaScript:**
```javascript
// Promise with no return value (like void)
async function logMessage() {
    await someAsyncOperation();
    console.log("Done");
    // No return statement
}

// Promise with return value
async function getUser() {
    const user = await fetchUser();
    return user; // Returns Promise<User>
}
```

**In C#:**
```csharp
// Task with NO return value (like Promise<void>)
public async Task LogMessage()
{
    await SomeAsyncOperation();
    Console.WriteLine("Done");
    // No return statement needed
}

// Task<T> with return value of type T
public async Task<User> GetUser()
{
    var user = await FetchUser();
    return user; // Returns Task<User>
}
```

### Detailed Breakdown:

```csharp
public async Task<User> GetUserByIdAsync(int id)
//│    │     │    │      │                │   │
//│    │     │    │      │                │   └─ Parameter: int id
//│    │     │    │      │                └───── Method name (Async suffix is convention)
//│    │     │    │      └────────────────────── Generic type parameter (return type)
//│    │     │    └───────────────────────────── Task means this is async
//│    │     └────────────────────────────────── "async" keyword enables await
//│    └──────────────────────────────────────── Access modifier
//└───────────────────────────────────────────── Return type (Task<User> = Promise<User>)
{
    // Inside async method, you can use "await"
    var user = await _repository.FindByIdAsync(id);
    //         │
    //         └─ "await" pauses execution until Task completes
    
    return user; // Returns User, but method signature says Task<User>
    //             C# automatically wraps it in Task
}
```

### Common Task Patterns

**1. Task with void (no return):**
```csharp
// JavaScript
async function sendEmail(address) {
    await emailService.send(address);
    // No return
}

// C#
public async Task SendEmailAsync(string address)
{
    await _emailService.SendAsync(address);
    // No return needed
}
```

**2. Task<T> with return value:**
```csharp
// JavaScript
async function calculateSum(a, b) {
    await someAsyncSetup();
    return a + b; // Returns Promise<number>
}

// C#
public async Task<int> CalculateSumAsync(int a, int b)
{
    await SomeAsyncSetup();
    return a + b; // Returns Task<int>
}
```

**3. Synchronous method returning Task (already completed):**
```csharp
// Sometimes you need to return Task but operation is synchronous
public Task<bool> IsValidAsync(string input)
{
    // No await needed, operation is synchronous
    bool isValid = input.Length > 0;
    return Task.FromResult(isValid); // Creates completed Task
}

// JavaScript equivalent
function isValidAsync(input) {
    const isValid = input.length > 0;
    return Promise.resolve(isValid);
}
```

**4. Multiple async operations:**
```csharp
// JavaScript - Run in parallel
async function getData() {
    const [users, products] = await Promise.all([
        fetchUsers(),
        fetchProducts()
    ]);
    return { users, products };
}

// C# - Run in parallel
public async Task<(List<User> users, List<Product> products)> GetDataAsync()
{
    var usersTask = FetchUsersAsync();
    var productsTask = FetchProductsAsync();
    
    // Wait for both to complete
    await Task.WhenAll(usersTask, productsTask);
    
    return (await usersTask, await productsTask);
}
```

### Why Use Task?

**Benefits:**
1. **Non-blocking**: Doesn't block the thread while waiting
2. **Scalability**: Can handle thousands of concurrent operations
3. **Easier error handling**: Try/catch works naturally
4. **Composition**: Easy to combine multiple async operations

**Example - The Difference:**

```csharp
// ❌ BLOCKING (Bad for web servers)
public User GetUser(int id)
{
    // This BLOCKS the thread for 2 seconds
    Thread.Sleep(2000);
    return _repository.FindById(id);
}

// ✅ NON-BLOCKING (Good!)
public async Task<User> GetUserAsync(int id)
{
    // This DOESN'T block - thread can do other work
    await Task.Delay(2000);
    return await _repository.FindByIdAsync(id);
}
```

---

## Generics Explained

### What Are Generics?

Generics allow you to write code that works with **any type**.

**JavaScript (No Generics):**
```javascript
// Have to create separate functions for each type
function findUserById(id) {
    return users.find(u => u.id === id);
}

function findProductById(id) {
    return products.find(p => p.id === id);
}

function findOrderById(id) {
    return orders.find(o => o.id === id);
}

// Lots of duplicate code! 😢
```

**TypeScript (Has Generics):**
```typescript
// Generic function - works with ANY type!
function findById<T>(items: T[], id: number): T | undefined {
    return items.find(item => item.id === id);
}

// Usage
const user = findById<User>(users, 1);        // Returns User | undefined
const product = findById<Product>(products, 1); // Returns Product | undefined
```

**C# (Has Generics):**
```csharp
// Generic method - works with ANY type!
public T? FindById<T>(List<T> items, int id) where T : class
{
    return items.FirstOrDefault(item => item.Id == id);
}

// Usage
var user = FindById<User>(users, 1);        // Returns User?
var product = FindById<Product>(products, 1); // Returns Product?
```

### Generic Classes

**Think of a generic class like a template:**

```csharp
// Generic class definition
public class Box<T>
//              │  │
//              │  └─ T is a "type parameter" (placeholder for any type)
//              └──── Opening bracket for generic
{
    private T _content;
    //      │
    //      └─ T will be replaced with actual type when used
    
    public void Store(T item)
    {
        _content = item;
    }
    
    public T Retrieve()
    {
        return _content;
    }
}

// Usage
Box<int> numberBox = new Box<int>();
//  │                          │
//  └─ T is replaced with int  └─ Create instance with T = int

numberBox.Store(42);         // Can only store int
int number = numberBox.Retrieve(); // Returns int

Box<string> textBox = new Box<string>();
textBox.Store("Hello");      // Can only store string
string text = textBox.Retrieve(); // Returns string
```

**JavaScript Equivalent (Using TypeScript):**
```typescript
class Box<T> {
    private content: T;
    
    store(item: T): void {
        this.content = item;
    }
    
    retrieve(): T {
        return this.content;
    }
}

const numberBox = new Box<number>();
numberBox.store(42);
const number = numberBox.retrieve();
```

### Generic Repository Example (Real-World)

This is what you'll see in ASP.NET Core a LOT:

```csharp
// Generic repository - works with ANY entity type!
public class Repository<T> where T : class
//                    │          │
//                    │          └─ Constraint: T must be a class
//                    └──────────── T represents any entity (User, Product, Order, etc.)
{
    private readonly DbContext _context;
    
    public Repository(DbContext context)
    {
        _context = context;
    }
    
    // Get by ID - works for ANY entity type
    public async Task<T?> GetByIdAsync(int id)
    {
        return await _context.Set<T>().FindAsync(id);
        //                       │
        //                       └─ Set<T> gets the table for type T
    }
    
    // Get all - works for ANY entity type
    public async Task<List<T>> GetAllAsync()
    {
        return await _context.Set<T>().ToListAsync();
    }
    
    // Add - works for ANY entity type
    public async Task<T> AddAsync(T entity)
    {
        await _context.Set<T>().AddAsync(entity);
        return entity;
    }
}

// Usage with different types
var userRepository = new Repository<User>(_context);
var user = await userRepository.GetByIdAsync(1); // Returns User?

var productRepository = new Repository<Product>(_context);
var product = await productRepository.GetByIdAsync(1); // Returns Product?

// ONE class works for ALL entity types! 🎉
```

### Generic Constraints

You can **restrict** what types can be used with generics:

```csharp
// 1. Must be a class (reference type)
public class Repository<T> where T : class
{
    // T can be User, Product, string, etc.
    // T CANNOT be int, bool, DateTime (value types)
}

// 2. Must be a struct (value type)
public class Calculator<T> where T : struct
{
    // T can be int, bool, DateTime
    // T CANNOT be string, User, Product (reference types)
}

// 3. Must have parameterless constructor
public class Factory<T> where T : new()
{
    public T CreateInstance()
    {
        return new T(); // Can create new instances
    }
}

// 4. Must inherit from a specific class
public class AnimalRepository<T> where T : Animal
{
    // T must be Animal or inherit from Animal (Dog, Cat, etc.)
}

// 5. Must implement an interface
public class SortableList<T> where T : IComparable<T>
{
    // T must implement IComparable<T>
}

// 6. Multiple constraints
public class Repository<T> where T : class, IEntity, new()
{
    // T must be:
    // - A class
    // - Implement IEntity interface
    // - Have parameterless constructor
}
```

### Why Use Generics?

**Benefits:**
1. **Code Reuse**: Write once, use with many types
2. **Type Safety**: Compiler checks types at compile-time
3. **Performance**: No boxing/unboxing for value types
4. **IntelliSense**: Better IDE support

**Example - Type Safety:**

```csharp
// Without generics
public class ArrayList
{
    private object[] items; // Can store ANY type
    
    public void Add(object item)
    {
        // Add item
    }
    
    public object Get(int index)
    {
        return items[index]; // Returns object, must cast
    }
}

// Usage - NO type safety!
var list = new ArrayList();
list.Add(42);
list.Add("Hello");
list.Add(new User());

int number = (int)list.Get(0); // Must cast, can fail at runtime!
string text = (string)list.Get(1); // Must cast

// With generics - Type safe!
public class List<T>
{
    private T[] items;
    
    public void Add(T item)
    {
        // Add item
    }
    
    public T Get(int index)
    {
        return items[index]; // Returns T, no cast needed
    }
}

// Usage - FULL type safety!
var numberList = new List<int>();
numberList.Add(42);
// numberList.Add("Hello"); // ❌ Compile error! Can't add string to List<int>

int number = numberList.Get(0); // No cast needed! ✅
```

---

## Class Keywords - virtual, abstract, override, sealed

### 1. virtual - Can Be Overridden

**JavaScript:**
```javascript
class Animal {
    makeSound() {
        return "Some sound";
    }
}

class Dog extends Animal {
    // Override parent method
    makeSound() {
        return "Woof!";
    }
}

const dog = new Dog();
console.log(dog.makeSound()); // "Woof!"
```

In JavaScript, you can **always** override methods. In C#, you must **explicitly allow** it with `virtual`:

**C#:**
```csharp
public class Animal
{
    // virtual = This method CAN be overridden by child classes
    public virtual string MakeSound()
    //     │
    //     └─ "virtual" keyword allows overriding
    {
        return "Some sound";
    }
    
    // Non-virtual = CANNOT be overridden
    public string GetName()
    {
        return "Animal";
    }
}

public class Dog : Animal
{
    // override = This method REPLACES the parent implementation
    public override string MakeSound()
    //     │
    //     └─ "override" keyword replaces virtual method
    {
        return "Woof!";
    }
    
    // ❌ Cannot override GetName() - it's not virtual!
}

// Usage
Animal animal = new Animal();
Console.WriteLine(animal.MakeSound()); // "Some sound"

Dog dog = new Dog();
Console.WriteLine(dog.MakeSound()); // "Woof!"

// Polymorphism - important!
Animal animalRef = new Dog(); // Store Dog in Animal variable
Console.WriteLine(animalRef.MakeSound()); // "Woof!" - calls Dog's version!
```

**Why Use virtual?**

It enables **polymorphism** - treating different types uniformly:

```csharp
public class Cat : Animal
{
    public override string MakeSound()
    {
        return "Meow!";
    }
}

// Polymorphism in action
List<Animal> animals = new List<Animal>
{
    new Dog(),
    new Cat(),
    new Dog()
};

foreach (Animal animal in animals)
{
    Console.WriteLine(animal.MakeSound());
    // Output:
    // Woof!
    // Meow!
    // Woof!
    
    // Each calls its own implementation!
}
```

### 2. abstract - MUST Be Overridden

**abstract** is like a **contract**: child classes MUST implement it.

```csharp
public abstract class Shape
//     │
//     └─ "abstract" class = Cannot create instances directly
{
    // Abstract property - MUST be implemented by child classes
    public abstract double Area { get; }
    //     │
    //     └─ No implementation (no { })
    
    // Abstract method - MUST be implemented
    public abstract void Draw();
    
    // Regular method - CAN be inherited as-is
    public void LogInfo()
    {
        Console.WriteLine($"Area: {Area}");
    }
}

public class Circle : Shape
{
    public double Radius { get; set; }
    
    // MUST override abstract property
    public override double Area
    {
        get { return Math.PI * Radius * Radius; }
    }
    
    // MUST override abstract method
    public override void Draw()
    {
        Console.WriteLine("Drawing a circle");
    }
}

public class Rectangle : Shape
{
    public double Width { get; set; }
    public double Height { get; set; }
    
    public override double Area
    {
        get { return Width * Height; }
    }
    
    public override void Draw()
    {
        Console.WriteLine("Drawing a rectangle");
    }
}

// Usage
// Shape shape = new Shape(); // ❌ ERROR! Cannot create instance of abstract class

Shape circle = new Circle { Radius = 5 };
Console.WriteLine(circle.Area); // 78.54...

Shape rectangle = new Rectangle { Width = 10, Height = 5 };
Console.WriteLine(rectangle.Area); // 50
```

**JavaScript Equivalent (No True Abstract):**
```javascript
class Shape {
    get area() {
        throw new Error("Must override area getter");
    }
    
    draw() {
        throw new Error("Must override draw method");
    }
}

class Circle extends Shape {
    constructor(radius) {
        super();
        this.radius = radius;
    }
    
    get area() {
        return Math.PI * this.radius * this.radius;
    }
    
    draw() {
        console.log("Drawing a circle");
    }
}
```

### 3. sealed - Cannot Be Inherited

**sealed** prevents inheritance:

```csharp
// Cannot be inherited
public sealed class FinalClass
//     │
//     └─ "sealed" = No class can inherit from this
{
    public void DoSomething()
    {
        Console.WriteLine("Doing something");
    }
}

// ❌ ERROR! Cannot inherit from sealed class
public class ChildClass : FinalClass
{
}

// Can also seal individual methods
public class BaseClass
{
    public virtual void Method1()
    {
        Console.WriteLine("Base Method1");
    }
    
    public virtual void Method2()
    {
        Console.WriteLine("Base Method2");
    }
}

public class DerivedClass : BaseClass
{
    // Override and seal - no further overriding allowed
    public sealed override void Method1()
    //     │
    //     └─ Cannot be overridden by children of DerivedClass
    {
        Console.WriteLine("Derived Method1");
    }
    
    // Regular override - can be overridden further
    public override void Method2()
    {
        Console.WriteLine("Derived Method2");
    }
}

public class FurtherDerivedClass : DerivedClass
{
    // ❌ Cannot override Method1 - it's sealed
    
    // ✅ Can override Method2
    public override void Method2()
    {
        Console.WriteLine("Further Derived Method2");
    }
}
```

### Summary Table

| Keyword | Purpose | Can Create Instance? | Can Override? |
|---------|---------|---------------------|--------------|
| **virtual** | Method can be overridden | Yes | Yes (in child classes) |
| **abstract** | Method MUST be overridden | No (abstract class) | Must override |
| **override** | Replaces virtual/abstract method | Yes | Depends on sealed |
| **sealed** | Prevents inheritance/overriding | Yes | No |

---

## Access Modifiers - public, private, protected, internal

Access modifiers control **visibility** - who can see and use your code.

### 1. public - Accessible Everywhere

```csharp
public class User
//│
//└─ Anyone can use this class
{
    public string Name { get; set; }
    //│
    //└─ Anyone can read/write this property
    
    public void Greet()
    //│
    //└─ Anyone can call this method
    {
        Console.WriteLine($"Hello, {Name}");
    }
}

// Anywhere in your code
var user = new User();
user.Name = "John"; // ✅ OK - public property
user.Greet();       // ✅ OK - public method
```

**JavaScript Equivalent:**
```javascript
// All class members are public by default in JS
class User {
    constructor() {
        this.name = ""; // public
    }
    
    greet() { // public
        console.log(`Hello, ${this.name}`);
    }
}
```

### 2. private - Only Within Same Class

```csharp
public class BankAccount
{
    // Private field - only accessible inside this class
    private decimal _balance;
    //│
    //└─ Cannot be accessed from outside
    
    public BankAccount(decimal initialBalance)
    {
        _balance = initialBalance; // ✅ OK - inside class
    }
    
    public void Deposit(decimal amount)
    {
        _balance += amount; // ✅ OK - inside class
    }
    
    private void ValidateAmount(decimal amount)
    //│
    //└─ Private method - only used internally
    {
        if (amount <= 0)
            throw new ArgumentException("Amount must be positive");
    }
    
    public decimal GetBalance()
    {
        return _balance; // ✅ OK - inside class
    }
}

// Outside the class
var account = new BankAccount(1000);
// account._balance = 5000; // ❌ ERROR! _balance is private
// account.ValidateAmount(100); // ❌ ERROR! ValidateAmount is private
account.Deposit(500); // ✅ OK - public method
```

**JavaScript Equivalent (Using # for private):**
```javascript
class BankAccount {
    #balance; // Private field (ES2022+)
    
    constructor(initialBalance) {
        this.#balance = initialBalance;
    }
    
    deposit(amount) {
        this.#balance += amount;
    }
    
    #validateAmount(amount) {
        if (amount <= 0) throw new Error("Amount must be positive");
    }
    
    getBalance() {
        return this.#balance;
    }
}

const account = new BankAccount(1000);
// account.#balance; // ❌ SyntaxError
```

### 3. protected - Within Class and Child Classes

```csharp
public class Animal
{
    protected string _species;
    //│
    //└─ Accessible in Animal and child classes
    
    protected void LogInfo()
    {
        Console.WriteLine($"Species: {_species}");
    }
}

public class Dog : Animal
{
    public Dog()
    {
        _species = "Canine"; // ✅ OK - child can access protected
        LogInfo(); // ✅ OK - child can call protected method
    }
}

// Outside the inheritance chain
var animal = new Animal();
// animal._species = "Unknown"; // ❌ ERROR! protected member
// animal.LogInfo(); // ❌ ERROR! protected method
```

**JavaScript Equivalent (Convention using _):**
```javascript
class Animal {
    constructor() {
        this._species = ""; // Convention: _ means "protected"
    }
    
    _logInfo() {
        console.log(`Species: ${this._species}`);
    }
}

class Dog extends Animal {
    constructor() {
        super();
        this._species = "Canine"; // Can access
        this._logInfo(); // Can call
    }
}
```

### 4. internal - Within Same Assembly/Project

```csharp
// In MyApp.Core project
internal class DatabaseHelper
//│
//└─ Only accessible within MyApp.Core project
{
    internal static string GetConnectionString()
    {
        return "Server=localhost;...";
    }
}

// In MyApp.Core project
var helper = new DatabaseHelper(); // ✅ OK - same project

// In MyApp.API project (different project)
// var helper = new DatabaseHelper(); // ❌ ERROR! internal class
```

**JavaScript:**
JavaScript doesn't have exact equivalent. Think of it like module-scoped:
```javascript
// In database.js
class DatabaseHelper {
    static getConnectionString() {
        return "Server=localhost;...";
    }
}

// Don't export it - only usable in this file
// export default DatabaseHelper; // Commented out = internal-ish
```

### 5. protected internal - Within Assembly OR Child Classes

```csharp
public class BaseClass
{
    protected internal void Method()
    //│        │
    //│        └─ OR accessible to child classes (even in other projects)
    //└────────── Accessible within same project
    {
        Console.WriteLine("Method");
    }
}

// In same project
var obj = new BaseClass();
obj.Method(); // ✅ OK - same project

// In different project, child class
public class ChildClass : BaseClass
{
    public void CallMethod()
    {
        Method(); // ✅ OK - child class
    }
}
```

### Visual Summary

```
┌─────────────────────────────────────────────────┐
│  public class User                              │
│  {                                              │
│      public string Name;           ← Everyone   │
│      private int _age;             ← This class only │
│      protected string _species;    ← This + children │
│      internal bool _flag;          ← Same project │
│      protected internal int _num;  ← Same project OR children │
│  }                                              │
└─────────────────────────────────────────────────┘
```

### Best Practices

```csharp
public class User
{
    // ✅ Good: Private fields (encapsulation)
    private string _firstName;
    private string _lastName;
    
    // ✅ Good: Public properties (controlled access)
    public string FirstName
    {
        get { return _firstName; }
        set
        {
            if (string.IsNullOrEmpty(value))
                throw new ArgumentException("First name cannot be empty");
            _firstName = value;
        }
    }
    
    // ✅ Good: Public methods for actions
    public void UpdateProfile(string firstName, string lastName)
    {
        FirstName = firstName;
        _lastName = lastName;
    }
    
    // ✅ Good: Private helper methods
    private bool ValidateName(string name)
    {
        return !string.IsNullOrEmpty(name);
    }
}
```

---

## Static vs Instance Members

### Instance Members (Default)

**Instance members** belong to each **individual object**:

```csharp
public class Car
{
    // Instance field - each Car has its own color
    private string _color;
    
    // Instance property - each Car has its own speed
    public int Speed { get; set; }
    
    // Instance method - operates on THIS car
    public void Accelerate()
    {
        Speed += 10;
    }
}

// Create multiple instances
Car car1 = new Car { Speed = 50 };
Car car2 = new Car { Speed = 30 };

car1.Accelerate(); // car1.Speed = 60
car2.Accelerate(); // car2.Speed = 40

// Each car has its own Speed value!
```

**JavaScript Equivalent:**
```javascript
class Car {
    constructor() {
        this.speed = 0; // Instance property
    }
    
    accelerate() { // Instance method
        this.speed += 10;
    }
}

const car1 = new Car();
const car2 = new Car();
car1.speed = 50;
car2.speed = 30;

car1.accelerate(); // car1.speed = 60
car2.accelerate(); // car2.speed = 40
```

### Static Members

**Static members** belong to the **class itself**, shared by all instances:

```csharp
public class Car
{
    // Static field - shared by ALL cars
    private static int _totalCarsCreated = 0;
    //      │
    //      └─ "static" = belongs to class, not instance
    
    // Instance property - each car has its own
    public string Model { get; set; }
    
    // Constructor - called when creating new Car
    public Car(string model)
    {
        Model = model;
        _totalCarsCreated++; // Increment shared counter
    }
    
    // Static method - can be called without creating instance
    public static int GetTotalCars()
    //     │
    //     └─ "static" method
    {
        return _totalCarsCreated;
    }
    
    // Static property
    public static string Manufacturer { get; set; } = "Generic Motors";
}

// Usage
Console.WriteLine(Car.GetTotalCars()); // 0 - no cars created yet
//                │
//                └─ Called on CLASS, not instance

var car1 = new Car("Model S");
var car2 = new Car("Model 3");
var car3 = new Car("Model X");

Console.WriteLine(Car.GetTotalCars()); // 3 - shared across all instances
Console.WriteLine(Car.Manufacturer); // "Generic Motors" - shared

// Each instance has its own Model
Console.WriteLine(car1.Model); // "Model S"
Console.WriteLine(car2.Model); // "Model 3"
```

**JavaScript Equivalent:**
```javascript
class Car {
    static totalCarsCreated = 0; // Static field
    static manufacturer = "Generic Motors"; // Static property
    
    constructor(model) {
        this.model = model; // Instance property
        Car.totalCarsCreated++; // Access static through class name
    }
    
    static getTotalCars() { // Static method
        return Car.totalCarsCreated;
    }
}

console.log(Car.getTotalCars()); // 0

const car1 = new Car("Model S");
const car2 = new Car("Model 3");

console.log(Car.getTotalCars()); // 2
console.log(Car.manufacturer); // "Generic Motors"
```

### When to Use Static vs Instance?

**Use Instance (default):**
- Data that varies per object (user name, car color, account balance)
- Methods that operate on specific object data

**Use Static:**
- Utility functions (Math.Max, String.IsNullOrEmpty)
- Constants (Math.PI)
- Factory methods (User.Create())
- Counters/shared state

**Examples:**

```csharp
// Static utility class
public static class StringHelper
//     │
//     └─ Static class = ALL members must be static
{
    public static bool IsValidEmail(string email)
    {
        return email.Contains("@");
    }
    
    public static string Capitalize(string text)
    {
        return char.ToUpper(text[0]) + text.Substring(1);
    }
}

// Usage - no instance needed
bool valid = StringHelper.IsValidEmail("test@example.com");
string name = StringHelper.Capitalize("john");

// Like Math class in both C# and JavaScript
double result = Math.Sqrt(16); // Static method
double pi = Math.PI; // Static property
```

---

## Collections - List, Array, IEnumerable

### Array - Fixed Size

```csharp
// Fixed size - cannot grow or shrink
int[] numbers = new int[3]; // Array of 3 integers
numbers[0] = 10;
numbers[1] = 20;
numbers[2] = 30;

// Or initialize with values
string[] names = new string[] { "John", "Jane", "Bob" };
// Shorthand
string[] names2 = { "John", "Jane", "Bob" };

// Access
Console.WriteLine(names[0]); // "John"
Console.WriteLine(names.Length); // 3

// ❌ Cannot add more items
// names[3] = "Alice"; // IndexOutOfRangeException!
```

**JavaScript Equivalent:**
```javascript
// JavaScript arrays are dynamic, but conceptually:
const numbers = new Array(3);
numbers[0] = 10;
numbers[1] = 20;
numbers[2] = 30;

const names = ["John", "Jane", "Bob"];
console.log(names.length); // 3
```

### List<T> - Dynamic Size

```csharp
// Dynamic size - can grow and shrink
List<int> numbers = new List<int>();
//  │   │
//  │   └─ Generic type parameter
//  └───── List class

// Add items
numbers.Add(10);
numbers.Add(20);
numbers.Add(30);

// Initialize with values
List<string> names = new List<string> { "John", "Jane", "Bob" };

// Access
Console.WriteLine(names[0]); // "John"
Console.WriteLine(names.Count); // 3 (not Length!)

// Add more items
names.Add("Alice");
Console.WriteLine(names.Count); // 4

// Remove items
names.Remove("Jane");
Console.WriteLine(names.Count); // 3

// Useful methods
bool hasJohn = names.Contains("John"); // true
int index = names.IndexOf("Bob"); // 2
names.Clear(); // Remove all
```

**JavaScript Equivalent:**
```javascript
const numbers = [];
numbers.push(10);
numbers.push(20);
numbers.push(30);

const names = ["John", "Jane", "Bob"];
console.log(names.length); // 3

names.push("Alice");
names.splice(names.indexOf("Jane"), 1); // Remove Jane
```

### IEnumerable<T> - Read-Only Sequence

`IEnumerable<T>` is an **interface** for a sequence of items you can iterate over:

```csharp
// IEnumerable = "something you can loop through"
IEnumerable<string> names = new List<string> { "John", "Jane", "Bob" };

// Can iterate
foreach (string name in names)
{
    Console.WriteLine(name);
}

// LINQ methods work on IEnumerable
var filtered = names.Where(n => n.StartsWith("J"));
var count = names.Count();

// ❌ Cannot modify
// names.Add("Alice"); // ERROR! IEnumerable doesn't have Add method
// names[0] = "Mike";  // ERROR! Cannot index IEnumerable
```

**When to use each:**

```csharp
public class UserService
{
    private List<User> _users = new List<User>(); // Private storage
    
    // Return IEnumerable to prevent modification
    public IEnumerable<User> GetAllUsers()
    {
        return _users; // List implements IEnumerable
        // Caller can iterate but not modify
    }
    
    // Method that needs to modify
    private void ProcessUsers(List<User> users)
    {
        users.Add(new User()); // Can modify
    }
    
    // Method that only reads
    private int CountActiveUsers(IEnumerable<User> users)
    {
        return users.Count(u => u.IsActive); // Only read
    }
}
```

### Collection Comparison Table

| Type | Size | Can Modify | Can Index | Use Case |
|------|------|-----------|-----------|----------|
| `T[]` | Fixed | Yes | Yes | Fixed-size data |
| `List<T>` | Dynamic | Yes | Yes | General purpose |
| `IEnumerable<T>` | N/A | No | No | Read-only iteration |
| `IList<T>` | N/A | Yes | Yes | Interface for lists |
| `ICollection<T>` | N/A | Yes | No | Interface for collections |

---

## Quick Reference

### Task
- `Task` = Promise with no return (`Promise<void>`)
- `Task<T>` = Promise with return type T
- `async/await` works same as JavaScript

### Generics
- `<T>` = Works with any type
- `List<User>` = List of Users
- `Repository<T>` = Repository for any entity type

### Class Keywords
- `virtual` = Can override (must opt-in)
- `abstract` = Must override (contract)
- `override` = Replacing parent method
- `sealed` = Cannot inherit/override

### Access Modifiers
- `public` = Everyone can use
- `private` = Only this class
- `protected` = This class + children
- `internal` = Same project only

### Static
- `static` = Belongs to class, not instance
- Call without creating object: `Math.Sqrt(16)`

### Collections
- `T[]` = Fixed array
- `List<T>` = Dynamic list
- `IEnumerable<T>` = Read-only sequence

Would you like me to explain any of these concepts in even more detail?
