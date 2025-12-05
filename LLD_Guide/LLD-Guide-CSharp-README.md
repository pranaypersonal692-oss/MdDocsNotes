# Low-Level Design Guide for C# - Complete Guide

## 📚 Complete Course Navigation

A comprehensive guide to mastering Low-Level Design (LLD) using C#, specifically designed for developers with JavaScript/TypeScript experience.

---

## 📖 Table of Contents

### **[Part 1: Introduction & SOLID Principles](LLD-Guide-CSharp-Part1-Introduction-SOLID.md)**
Introduction to LLD, C# vs JS/TS differences, and comprehensive SOLID principles.

**Topics Covered:**
- What is Low-Level Design?
- C# vs JavaScript/TypeScript comparison
- **S**ingle Responsibility Principle (SRP)
- **O**pen/Closed Principle (OCP)
- **L**iskov Substitution Principle (LSP)
- **I**nterface Segregation Principle (ISP)
- **D**ependency Inversion Principle (DIP)

**Key Takeaway:** SOLID forms the foundation of good object-oriented design. Master these before moving to patterns.

---

### **[Part 2: Creational Design Patterns](LLD-Guide-CSharp-Part2-Creational-Patterns.md)**
Patterns for object creation mechanisms.

**Topics Covered:**
- **Singleton Pattern** - Ensure single instance
- **Factory Method Pattern** - Create objects via interface
- **Abstract Factory Pattern** - Create families of related objects
- **Builder Pattern** - Construct complex objects step-by-step
- **Prototype Pattern** - Clone existing objects

**Key Takeaway:** Choose the right pattern based on your object creation needs.

**Most Used:**
1. Singleton (logging, configuration)
2. Factory Method (object creation)
3. Builder (complex object construction)

---

### **[Part 3: Structural Design Patterns](LLD-Guide-CSharp-Part3-Structural-Patterns.md)**
Patterns for composing objects and classes.

**Topics Covered:**
- **Adapter Pattern** - Make incompatible interfaces compatible
- **Decorator Pattern** - Add responsibilities dynamically
- **Facade Pattern** - Simplify complex subsystems
- **Proxy Pattern** - Control access to objects
- **Composite Pattern** - Tree structures (part-whole hierarchies)
- **Bridge Pattern** - Separate abstraction from implementation
- **Flyweight Pattern** - Share objects efficiently

**Key Takeaway:** Structural patterns help organize relationships between objects.

**Most Used:**
1. Adapter (integrate third-party libraries)
2. Decorator (extend functionality)
3. Facade (simplify complex APIs)

---

### **[Part 4: Behavioral Design Patterns](LLD-Guide-CSharp-Part4-Behavioral-Patterns.md)**
Patterns for algorithms and object interaction.

**Topics Covered:**
- **Strategy Pattern** - Encapsulate interchangeable algorithms
- **Observer Pattern** - One-to-many dependency (pub/sub)
- **Command Pattern** - Encapsulate requests (undo/redo)
- **Template Method Pattern** - Define algorithm skeleton
- **Iterator Pattern** - Sequential access to elements
- **State Pattern** - State-based behavior
- **Chain of Responsibility Pattern** - Pass requests through a chain
- **Mediator Pattern** - Centralize complex communications
- **Memento Pattern** - Capture and restore state
- **Visitor Pattern** - Add operations to objects

**Key Takeaway:** Behavioral patterns define how objects collaborate and communicate.

**Most Used:**
1. Strategy (payment methods, sorting algorithms)
2. Observer (event handling, notifications)
3. Command (undo/redo systems)

---

### **[Part 5: Common LLD Problems](LLD-Guide-CSharp-Part5-Common-Problems.md)**
Complete implementations of frequently asked interview problems.

**Problems Covered:**
1. **Parking Lot System**
   - Multiple levels, vehicle types
   - Track availability, calculate fees
   - Patterns: Singleton, Factory, Enum

2. **Library Management System**
   - Books, members, loans
   - Search functionality, fine calculation
   - Patterns: Singleton, Strategy

3. **Elevator System**
   - Multiple elevators, request handling
   - Optimization algorithms
   - Patterns: Strategy, State

4. **ATM System**
   - Account management, transactions
   - Authentication, balance operations
   - Patterns: Command, State

5. **Hotel Booking System**
   - Room management, reservations
   - Availability search, pricing
   - Patterns: Factory, Strategy

6. **URL Shortener**
   - Short code generation
   - Redirect tracking, analytics
   - Patterns: Singleton, Factory

**Key Takeaway:** Practice these problems to master LLD interviews.

---

### **[Part 6: Best Practices & Interview Tips](LLD-Guide-CSharp-Part6-Best-Practices.md)**
Interview strategies, best practices, and advanced topics.

