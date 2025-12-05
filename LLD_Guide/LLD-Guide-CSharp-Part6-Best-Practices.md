# Low-Level Design Guide for C# - Part 6: Best Practices & Interview Tips

## Table of Contents
- [LLD Interview Approach](#lld-interview-approach)
- [Design Principles Checklist](#design-principles-checklist)
- [Code Quality Best Practices](#code-quality-best-practices)
- [Common Mistakes to Avoid](#common-mistakes-to-avoid)
- [Interview Problem-Solving Framework](#interview-problem-solving-framework)
- [Advanced Topics](#advanced-topics)
- [Practice Problems](#practice-problems)
- [Resources for Further Learning](#resources-for-further-learning)

---

## LLD Interview Approach

### The 7-Step Process

#### 1. **Clarify Requirements** (5-10 minutes)
Ask questions to understand the scope:

```
Example: Design a Parking Lot

Questions to ask:
- What types of vehicles? (Car, motorcycle, truck)
- How many levels/floors?
- Pricing model? (Hourly, daily, vehicle type)
- Entry/exit system? (Ticket-based, RFID)
- Payment methods?
- Peak capacity?
- Do we need to track availability in real-time?
```

**For JS/TS developers**: This is similar to understanding API requirements before building endpoints.

---

#### 2. **Define Use Cases** (5 minutes)
List primary and secondary use cases:

```
Primary:
- Park a vehicle
- Unpark a vehicle
- Calculate fee
- Check availability

Secondary:
- Reserve a spot
- Handle payment
- Generate reports
- Handle admin functions
```

---

#### 3. **Identify Core Entities** (5-10 minutes)
List nouns (entities) and their attributes:

```csharp
// Core Entities
class Vehicle
{
    string LicensePlate
    VehicleType Type
}

class ParkingSpot
{
    int SpotNumber
    SpotType Type
    SpotStatus Status
}

class ParkingTicket
{
    string TicketId
    DateTime EntryTime
    DateTime ExitTime
}

class ParkingLot
{
    List<ParkingLevel> Levels
}
```

---

#### 4. **Define Relationships** (5 minutes)
Identify how entities relate:

```
- ParkingLot HAS-MANY ParkingLevel
- ParkingLevel HAS-MANY ParkingSpot
- ParkingSpot CAN-HAVE-ONE Vehicle
- Vehicle HAS-ONE ParkingTicket
- ParkingTicket BELONGS-TO Vehicle
```

**Relationship Types:**
- **Composition** (HAS-A): ParkingLot has ParkingLevels (Level can't exist without Lot)
- **Aggregation** (HAS-A): ParkingSpot has Vehicle (Vehicle can exist independently)
- **Association**: Ticket is associated with Vehicle
- **Inheritance** (IS-A): Car IS-A Vehicle

---

#### 5. **Apply Design Patterns** (10-15 minutes)
Choose appropriate patterns:

```csharp
// Singleton for ParkingLot (single instance)
public class ParkingLot
{
    private static readonly Lazy<ParkingLot> _instance;
    public static ParkingLot Instance => _instance.Value;
}

// Strategy for pricing
public interface IPricingStrategy
{
    decimal CalculateFee(TimeSpan duration, VehicleType type);
}

// Factory for vehicle creation
public class VehicleFactory
{
    public static Vehicle CreateVehicle(VehicleType type, string licensePlate)
    {
        return type switch
        {
            VehicleType.Car => new Car(licensePlate),
            VehicleType.Motorcycle => new Motorcycle(licensePlate),
            VehicleType.Truck => new Truck(licensePlate),
            _ => throw new ArgumentException("Invalid vehicle type")
        };
    }
}
```

---

#### 6. **Design Class Diagram** (10 minutes)
Draw or describe the class structure:

```
┌────────────────┐
│  ParkingLot    │
├────────────────┤
│ - levels       │
│ - tickets      │
├────────────────┤
│ + parkVehicle()│
│ + unparkVehicle│
└────────┬───────┘
         │ 1
         │ *
         │
┌────────▼───────┐
│ ParkingLevel   │
├────────────────┤
│ - levelNumber  │
│ - spots        │
├────────────────┤
│ + findSpot()   │
└────────┬───────┘
         │ 1
         │ *
         │
┌────────▼───────┐
│ ParkingSpot    │
├────────────────┤
│ - spotNumber   │
│ - type         │
│ - status       │
├────────────────┤
│ + parkVehicle()│
│ + canFit()     │
└────────────────┘
```

---

#### 7. **Code Implementation** (20-30 minutes)
Write clean, compilable code:

```csharp
public class ParkingLot
{
    private static readonly Lazy<ParkingLot> _instance = 
        new Lazy<ParkingLot>(() => new ParkingLot());
    public static ParkingLot Instance => _instance.Value;
    
    private readonly List<ParkingLevel> _levels;
    private readonly Dictionary<string, ParkingTicket> _tickets;
    
    private ParkingLot()
    {
        _levels = new List<ParkingLevel>();
        _tickets = new Dictionary<string, ParkingTicket>();
    }
    
    public ParkingTicket ParkVehicle(Vehicle vehicle)
    {
        foreach (var level in _levels)
        {
            var spot = level.FindAvailableSpot(vehicle);
            if (spot != null)
            {
                spot.ParkVehicle(vehicle);
                var ticket = new ParkingTicket(vehicle, spot);
                _tickets[ticket.TicketId] = ticket;
                return ticket;
            }
        }
        throw new InvalidOperationException("No available spots");
    }
    
    public decimal UnparkVehicle(string ticketId)
    {
        if (!_tickets.TryGetValue(ticketId, out var ticket))
            throw new ArgumentException("Invalid ticket");
        
        ticket.Spot.RemoveVehicle();
        ticket.ExitTime = DateTime.Now;
        
        var fee = CalculateFee(ticket);
        _tickets.Remove(ticketId);
        
        return fee;
    }
    
    private decimal CalculateFee(ParkingTicket ticket)
    {
        var duration = ticket.ExitTime.Value - ticket.EntryTime;
        var hours = Math.Ceiling(duration.TotalHours);
        
        return ticket.Vehicle.Type switch
        {
            VehicleType.Motorcycle => (decimal)hours * 5m,
            VehicleType.Car => (decimal)hours * 10m,
            VehicleType.Truck => (decimal)hours * 20m,
            _ => 0m
        };
    }
}
```

---

## Design Principles Checklist

### SOLID Compliance

✅ **Single Responsibility**
- Each class has one clear purpose
- Example: `FeeCalculator` only calculates fees, doesn't manage spots

```csharp
// Good
public class FeeCalculator
{
    public decimal Calculate(TimeSpan duration, VehicleType type) { }
}

// Bad
public class ParkingSpot
{
    public void ParkVehicle() { }
    public decimal CalculateFee() { } // Wrong! Not spot's responsibility
}
```

✅ **Open/Closed**
- Extend via inheritance/composition, not modification
- Use interfaces and abstract classes

```csharp
// Good - can add new pricing strategies without modifying existing code
public interface IPricingStrategy
{
    decimal CalculateFee(TimeSpan duration, VehicleType type);
}

public class HourlyPricing : IPricingStrategy { }
public class DailyPricing : IPricingStrategy { }
```

✅ **Liskov Substitution**
- Subclasses should be substitutable for base classes

```csharp
// Good
public abstract class Vehicle
{
    public abstract bool CanPark(SpotType spotType);
}

public class Motorcycle : Vehicle
{
    public override bool CanPark(SpotType spotType) => true; // Can park anywhere
}
```

✅ **Interface Segregation**
- Small, focused interfaces

```csharp
// Good - segregated interfaces
public interface IPayable
{
    void ProcessPayment(decimal amount);
}

public interface IReservable
{
    void Reserve(DateTime from, DateTime to);
}

// Bad - fat interface
public interface IParkingService
{
    void Park();
    void Unpark();
    void Pay();
    void Reserve();
    void CancelReservation();
    void GenerateReport();
}
```

✅ **Dependency Inversion**
- Depend on abstractions, not concretions

```csharp
// Good
public class ParkingLot
{
    private readonly IPaymentProcessor _paymentProcessor;
    private readonly INotificationService _notificationService;
    
    public ParkingLot(IPaymentProcessor paymentProcessor, INotificationService notificationService)
    {
        _paymentProcessor = paymentProcessor;
        _notificationService = notificationService;
    }
}

// Bad
public class ParkingLot
{
    private readonly CreditCardProcessor _processor = new CreditCardProcessor(); // Tightly coupled
}
```

---

## Code Quality Best Practices

### 1. Naming Conventions

```csharp
// ✅ Good naming
public class ParkingSpot
{
    public int SpotNumber { get; set; }
    public SpotType Type { get; set; }
    
    public bool CanFitVehicle(Vehicle vehicle)
    {
        return vehicle.Type switch
        {
            VehicleType.Motorcycle => true,
            VehicleType.Car => Type == SpotType.Compact || Type == SpotType.Large,
            VehicleType.Truck => Type == SpotType.Large,
            _ => false
        };
    }
}

// ❌ Bad naming
public class PS
{
    public int num { get; set; }
    public int t { get; set; }
    
    public bool fit(Vehicle v)
    {
        // ...
    }
}
```

### 2. Error Handling

```csharp
// ✅ Good - specific exceptions
public ParkingTicket ParkVehicle(Vehicle vehicle)
{
    if (vehicle == null)
        throw new ArgumentNullException(nameof(vehicle));
    
    var spot = FindAvailableSpot(vehicle);
    if (spot == null)
        throw new InvalidOperationException("No available parking spots for this vehicle type");
    
    return CreateTicket(vehicle, spot);
}

// ❌ Bad - generic exceptions or silent failures
public ParkingTicket ParkVehicle(Vehicle vehicle)
{
    try
    {
        var spot = FindAvailableSpot(vehicle);
        return CreateTicket(vehicle, spot);
    }
    catch
    {
        return null; // Silent failure
    }
}
```

### 3. Use of Properties

```csharp
// ✅ Good - encapsulation with properties
public class ParkingSpot
{
    public int SpotNumber { get; private set; }
    public SpotStatus Status { get; private set; }
    private Vehicle _parkedVehicle;
    
    public void Park(Vehicle vehicle)
    {
        if (Status != SpotStatus.Available)
            throw new InvalidOperationException("Spot not available");
        
        _parkedVehicle = vehicle;
        Status = SpotStatus.Occupied;
    }
}

// ❌ Bad - public fields
public class ParkingSpot
{
    public int SpotNumber;
    public SpotStatus Status;
    public Vehicle ParkedVehicle; // Can be modified directly
}
```

### 4. Immutability Where Appropriate

```csharp
// ✅ Good - immutable value objects
public class ParkingTicket
{
    public string TicketId { get; }
    public Vehicle Vehicle { get; }
    public ParkingSpot Spot { get; }
    public DateTime EntryTime { get; }
    public DateTime? ExitTime { get; private set; }
    
    public ParkingTicket(Vehicle vehicle, ParkingSpot spot)
    {
        TicketId = Guid.NewGuid().ToString();
        Vehicle = vehicle;
        Spot = spot;
        EntryTime = DateTime.Now;
    }
    
    public void SetExitTime()
    {
        ExitTime = DateTime.Now;
    }
}
```

### 5. Use Enums for Constants

```csharp
// ✅ Good - type-safe enums
public enum VehicleType
{
    Motorcycle,
    Car,
    Truck
}

public enum SpotStatus
{
    Available,
    Occupied,
    Reserved,
    Maintenance
}

// ❌ Bad - magic strings
public class ParkingSpot
{
    public string Status { get; set; } // Could be "available", "AVAILABLE", "Available", etc.
}
```

---

## Common Mistakes to Avoid

### 1. ❌ God Class (Violates SRP)

```csharp
// BAD - ParkingLot does everything
public class ParkingLot
{
    public void ParkVehicle() { }
    public void UnparkVehicle() { }
    public void ProcessPayment() { }
    public void SendEmail() { }
    public void GenerateReport() { }
    public void ManageEmployees() { }
    public void HandleMaintenance() { }
}

// GOOD - Separated responsibilities
public class ParkingLot
{
    public ParkingTicket ParkVehicle(Vehicle vehicle) { }
    public decimal UnparkVehicle(string ticketId) { }
}

public class PaymentService
{
    public void ProcessPayment(decimal amount) { }
}

public class NotificationService
{
    public void SendEmail(string to, string subject, string body) { }
}
```

### 2. ❌ Premature Optimization

```csharp
// BAD - Over-engineering for scale not needed
public class ParkingLot
{
    private readonly ConcurrentDictionary<string, ParkingTicket> _tickets;
    private readonly ReaderWriterLockSlim _lock;
    private readonly MemoryCache _cache;
    // Complex caching, locking for a simple problem
}

// GOOD - Simple, clear implementation
public class ParkingLot
{
    private readonly Dictionary<string, ParkingTicket> _tickets;
    // Add optimization only when needed
}
```

### 3. ❌ Not Handling Edge Cases

```csharp
// BAD
public void ParkVehicle(Vehicle vehicle)
{
    var spot = FindSpot();
    spot.Park(vehicle); // What if spot is null?
}

// GOOD
public ParkingTicket ParkVehicle(Vehicle vehicle)
{
    if (vehicle == null)
        throw new ArgumentNullException(nameof(vehicle));
    
    var spot = FindAvailableSpot(vehicle);
    if (spot == null)
        throw new InvalidOperationException("No available spots");
    
    spot.ParkVehicle(vehicle);
    return new ParkingTicket(vehicle, spot);
}
```

### 4. ❌ Tight Coupling

```csharp
// BAD
public class ParkingLot
{
    public void ProcessPayment(decimal amount)
    {
        var processor = new CreditCardProcessor(); // Tightly coupled
        processor.Process(amount);
    }
}

// GOOD
public class ParkingLot
{
    private readonly IPaymentProcessor _paymentProcessor;
    
    public ParkingLot(IPaymentProcessor paymentProcessor)
    {
        _paymentProcessor = paymentProcessor;
    }
    
    public void ProcessPayment(decimal amount)
    {
        _paymentProcessor.Process(amount);
    }
}
```

---

## Interview Problem-Solving Framework

### Time Management (45-60 minute interview)

| Phase | Time | Activity |
|-------|------|----------|
| **Requirements** | 5-10 min | Ask clarifying questions |
| **Design** | 10-15 min | Entities, relationships, patterns |
| **Class Diagram** | 5-10 min | Discuss structure |
| **Implementation** | 20-30 min | Write code for core functionality |
| **Discussion** | 5-10 min | Trade-offs, scalability, extensions |

### What Interviewers Look For

1. **Problem Understanding**
   - Do you ask the right questions?
   - Do you understand requirements?

2. **Design Thinking**
   - Proper abstraction
   - SOLID principles
   - Design patterns knowledge

3. **Code Quality**
   - Clean, readable code
   - Proper naming
   - Error handling

4. **Communication**
   - Explain your thinking
   - Discuss trade-offs
   - Open to feedback

5. **Extension Thinking**
   - How would you handle X?
   - What if we need Y?

---

## Advanced Topics

### 1. Concurrency & Thread Safety

```csharp
public class ThreadSafeParkingLot
{
    private readonly object _lock = new object();
    private readonly Dictionary<string, ParkingTicket> _tickets;
    
    public ParkingTicket ParkVehicle(Vehicle vehicle)
    {
        lock (_lock)
        {
            var spot = FindAvailableSpot(vehicle);
            if (spot == null)
                throw new InvalidOperationException("No spots available");
            
            spot.ParkVehicle(vehicle);
            var ticket = new ParkingTicket(vehicle, spot);
            _tickets[ticket.TicketId] = ticket;
            return ticket;
        }
    }
}

// Or use concurrent collections
public class ParkingLot
{
    private readonly ConcurrentDictionary<string, ParkingTicket> _tickets = new();
}
```

### 2. Database Persistence Layer

```csharp
// Repository pattern for data access
public interface IParkingRepository
{
    void SaveTicket(ParkingTicket ticket);
    ParkingTicket GetTicket(string ticketId);
    List<ParkingSpot> GetAvailableSpots(VehicleType type);
}

public class SqlParkingRepository : IParkingRepository
{
    private readonly string _connectionString;
    
    public void SaveTicket(ParkingTicket ticket)
    {
        using var connection = new SqlConnection(_connectionString);
        // SQL insert logic
    }
}

public class ParkingLot
{
    private readonly IParkingRepository _repository;
    
    public ParkingLot(IParkingRepository repository)
    {
        _repository = repository;
    }
}
```

### 3. Event-Driven Architecture

```csharp
// Event for notifications
public class VehicleParkedEvent
{
    public string TicketId { get; set; }
    public string LicensePlate { get; set; }
    public DateTime Timestamp { get; set; }
}

public class ParkingLot
{
    public event EventHandler<VehicleParkedEvent> VehicleParked;
    
    public ParkingTicket ParkVehicle(Vehicle vehicle)
    {
        var ticket = CreateTicket(vehicle);
        
        // Raise event
        VehicleParked?.Invoke(this, new VehicleParkedEvent
        {
            TicketId = ticket.TicketId,
            LicensePlate = vehicle.LicensePlate,
            Timestamp = DateTime.Now
        });
        
        return ticket;
    }
}

// Subscriber
public class NotificationService
{
    public void Subscribe(ParkingLot lot)
    {
        lot.VehicleParked += OnVehicleParked;
    }
    
    private void OnVehicleParked(object sender, VehicleParkedEvent e)
    {
        Console.WriteLine($"Vehicle parked: {e.LicensePlate}");
        // Send SMS, email, etc.
    }
}
```

---

## Practice Problems

### Beginner Level
1. **Design a Stack** with push, pop, peek, isEmpty
2. **Design a Queue** with enqueue, dequeue, front
3. **Design a Simple Calculator** with basic operations
4. **Design a Book** class with proper encapsulation

### Intermediate Level
5. **Design a Vending Machine** with product selection and payment
6. **Design a Chess Game** with pieces, board, and move validation
7. **Design a Movie Ticket Booking System**
8. **Design an Online Shopping Cart**
9. **Design a Restaurant Reservation System**
10. **Design a Ride-Sharing Service** (like Uber)

### Advanced Level
11. **Design Splitwise** (expense sharing)
12. **Design a Notification Service** (multi-channel)
13. **Design a Rate Limiter**
14. **Design a Distributed Cache** (like Redis)
15. **Design a Meeting Scheduler** (like Calendly)

---

## Resources for Further Learning

### Books
1. **"Head First Design Patterns"** - Eric Freeman
2. **"Design Patterns: Elements of Reusable Object-Oriented Software"** - Gang of Four
3. **"Clean Code"** - Robert C. Martin
4. **"Refactoring"** - Martin Fowler

### Online Resources
1. **Refactoring.Guru** - Design patterns with examples
2. **SourceMaking.com** - Design patterns and anti-patterns
3. **LeetCode/HackerRank** - Practice OOP problems
4. **System Design Primer** (GitHub)

### C# Specific
1. **Microsoft Docs** - C# programming guide
2. **C# Design Patterns** (DoFactory)
3. **.NET Design Patterns** by Pluralsight

### For JS/TS Developers Transitioning
1. **TypeScript to C# comparison guides**
2. **LINQ vs Array methods**
3. **Async/await similarities**
4. **Dependency Injection in .NET**

---

## Final Interview Tips

### Do's ✅
1. **Ask clarifying questions** before jumping to code
2. **Think out loud** - explain your reasoning
3. **Start simple** - basic solution first, then optimize
4. **Use proper naming** - readable code is important
5. **Handle edge cases** - null checks, empty collections
6. **Discuss trade-offs** - time vs space, simplicity vs flexibility
7. **Be open to feedback** - adapt based on interviewer hints

### Don'ts ❌
1. **Don't rush to code** without understanding requirements
2. **Don't over-engineer** - YAGNI (You Aren't Gonna Need It)
3. **Don't ignore SOLID** - interviewers look for this
4. **Don't use magic numbers** - use constants or enums
5. **Don't write incomplete code** - compilable code is better
6. **Don't be rigid** - be ready to change approach
7. **Don't forget to test** - walk through examples

### Sample Interview Questions to Prepare

1. "Walk me through your design process"
2. "Why did you choose this design pattern?"
3. "How would you handle X scenario?" (edge cases)
4. "What if we needed to support Y feature?" (extensibility)
5. "How would this scale?" (scalability)
6. "What are the trade-offs of your approach?"

---

## Conclusion

**Key Takeaways:**

1. **Master SOLID principles** - Foundation of good design
2. **Know design patterns** - When and why to use them
3. **Practice common problems** - Parking lot, library, elevator, etc.
4. **Think extensibility** - Design for change
5. **Code quality matters** - Clean, readable, maintainable
6. **Communication is key** - Explain your thinking clearly

**For JS/TS Developers:**

- C# is more strict but offers better compile-time safety
- Interfaces are contracts, not just TypeScript annotations
- Think in terms of classes and inheritance more
- Dependency Injection is built into .NET ecosystem
- LINQ is your friend (similar to array methods in JS)

**Practice Makes Perfect!**

Solve at least 10-15 LLD problems before your interview. Focus on:
- E-commerce systems
- Booking systems
- Resource management
- Social platforms
- Gaming systems

Good luck with your interviews! 🚀

---

**Previous:** [Part 5: Common LLD Problems](LLD-Guide-CSharp-Part5-Common-Problems.md)

**Start:** [Part 1: Introduction & SOLID Principles](LLD-Guide-CSharp-Part1-Introduction-SOLID.md)
