# Low-Level Design Guide for C# - Part 4: Behavioral Design Patterns

## Table of Contents
- [Introduction to Behavioral Patterns](#introduction-to-behavioral-patterns)
- [Strategy Pattern](#strategy-pattern)
- [Observer Pattern](#observer-pattern)
- [Command Pattern](#command-pattern)
- [Template Method Pattern](#template-method-pattern)
- [Iterator Pattern](#iterator-pattern)
- [State Pattern](#state-pattern)
- [Chain of Responsibility Pattern](#chain-of-responsibility-pattern)
- [Mediator Pattern](#mediator-pattern)
- [Memento Pattern](#memento-pattern)
- [Visitor Pattern](#visitor-pattern)
- [Summary](#summary)

---

## Introduction to Behavioral Patterns

**Behavioral patterns** focus on communication between objects, how they operate together, and how responsibilities are assigned.

### Key Concepts
- **Algorithm encapsulation**: Separate algorithms from objects
- **Object communication**: Define how objects interact
- **Responsibility distribution**: Assign responsibilities effectively

---

## Strategy Pattern

> **Defines a family of algorithms, encapsulates each one, and makes them interchangeable**

### When to Use
- Multiple related classes differ only in behavior
- Need different variants of an algorithm
- Algorithm uses data clients shouldn't know about
- Class defines many behaviors as conditional statements

### Problem: Payment Processing

```csharp
// ❌ Bad: Switch statement for different strategies
public class PaymentProcessor
{
    public void ProcessPayment(decimal amount, string method)
    {
        switch (method.ToLower())
        {
            case "creditcard":
                // Credit card logic
                break;
            case "paypal":
                // PayPal logic
                break;
            case "bitcoin":
                // Bitcoin logic
                break;
            // Adding new payment method requires modifying this class
        }
    }
}
```

---

### ✅ Solution: Strategy Pattern

```csharp
// Strategy interface
public interface IPaymentStrategy
{
    bool ProcessPayment(decimal amount);
    string GetPaymentMethodName();
}

// Concrete strategies
public class CreditCardPayment : IPaymentStrategy
{
    private readonly string _cardNumber;
    private readonly string _cvv;
    private readonly string _expiryDate;
    
    public CreditCardPayment(string cardNumber, string cvv, string expiryDate)
    {
        _cardNumber = cardNumber;
        _cvv = cvv;
        _expiryDate = expiryDate;
    }
    
    public bool ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} via Credit Card ending in {_cardNumber.Substring(_cardNumber.Length - 4)}");
        // Validate card, charge, etc.
        return true;
    }
    
    public string GetPaymentMethodName() => "Credit Card";
}

public class PayPalPayment : IPaymentStrategy
{
    private readonly string _email;
    
    public PayPalPayment(string email)
    {
        _email = email;
    }
    
    public bool ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} via PayPal account: {_email}");
        // PayPal API call
        return true;
    }
    
    public string GetPaymentMethodName() => "PayPal";
}

public class BitcoinPayment : IPaymentStrategy
{
    private readonly string _walletAddress;
    
    public BitcoinPayment(string walletAddress)
    {
        _walletAddress = walletAddress;
    }
    
    public bool ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} worth of Bitcoin to wallet: {_walletAddress}");
        // Bitcoin transaction
        return true;
    }
    
    public string GetPaymentMethodName() => "Bitcoin";
}

// Context
public class ShoppingCart
{
    private readonly List<string> _items = new List<string>();
    private IPaymentStrategy _paymentStrategy;
    
    public void AddItem(string item)
    {
        _items.Add(item);
        Console.WriteLine($"Added {item} to cart");
    }
    
    public void SetPaymentStrategy(IPaymentStrategy strategy)
    {
        _paymentStrategy = strategy;
        Console.WriteLine($"Payment method set to: {strategy.GetPaymentMethodName()}");
    }
    
    public void Checkout(decimal amount)
    {
        if (_paymentStrategy == null)
        {
            Console.WriteLine("Please select a payment method");
            return;
        }
        
        Console.WriteLine($"Checking out {_items.Count} items...");
        bool success = _paymentStrategy.ProcessPayment(amount);
        
        if (success)
        {
            Console.WriteLine("Payment successful!");
            _items.Clear();
        }
    }
}

// Usage
var cart = new ShoppingCart();
cart.AddItem("Laptop");
cart.AddItem("Mouse");

// Can switch strategies at runtime
cart.SetPaymentStrategy(new CreditCardPayment("1234-5678-9012-3456", "123", "12/25"));
cart.Checkout(1299.99m);

// Different order, different strategy
var cart2 = new ShoppingCart();
cart2.AddItem("Book");
cart2.SetPaymentStrategy(new PayPalPayment("user@email.com"));
cart2.Checkout(29.99m);
```

---

### Real-World Example: Compression Algorithms

```csharp
public interface ICompressionStrategy
{
    byte[] Compress(byte[] data);
    byte[] Decompress(byte[] data);
    string GetAlgorithmName();
}

public class ZipCompression : ICompressionStrategy
{
    public byte[] Compress(byte[] data)
    {
        Console.WriteLine($"Compressing {data.Length} bytes using ZIP");
        // ZIP compression logic
        return new byte[data.Length / 2]; // Simulated
    }
    
    public byte[] Decompress(byte[] data)
    {
        Console.WriteLine($"Decompressing {data.Length} bytes from ZIP");
        return new byte[data.Length * 2]; // Simulated
    }
    
    public string GetAlgorithmName() => "ZIP";
}

public class RarCompression : ICompressionStrategy
{
    public byte[] Compress(byte[] data)
    {
        Console.WriteLine($"Compressing {data.Length} bytes using RAR");
        return new byte[data.Length / 3]; // Better compression
    }
    
    public byte[] Decompress(byte[] data)
    {
        Console.WriteLine($"Decompressing {data.Length} bytes from RAR");
        return new byte[data.Length * 3];
    }
    
    public string GetAlgorithmName() => "RAR";
}

public class FileCompressor
{
    private ICompressionStrategy _strategy;
    
    public void SetStrategy(ICompressionStrategy strategy)
    {
        _strategy = strategy;
    }
    
    public void CompressFile(string filePath)
    {
        byte[] fileData = new byte[1000]; // Simulated file data
        byte[] compressed = _strategy.Compress(fileData);
        Console.WriteLine($"Compressed using {_strategy.GetAlgorithmName()}: {compressed.Length} bytes\n");
    }
}

// Usage
var compressor = new FileCompressor();
compressor.SetStrategy(new ZipCompression());
compressor.CompressFile("document.txt");

compressor.SetStrategy(new RarCompression());
compressor.CompressFile("document.txt");
```

---

## Observer Pattern

> **Defines a one-to-many dependency so when one object changes state, all dependents are notified**

Also known as **Publish-Subscribe pattern**.

### When to Use
- Change to one object requires changing others (and you don't know how many)
- Object should notify others without knowing who they are
- Need to decouple senders and receivers

### JS/TS Connection

Similar to event emitters or RxJS Observables:

```typescript
// TypeScript event emitter
class EventEmitter {
  private listeners: Map<string, Function[]> = new Map();
  
  on(event: string, callback: Function) {
    // Subscribe
  }
  
  emit(event: string, data: any) {
    // Notify all subscribers
  }
}
```

---

### ✅ Implementation

```csharp
// Subject interface
public interface ISubject
{
    void Attach(IObserver observer);
    void Detach(IObserver observer);
    void Notify();
}

// Observer interface
public interface IObserver
{
    void Update(ISubject subject);
}

// Concrete Subject - Stock
public class Stock : ISubject
{
    private readonly List<IObserver> _observers = new List<IObserver>();
    private string _symbol;
    private decimal _price;
    
    public Stock(string symbol, decimal price)
    {
        _symbol = symbol;
        _price = price;
    }
    
    public string Symbol => _symbol;
    public decimal Price => _price;
    
    public void SetPrice(decimal price)
    {
        Console.WriteLine($"\n{_symbol} price changed: ${_price} → ${price}");
        _price = price;
        Notify();
    }
    
    public void Attach(IObserver observer)
    {
        _observers.Add(observer);
        Console.WriteLine($"Observer attached to {_symbol}");
    }
    
    public void Detach(IObserver observer)
    {
        _observers.Remove(observer);
        Console.WriteLine($"Observer detached from {_symbol}");
    }
    
    public void Notify()
    {
        foreach (var observer in _observers)
        {
            observer.Update(this);
        }
    }
}

// Concrete Observers
public class InvestorObserver : IObserver
{
    private readonly string _name;
    private readonly decimal _buyThreshold;
    private readonly decimal _sellThreshold;
    
    public InvestorObserver(string name, decimal buyThreshold, decimal sellThreshold)
    {
        _name = name;
        _buyThreshold = buyThreshold;
        _sellThreshold = sellThreshold;
    }
    
    public void Update(ISubject subject)
    {
        if (subject is Stock stock)
        {
            if (stock.Price < _buyThreshold)
            {
                Console.WriteLine($"  [{_name}] BUY signal for {stock.Symbol} at ${stock.Price}");
            }
            else if (stock.Price > _sellThreshold)
            {
                Console.WriteLine($"  [{_name}] SELL signal for {stock.Symbol} at ${stock.Price}");
            }
            else
            {
                Console.WriteLine($"  [{_name}] HOLD {stock.Symbol} at ${stock.Price}");
            }
        }
    }
}

public class PriceAlertObserver : IObserver
{
    private readonly decimal _alertPrice;
    
    public PriceAlertObserver(decimal alertPrice)
    {
        _alertPrice = alertPrice;
    }
    
    public void Update(ISubject subject)
    {
        if (subject is Stock stock)
        {
            if (stock.Price >= _alertPrice)
            {
                Console.WriteLine($"  [ALERT] {stock.Symbol} reached target price ${_alertPrice}!");
            }
        }
    }
}

// Usage
var googleStock = new Stock("GOOGL", 150.00m);

var investor1 = new InvestorObserver("Alice", 140.00m, 160.00m);
var investor2 = new InvestorObserver("Bob", 145.00m, 155.00m);
var priceAlert = new PriceAlertObserver(160.00m);

googleStock.Attach(investor1);
googleStock.Attach(investor2);
googleStock.Attach(priceAlert);

// Price changes trigger notifications to all observers
googleStock.SetPrice(145.00m);
googleStock.SetPrice(138.00m);
googleStock.SetPrice(162.00m);

googleStock.Detach(investor1);
googleStock.SetPrice(155.00m);
```

---

### C# Events (Built-in Observer)

C# has built-in support for the Observer pattern via events:

```csharp
// Using C# events
public class WeatherStation
{
    // Event declaration
    public event EventHandler<WeatherChangedEventArgs> WeatherChanged;
    
    private decimal _temperature;
    
    public decimal Temperature
    {
        get => _temperature;
        set
        {
            if (_temperature != value)
            {
                _temperature = value;
                OnWeatherChanged(new WeatherChangedEventArgs(_temperature));
            }
        }
    }
    
    protected virtual void OnWeatherChanged(WeatherChangedEventArgs e)
    {
        WeatherChanged?.Invoke(this, e);
    }
}

public class WeatherChangedEventArgs : EventArgs
{
    public decimal Temperature { get; }
    
    public WeatherChangedEventArgs(decimal temperature)
    {
        Temperature = temperature;
    }
}

// Observers
public class PhoneApp
{
    public void Subscribe(WeatherStation station)
    {
        station.WeatherChanged += OnWeatherChanged;
    }
    
    private void OnWeatherChanged(object sender, WeatherChangedEventArgs e)
    {
        Console.WriteLine($"[Phone App] Temperature updated: {e.Temperature}°C");
    }
}

public class WebDashboard
{
    public void Subscribe(WeatherStation station)
    {
        station.WeatherChanged += OnWeatherChanged;
    }
    
    private void OnWeatherChanged(object sender, WeatherChangedEventArgs e)
    {
        Console.WriteLine($"[Web Dashboard] Showing: {e.Temperature}°C");
    }
}

// Usage
var station = new WeatherStation();
var phone = new PhoneApp();
var dashboard = new WebDashboard();

phone.Subscribe(station);
dashboard.Subscribe(station);

station.Temperature = 25.5m;
station.Temperature = 28.3m;
```

---

## Command Pattern

> **Encapsulates a request as an object, allowing parameterization and queuing of requests**

### When to Use
- Parameterize objects with operations
- Queue operations
- Support undo/redo
- Log changes
- Support transactions

### Real-World Example: Text Editor with Undo/Redo

```csharp
// Command interface
public interface ICommand
{
    void Execute();
    void Undo();
}

// Receiver
public class TextDocument
{
    private readonly StringBuilder _content = new StringBuilder();
    
    public void InsertText(string text, int position)
    {
        _content.Insert(position, text);
        Console.WriteLine($"Inserted '{text}' at position {position}");
    }
    
    public void DeleteText(int position, int length)
    {
        _content.Remove(position, length);
        Console.WriteLine($"Deleted {length} characters from position {position}");
    }
    
    public string GetContent() => _content.ToString();
}

// Concrete Commands
public class InsertTextCommand : ICommand
{
    private readonly TextDocument _document;
    private readonly string _text;
    private readonly int _position;
    
    public InsertTextCommand(TextDocument document, string text, int position)
    {
        _document = document;
        _text = text;
        _position = position;
    }
    
    public void Execute()
    {
        _document.InsertText(_text, _position);
    }
    
    public void Undo()
    {
        _document.DeleteText(_position, _text.Length);
    }
}

public class DeleteTextCommand : ICommand
{
    private readonly TextDocument _document;
    private readonly int _position;
    private readonly int _length;
    private string _deletedText;
    
    public DeleteTextCommand(TextDocument document, int position, int length)
    {
        _document = document;
        _position = position;
        _length = length;
    }
    
    public void Execute()
    {
        _deletedText = _document.GetContent().Substring(_position, _length);
        _document.DeleteText(_position, _length);
    }
    
    public void Undo()
    {
        _document.InsertText(_deletedText, _position);
    }
}

// Invoker
public class TextEditor
{
    private readonly Stack<ICommand> _undoStack = new Stack<ICommand>();
    private readonly Stack<ICommand> _redoStack = new Stack<ICommand>();
    
    public void ExecuteCommand(ICommand command)
    {
        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear(); // Clear redo stack when new command is executed
    }
    
    public void Undo()
    {
        if (_undoStack.Count > 0)
        {
            var command = _undoStack.Pop();
            command.Undo();
            _redoStack.Push(command);
            Console.WriteLine("Undo performed");
        }
        else
        {
            Console.WriteLine("Nothing to undo");
        }
    }
    
    public void Redo()
    {
        if (_redoStack.Count > 0)
        {
            var command = _redoStack.Pop();
            command.Execute();
            _undoStack.Push(command);
            Console.WriteLine("Redo performed");
        }
        else
        {
            Console.WriteLine("Nothing to redo");
        }
    }
}

// Usage
var document = new TextDocument();
var editor = new TextEditor();

editor.ExecuteCommand(new InsertTextCommand(document, "Hello", 0));
Console.WriteLine($"Content: {document.GetContent()}\n");

editor.ExecuteCommand(new InsertTextCommand(document, " World", 5));
Console.WriteLine($"Content: {document.GetContent()}\n");

editor.ExecuteCommand(new InsertTextCommand(document, "!", 11));
Console.WriteLine($"Content: {document.GetContent()}\n");

editor.Undo();
Console.WriteLine($"Content: {document.GetContent()}\n");

editor.Undo();
Console.WriteLine($"Content: {document.GetContent()}\n");

editor.Redo();
Console.WriteLine($"Content: {document.GetContent()}\n");
```

---

## Template Method Pattern

> **Defines the skeleton of an algorithm, deferring some steps to subclasses**

### When to Use
- Common behavior with variation in specific steps
- Control extension points
- Avoid code duplication

### Example: Data Mining

```csharp
// Abstract class with template method
public abstract class DataMiner
{
    // Template method - defines the algorithm structure
    public void Mine(string path)
    {
        var file = OpenFile(path);
        var rawData = ExtractData(file);
        var parsedData = ParseData(rawData);
        var analysis = AnalyzeData(parsedData);
        SendReport(analysis);
        CloseFile(file);
    }
    
    // Common operations
    protected virtual object OpenFile(string path)
    {
        Console.WriteLine($"Opening file: {path}");
        return new object(); // Simulated file handle
    }
    
    protected virtual void CloseFile(object file)
    {
        Console.WriteLine("Closing file\n");
    }
    
    // Abstract operations - must be implemented by subclasses
    protected abstract object ExtractData(object file);
    protected abstract object ParseData(object rawData);
    
    // Hook - can be overridden but has default implementation
    protected virtual object AnalyzeData(object data)
    {
        Console.WriteLine("Performing basic analysis");
        return data;
    }
    
    protected virtual void SendReport(object analysis)
    {
        Console.WriteLine("Sending report via email");
    }
}

// Concrete implementations
public class PdfDataMiner : DataMiner
{
    protected override object ExtractData(object file)
    {
        Console.WriteLine("Extracting data from PDF");
        return "PDF raw data";
    }
    
    protected override object ParseData(object rawData)
    {
        Console.WriteLine("Parsing PDF data");
        return "Parsed PDF data";
    }
    
    protected override object AnalyzeData(object data)
    {
        Console.WriteLine("Analyzing PDF data with specialized algorithms");
        return "PDF analysis results";
    }
}

public class CsvDataMiner : DataMiner
{
    protected override object ExtractData(object file)
    {
        Console.WriteLine("Extracting data from CSV");
        return "CSV raw data";
    }
    
    protected override object ParseData(object rawData)
    {
        Console.WriteLine("Parsing CSV data");
        return "Parsed CSV data";
    }
    
    protected override void SendReport(object analysis)
    {
        Console.WriteLine("Sending report via Slack");
    }
}

// Usage
DataMiner pdfMiner = new PdfDataMiner();
pdfMiner.Mine("report.pdf");

DataMiner csvMiner = new CsvDataMiner();
csvMiner.Mine("data.csv");
```

---

## State Pattern

> **Allows an object to alter its behavior when its internal state changes**

### When to Use
- Object behavior depends on state
- Operations have large conditional statements
- State transitions are complex

### Example: Document Workflow

```csharp
// State interface
public interface IDocumentState
{
    void Publish(Document document);
    void Approve(Document document);
    void Reject(Document document);
}

// Context
public class Document
{
    private IDocumentState _state;
    public string Content { get; set; }
    public string CurrentStateName => _state.GetType().Name;
    
    public Document(string content)
    {
        Content = content;
        _state = new DraftState(); // Initial state
        Console.WriteLine($"Document created in {CurrentStateName}");
    }
    
    public void SetState(IDocumentState state)
    {
        _state = state;
        Console.WriteLine($"State changed to: {CurrentStateName}");
    }
    
    public void Publish()
    {
        _state.Publish(this);
    }
    
    public void Approve()
    {
        _state.Approve(this);
    }
    
    public void Reject()
    {
        _state.Reject(this);
    }
}

// Concrete States
public class DraftState : IDocumentState
{
    public void Publish(Document document)
    {
        Console.WriteLine("Submitting draft for moderation...");
        document.SetState(new ModerationState());
    }
    
    public void Approve(Document document)
    {
        Console.WriteLine("Cannot approve a draft");
    }
    
    public void Reject(Document document)
    {
        Console.WriteLine("Cannot reject a draft");
    }
}

public class ModerationState : IDocumentState
{
    public void Publish(Document document)
    {
        Console.WriteLine("Already in moderation");
    }
    
    public void Approve(Document document)
    {
        Console.WriteLine("Document approved! Publishing...");
        document.SetState(new PublishedState());
    }
    
    public void Reject(Document document)
    {
        Console.WriteLine("Document rejected. Sending back to draft...");
        document.SetState(new DraftState());
    }
}

public class PublishedState : IDocumentState
{
    public void Publish(Document document)
    {
        Console.WriteLine("Already published");
    }
    
    public void Approve(Document document)
    {
        Console.WriteLine("Already approved");
    }
    
    public void Reject(Document document)
    {
        Console.WriteLine("Unpublishing document...");
        document.SetState(new DraftState());
    }
}

// Usage
var doc = new Document("My Article Content");

doc.Approve();  // Cannot approve a draft
doc.Publish();  // Submits for moderation
doc.Publish();  // Already in moderation
doc.Approve();  // Approves and publishes
doc.Reject();   // Unpublishes
```

---

## Chain of Responsibility Pattern

> **Passes requests along a chain of handlers until one handles it**

### When to Use
- More than one object can handle a request
- Don't know handler beforehand
- Want to issue request to several objects without specifying receiver

### Example: Support Ticket System

```csharp
// Handler interface
public abstract class SupportHandler
{
    protected SupportHandler _nextHandler;
    
    public void SetNext(SupportHandler handler)
    {
        _nextHandler = handler;
    }
    
    public abstract void HandleRequest(SupportTicket ticket);
}

// Request
public class SupportTicket
{
    public string Issue { get; set; }
    public int Priority { get; set; } // 1-3
    public string Customer { get; set; }
}

// Concrete Handlers
public class Level1Support : SupportHandler
{
    public override void HandleRequest(SupportTicket ticket)
    {
        if (ticket.Priority == 1)
        {
            Console.WriteLine($"[Level 1] Handling basic issue for {ticket.Customer}: {ticket.Issue}");
        }
        else if (_nextHandler != null)
        {
            Console.WriteLine($"[Level 1] Escalating to Level 2...");
            _nextHandler.HandleRequest(ticket);
        }
    }
}

public class Level2Support : SupportHandler
{
    public override void HandleRequest(SupportTicket ticket)
    {
        if (ticket.Priority == 2)
        {
            Console.WriteLine($"[Level 2] Handling moderate issue for {ticket.Customer}: {ticket.Issue}");
        }
        else if (_nextHandler != null)
        {
            Console.WriteLine($"[Level 2] Escalating to Level 3...");
            _nextHandler.HandleRequest(ticket);
        }
    }
}

public class Level3Support : SupportHandler
{
    public override void HandleRequest(SupportTicket ticket)
    {
        if (ticket.Priority == 3)
        {
            Console.WriteLine($"[Level 3] Handling critical issue for {ticket.Customer}: {ticket.Issue}");
        }
        else
        {
            Console.WriteLine($"[Level 3] No one can handle this issue!");
        }
    }
}

// Usage
var level1 = new Level1Support();
var level2 = new Level2Support();
var level3 = new Level3Support();

level1.SetNext(level2);
level2.SetNext(level3);

var ticket1 = new SupportTicket 
{ 
    Customer = "John", 
    Issue = "Password reset", 
    Priority = 1 
};

var ticket2 = new SupportTicket 
{ 
    Customer = "Jane", 
    Issue = "Database corruption", 
    Priority = 3 
};

var ticket3 = new SupportTicket 
{ 
    Customer = "Bob", 
    Issue = "Software installation", 
    Priority = 2 
};

level1.HandleRequest(ticket1);
Console.WriteLine();
level1.HandleRequest(ticket2);
Console.WriteLine();
level1.HandleRequest(ticket3);
```

---

## Mediator Pattern

> **Defines an object that encapsulates how a set of objects interact**

### Example: Chat Room

```csharp
// Mediator interface
public interface IChatMediator
{
    void SendMessage(string message, User user);
    void AddUser(User user);
}

// Concrete Mediator
public class ChatRoom : IChatMediator
{
    private readonly List<User> _users = new List<User>();
    
    public void AddUser(User user)
    {
        _users.Add(user);
        Console.WriteLine($"{user.Name} joined the chat");
    }
    
    public void SendMessage(string message, User sender)
    {
        foreach (var user in _users)
        {
            // Don't send to sender
            if (user != sender)
            {
                user.Receive(message, sender);
            }
        }
    }
}

// Colleague
public class User
{
    private readonly IChatMediator _mediator;
    public string Name { get; }
    
    public User(string name, IChatMediator mediator)
    {
        Name = name;
        _mediator = mediator;
    }
    
    public void Send(string message)
    {
        Console.WriteLine($"{Name} sends: {message}");
        _mediator.SendMessage(message, this);
    }
    
    public void Receive(string message, User sender)
    {
        Console.WriteLine($"{Name} received from {sender.Name}: {message}");
    }
}

// Usage
var chatRoom = new ChatRoom();

var alice = new User("Alice", chatRoom);
var bob = new User("Bob", chatRoom);
var charlie = new User("Charlie", chatRoom);

chatRoom.AddUser(alice);
chatRoom.AddUser(bob);
chatRoom.AddUser(charlie);

alice.Send("Hello everyone!");
Console.WriteLine();
bob.Send("Hi Alice!");
```

---

## Memento Pattern

> **Captures and restores an object's internal state without violating encapsulation**

### Example: Game Save System

```csharp
// Memento
public class GameMemento
{
    public int Level { get; }
    public int Score { get; }
    public int Health { get; }
    public DateTime SaveTime { get; }
    
    public GameMemento(int level, int score, int health)
    {
        Level = level;
        Score = score;
        Health = health;
        SaveTime = DateTime.Now;
    }
}

// Originator
public class GameState
{
    public int Level { get; set; }
    public int Score { get; set; }
    public int Health { get; set; }
    
    public GameMemento Save()
    {
        Console.WriteLine($"Saving game: Level {Level}, Score {Score}, Health {Health}");
        return new GameMemento(Level, Score, Health);
    }
    
    public void Restore(GameMemento memento)
    {
        Level = memento.Level;
        Score = memento.Score;
        Health = memento.Health;
        Console.WriteLine($"Game restored: Level {Level}, Score {Score}, Health {Health}");
    }
    
    public void Display()
    {
        Console.WriteLine($"Current: Level {Level}, Score {Score}, Health {Health}");
    }
}

// Caretaker
public class GameCaretaker
{
    private readonly Stack<GameMemento> _saves = new Stack<GameMemento>();
    
    public void Save(GameState game)
    {
        _saves.Push(game.Save());
    }
    
    public void Undo(GameState game)
    {
        if (_saves.Count > 0)
        {
            game.Restore(_saves.Pop());
        }
        else
        {
            Console.WriteLine("No saves available");
        }
    }
}

// Usage
var game = new GameState { Level = 1, Score = 0, Health = 100 };
var caretaker = new GameCaretaker();

game.Display();
caretaker.Save(game);

game.Level = 2;
game.Score = 500;
game.Health = 80;
game.Display();
caretaker.Save(game);

game.Level = 3;
game.Score = 1200;
game.Health = 50;
game.Display();

Console.WriteLine("\nPlayer died! Restoring...");
caretaker.Undo(game);
game.Display();
```

---

## Visitor Pattern

> **Lets you define new operations without changing classes of elements operated on**

### Example: Shape Area Calculator

```csharp
// Element interface
public interface IShape
{
    void Accept(IShapeVisitor visitor);
}

// Visitor interface
public interface IShapeVisitor
{
    void Visit(Circle circle);
    void Visit(Rectangle rectangle);
    void Visit(Triangle triangle);
}

// Concrete Elements
public class Circle : IShape
{
    public double Radius { get; set; }
    
    public Circle(double radius)
    {
        Radius = radius;
    }
    
    public void Accept(IShapeVisitor visitor)
    {
        visitor.Visit(this);
    }
}

public class Rectangle : IShape
{
    public double Width { get; set; }
    public double Height { get; set; }
    
    public Rectangle(double width, double height)
    {
        Width = width;
        Height = height;
    }
    
    public void Accept(IShapeVisitor visitor)
    {
        visitor.Visit(this);
    }
}

public class Triangle : IShape
{
    public double Base { get; set; }
    public double Height { get; set; }
    
    public Triangle(double baseLength, double height)
    {
        Base = baseLength;
        Height = height;
    }
    
    public void Accept(IShapeVisitor visitor)
    {
        visitor.Visit(this);
    }
}

// Concrete Visitors
public class AreaCalculator : IShapeVisitor
{
    public double TotalArea { get; private set; }
    
    public void Visit(Circle circle)
    {
        double area = Math.PI * circle.Radius * circle.Radius;
        Console.WriteLine($"Circle area: {area:F2}");
        TotalArea += area;
    }
    
    public void Visit(Rectangle rectangle)
    {
        double area = rectangle.Width * rectangle.Height;
        Console.WriteLine($"Rectangle area: {area:F2}");
        TotalArea += area;
    }
    
    public void Visit(Triangle triangle)
    {
        double area = 0.5 * triangle.Base * triangle.Height;
        Console.WriteLine($"Triangle area: {area:F2}");
        TotalArea += area;
    }
}

public class PerimeterCalculator : IShapeVisitor
{
    public double TotalPerimeter { get; private set; }
    
    public void Visit(Circle circle)
    {
        double perimeter = 2 * Math.PI * circle.Radius;
        Console.WriteLine($"Circle perimeter: {perimeter:F2}");
        TotalPerimeter += perimeter;
    }
    
    public void Visit(Rectangle rectangle)
    {
        double perimeter = 2 * (rectangle.Width + rectangle.Height);
        Console.WriteLine($"Rectangle perimeter: {perimeter:F2}");
        TotalPerimeter += perimeter;
    }
    
    public void Visit(Triangle triangle)
    {
        // Assuming equilateral for simplicity
        double perimeter = 3 * triangle.Base;
        Console.WriteLine($"Triangle perimeter: {perimeter:F2}");
        TotalPerimeter += perimeter;
    }
}

// Usage
var shapes = new List<IShape>
{
    new Circle(5),
    new Rectangle(4, 6),
    new Triangle(3, 4)
};

var areaCalculator = new AreaCalculator();
var perimeterCalculator = new PerimeterCalculator();

Console.WriteLine("Calculating areas:");
foreach (var shape in shapes)
{
    shape.Accept(areaCalculator);
}
Console.WriteLine($"Total area: {areaCalculator.TotalArea:F2}\n");

Console.WriteLine("Calculating perimeters:");
foreach (var shape in shapes)
{
    shape.Accept(perimeterCalculator);
}
Console.WriteLine($"Total perimeter: {perimeterCalculator.TotalPerimeter:F2}");
```

---

## Summary

### Behavioral Patterns Quick Reference

| Pattern | Purpose | Key Benefit |
|---------|---------|-------------|
| **Strategy** | Encapsulate algorithms | Switch algorithms at runtime |
| **Observer** | One-to-many notification | Loose coupling between publisher/subscribers |
| **Command** | Encapsulate requests | Undo/redo, queuing, logging |
| **Template Method** | Algorithm skeleton | Code reuse with variation |
| **Iterator** | Access elements sequentially | Uniform access to collections |
| **State** | State-based behavior | Organize state-specific code |
| **Chain of Responsibility** | Pass request through chain | Decoupled request handling |
| **Mediator** | Centralize complex communications | Reduced coupling |
| **Memento** | Capture/restore state | Undo mechanisms |
| **Visitor** | Add operations to objects | Add functionality without changing classes |

### When to Use Each Pattern

- **Strategy**: When you have multiple algorithms for the same task
- **Observer**: When changes to one object require updating others
- **Command**: When you need undo/redo or want to queue operations
- **Template Method**: When you have a common algorithm with variations
- **State**: When behavior changes based on state
- **Chain of Responsibility**: When multiple objects can handle a request
- **Mediator**: When objects have complex interactions
- **Memento**: When you need to save/restore object state
- **Visitor**: When you frequently add new operations to existing structures

---

**Continue to:** [Part 5: Common LLD Problems](LLD-Guide-CSharp-Part5-Common-Problems.md)

**Previous:** [Part 3: Structural Design Patterns](LLD-Guide-CSharp-Part3-Structural-Patterns.md)