**Topics Covered:**
- **7-Step Interview Approach**
  1. Clarify requirements
  2. Define use cases
  3. Identify entities
  4. Define relationships
  5. Apply patterns
  6. Design class diagram
  7. Implement code

- **Design Principles Checklist**
- **Code Quality Best Practices**
- **Common Mistakes to Avoid**
- **Advanced Topics**
  - Concurrency & Thread Safety
  - Database Persistence
  - Event-Driven Architecture

- **Practice Problems** (15 problems)
- **Resources for Further Learning**
- **Interview Do's and Don'ts**

**Key Takeaway:** Preparation and systematic approach are keys to LLD interview success.

---

## 🎯 How to Use This Guide

### For Beginners
1. Start with **Part 1 (SOLID)** - Foundation is crucial
2. Move to **Part 2 (Creational Patterns)** - Learn basic patterns
3. Practice with **Part 5 (Common Problems)** - Apply your knowledge
4. Read **Part 6 (Best Practices)** - Interview preparation

### For Interview Preparation
1. Review **Part 1 (SOLID)** - Refresh principles
2. Skim **Parts 2-4 (Patterns)** - Pattern quick reference
3. Practice **Part 5 (Common Problems)** - Solve all 6 problems
4. Master **Part 6 (Interview Tips)** - The 7-step approach

### For Experienced Developers
1. Jump to **Parts 2-4 (Patterns)** - Pattern refresher
2. Focus on **Part 5 (Common Problems)** - Complex implementations
3. Study **Part 6 (Advanced Topics)** - Concurrency, persistence

---

## 🚀 Quick Reference

### SOLID Principles
| Principle | Meaning | Remember |
|-----------|---------|----------|
| **S**RP | One class, one responsibility | UserService ≠ EmailService |
| **O**CP | Open for extension, closed for modification | Use interfaces |
| **L**SP | Subtypes substitutable for base types | No surprises |
| **I**SP | Small, focused interfaces | Don't force implementation |
| **D**IP | Depend on abstractions | Use interfaces/DI |

### Design Patterns Quick Lookup

**Need to create objects?** → Creational Patterns
- Single instance? → **Singleton**
- Complex construction? → **Builder**
- Unknown type at runtime? → **Factory Method**
- Families of objects? → **Abstract Factory**

**Need to structure objects?** → Structural Patterns
- Incompatible interface? → **Adapter**
- Add behavior dynamically? → **Decorator**
- Simplify complex system? → **Facade**
- Control access? → **Proxy**
- Tree structure? → **Composite**

**Need to define behavior?** → Behavioral Patterns
- Swap algorithms? → **Strategy**
- Notify multiple objects? → **Observer**
- Undo/redo? → **Command**
- State-based behavior? → **State**
- Pass request through chain? → **Chain of Responsibility**

---

## 💻 Code Examples

Every pattern and problem in this guide includes:
- ✅ Complete, compilable C# code
- ✅ Real-world examples
- ✅ Good vs Bad comparisons
- ✅ Explanations for JS/TS developers
- ✅ Use cases and benefits

---

## 🎓 Learning Path

### Week 1: Foundation
- [ ] Complete Part 1 (SOLID Principles)
- [ ] Understand each principle with examples
- [ ] Practice identifying violations in code

### Week 2: Creational Patterns
- [ ] Complete Part 2
- [ ] Implement each pattern from scratch
- [ ] Practice: Design a Document Editor using Builder

### Week 3: Structural Patterns
- [ ] Complete Part 3
- [ ] Implement each pattern
- [ ] Practice: Design a Media Player using Adapter + Decorator

### Week 4: Behavioral Patterns
- [ ] Complete Part 4
- [ ] Implement each pattern
- [ ] Practice: Design a Text Editor with Command + Memento

### Week 5-6: Problem Solving
- [ ] Solve all 6 problems in Part 5
- [ ] Time yourself (45-60 minutes each)
- [ ] Compare your solution with provided code

### Week 7: Interview Preparation
- [ ] Complete Part 6
- [ ] Practice 7-step approach
- [ ] Mock interviews with friends

---

## 📊 Pattern Usage Statistics

**Most Frequently Used in Interviews:**

1. **Singleton** (95%) - Almost always needed
2. **Factory Method** (85%) - Very common
3. **Observer** (75%) - Event handling
4. **Strategy** (70%) - Algorithm selection
5. **Decorator** (60%) - Extending functionality
6. **Builder** (50%) - Complex objects
7. **Adapter** (45%) - Integration
8. **State** (40%) - Lifecycle management
9. **Command** (35%) - Undo/redo
10. **Facade** (30%) - Simplification

---

## 🎯 Interview Success Checklist

### Before the Interview
- [ ] Reviewed all SOLID principles
- [ ] Can explain 5+ design patterns
- [ ] Solved 3+ LLD problems end-to-end
- [ ] Practiced the 7-step approach
- [ ] Understand time management (45-60 min)

