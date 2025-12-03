# ASP.NET API Guide - Index

## Complete Guide to Building Scalable & Maintainable ASP.NET APIs

This comprehensive guide covers everything you need to know to build production-grade ASP.NET APIs using a real-world **E-Commerce Order Management System** as an example.

---

## Guide Structure

### [Part 1: Introduction, Architecture & Project Structure](aspnet-api-guide-part1.md)
Learn the foundational concepts and setup:
- Why ASP.NET for APIs?
- Clean Architecture (Onion Architecture)
- SOLID Principles
- Repository & Unit of Work patterns
- Project structure and solution setup
- Configuration management

**Topics**: Architecture patterns, dependency injection, project organization

---

### [Part 2: Core Implementation](aspnet-api-guide-part2.md)
Build the core application components:
- Domain entities and business logic
- Value objects and enums
- DTOs (Data Transfer Objects)
- AutoMapper configuration
- FluentValidation for input validation
- Service layer implementation
- Controller design

**Topics**: Domain-driven design, validation, services, controllers

---

### [Part 3: Repository Pattern & Database Layer](aspnet-api-guide-part3.md)
Implement robust data access:
- DbContext configuration with EF Core
- Entity configuration using Fluent API
- Generic repository implementation
- Specific repositories with custom queries
- Unit of Work pattern
- Database migrations
- Query optimization techniques

**Topics**: Entity Framework Core, repositories, database design, performance

---

### [Part 4: Authentication & Authorization](aspnet-api-guide-part4.md)
Secure your API:
- JWT authentication setup
- User management system
- Role-based authorization
- Claims-based authorization
- Refresh token implementation
- API key authentication
- Custom authorization policies

**Topics**: Security, JWT, authentication, authorization, identity

---

### [Part 5: Middleware, Logging & Error Handling](aspnet-api-guide-part5.md)
Add cross-cutting concerns:
- Global exception handling
- Custom middleware (logging, rate limiting, performance monitoring)
- Structured logging with Serilog
- Request/Response logging
- API versioning
- Health checks

**Topics**: Middleware pipeline, logging, error handling, observability

---

### [Part 6: Performance, Caching & Scalability](aspnet-api-guide-part6.md)
Optimize for production:
- Response caching strategies
- Distributed caching with Redis
- Database query optimization
- Async/await best practices
- Background jobs with Hangfire
- API rate limiting & throttling
- Horizontal scaling patterns

**Topics**: Performance, caching, scalability, async programming

---

### [Part 7: Testing & Deployment](aspnet-api-guide-part7.md)
Test and deploy with confidence:
- Unit testing with xUnit, Moq, FluentAssertions
- Integration testing with WebApplicationFactory
- API testing strategies
- Test data builders
- CI/CD with GitHub Actions
- Docker containerization
- Kubernetes deployment
- Production checklist

**Topics**: Testing, CI/CD, containers, deployment, production readiness

---

## Quick Start

### Prerequisites
- .NET 8.0 SDK
- Visual Studio 2022 / Rider / VS Code
- SQL Server or PostgreSQL
- Redis (optional, for caching)

### Create Your First API

```bash
# Create solution
dotnet new sln -n OrderManagement

# Create projects
dotnet new webapi -n OrderManagement.API
dotnet new classlib -n OrderManagement.Application
dotnet new classlib -n OrderManagement.Domain
dotnet new classlib -n OrderManagement.Infrastructure

# Add to solution
dotnet sln add **/*.csproj
```

### Follow the Guide
Start with [Part 1](aspnet-api-guide-part1.md) and work through each section sequentially.

---

## Code Example Highlights

### Clean Architecture Layers
```
OrderManagement.API/          → Presentation Layer (Controllers, Middleware)
OrderManagement.Application/  → Application Layer (Services, DTOs, Interfaces)
OrderManagement.Domain/       → Domain Layer (Entities, Business Logic)
OrderManagement.Infrastructure/ → Infrastructure Layer (Data Access, External Services)
```

### Sample Order Entity (Domain)
```csharp
public class Order : BaseEntity
{
    public string OrderNumber { get; set; }
    public int CustomerId { get; set; }
    public OrderStatus Status { get; set; }
    public ICollection<OrderItem> Items { get; set; }
    
    public decimal Total => Items.Sum(x => x.TotalPrice) + ShippingCost + TaxAmount;
    
    public void Submit() { /* business logic */ }
    public void Cancel() { /* business logic */ }
}
```

### Sample Controller (API)
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    
    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> GetOrder(int id)
    {
        var order = await _orderService.GetOrderByIdAsync(id);
        return Ok(order);
    }
    
    [HttpPost]
    public async Task<ActionResult<OrderDto>> CreateOrder(CreateOrderDto dto)
    {
        var order = await _orderService.CreateOrderAsync(dto);
        return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
    }
}
```

---

## Key Concepts Covered

✅ **Clean Architecture** - Separation of concerns with proper layering  
✅ **SOLID Principles** - Maintainable and testable code  
✅ **Repository Pattern** - Abstracted data access  
✅ **Unit of Work** - Transaction management  
✅ **JWT Authentication** - Secure API endpoints  
✅ **Middleware** - Cross-cutting concerns  
✅ **Caching** - Performance optimization  
✅ **Testing** - Unit, integration, and API tests  
✅ **Deployment** - Docker, Kubernetes, CI/CD  

---

## Technologies Used

- **ASP.NET Core 8.0** - Web API framework
- **Entity Framework Core** - ORM for database access
- **AutoMapper** - Object-to-object mapping
- **FluentValidation** - Input validation
- **Serilog** - Structured logging
- **JWT Bearer** - Authentication
- **Redis** - Distributed caching
- **Swagger/OpenAPI** - API documentation
- **xUnit** - Unit testing
- **Moq** - Mocking framework
- **Docker** - Containerization
- **GitHub Actions** - CI/CD

---

## Production-Ready Features

This guide includes implementations for:
- ✅ Authentication & Authorization
- ✅ Error Handling & Logging
- ✅ Caching & Performance Optimization
- ✅ Rate Limiting & Security
- ✅ Health Checks & Monitoring
- ✅ Database Migrations
- ✅ API Versioning
- ✅ Testing & CI/CD
- ✅ Docker & Kubernetes Deployment

---

## Additional Resources

- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core)
- [Entity Framework Core](https://docs.microsoft.com/ef/core)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Microsoft Architecture Guides](https://dotnet.microsoft.com/learn/aspnet/architecture)

---

## Navigation

Start your journey: **[Part 1: Introduction, Architecture & Project Structure →](aspnet-api-guide-part1.md)**

---

Created with ❤️ for building world-class ASP.NET APIs
