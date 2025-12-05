# Low-Level Design Guide for C# - Part 3: Structural Design Patterns

## Table of Contents
- [Introduction to Structural Patterns](#introduction-to-structural-patterns)
- [Adapter Pattern](#adapter-pattern)
- [Decorator Pattern](#decorator-pattern)
- [Facade Pattern](#facade-pattern)
- [Proxy Pattern](#proxy-pattern)
- [Composite Pattern](#composite-pattern)
- [Bridge Pattern](#bridge-pattern)
- [Flyweight Pattern](#flyweight-pattern)
- [Summary](#summary)

---

## Introduction to Structural Patterns

**Structural patterns** deal with object composition and relationships. They help ensure that when one part changes, the entire structure doesn't need to change.

### Key Concepts
- **Composition over inheritance**: Build complex functionality by combining objects
- **Interface adaptation**: Make incompatible interfaces work together
- **Responsibility delegation**: Distribute functionality across objects

---

## Adapter Pattern

> **Converts the interface of a class into another interface clients expect**

Also known as **Wrapper pattern**.

### When to Use
- Need to use an existing class with an incompatible interface
- Want to create reusable classes that work with unrelated classes
- Need to use several existing subclasses but can't subclass all

### Problem Scenario

```csharp
// Old payment system (legacy code)
public class OldPaymentProcessor
{
    public void MakePayment(string cardNumber, double amount)
    {
        Console.WriteLine($"Processing ${amount} using card {cardNumber}");
    }
}

// New payment interface (your current system expects this)
public interface IPaymentGateway
{
    void ProcessPayment(decimal amount, string paymentDetails);
}

// Problem: Can't use OldPaymentProcessor directly because interface doesn't match
```

---

### ✅ Solution: Adapter Pattern

```csharp
// Adapter makes OldPaymentProcessor compatible with IPaymentGateway
public class PaymentAdapter : IPaymentGateway
{
    private readonly OldPaymentProcessor _oldProcessor;
    
    public PaymentAdapter(OldPaymentProcessor oldProcessor)
    {
        _oldProcessor = oldProcessor;
    }
    
    public void ProcessPayment(decimal amount, string paymentDetails)
    {
        // Adapt the interface
        double amountDouble = (double)amount;
        _oldProcessor.MakePayment(paymentDetails, amountDouble);
    }
}

// Usage
public class PaymentService
{
    private readonly IPaymentGateway _gateway;
    
    public PaymentService(IPaymentGateway gateway)
    {
        _gateway = gateway;
    }
    
    public void Charge(decimal amount, string paymentDetails)
    {
        _gateway.ProcessPayment(amount, paymentDetails);
    }
}

// Now we can use the old processor!
var oldProcessor = new OldPaymentProcessor();
var adapter = new PaymentAdapter(oldProcessor);
var service = new PaymentService(adapter);
service.Charge(100.50m, "1234-5678-9012-3456");
```

---

### Real-World Example: Media Player

```csharp
// Target interface (what our code expects)
public interface IMediaPlayer
{
    void Play(string fileName);
}

// Adaptee (existing incompatible class - plays only MP3)
public class AudioPlayer
{
    public void PlayMp3(string fileName)
    {
        Console.WriteLine($"Playing MP3 file: {fileName}");
    }
}

// Another adaptee (plays MP4 and VLC)
public class VideoPlayer
{
    public void PlayMp4(string fileName)
    {
        Console.WriteLine($"Playing MP4 file: {fileName}");
    }
    
    public void PlayVlc(string fileName)
    {
        Console.WriteLine($"Playing VLC file: {fileName}");
    }
}

// Adapter for advanced formats
public class MediaAdapter : IMediaPlayer
{
    private readonly VideoPlayer _videoPlayer;
    
    public MediaAdapter(string audioType)
    {
        if (audioType.Equals("mp4", StringComparison.OrdinalIgnoreCase) || 
            audioType.Equals("vlc", StringComparison.OrdinalIgnoreCase))
        {
            _videoPlayer = new VideoPlayer();
        }
    }
    
    public void Play(string fileName)
    {
        var extension = Path.GetExtension(fileName).TrimStart('.').ToLower();
        
        if (extension == "mp4")
        {
            _videoPlayer.PlayMp4(fileName);
        }
        else if (extension == "vlc")
        {
            _videoPlayer.PlayVlc(fileName);
        }
    }
}

// Enhanced player that supports multiple formats
public class UniversalMediaPlayer : IMediaPlayer
{
    private readonly AudioPlayer _audioPlayer = new AudioPlayer();
    private MediaAdapter _mediaAdapter;
    
    public void Play(string fileName)
    {
        var extension = Path.GetExtension(fileName).TrimStart('.').ToLower();
        
        if (extension == "mp3")
        {
            _audioPlayer.PlayMp3(fileName);
        }
        else if (extension == "mp4" || extension == "vlc")
        {
            _mediaAdapter = new MediaAdapter(extension);
            _mediaAdapter.Play(fileName);
        }
        else
        {
            Console.WriteLine($"Invalid format: {extension}");
        }
    }
}

// Usage
var player = new UniversalMediaPlayer();
player.Play("song.mp3");
player.Play("video.mp4");
player.Play("movie.vlc");
player.Play("unknown.avi"); // Invalid format
```

### JS/TS Connection

In TypeScript, you might adapt APIs like this:

```typescript
// Adapter for different API response formats
class APIAdapter {
  adaptResponse(oldFormatData: any) {
    return {
      id: oldFormatData.ID,
      name: oldFormatData.NAME,
      email: oldFormatData.EMAIL_ADDRESS
    };
  }
}
```

C# uses the same concept but with explicit interfaces and types.

---

## Decorator Pattern

> **Attaches additional responsibilities to an object dynamically**

Provides a flexible alternative to subclassing for extending functionality.

### When to Use
- Need to add responsibilities to individual objects dynamically
- Want to add functionality without affecting other objects
- Extension by subclassing is impractical

### Problem: Beverage Pricing

```csharp
// ❌ Bad: Class explosion
public class Coffee { }
public class CoffeeWithMilk : Coffee { }
public class CoffeeWithSugar : Coffee { }
public class CoffeeWithMilkAndSugar : Coffee { }
public class CoffeeWithMilkAndSugarAndWhippedCream : Coffee { }
// ... endless combinations!
```

---

### ✅ Solution: Decorator Pattern

```csharp
// Component interface
public interface IBeverage
{
    string GetDescription();
    decimal GetCost();
}

// Concrete component
public class Espresso : IBeverage
{
    public string GetDescription() => "Espresso";
    public decimal GetCost() => 1.99m;
}

public class DarkRoast : IBeverage
{
    public string GetDescription() => "Dark Roast Coffee";
    public decimal GetCost() => 2.49m;
}

// Base decorator
public abstract class BeverageDecorator : IBeverage
{
    protected readonly IBeverage _beverage;
    
    protected BeverageDecorator(IBeverage beverage)
    {
        _beverage = beverage;
    }
    
    public virtual string GetDescription() => _beverage.GetDescription();
    public virtual decimal GetCost() => _beverage.GetCost();
}

// Concrete decorators
public class Milk : BeverageDecorator
{
    public Milk(IBeverage beverage) : base(beverage) { }
    
    public override string GetDescription() => $"{_beverage.GetDescription()}, Milk";
    public override decimal GetCost() => _beverage.GetCost() + 0.50m;
}

public class Sugar : BeverageDecorator
{
    public Sugar(IBeverage beverage) : base(beverage) { }
    
    public override string GetDescription() => $"{_beverage.GetDescription()}, Sugar";
    public override decimal GetCost() => _beverage.GetCost() + 0.20m;
}

public class WhippedCream : BeverageDecorator
{
    public WhippedCream(IBeverage beverage) : base(beverage) { }
    
    public override string GetDescription() => $"{_beverage.GetDescription()}, Whipped Cream";
    public override decimal GetCost() => _beverage.GetCost() + 0.70m;
}

public class Caramel : BeverageDecorator
{
    public Caramel(IBeverage beverage) : base(beverage) { }
    
    public override string GetDescription() => $"{_beverage.GetDescription()}, Caramel";
    public override decimal GetCost() => _beverage.GetCost() + 0.60m;
}

// Usage - wrap decorators around each other!
IBeverage beverage = new Espresso();
Console.WriteLine($"{beverage.GetDescription()} ${beverage.GetCost()}");
// Output: Espresso $1.99

beverage = new Milk(beverage);
Console.WriteLine($"{beverage.GetDescription()} ${beverage.GetCost()}");
// Output: Espresso, Milk $2.49

beverage = new Sugar(beverage);
Console.WriteLine($"{beverage.GetDescription()} ${beverage.GetCost()}");
// Output: Espresso, Milk, Sugar $2.69

beverage = new WhippedCream(beverage);
Console.WriteLine($"{beverage.GetDescription()} ${beverage.GetCost()}");
// Output: Espresso, Milk, Sugar, Whipped Cream $3.39

// Build complex beverages easily
IBeverage fancyCoffee = new WhippedCream(
    new Caramel(
        new Milk(
            new Milk(
                new DarkRoast()
            )
        )
    )
);
Console.WriteLine($"{fancyCoffee.GetDescription()} ${fancyCoffee.GetCost()}");
// Output: Dark Roast Coffee, Milk, Milk, Caramel, Whipped Cream $4.89
```

---

### Real-World Example: Text Formatting

```csharp
// Component
public interface ITextComponent
{
    string GetText();
}

// Concrete component
public class PlainText : ITextComponent
{
    private readonly string _text;
    
    public PlainText(string text)
    {
        _text = text;
    }
    
    public string GetText() => _text;
}

// Base decorator
public abstract class TextDecorator : ITextComponent
{
    protected readonly ITextComponent _component;
    
    protected TextDecorator(ITextComponent component)
    {
        _component = component;
    }
    
    public virtual string GetText() => _component.GetText();
}

// Concrete decorators
public class BoldDecorator : TextDecorator
{
    public BoldDecorator(ITextComponent component) : base(component) { }
    
    public override string GetText() => $"<b>{_component.GetText()}</b>";
}

public class ItalicDecorator : TextDecorator
{
    public ItalicDecorator(ITextComponent component) : base(component) { }
    
    public override string GetText() => $"<i>{_component.GetText()}</i>";
}

public class UnderlineDecorator : TextDecorator
{
    public UnderlineDecorator(ITextComponent component) : base(component) { }
    
    public override string GetText() => $"<u>{_component.GetText()}</u>";
}

public class ColorDecorator : TextDecorator
{
    private readonly string _color;
    
    public ColorDecorator(ITextComponent component, string color) : base(component)
    {
        _color = color;
    }
    
    public override string GetText() => $"<span style='color:{_color}'>{_component.GetText()}</span>";
}

// Usage
ITextComponent text = new PlainText("Hello World");
text = new BoldDecorator(text);
text = new ItalicDecorator(text);
text = new ColorDecorator(text, "red");

Console.WriteLine(text.GetText());
// Output: <span style='color:red'><i><b>Hello World</b></i></span>
```

---

## Facade Pattern

> **Provides a unified interface to a set of interfaces in a subsystem**

Defines a higher-level interface that makes the subsystem easier to use.

### When to Use
- Want to provide a simple interface to a complex subsystem
- Need to decouple client code from subsystem implementation
- Want to layer your subsystems

### Problem: Complex Home Theater System

```csharp
// Complex subsystems
public class Amplifier
{
    public void On() => Console.WriteLine("Amplifier on");
    public void Off() => Console.WriteLine("Amplifier off");
    public void SetVolume(int level) => Console.WriteLine($"Volume set to {level}");
}

public class DVDPlayer
{
    public void On() => Console.WriteLine("DVD Player on");
    public void Off() => Console.WriteLine("DVD Player off");
    public void Play(string movie) => Console.WriteLine($"Playing '{movie}'");
    public void Stop() => Console.WriteLine("DVD stopped");
    public void Eject() => Console.WriteLine("DVD ejected");
}

public class Projector
{
    public void On() => Console.WriteLine("Projector on");
    public void Off() => Console.WriteLine("Projector off");
    public void WideScreenMode() => Console.WriteLine("Projector in widescreen mode");
}

public class Lights
{
    public void Dim(int level) => Console.WriteLine($"Lights dimmed to {level}%");
    public void On() => Console.WriteLine("Lights on");
}

public class Screen
{
    public void Down() => Console.WriteLine("Screen going down");
    public void Up() => Console.WriteLine("Screen going up");
}

public class SoundSystem
{
    public void On() => Console.WriteLine("Sound system on");
    public void Off() => Console.WriteLine("Sound system off");
    public void SetSurroundSound() => Console.WriteLine("Surround sound enabled");
}
```

---

### ✅ Solution: Facade

```csharp
// Facade simplifies the complex subsystem
public class HomeTheaterFacade
{
    private readonly Amplifier _amp;
    private readonly DVDPlayer _dvd;
    private readonly Projector _projector;
    private readonly Lights _lights;
    private readonly Screen _screen;
    private readonly SoundSystem _soundSystem;
    
    public HomeTheaterFacade(
        Amplifier amp,
        DVDPlayer dvd,
        Projector projector,
        Lights lights,
        Screen screen,
        SoundSystem soundSystem)
    {
        _amp = amp;
        _dvd = dvd;
        _projector = projector;
        _lights = lights;
        _screen = screen;
        _soundSystem = soundSystem;
    }
    
    public void WatchMovie(string movie)
    {
        Console.WriteLine("Get ready to watch a movie...");
        _lights.Dim(10);
        _screen.Down();
        _projector.On();
        _projector.WideScreenMode();
        _amp.On();
        _amp.SetVolume(5);
        _soundSystem.On();
        _soundSystem.SetSurroundSound();
        _dvd.On();
        _dvd.Play(movie);
    }
    
    public void EndMovie()
    {
        Console.WriteLine("Shutting down movie theater...");
        _dvd.Stop();
        _dvd.Eject();
        _dvd.Off();
        _soundSystem.Off();
        _amp.Off();
        _projector.Off();
        _screen.Up();
        _lights.On();
    }
}

// Usage - simple!
var amp = new Amplifier();
var dvd = new DVDPlayer();
var projector = new Projector();
var lights = new Lights();
var screen = new Screen();
var soundSystem = new SoundSystem();

var homeTheater = new HomeTheaterFacade(amp, dvd, projector, lights, screen, soundSystem);

// One simple call instead of 10+
homeTheater.WatchMovie("Inception");

// Later...
homeTheater.EndMovie();
```

---

### Real-World Example: Order Processing

```csharp
// Complex subsystems
public class InventorySystem
{
    public bool CheckStock(string productId, int quantity)
    {
        Console.WriteLine($"Checking stock for {productId}: {quantity} units");
        return true; // Simplified
    }
    
    public void ReserveStock(string productId, int quantity)
    {
        Console.WriteLine($"Reserved {quantity} units of {productId}");
    }
}

public class PaymentGateway
{
    public bool ProcessPayment(string cardNumber, decimal amount)
    {
        Console.WriteLine($"Processing payment of ${amount}");
        return true; // Simplified
    }
}

public class ShippingSystem
{
    public string CreateShipment(string address, string productId)
    {
        Console.WriteLine($"Creating shipment to {address}");
        return "SHIP-12345"; // Tracking number
    }
}

public class NotificationService
{
    public void SendOrderConfirmation(string email, string orderId)
    {
        Console.WriteLine($"Sending confirmation email to {email} for order {orderId}");
    }
}

public class InvoiceGenerator
{
    public string GenerateInvoice(string orderId, decimal amount)
    {
        Console.WriteLine($"Generating invoice for order {orderId}");
        return $"INV-{orderId}";
    }
}

// Facade
public class OrderProcessingFacade
{
    private readonly InventorySystem _inventory;
    private readonly PaymentGateway _payment;
    private readonly ShippingSystem _shipping;
    private readonly NotificationService _notification;
    private readonly InvoiceGenerator _invoice;
    
    public OrderProcessingFacade()
    {
        _inventory = new InventorySystem();
        _payment = new PaymentGateway();
        _shipping = new ShippingSystem();
        _notification = new NotificationService();
        _invoice = new InvoiceGenerator();
    }
    
    public bool PlaceOrder(string productId, int quantity, decimal amount, 
                          string cardNumber, string email, string shippingAddress)
    {
        Console.WriteLine("=== Starting Order Process ===");
        
        // Step 1: Check inventory
        if (!_inventory.CheckStock(productId, quantity))
        {
            Console.WriteLine("Product out of stock");
            return false;
        }
        
        // Step 2: Process payment
        if (!_payment.ProcessPayment(cardNumber, amount))
        {
            Console.WriteLine("Payment failed");
            return false;
        }
        
        // Step 3: Reserve stock
        _inventory.ReserveStock(productId, quantity);
        
        // Step 4: Create shipment
        string trackingNumber = _shipping.CreateShipment(shippingAddress, productId);
        
        // Step 5: Generate invoice
        string orderId = Guid.NewGuid().ToString();
        string invoiceId = _invoice.GenerateInvoice(orderId, amount);
        
        // Step 6: Send notification
        _notification.SendOrderConfirmation(email, orderId);
        
        Console.WriteLine($"=== Order Complete: {orderId} ===");
        Console.WriteLine($"Tracking: {trackingNumber}");
        Console.WriteLine($"Invoice: {invoiceId}");
        
        return true;
    }
}

// Usage - very simple for the client
var orderSystem = new OrderProcessingFacade();
orderSystem.PlaceOrder(
    productId: "PROD-001",
    quantity: 2,
    amount: 99.99m,
    cardNumber: "1234-5678-9012-3456",
    email: "customer@email.com",
    shippingAddress: "123 Main St, City, State"
);
```

---

## Proxy Pattern

> **Provides a surrogate or placeholder for another object to control access to it**

### When to Use
- **Virtual Proxy**: Delay expensive object creation until needed
- **Protection Proxy**: Control access based on permissions
- **Remote Proxy**: Represent object in different address space
- **Caching Proxy**: Cache results of expensive operations

### Types of Proxies

#### 1. Virtual Proxy (Lazy Loading)

```csharp
// Subject interface
public interface IImage
{
    void Display();
}

// Real subject - expensive to create
public class RealImage : IImage
{
    private readonly string _fileName;
    
    public RealImage(string fileName)
    {
        _fileName = fileName;
        LoadFromDisk();
    }
    
    private void LoadFromDisk()
    {
        Console.WriteLine($"Loading image from disk: {_fileName}");
        // Simulate expensive operation
        Thread.Sleep(2000);
    }
    
    public void Display()
    {
        Console.WriteLine($"Displaying image: {_fileName}");
    }
}

// Proxy - creates RealImage only when needed
public class ImageProxy : IImage
{
    private readonly string _fileName;
    private RealImage _realImage;
    
    public ImageProxy(string fileName)
    {
        _fileName = fileName;
    }
    
    public void Display()
    {
        // Lazy initialization
        if (_realImage == null)
        {
            _realImage = new RealImage(_fileName);
        }
        _realImage.Display();
    }
}

// Usage
IImage image1 = new ImageProxy("photo1.jpg"); // Image NOT loaded yet
IImage image2 = new ImageProxy("photo2.jpg"); // Image NOT loaded yet

Console.WriteLine("Images created (but not loaded)");

image1.Display(); // NOW it loads - takes 2 seconds
image1.Display(); // Uses cached image - instant
image2.Display(); // Loads - takes 2 seconds
```

---

#### 2. Protection Proxy (Access Control)

```csharp
// Subject
public interface IDocument
{
    void View();
    void Edit(string content);
    void Delete();
}

// Real subject
public class Document : IDocument
{
    private string _content;
    private readonly string _name;
    
    public Document(string name, string content)
    {
        _name = name;
        _content = content;
    }
    
    public void View()
    {
        Console.WriteLine($"Viewing document '{_name}': {_content}");
    }
    
    public void Edit(string content)
    {
        _content = content;
        Console.WriteLine($"Document '{_name}' edited");
    }
    
    public void Delete()
    {
        Console.WriteLine($"Document '{_name}' deleted");
    }
}

// User roles
public enum UserRole
{
    Viewer,
    Editor,
    Admin
}

// Protection proxy
public class DocumentProxy : IDocument
{
    private readonly Document _document;
    private readonly UserRole _userRole;
    
    public DocumentProxy(Document document, UserRole userRole)
    {
        _document = document;
        _userRole = userRole;
    }
    
    public void View()
    {
        // Everyone can view
        _document.View();
    }
    
    public void Edit(string content)
    {
        if (_userRole == UserRole.Editor || _userRole == UserRole.Admin)
        {
            _document.Edit(content);
        }
        else
        {
            Console.WriteLine("Access denied: You don't have permission to edit");
        }
    }
    
    public void Delete()
    {
        if (_userRole == UserRole.Admin)
        {
            _document.Delete();
        }
        else
        {
            Console.WriteLine("Access denied: You don't have permission to delete");
        }
    }
}

// Usage
var document = new Document("Secret Plan", "Top secret content");

// Viewer
var viewerProxy = new DocumentProxy(document, UserRole.Viewer);
viewerProxy.View();   // Works
viewerProxy.Edit("New content"); // Access denied
viewerProxy.Delete(); // Access denied

// Editor
var editorProxy = new DocumentProxy(document, UserRole.Editor);
editorProxy.View();   // Works
editorProxy.Edit("Updated content"); // Works
editorProxy.Delete(); // Access denied

// Admin
var adminProxy = new DocumentProxy(document, UserRole.Admin);
adminProxy.View();   // Works
adminProxy.Edit("Admin update"); // Works
adminProxy.Delete(); // Works
```

---

#### 3. Caching Proxy

```csharp
public interface IDataService
{
    string GetData(string key);
}

public class ExpensiveDataService : IDataService
{
    public string GetData(string key)
    {
        Console.WriteLine($"Fetching data from database for key: {key}");
        Thread.Sleep(1000); // Simulate slow database query
        return $"Data for {key}";
    }
}

public class CachingDataServiceProxy : IDataService
{
    private readonly ExpensiveDataService _realService;
    private readonly Dictionary<string, string> _cache;
    
    public CachingDataServiceProxy(ExpensiveDataService realService)
    {
        _realService = realService;
        _cache = new Dictionary<string, string>();
    }
    
    public string GetData(string key)
    {
        // Check cache first
        if (_cache.ContainsKey(key))
        {
            Console.WriteLine($"Returning cached data for key: {key}");
            return _cache[key];
        }
        
        // Cache miss - fetch from real service
        string data = _realService.GetData(key);
        _cache[key] = data;
        
        return data;
    }
}

// Usage
IDataService service = new CachingDataServiceProxy(new ExpensiveDataService());

service.GetData("user:123"); // Slow - fetches from DB
service.GetData("user:123"); // Fast - from cache
service.GetData("user:456"); // Slow - fetches from DB
service.GetData("user:123"); // Fast - from cache
```

---

## Composite Pattern

> **Composes objects into tree structures to represent part-whole hierarchies**

Lets clients treat individual objects and compositions uniformly.

### When to Use
- Represent part-whole hierarchies
- Want clients to ignore difference between compositions and individual objects
- Need tree structures (file systems, menus, organizations)

### Problem: File System

```csharp
// Component interface
public interface IFileSystemItem
{
    string GetName();
    int GetSize();
    void Display(int indent = 0);
}

// Leaf - File
public class File : IFileSystemItem
{
    private readonly string _name;
    private readonly int _size;
    
    public File(string name, int size)
    {
        _name = name;
        _size = size;
    }
    
    public string GetName() => _name;
    public int GetSize() => _size;
    
    public void Display(int indent = 0)
    {
        Console.WriteLine($"{new string(' ', indent)}📄 {_name} ({_size} KB)");
    }
}

// Composite - Directory
public class Directory : IFileSystemItem
{
    private readonly string _name;
    private readonly List<IFileSystemItem> _items = new List<IFileSystemItem>();
    
    public Directory(string name)
    {
        _name = name;
    }
    
    public void Add(IFileSystemItem item)
    {
        _items.Add(item);
    }
    
    public void Remove(IFileSystemItem item)
    {
        _items.Remove(item);
    }
    
    public string GetName() => _name;
    
    public int GetSize()
    {
        // Sum of all children
        return _items.Sum(item => item.GetSize());
    }
    
    public void Display(int indent = 0)
    {
        Console.WriteLine($"{new string(' ', indent)}📁 {_name} ({GetSize()} KB)");
        foreach (var item in _items)
        {
            item.Display(indent + 2);
        }
    }
}

// Usage
var root = new Directory("root");

var documents = new Directory("Documents");
documents.Add(new File("resume.pdf", 120));
documents.Add(new File("cover-letter.docx", 45));

var photos = new Directory("Photos");
photos.Add(new File("vacation1.jpg", 2048));
photos.Add(new File("vacation2.jpg", 1856));

var workPhotos = new Directory("Work");
workPhotos.Add(new File("project1.png", 512));
workPhotos.Add(new File("project2.png", 384));
photos.Add(workPhotos);

root.Add(documents);
root.Add(photos);
root.Add(new File("readme.txt", 12));

// Display entire tree
root.Display();

// Output:
// 📁 root (4977 KB)
//   📁 Documents (165 KB)
//     📄 resume.pdf (120 KB)
//     📄 cover-letter.docx (45 KB)
//   📁 Photos (4800 KB)
//     📄 vacation1.jpg (2048 KB)
//     📄 vacation2.jpg (1856 KB)
//     📁 Work (896 KB)
//       📄 project1.png (512 KB)
//       📄 project2.png (384 KB)
//   📄 readme.txt (12 KB)

Console.WriteLine($"\nTotal size: {root.GetSize()} KB");
```

---

### Real-World Example: UI Components

```csharp
public interface IUIComponent
{
    void Render();
    void Add(IUIComponent component);
    void Remove(IUIComponent component);
}

// Leaf components
public class Button : IUIComponent
{
    private readonly string _text;
    
    public Button(string text)
    {
        _text = text;
    }
    
    public void Render()
    {
        Console.WriteLine($"  <button>{_text}</button>");
    }
    
    public void Add(IUIComponent component)
    {
        throw new NotSupportedException("Button cannot have children");
    }
    
    public void Remove(IUIComponent component)
    {
        throw new NotSupportedException("Button cannot have children");
    }
}

public class TextBox : IUIComponent
{
    private readonly string _placeholder;
    
    public TextBox(string placeholder)
    {
        _placeholder = placeholder;
    }
    
    public void Render()
    {
        Console.WriteLine($"  <input placeholder='{_placeholder}' />");
    }
    
    public void Add(IUIComponent component)
    {
        throw new NotSupportedException("TextBox cannot have children");
    }
    
    public void Remove(IUIComponent component)
    {
        throw new NotSupportedException("TextBox cannot have children");
    }
}

// Composite components
public class Panel : IUIComponent
{
    private readonly string _title;
    private readonly List<IUIComponent> _children = new List<IUIComponent>();
    
    public Panel(string title)
    {
        _title = title;
    }
    
    public void Add(IUIComponent component)
    {
        _children.Add(component);
    }
    
    public void Remove(IUIComponent component)
    {
        _children.Remove(component);
    }
    
    public void Render()
    {
        Console.WriteLine($"<div class='panel'>");
        Console.WriteLine($"  <h3>{_title}</h3>");
        foreach (var child in _children)
        {
            child.Render();
        }
        Console.WriteLine($"</div>");
    }
}

public class Form : IUIComponent
{
    private readonly string _name;
    private readonly List<IUIComponent> _children = new List<IUIComponent>();
    
    public Form(string name)
    {
        _name = name;
    }
    
    public void Add(IUIComponent component)
    {
        _children.Add(component);
    }
    
    public void Remove(IUIComponent component)
    {
        _children.Remove(component);
    }
    
    public void Render()
    {
        Console.WriteLine($"<form name='{_name}'>");
        foreach (var child in _children)
        {
            child.Render();
        }
        Console.WriteLine($"</form>");
    }
}

// Usage
var loginForm = new Form("loginForm");

var credentialsPanel = new Panel("Credentials");
credentialsPanel.Add(new TextBox("Username"));
credentialsPanel.Add(new TextBox("Password"));

var actionsPanel = new Panel("Actions");
actionsPanel.Add(new Button("Login"));
actionsPanel.Add(new Button("Cancel"));

loginForm.Add(credentialsPanel);
loginForm.Add(actionsPanel);

loginForm.Render();
```

---

## Bridge Pattern

> **Decouples an abstraction from its implementation so the two can vary independently**

### When to Use
- Want to avoid permanent binding between abstraction and implementation
- Both abstraction and implementation should be extensible by subclassing
- Changes in implementation shouldn't affect clients

### Problem & Solution

```csharp
// Implementation interface
public interface IMessageSender
{
    void SendMessage(string message);
}

// Concrete implementations
public class EmailSender : IMessageSender
{
    public void SendMessage(string message)
    {
        Console.WriteLine($"Email sent: {message}");
    }
}

public class SmsSender : IMessageSender
{
    public void SendMessage(string message)
    {
        Console.WriteLine($"SMS sent: {message}");
    }
}

public class PushNotificationSender : IMessageSender
{
    public void SendMessage(string message)
    {
        Console.WriteLine($"Push notification sent: {message}");
    }
}

// Abstraction
public abstract class Message
{
    protected IMessageSender _sender;
    
    protected Message(IMessageSender sender)
    {
        _sender = sender;
    }
    
    public abstract void Send();
}

// Refined abstractions
public class TextMessage : Message
{
    private readonly string _text;
    
    public TextMessage(IMessageSender sender, string text) : base(sender)
    {
        _text = text;
    }
    
    public override void Send()
    {
        _sender.SendMessage($"[TEXT] {_text}");
    }
}

public class UrgentMessage : Message
{
    private readonly string _text;
    
    public UrgentMessage(IMessageSender sender, string text) : base(sender)
    {
        _text = text;
    }
    
    public override void Send()
    {
        _sender.SendMessage($"[URGENT!!!] {_text}");
    }
}

// Usage - mix and match abstractions and implementations
Message message1 = new TextMessage(new EmailSender(), "Hello via email");
message1.Send();

Message message2 = new TextMessage(new SmsSender(), "Hello via SMS");
message2.Send();

Message message3 = new UrgentMessage(new PushNotificationSender(), "Server down!");
message3.Send();

Message message4 = new UrgentMessage(new EmailSender(), "Critical issue");
message4.Send();
```

---

## Flyweight Pattern

> **Uses sharing to support large numbers of fine-grained objects efficiently**

### When to Use
- Application uses many objects
- Storage costs are high due to object quantity
- Most object state can be made extrinsic
- Many groups of objects can be replaced by fewer shared objects

### Example: Text Editor Characters

```csharp
// Flyweight - shared immutable data
public class CharacterStyle
{
    public string Font { get; }
    public int Size { get; }
    public string Color { get; }
    
    public CharacterStyle(string font, int size, string color)
    {
        Font = font;
        Size = size;
        Color = color;
    }
    
    public void Display(char character)
    {
        Console.WriteLine($"Character '{character}' - Font: {Font}, Size: {Size}, Color: {Color}");
    }
}

// Flyweight factory
public class CharacterStyleFactory
{
    private readonly Dictionary<string, CharacterStyle> _styles = new Dictionary<string, CharacterStyle>();
    
    public CharacterStyle GetStyle(string font, int size, string color)
    {
        string key = $"{font}_{size}_{color}";
        
        if (!_styles.ContainsKey(key))
        {
            _styles[key] = new CharacterStyle(font, size, color);
            Console.WriteLine($"Creating new style: {key}");
        }
        
        return _styles[key];
    }
    
    public int GetTotalStyles() => _styles.Count;
}

// Client
public class Character
{
    private readonly char _symbol;
    private readonly CharacterStyle _style; // Shared flyweight
    
    public Character(char symbol, CharacterStyle style)
    {
        _symbol = symbol;
        _style = style;
    }
    
    public void Display()
    {
        _style.Display(_symbol);
    }
}

// Usage
var factory = new CharacterStyleFactory();

var characters = new List<Character>();

// Even with thousands of characters, only a few style objects are created
var arial12Black = factory.GetStyle("Arial", 12, "Black");
characters.Add(new Character('H', arial12Black));
characters.Add(new Character('e', arial12Black));
characters.Add(new Character('l', arial12Black));
characters.Add(new Character('l', arial12Black));
characters.Add(new Character('o', arial12Black));

var timesNewRoman14Red = factory.GetStyle("Times New Roman", 14, "Red");
characters.Add(new Character('W', timesNewRoman14Red));
characters.Add(new Character('o', timesNewRoman14Red));
characters.Add(new Character('r', timesNewRoman14Red));
characters.Add(new Character('l', timesNewRoman14Red));
characters.Add(new Character('d', timesNewRoman14Red));

Console.WriteLine($"\nTotal styles created: {factory.GetTotalStyles()}"); // Only 2!
Console.WriteLine($"Total characters: {characters.Count}"); // 10

// Display all
foreach (var character in characters)
{
    character.Display();
}
```

---

## Summary

### Structural Patterns Quick Reference

| Pattern | Purpose | When to Use | Key Benefit |
|---------|---------|-------------|-------------|
| **Adapter** | Convert interface | Incompatible interfaces | Makes incompatible code work together |
| **Decorator** | Add responsibilities | Extend functionality dynamically | Flexible alternative to subclassing |
| **Facade** | Simplify interface | Complex subsystem | Easier to use interface |
| **Proxy** | Control access | Lazy loading, access control, caching | Adds functionality without changing subject |
| **Composite** | Tree structures | Part-whole hierarchies | Uniform treatment of objects |
| **Bridge** | Separate abstraction/implementation | Both vary independently | Greater flexibility |
| **Flyweight** | Share objects | Many similar objects | Reduced memory usage |

### Best Practices

1. **Adapter**: Use when integrating third-party libraries
2. **Decorator**: Prefer over inheritance for extending behavior
3. **Facade**: Create for complex APIs to simplify client code
4. **Proxy**: Implement caching proxies for expensive operations
5. **Composite**: Perfect for tree-like structures (file systems, UI)
6. **Bridge**: Use when both abstraction and implementation may change
7. **Flyweight**: Optimize memory with many similar objects

---

**Continue to:** [Part 4: Behavioral Design Patterns](LLD-Guide-CSharp-Part4-Behavioral-Patterns.md)

**Previous:** [Part 2: Creational Design Patterns](LLD-Guide-CSharp-Part2-Creational-Patterns.md)