### During the Interview
- [ ] Ask clarifying questions (5-10 min)
- [ ] Identify entities and relationships
- [ ] Apply appropriate design patterns
- [ ] Write clean, compilable code
- [ ] Handle edge cases
- [ ] Explain trade-offs
- [ ] Discuss scalability

### Common Interview Problems
- [ ] Parking Lot System ⭐⭐⭐
- [ ] Library Management ⭐⭐
- [ ] Elevator System ⭐⭐⭐
- [ ] ATM System ⭐⭐
- [ ] Hotel Booking ⭐⭐
- [ ] Ride Sharing (Uber/Lyft) ⭐⭐⭐
- [ ] Chess Game ⭐⭐
- [ ] Social Media (Twitter/FB) ⭐⭐⭐
- [ ] Food Delivery (DoorDash) ⭐⭐⭐

(⭐ = difficulty/frequency)

---

## 🔗 File Structure

```
LLD-Guide-CSharp/
│
├── LLD-Guide-CSharp-README.md (this file)
│
├── LLD-Guide-CSharp-Part1-Introduction-SOLID.md
│   └── Introduction, C# vs JS/TS, SOLID Principles
│
├── LLD-Guide-CSharp-Part2-Creational-Patterns.md
│   └── Singleton, Factory, Abstract Factory, Builder, Prototype
│
├── LLD-Guide-CSharp-Part3-Structural-Patterns.md
│   └── Adapter, Decorator, Facade, Proxy, Composite, Bridge, Flyweight
│
├── LLD-Guide-CSharp-Part4-Behavioral-Patterns.md
│   └── Strategy, Observer, Command, Template, State, Chain, Mediator, Memento, Visitor
│
├── LLD-Guide-CSharp-Part5-Common-Problems.md
│   └── Parking Lot, Library, Elevator, ATM, Hotel, URL Shortener
│
└── LLD-Guide-CSharp-Part6-Best-Practices.md
    └── Interview tips, Best practices, Advanced topics, Resources
```

---

## 📝 Notes for JavaScript/TypeScript Developers

### Key Differences

| Concept | TypeScript | C# |
|---------|-----------|-----|
| **Type System** | Structural (duck typing) | Nominal (explicit) |
| **Interfaces** | Optional contracts | Must implement fully |
| **Access Modifiers** | Optional (convention) | Explicit required |
| **Properties** | Direct fields | Get/Set accessors |
| **Null Safety** | `?` for optional | Nullable reference types |
| **Modules** | ES6 modules | Namespaces + using |
| **Async** | Promises, async/await | Tasks, async/await |
| **Collections** | Arrays, objects | Lists, Dictionaries, Arrays |
| **DI** | Manual or frameworks | Built-in (.NET Core) |

### Similarities

- ✅ Both support async/await
- ✅ Both have LINQ-like operations (Array methods vs LINQ)
- ✅ Both support generics
- ✅ Both have lambda expressions
- ✅ Both support events/delegates

---

## 🛠️ Tools & Resources

### IDEs
- **Visual Studio** - Full-featured IDE
- **Visual Studio Code** - Lightweight (familiar to JS developers)
- **JetBrains Rider** - Cross-platform

### Online Compilers
- **dotnetfiddle.net** - Run C# code online
- **replit.com** - Online C# environment

### Practice Platforms
- **LeetCode** (Object-Oriented Design section)
- **InterviewBit** (Low-Level Design)
- **Educative.io** (Grokking the Object-Oriented Design Interview)

---

## 💡 Tips from the Author

1. **Master SOLID first** - Everything builds on this foundation
2. **Code along** - Don't just read, implement each pattern
3. **Practice timing** - 45-60 minutes for complete problem
4. **Think extensibility** - "What if we need to add X?"
5. **Communicate clearly** - Explain your reasoning
6. **Start simple** - Basic solution first, then optimize

---

## 🎉 Conclusion

This comprehensive guide covers everything you need to master Low-Level Design interviews in C#. By the end:

✅ You'll understand all SOLID principles deeply
✅ You'll know when and why to use each design pattern
✅ You'll have solved 6+ complete LLD problems
✅ You'll have a systematic approach to any LLD question
✅ You'll write clean, maintainable, extensible code

**Remember:** LLD is about more than memorizing patterns. It's about understanding **why** we design systems in certain ways and making **informed trade-offs** based on requirements.

---

## 📧 Feedback & Questions

If you find any errors or have suggestions for improvement, please feel free to provide feedback!

---

**Happy Coding! 🚀**

*Last Updated: 2025-12-05*

---

## Quick Links

- [Start from Part 1](LLD-Guide-CSharp-Part1-Introduction-SOLID.md)
- [Jump to Common Problems](LLD-Guide-CSharp-Part5-Common-Problems.md)
- [Interview Tips](LLD-Guide-CSharp-Part6-Best-Practices.md)
