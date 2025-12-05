# Low-Level Design Guide for C# - Part 1: Introduction & SOLID Principles

## Table of Contents
- [Introduction to LLD](#introduction-to-lld)
- [C# vs JS/TS: Key Differences](#c-vs-jsts-key-differences)
- [SOLID Principles](#solid-principles)
  - [Single Responsibility Principle (SRP)](#single-responsibility-principle-srp)
  - [Open/Closed Principle (OCP)](#openclosed-principle-ocp)
  - [Liskov Substitution Principle (LSP)](#liskov-substitution-principle-lsp)
  - [Interface Segregation Principle (ISP)](#interface-segregation-principle-isp)
  - [Dependency Inversion Principle (DIP)](#dependency-inversion-principle-dip)

---

## Introduction to LLD

**Low-Level Design (LLD)** focuses on the detailed design of individual components and classes in a system. It deals with:
- Class structure and relationships
- Design patterns
- Code organization
- Object-oriented principles
- Method signatures and data structures

### Why LLD Matters
- **Maintainability**: Well-designed code is easier to modify and extend
- **Scalability**: Proper design allows systems to grow without major rewrites
- **Testability**: Good LLD makes unit testing straightforward
- **Collaboration**: Clear design helps teams work together effectively

---

## C# vs JS/TS: Key Differences

As a JS/TS developer transitioning to C#, here are the key differences:

### Type System

**TypeScript:**
```typescript
interface User {
  id: number;
  name: string;
}

class UserService {
  getUser(id: number): User {
    // implementation
  }
}
```

**C#:**
```csharp
public interface IUser
{
    int Id { get; set; }
    string Name { get; set; }
}

public class User : IUser
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class UserService
{
    public User GetUser(int id)
    {
        // implementation
    }
}
```

### Key Differences:
1. **Explicit Access Modifiers**: C# requires `public`, `private`, `protected`, `internal`
2. **Properties vs Fields**: C# uses properties with getters/setters
3. **Strong Typing**: C# is statically typed (no `any` escape hatch like TS)
4. **Interfaces**: C# interfaces are contracts; classes must explicitly implement them
5. **Null Safety**: C# 8.0+ has nullable reference types (similar to TS strict null checks)
6. **No duck typing**: C# uses nominal typing (must explicitly implement interfaces)

### Naming Conventions

| Element | TypeScript | C# |
|---------|-----------|-----|
| Classes | PascalCase | PascalCase |
| Interfaces | PascalCase (I prefix optional) | PascalCase (I prefix required) |
| Methods | camelCase | PascalCase |
| Properties | camelCase | PascalCase |
| Private fields | _camelCase or camelCase | _camelCase or camelCase |
| Constants | UPPER_CASE or camelCase | PascalCase or UPPER_CASE |

---

## SOLID Principles

SOLID is an acronym for five design principles that make software designs more understandable, flexible, and maintainable.

---

### Single Responsibility Principle (SRP)

> **A class should have only one reason to change**

Each class should focus on a single responsibility or concern.

#### ❌ Bad Example (Violates SRP)

```csharp
// This class has multiple responsibilities
public class UserManager
{
    public void CreateUser(string email, string password)
    {
        // 1. Validate user data
        if (string.IsNullOrEmpty(email) || !email.Contains("@"))
            throw new ArgumentException("Invalid email");
        
        // 2. Hash password
        string hashedPassword = BCrypt.HashPassword(password);
        
        // 3. Save to database
        using (var connection = new SqlConnection("connectionString"))
        {
            var command = new SqlCommand("INSERT INTO Users...", connection);
            command.ExecuteNonQuery();
        }
        
        // 4. Send email
        var smtpClient = new SmtpClient("smtp.gmail.com");
        smtpClient.Send(new MailMessage("from@email.com", email, "Welcome!", "Thanks for joining!"));
        
        // 5. Log the action
        File.AppendAllText("log.txt", $"User created: {email}");
    }
}
```

**Problems:**
- Class changes if validation rules change
- Class changes if database changes
- Class changes if email provider changes
- Class changes if logging mechanism changes
- Hard to test individual behaviors

#### ✅ Good Example (Follows SRP)

```csharp
// Each class has a single responsibility

public interface IUserValidator
{
    void Validate(string email, string password);
}

public class UserValidator : IUserValidator
{
    public void Validate(string email, string password)
    {
        if (string.IsNullOrEmpty(email) || !email.Contains("@"))
            throw new ArgumentException("Invalid email");
        
        if (string.IsNullOrEmpty(password) || password.Length < 8)
            throw new ArgumentException("Password must be at least 8 characters");
    }
}

public interface IPasswordHasher
{
    string Hash(string password);
}

public class BcryptPasswordHasher : IPasswordHasher
{
    public string Hash(string password)
    {
        return BCrypt.HashPassword(password);
    }
}

public interface IUserRepository
{
    void Save(User user);
}

public class UserRepository : IUserRepository
{
    private readonly string _connectionString;
    
    public UserRepository(string connectionString)
    {
        _connectionString = connectionString;
    }
    
    public void Save(User user)
    {
        using (var connection = new SqlConnection(_connectionString))
        {
            var command = new SqlCommand("INSERT INTO Users (Email, PasswordHash) VALUES (@Email, @PasswordHash)", connection);
            command.Parameters.AddWithValue("@Email", user.Email);
            command.Parameters.AddWithValue("@PasswordHash", user.PasswordHash);
            connection.Open();
            command.ExecuteNonQuery();
        }
    }
}

public interface IEmailService
{
    void SendWelcomeEmail(string email);
}

public class EmailService : IEmailService
{
    private readonly string _smtpHost;
    
    public EmailService(string smtpHost)
    {
        _smtpHost = smtpHost;
    }
    
    public void SendWelcomeEmail(string email)
    {
        var smtpClient = new SmtpClient(_smtpHost);
        smtpClient.Send(new MailMessage("from@email.com", email, "Welcome!", "Thanks for joining!"));
    }
}

public interface ILogger
{
    void Log(string message);
}

public class FileLogger : ILogger
{
    private readonly string _logFilePath;
    
    public FileLogger(string logFilePath)
    {
        _logFilePath = logFilePath;
    }
    
    public void Log(string message)
    {
        File.AppendAllText(_logFilePath, $"{DateTime.UtcNow}: {message}\n");
    }
}

public class User
{
    public string Email { get; set; }
    public string PasswordHash { get; set; }
}

// Now the UserManager orchestrates, but delegates responsibilities
public class UserManager
{
    private readonly IUserValidator _validator;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IUserRepository _repository;
    private readonly IEmailService _emailService;
    private readonly ILogger _logger;
    
    public UserManager(
        IUserValidator validator,
        IPasswordHasher passwordHasher,
        IUserRepository repository,
        IEmailService emailService,
        ILogger logger)
    {
        _validator = validator;
        _passwordHasher = passwordHasher;
        _repository = repository;
        _emailService = emailService;
        _logger = logger;
    }
    
    public void CreateUser(string email, string password)
    {
        _validator.Validate(email, password);
        
        var user = new User
        {
            Email = email,
            PasswordHash = _passwordHasher.Hash(password)
        };
        
        _repository.Save(user);
        _emailService.SendWelcomeEmail(email);
        _logger.Log($"User created: {email}");
    }
}
```

**Benefits:**
- Each class can be tested independently
- Changes to one responsibility don't affect others
- Easy to swap implementations (e.g., use different logger)
- Code is more readable and maintainable

#### JS/TS Comparison

In TypeScript, you might use modules and dependency injection similarly:

```typescript
// TypeScript equivalent
export class UserManager {
  constructor(
    private validator: IUserValidator,
    private passwordHasher: IPasswordHasher,
    private repository: IUserRepository,
    private emailService: IEmailService,
    private logger: ILogger
  ) {}
  
  createUser(email: string, password: string): void {
    // Same logic as C#
  }
}
```

The concept is the same, but C# enforces interface contracts more strictly.

---

### Open/Closed Principle (OCP)

> **Software entities should be open for extension but closed for modification**

You should be able to add new functionality without changing existing code.

#### ❌ Bad Example (Violates OCP)

```csharp
public enum PaymentMethod
{
    CreditCard,
    PayPal,
    BankTransfer
}

public class PaymentProcessor
{
    public void ProcessPayment(decimal amount, PaymentMethod method)
    {
        if (method == PaymentMethod.CreditCard)
        {
            Console.WriteLine($"Processing credit card payment of ${amount}");
            // Credit card specific logic
            ValidateCreditCard();
            ChargeCreditCard(amount);
        }
        else if (method == PaymentMethod.PayPal)
        {
            Console.WriteLine($"Processing PayPal payment of ${amount}");
            // PayPal specific logic
            AuthenticatePayPal();
            ChargePayPal(amount);
        }
        else if (method == PaymentMethod.BankTransfer)
        {
            Console.WriteLine($"Processing bank transfer of ${amount}");
            // Bank transfer specific logic
            ValidateBankAccount();
            TransferFunds(amount);
        }
    }
    
    // Helper methods...
}
```

**Problem**: Every time we add a new payment method (e.g., Cryptocurrency), we must modify the `PaymentProcessor` class.

#### ✅ Good Example (Follows OCP)

```csharp
// Define an abstraction
public interface IPaymentMethod
{
    void ProcessPayment(decimal amount);
    string GetPaymentMethodName();
}

// Implement specific payment methods
public class CreditCardPayment : IPaymentMethod
{
    private readonly string _cardNumber;
    private readonly string _cvv;
    
    public CreditCardPayment(string cardNumber, string cvv)
    {
        _cardNumber = cardNumber;
        _cvv = cvv;
    }
    
    public void ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing credit card payment of ${amount}");
        ValidateCard();
        Charge(amount);
    }
    
    public string GetPaymentMethodName() => "Credit Card";
    
    private void ValidateCard()
    {
        // Validate card number and CVV
        if (_cardNumber.Length != 16)
            throw new InvalidOperationException("Invalid card number");
    }
    
    private void Charge(decimal amount)
    {
        // Charge the credit card
        Console.WriteLine($"Charged ${amount} to card ending in {_cardNumber.Substring(12)}");
    }
}

public class PayPalPayment : IPaymentMethod
{
    private readonly string _email;
    private readonly string _password;
    
    public PayPalPayment(string email, string password)
    {
        _email = email;
        _password = password;
    }
    
    public void ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing PayPal payment of ${amount}");
        Authenticate();
        Charge(amount);
    }
    
    public string GetPaymentMethodName() => "PayPal";
    
    private void Authenticate()
    {
        // Authenticate with PayPal
        Console.WriteLine($"Authenticated PayPal account: {_email}");
    }
    
    private void Charge(decimal amount)
    {
        Console.WriteLine($"Charged ${amount} via PayPal");
    }
}

public class BankTransferPayment : IPaymentMethod
{
    private readonly string _accountNumber;
    private readonly string _routingNumber;
    
    public BankTransferPayment(string accountNumber, string routingNumber)
    {
        _accountNumber = accountNumber;
        _routingNumber = routingNumber;
    }
    
    public void ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing bank transfer of ${amount}");
        ValidateAccount();
        Transfer(amount);
    }
    
    public string GetPaymentMethodName() => "Bank Transfer";
    
    private void ValidateAccount()
    {
        Console.WriteLine($"Validating account: {_accountNumber}");
    }
    
    private void Transfer(decimal amount)
    {
        Console.WriteLine($"Transferred ${amount} from account {_accountNumber}");
    }
}

// NEW: Adding cryptocurrency without modifying existing code!
public class CryptocurrencyPayment : IPaymentMethod
{
    private readonly string _walletAddress;
    
    public CryptocurrencyPayment(string walletAddress)
    {
        _walletAddress = walletAddress;
    }
    
    public void ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing cryptocurrency payment of ${amount}");
        ValidateWallet();
        TransferCrypto(amount);
    }
    
    public string GetPaymentMethodName() => "Cryptocurrency";
    
    private void ValidateWallet()
    {
        Console.WriteLine($"Validating wallet: {_walletAddress}");
    }
    
    private void TransferCrypto(decimal amount)
    {
        Console.WriteLine($"Transferred ${amount} worth of crypto to {_walletAddress}");
    }
}

// The processor is now closed for modification, open for extension
public class PaymentProcessor
{
    public void ProcessPayment(decimal amount, IPaymentMethod paymentMethod)
    {
        Console.WriteLine($"Starting payment via {paymentMethod.GetPaymentMethodName()}");
        paymentMethod.ProcessPayment(amount);
        Console.WriteLine("Payment completed successfully");
    }
}

// Usage
public class Program
{
    public static void Main()
    {
        var processor = new PaymentProcessor();
        
        // Process different payments
        processor.ProcessPayment(100.00m, new CreditCardPayment("1234567890123456", "123"));
        processor.ProcessPayment(250.00m, new PayPalPayment("user@email.com", "password"));
        processor.ProcessPayment(500.00m, new BankTransferPayment("9876543210", "123456789"));
        
        // New payment method without modifying PaymentProcessor!
        processor.ProcessPayment(75.00m, new CryptocurrencyPayment("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"));
    }
}
```

**Benefits:**
- Add new payment methods without changing `PaymentProcessor`
- Each payment method is independently testable
- No risk of breaking existing payment methods when adding new ones

---

### Liskov Substitution Principle (LSP)

> **Objects of a superclass should be replaceable with objects of a subclass without breaking the application**

Subtypes must be substitutable for their base types.

#### ❌ Bad Example (Violates LSP)

```csharp
public class Bird
{
    public virtual void Fly()
    {
        Console.WriteLine("Flying in the sky");
    }
}

public class Sparrow : Bird
{
    public override void Fly()
    {
        Console.WriteLine("Sparrow flying");
    }
}

public class Penguin : Bird
{
    public override void Fly()
    {
        // Penguins can't fly!
        throw new NotSupportedException("Penguins cannot fly");
    }
}

// Usage
public class BirdWatcher
{
    public void MakeBirdFly(Bird bird)
    {
        bird.Fly(); // This will throw an exception for Penguin!
    }
}

// This breaks LSP
var watcher = new BirdWatcher();
watcher.MakeBirdFly(new Sparrow()); // Works
watcher.MakeBirdFly(new Penguin()); // Throws exception!
```

**Problem**: `Penguin` cannot be substituted for `Bird` without breaking the application.

#### ✅ Good Example (Follows LSP)

```csharp
// Better abstraction
public abstract class Bird
{
    public abstract void Move();
    public abstract void MakeSound();
}

public interface IFlyable
{
    void Fly();
}

public interface ISwimmable
{
    void Swim();
}

public class Sparrow : Bird, IFlyable
{
    public override void Move()
    {
        Fly();
    }
    
    public void Fly()
    {
        Console.WriteLine("Sparrow is flying");
    }
    
    public override void MakeSound()
    {
        Console.WriteLine("Chirp chirp");
    }
}

public class Penguin : Bird, ISwimmable
{
    public override void Move()
    {
        Swim();
    }
    
    public void Swim()
    {
        Console.WriteLine("Penguin is swimming");
    }
    
    public override void MakeSound()
    {
        Console.WriteLine("Squawk");
    }
}

public class Duck : Bird, IFlyable, ISwimmable
{
    public override void Move()
    {
        // Ducks can choose
        Fly();
    }
    
    public void Fly()
    {
        Console.WriteLine("Duck is flying");
    }
    
    public void Swim()
    {
        Console.WriteLine("Duck is swimming");
    }
    
    public override void MakeSound()
    {
        Console.WriteLine("Quack quack");
    }
}

// Usage
public class BirdWatcher
{
    public void ObserveBird(Bird bird)
    {
        bird.Move(); // Works for all birds
        bird.MakeSound();
    }
    
    public void ObserveFlyingBird(IFlyable flyingBird)
    {
        flyingBird.Fly(); // Only accepts birds that can fly
    }
    
    public void ObserveSwimmingBird(ISwimmable swimmingBird)
    {
        swimmingBird.Swim(); // Only accepts birds that can swim
    }
}

// This follows LSP
var watcher = new BirdWatcher();
watcher.ObserveBird(new Sparrow()); // Works
watcher.ObserveBird(new Penguin()); // Works
watcher.ObserveBird(new Duck());    // Works

watcher.ObserveFlyingBird(new Sparrow()); // Works
watcher.ObserveFlyingBird(new Duck());    // Works
// watcher.ObserveFlyingBird(new Penguin()); // Won't compile - good!
```

#### Another Example: Rectangle-Square Problem

❌ **Bad:**

```csharp
public class Rectangle
{
    public virtual int Width { get; set; }
    public virtual int Height { get; set; }
    
    public int GetArea()
    {
        return Width * Height;
    }
}

public class Square : Rectangle
{
    public override int Width
    {
        get => base.Width;
        set
        {
            base.Width = value;
            base.Height = value; // Setting both!
        }
    }
    
    public override int Height
    {
        get => base.Height;
        set
        {
            base.Height = value;
            base.Width = value; // Setting both!
        }
    }
}

// This violates LSP
void TestRectangle(Rectangle rect)
{
    rect.Width = 5;
    rect.Height = 4;
    Assert.AreEqual(20, rect.GetArea()); // Fails for Square!
}
```

✅ **Good:**

```csharp
public interface IShape
{
    int GetArea();
}

public class Rectangle : IShape
{
    public int Width { get; set; }
    public int Height { get; set; }
    
    public int GetArea()
    {
        return Width * Height;
    }
}

public class Square : IShape
{
    public int SideLength { get; set; }
    
    public int GetArea()
    {
        return SideLength * SideLength;
    }
}

// Now they're not in a hierarchy that violates LSP
void TestShape(IShape shape)
{
    int area = shape.GetArea(); // Works for both
}
```

---

### Interface Segregation Principle (ISP)

> **Clients should not be forced to depend on interfaces they don't use**

Keep interfaces small and focused rather than large and monolithic.

#### ❌ Bad Example (Violates ISP)

```csharp
// Fat interface with too many responsibilities
public interface IWorker
{
    void Work();
    void Eat();
    void Sleep();
    void GetPaid();
    void TakeMedicalLeave();
    void AttendMeeting();
}

// Human worker - uses all methods
public class HumanWorker : IWorker
{
    public void Work() => Console.WriteLine("Working...");
    public void Eat() => Console.WriteLine("Eating lunch...");
    public void Sleep() => Console.WriteLine("Sleeping...");
    public void GetPaid() => Console.WriteLine("Receiving salary...");
    public void TakeMedicalLeave() => Console.WriteLine("Taking leave...");
    public void AttendMeeting() => Console.WriteLine("Attending meeting...");
}

// Robot worker - doesn't eat, sleep, or take leave!
public class RobotWorker : IWorker
{
    public void Work() => Console.WriteLine("Working...");
    public void GetPaid() => Console.WriteLine("Maintenance cost...");
    public void AttendMeeting() => Console.WriteLine("Attending meeting...");
    
    // Forced to implement methods that don't make sense
    public void Eat() => throw new NotSupportedException("Robots don't eat");
    public void Sleep() => throw new NotSupportedException("Robots don't sleep");
    public void TakeMedicalLeave() => throw new NotSupportedException("Robots don't take medical leave");
}
```

#### ✅ Good Example (Follows ISP)

```csharp
// Split into smaller, focused interfaces
public interface IWorkable
{
    void Work();
}

public interface IPayable
{
    void GetPaid();
}

public interface IFeedable
{
    void Eat();
}

public interface ISleepable
{
    void Sleep();
}

public interface IMedicalLeavable
{
    void TakeMedicalLeave();
}

public interface IMeetingAttendee
{
    void AttendMeeting();
}

// Human worker implements what it needs
public class HumanWorker : IWorkable, IPayable, IFeedable, ISleepable, IMedicalLeavable, IMeetingAttendee
{
    public void Work() => Console.WriteLine("Working...");
    public void Eat() => Console.WriteLine("Eating lunch...");
    public void Sleep() => Console.WriteLine("Sleeping...");
    public void GetPaid() => Console.WriteLine("Receiving salary...");
    public void TakeMedicalLeave() => Console.WriteLine("Taking leave...");
    public void AttendMeeting() => Console.WriteLine("Attending meeting...");
}

// Robot worker implements only what it needs
public class RobotWorker : IWorkable, IPayable, IMeetingAttendee
{
    public void Work() => Console.WriteLine("Working 24/7...");
    public void GetPaid() => Console.WriteLine("Processing maintenance cost...");
    public void AttendMeeting() => Console.WriteLine("Attending meeting via video link...");
}

// Contractor - works, gets paid, attends meetings, but no medical leave
public class ContractorWorker : IWorkable, IPayable, IMeetingAttendee
{
    public void Work() => Console.WriteLine("Working remotely...");
    public void GetPaid() => Console.WriteLine("Receiving payment...");
    public void AttendMeeting() => Console.WriteLine("Attending virtual meeting...");
}

// Usage
public class WorkManager
{
    public void ManageWork(IWorkable worker)
    {
        worker.Work();
    }
    
    public void ProcessPayroll(IPayable worker)
    {
        worker.GetPaid();
    }
    
    public void ScheduleMeeting(IMeetingAttendee attendee)
    {
        attendee.AttendMeeting();
    }
    
    public void ProcessLeave(IMedicalLeavable employee)
    {
        employee.TakeMedicalLeave();
    }
}
```

**Benefits:**
- Classes only implement what they need
- No throwing `NotSupportedException`
- Easy to add new worker types
- Clear contracts

#### JS/TS Comparison

TypeScript uses structural typing, so ISP is less strictly enforced:

```typescript
// TypeScript - structural typing
interface Worker {
  work(): void;
  eat?(): void;  // Optional methods
  sleep?(): void;
}

// This works but isn't ideal
const robot: Worker = {
  work: () => console.log("Working")
  // Can omit eat and sleep
};
```

C# forces you to implement all interface members, which makes ISP more important.

---

### Dependency Inversion Principle (DIP)

> **High-level modules should not depend on low-level modules. Both should depend on abstractions.**

> **Abstractions should not depend on details. Details should depend on abstractions.**

#### ❌ Bad Example (Violates DIP)

```csharp
// Low-level modules (concrete implementations)
public class EmailSender
{
    public void SendEmail(string to, string subject, string body)
    {
        Console.WriteLine($"Sending email to {to}: {subject}");
        // SMTP logic
    }
}

public class SmsSender
{
    public void SendSms(string phoneNumber, string message)
    {
        Console.WriteLine($"Sending SMS to {phoneNumber}: {message}");
        // SMS gateway logic
    }
}

// High-level module depends directly on low-level modules
public class NotificationService
{
    private EmailSender _emailSender;
    private SmsSender _smsSender;
    
    public NotificationService()
    {
        // Tightly coupled to concrete implementations
        _emailSender = new EmailSender();
        _smsSender = new SmsSender();
    }
    
    public void NotifyUserByEmail(string email, string message)
    {
        _emailSender.SendEmail(email, "Notification", message);
    }
    
    public void NotifyUserBySms(string phone, string message)
    {
        _smsSender.SendSms(phone, message);
    }
}
```

**Problems:**
- `NotificationService` is tightly coupled to specific implementations
- Hard to test (can't mock `EmailSender` or `SmsSender`)
- Can't easily add new notification methods
- Violates OCP too

#### ✅ Good Example (Follows DIP)

```csharp
// Abstraction (high-level)
public interface INotificationChannel
{
    void Send(string recipient, string message);
    string GetChannelName();
}

// Low-level modules depend on abstraction
public class EmailNotificationChannel : INotificationChannel
{
    private readonly string _smtpServer;
    
    public EmailNotificationChannel(string smtpServer)
    {
        _smtpServer = smtpServer;
    }
    
    public void Send(string recipient, string message)
    {
        Console.WriteLine($"[EMAIL via {_smtpServer}] To: {recipient}");
        Console.WriteLine($"Message: {message}");
        // Actual SMTP logic here
    }
    
    public string GetChannelName() => "Email";
}

public class SmsNotificationChannel : INotificationChannel
{
    private readonly string _gatewayUrl;
    
    public SmsNotificationChannel(string gatewayUrl)
    {
        _gatewayUrl = gatewayUrl;
    }
    
    public void Send(string recipient, string message)
    {
        Console.WriteLine($"[SMS via {_gatewayUrl}] To: {recipient}");
        Console.WriteLine($"Message: {message}");
        // Actual SMS gateway logic here
    }
    
    public string GetChannelName() => "SMS";
}

public class PushNotificationChannel : INotificationChannel
{
    private readonly string _fcmApiKey;
    
    public PushNotificationChannel(string fcmApiKey)
    {
        _fcmApiKey = fcmApiKey;
    }
    
    public void Send(string recipient, string message)
    {
        Console.WriteLine($"[PUSH via FCM] To device: {recipient}");
        Console.WriteLine($"Message: {message}");
        // FCM push notification logic here
    }
    
    public string GetChannelName() => "Push Notification";
}

// High-level module depends on abstraction
public class NotificationService
{
    private readonly IEnumerable<INotificationChannel> _channels;
    
    // Dependency injection - depends on abstraction, not concrete types
    public NotificationService(IEnumerable<INotificationChannel> channels)
    {
        _channels = channels;
    }
    
    public void NotifyUser(string recipient, string message)
    {
        foreach (var channel in _channels)
        {
            channel.Send(recipient, message);
        }
    }
    
    public void NotifyUserViaChannel(string recipient, string message, string channelName)
    {
        var channel = _channels.FirstOrDefault(c => c.GetChannelName() == channelName);
        if (channel != null)
        {
            channel.Send(recipient, message);
        }
        else
        {
            throw new ArgumentException($"Channel '{channelName}' not found");
        }
    }
}

// Usage with Dependency Injection
public class Program
{
    public static void Main()
    {
        // Configure dependencies
        var channels = new List<INotificationChannel>
        {
            new EmailNotificationChannel("smtp.gmail.com"),
            new SmsNotificationChannel("https://sms-gateway.com"),
            new PushNotificationChannel("fcm-api-key-123")
        };
        
        // Inject dependencies
        var notificationService = new NotificationService(channels);
        
        // Use the service
        notificationService.NotifyUserViaChannel("user@email.com", "Hello!", "Email");
        notificationService.NotifyUserViaChannel("+1234567890", "Hello!", "SMS");
        
        // Send via all channels
        notificationService.NotifyUser("recipient", "Important message");
    }
}

// Easy to test with mocks
public class NotificationServiceTests
{
    [Test]
    public void TestNotifyUser()
    {
        // Create mock channels
        var mockChannel = new Mock<INotificationChannel>();
        mockChannel.Setup(c => c.Send(It.IsAny<string>(), It.IsAny<string>()));
        
        var service = new NotificationService(new[] { mockChannel.Object });
        service.NotifyUser("test@email.com", "Test message");
        
        mockChannel.Verify(c => c.Send("test@email.com", "Test message"), Times.Once);
    }
}
```

**Benefits:**
- `NotificationService` doesn't depend on concrete implementations
- Easy to test with mocks
- Easy to add new notification channels
- Follows OCP as well
- Can swap implementations at runtime

#### DIP in Practice: Dependency Injection

C# heavily uses Dependency Injection (DI) containers (similar to Angular's DI):

```csharp
// In ASP.NET Core Startup.cs or Program.cs
public void ConfigureServices(IServiceCollection services)
{
    // Register dependencies
    services.AddScoped<INotificationChannel, EmailNotificationChannel>();
    services.AddScoped<NotificationService>();
    
    // The DI container will automatically inject dependencies
}

// In a controller
public class UserController : Controller
{
    private readonly NotificationService _notificationService;
    
    // DI container automatically provides NotificationService
    public UserController(NotificationService notificationService)
    {
        _notificationService = notificationService;
    }
    
    public IActionResult SendNotification()
    {
        _notificationService.NotifyUser("user@email.com", "Hello!");
        return Ok();
    }
}
```

---

## Summary

### SOLID Quick Reference

| Principle | Meaning | Key Benefit |
|-----------|---------|-------------|
| **S**RP | One class, one responsibility | Easier to understand and modify |
| **O**CP | Open for extension, closed for modification | Add features without breaking existing code |
| **L**SP | Subtypes must be substitutable | Reliable inheritance hierarchies |
| **I**SP | Small, focused interfaces | No forced implementation of unused methods |
| **D**IP | Depend on abstractions, not concretions | Loose coupling, easy testing |

### Key Takeaways for JS/TS Developers

1. **C# enforces contracts strictly** - Interfaces must be fully implemented
2. **Use constructor injection** - Similar to Angular's DI
3. **Abstract classes vs Interfaces** - C# has both (TS only has interfaces)
4. **Properties over fields** - Use `{ get; set; }` instead of direct field access
5. **Access modifiers matter** - Always specify `public`, `private`, etc.

### Next Steps

In **Part 2**, we'll cover:
- Creational Design Patterns (Factory, Builder, Singleton, etc.)
- When and why to use each pattern
- Real-world examples in C#

---

**Continue to:** [Part 2: Creational Design Patterns](LLD-Guide-CSharp-Part2-Creational-Patterns.md)
