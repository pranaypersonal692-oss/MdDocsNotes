# Module 02: High-Level Architecture Design

## 📖 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Clean Architecture Principles](#clean-architecture-principles)
3. [System Architecture](#system-architecture)
4. [Component Architecture](#component-architecture)
5. [Communication Patterns](#communication-patterns)
6. [Design Patterns](#design-patterns)
7. [Scalability Strategy](#scalability-strategy)
8. [Security Architecture](#security-architecture)

---

## 1. Architecture Overview

### 1.1 Architectural Goals

Our architecture is designed with the following principles:

🎯 **Maintainability**: Easy to understand, modify, and extend  
🎯 **Testability**: Each layer can be tested independently  
🎯 **Scalability**: Can handle growing user base and data  
🎯 **Security**: Built-in security at every layer  
🎯 **Performance**: Optimized for speed and efficiency  
🎯 **Flexibility**: Easy to swap out components  

### 1.2 Architectural Style

We're using **Clean Architecture** (also known as Onion Architecture or Hexagonal Architecture) combined with **Domain-Driven Design (DDD)** principles.

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[Angular 19 SPA]
    end
    
    subgraph "API Layer"
        B[Controllers]
        C[Middleware]
        D[Filters]
    end
    
    subgraph "Application Layer"
        E[Services]
        F[DTOs]
        G[Mappers]
        H[Validators]
    end
    
    subgraph "Domain Layer"
        I[Entities]
        J[Value Objects]
        K[Business Rules]
        L[Interfaces]
    end
    
    subgraph "Infrastructure Layer"
        M[Repositories]
        N[DbContext]
        O[External Services]
        P[File System]
    end
    
    subgraph "Data Layer"
        Q[(SQL Server)]
        R[(Redis)]
    end
    
    A -->|HTTP| B
    B --> C
    B --> D
    B --> E
    E --> F
    E --> G
    E --> H
    E --> L
    I --> K
    L --> M
    M --> N
    N --> Q
    E --> O
    E --> R
    O --> P
```

---

## 2. Clean Architecture Principles

### 2.1 The Dependency Rule

> **"Source code dependencies must point only inward, toward higher-level policies."**

```mermaid
graph LR
    A[Presentation] --> B[Application]
    B --> C[Domain]
    D[Infrastructure] --> C
    
    style C fill:#90EE90
    style B fill:#87CEEB
    style A fill:#FFB6C1
    style D fill:#DDA0DD
```

**Key Points**:
- Domain layer has NO dependencies on other layers
- Application layer depends only on Domain
- Infrastructure and Presentation depend on Application and Domain
- Dependencies point INWARD

### 2.2 Layer Responsibilities

#### 🟢 Domain Layer (Core Business Logic)
**Responsibilities**:
- Define business entities
- Define business rules
- Define repository interfaces
- No dependencies on external libraries

**Contains**:
- `Entities/` - Movie, Theater, Booking, User, etc.
- `ValueObjects/` - Price, Email, PhoneNumber, etc.
- `Enums/` - BookingStatus, SeatType, MovieFormat, etc.
- `Interfaces/` - IMovieRepository, IBookingService, etc.
- `Specifications/` - Business rule specifications

**Example**:
```csharp
// Domain Entity - No dependencies
public class Movie
{
    public int Id { get; private set; }
    public string Title { get; private set; }
    public TimeSpan Duration { get; private set; }
    
    // Business rule enforcement
    public void UpdateTitle(string newTitle)
    {
        if (string.IsNullOrWhiteSpace(newTitle))
            throw new DomainException("Movie title cannot be empty");
        
        Title = newTitle;
    }
}
```

#### 🔵 Application Layer (Use Cases)
**Responsibilities**:
- Implement use cases (business workflows)
- Define DTOs for data transfer
- Coordinate between domain and infrastructure
- Handle application-specific business rules

**Contains**:
- `Services/` - MovieService, BookingService, PaymentService
- `DTOs/` - MovieDto, BookingDto, CreateBookingRequest
- `Interfaces/` - IMovieService, IBookingService
- `Mapping/` - AutoMapper profiles
- `Validators/` - FluentValidation validators

**Example**:
```csharp
// Application Service
public class BookingService : IBookingService
{
    private readonly IBookingRepository _bookingRepository;
    private readonly IPaymentService _paymentService;
    private readonly IEmailService _emailService;
    
    public async Task<BookingDto> CreateBooking(CreateBookingRequest request)
    {
        // 1. Validate seats availability
        // 2. Create booking entity
        // 3. Process payment
        // 4. Send confirmation email
        // 5. Return DTO
    }
}
```

#### 🟣 Infrastructure Layer (External Concerns)
**Responsibilities**:
- Implement repository interfaces
- Database access (Entity Framework)
- External service integrations
- File system operations
- Caching implementation

**Contains**:
- `Persistence/` - DbContext, Configurations, Migrations
- `Repositories/` - MovieRepository, BookingRepository
- `ExternalServices/` - EmailService, PaymentGateway, CloudStorage
- `Caching/` - RedisCacheService

**Example**:
```csharp
// Infrastructure Repository
public class MovieRepository : IMovieRepository
{
    private readonly ApplicationDbContext _context;
    
    public async Task<Movie> GetByIdAsync(int id)
    {
        return await _context.Movies
            .Include(m => m.Cast)
            .FirstOrDefaultAsync(m => m.Id == id);
    }
}
```

#### 🔴 Presentation Layer (User Interface)
**Responsibilities**:
- Handle HTTP requests
- Validate input
- Return HTTP responses
- Authentication/Authorization

**Contains**:
- `Controllers/` - MoviesController, BookingsController
- `Middleware/` - ExceptionHandling, Logging
- `Filters/` - Authorization, Validation
- `Models/` - Request/Response models

**Example**:
```csharp
// API Controller
[ApiController]
[Route("api/[controller]")]
public class MoviesController : ControllerBase
{
    private readonly IMovieService _movieService;
    
    [HttpGet]
    public async Task<ActionResult<List<MovieDto>>> GetMovies()
    {
        var movies = await _movieService.GetAllMoviesAsync();
        return Ok(movies);
    }
}
```

---

## 3. System Architecture

### 3.1 Complete System Architecture

```mermaid
graph TB
    subgraph "Client Side"
        UI[Angular 19 SPA]
        State[Signal Store]
        Router[Angular Router]
    end
    
    subgraph "Load Balancer"
        LB[NGINX / Azure LB]
    end
    
    subgraph "API Server 1"
        API1[ASP.NET Core API]
        Auth1[JWT Middleware]
        Cache1[Memory Cache]
    end
    
    subgraph "API Server 2"
        API2[ASP.NET Core API]
        Auth2[JWT Middleware]
        Cache2[Memory Cache]
    end
    
    subgraph "Caching Layer"
        Redis[(Redis Cache)]
    end
    
    subgraph "Database Layer"
        Primary[(SQL Server Primary)]
        Replica1[(SQL Server Replica 1)]
        Replica2[(SQL Server Replica 2)]
    end
    
    subgraph "External Services"
        Payment[Payment Gateway]
        Email[Email Service]
        Storage[Cloud Storage]
    end
    
    subgraph "Background Jobs"
        Jobs[Hangfire Server]
    end
    
    UI --> Router
    UI --> State
    UI -->|HTTPS| LB
    
    LB --> API1
    LB --> API2
    
    API1 --> Auth1
    API2 --> Auth2
    
    API1 --> Cache1
    API2 --> Cache2
    
    API1 --> Redis
    API2 --> Redis
    
    API1 --> Primary
    API2 --> Primary
    
    Primary --> Replica1
    Primary --> Replica2
    
    API1 --> Payment
    API1 --> Email
    API1 --> Storage
    
    Jobs --> Primary
    Jobs --> Email
    
    style UI fill:#FFB6C1
    style Primary fill:#90EE90
    style Redis fill:#FFA500
```

### 3.2 Request Flow

#### User Browsing Movies (Read Operation)

```mermaid
sequenceDiagram
    participant User
    participant Angular
    participant NGINX
    participant API
    participant Cache
    participant DB
    
    User->>Angular: Browse movies
    Angular->>NGINX: GET /api/movies
    NGINX->>API: Forward request
    API->>API: Check authentication
    API->>Cache: Check Redis cache
    
    alt Cache Hit
        Cache-->>API: Return cached data
    else Cache Miss
        API->>DB: Query movies
        DB-->>API: Return movies
        API->>Cache: Store in cache (5 min TTL)
    end
    
    API-->>NGINX: Return movies JSON
    NGINX-->>Angular: Forward response
    Angular->>Angular: Update Signal state
    Angular-->>User: Display movies
```

#### User Making Booking (Write Operation)

```mermaid
sequenceDiagram
    participant User
    participant Angular
    participant API
    participant DB
    participant Payment
    participant Email
    participant Queue
    
    User->>Angular: Submit booking
    Angular->>API: POST /api/bookings
    API->>API: Validate JWT token
    API->>API: Validate request
    API->>DB: Begin transaction
    API->>DB: Check seat availability
    
    alt Seats Available
        API->>DB: Create booking (Pending)
        API->>Payment: Process payment
        
        alt Payment Success
            Payment-->>API: Payment confirmed
            API->>DB: Update booking (Confirmed)
            API->>DB: Commit transaction
            API->>Queue: Queue email job
            Queue->>Email: Send confirmation
            API-->>Angular: Return booking details
            Angular-->>User: Show success
        else Payment Failed
            Payment-->>API: Payment failed
            API->>DB: Rollback transaction
            API-->>Angular: Return error
            Angular-->>User: Show error
        end
    else Seats Not Available
        API->>DB: Rollback transaction
        API-->>Angular: Return error
        Angular-->>User: Show "seats taken"
    end
```

---

## 4. Component Architecture

### 4.1 Backend Components

```mermaid
graph TB
    subgraph "MovieTicket.API"
        A1[Program.cs]
        A2[Controllers]
        A3[Middleware]
        A4[Filters]
    end
    
    subgraph "MovieTicket.Application"
        B1[Services]
        B2[DTOs]
        B3[Validators]
        B4[Mapping]
    end
    
    subgraph "MovieTicket.Domain"
        C1[Entities]
        C2[ValueObjects]
        C3[Interfaces]
        C4[Specifications]
    end
    
    subgraph "MovieTicket.Infrastructure"
        D1[Persistence]
        D2[Repositories]
        D3[ExternalServices]
        D4[Caching]
    end
    
    A2 --> B1
    B1 --> C3
    C3 --> D2
    D2 --> D1
    B1 --> D3
    B1 --> D4
```

### 4.2 Solution Structure

```
MovieTicketBooking/
│
├── src/
│   ├── MovieTicket.Domain/
│   │   ├── Entities/
│   │   │   ├── Movie.cs
│   │   │   ├── Theater.cs
│   │   │   ├── Screen.cs
│   │   │   ├── Show.cs
│   │   │   ├── Booking.cs
│   │   │   ├── Seat.cs
│   │   │   ├── User.cs
│   │   │   └── Payment.cs
│   │   ├── ValueObjects/
│   │   │   ├── Price.cs
│   │   │   ├── Email.cs
│   │   │   └── PhoneNumber.cs
│   │   ├── Enums/
│   │   │   ├── BookingStatus.cs
│   │   │   ├── SeatType.cs
│   │   │   ├── MovieFormat.cs
│   │   │   └── PaymentStatus.cs
│   │   ├── Interfaces/
│   │   │   ├── Repositories/
│   │   │   └── Services/
│   │   └── Specifications/
│   │
│   ├── MovieTicket.Application/
│   │   ├── Services/
│   │   │   ├── MovieService.cs
│   │   │   ├── BookingService.cs
│   │   │   ├── TheaterService.cs
│   │   │   └── UserService.cs
│   │   ├── DTOs/
│   │   │   ├── Movies/
│   │   │   ├── Bookings/
│   │   │   ├── Theaters/
│   │   │   └── Users/
│   │   ├── Validators/
│   │   ├── Mapping/
│   │   └── Exceptions/
│   │
│   ├── MovieTicket.Infrastructure/
│   │   ├── Persistence/
│   │   │   ├── ApplicationDbContext.cs
│   │   │   ├── Configurations/
│   │   │   └── Migrations/
│   │   ├── Repositories/
│   │   ├── ExternalServices/
│   │   │   ├── EmailService.cs
│   │   │   ├── PaymentGateway.cs
│   │   │   └── CloudStorageService.cs
│   │   └── Caching/
│   │       └── RedisCacheService.cs
│   │
│   └── MovieTicket.API/
│       ├── Controllers/
│       │   ├── MoviesController.cs
│       │   ├── BookingsController.cs
│       │   ├── TheatersController.cs
│       │   └── AuthController.cs
│       ├── Middleware/
│       │   ├── ExceptionHandlingMiddleware.cs
│       │   └── RequestLoggingMiddleware.cs
│       ├── Filters/
│       └── Program.cs
│
├── tests/
│   ├── MovieTicket.UnitTests/
│   ├── MovieTicket.IntegrationTests/
│   └── MovieTicket.E2ETests/
│
└── client/
    └── movie-booking-app/
        ├── src/
        │   ├── app/
        │   │   ├── core/
        │   │   ├── features/
        │   │   ├── shared/
        │   │   └── app.component.ts
        │   └── environments/
        └── angular.json
```

### 4.3 Frontend Architecture

```mermaid
graph TB
    subgraph "Core Modules"
        A1[Auth Module]
        A2[HTTP Interceptors]
        A3[Guards]
        A4[Core Services]
    end
    
    subgraph "Feature Modules"
        B1[Movies Feature]
        B2[Bookings Feature]
        B3[User Feature]
        B4[Admin Feature]
    end
    
    subgraph "Shared Module"
        C1[UI Components]
        C2[Pipes]
        C3[Directives]
        C4[Models]
    end
    
    subgraph "State Management"
        D1[Movie State]
        D2[Booking State]
        D3[Auth State]
        D4[UI State]
    end
    
    B1 --> A4
    B2 --> A4
    B3 --> A4
    B4 --> A4
    
    B1 --> C1
    B2 --> C1
    
    B1 --> D1
    B2 --> D2
    A1 --> D3
```

---

## 5. Communication Patterns

### 5.1 API Communication

#### REST API Design

All API endpoints follow RESTful conventions:

| HTTP Method | Endpoint | Description | Request Body | Response |
|------------|----------|-------------|--------------|----------|
| GET | `/api/movies` | Get all movies | - | `Movie[]` |
| GET | `/api/movies/{id}` | Get movie by ID | - | `Movie` |
| POST | `/api/movies` | Create movie | `CreateMovieDto` | `Movie` |
| PUT | `/api/movies/{id}` | Update movie | `UpdateMovieDto` | `Movie` |
| DELETE | `/api/movies/{id}` | Delete movie | - | `204 No Content` |

#### API Response Format

**Success Response**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "Inception",
    "genre": "Sci-Fi"
  },
  "message": null,
  "errors": null
}
```

**Error Response**:
```json
{
  "success": false,
  "data": null,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email is required"
    }
  ]
}
```

### 5.2 Real-Time Communication

For seat selection, we use **SignalR** for real-time updates:

```mermaid
sequenceDiagram
    participant User1
    participant Hub
    participant User2
    
    User1->>Hub: Connect to ShowHub
    User2->>Hub: Connect to ShowHub
    Hub->>User1: Connection established
    Hub->>User2: Connection established
    
    User1->>Hub: SelectSeat(showId, seatId)
    Hub->>Hub: Lock seat
    Hub->>User2: Broadcast SeatSelected
    User2->>User2: Update UI (seat unavailable)
    
    User1->>Hub: ConfirmBooking()
    Hub->>Hub: Book seat
    Hub->>User2: Broadcast SeatBooked
```

---

## 6. Design Patterns

### 6.1 Repository Pattern

**Purpose**: Abstract data access logic

```csharp
// Generic Repository
public interface IRepository<T> where T : class
{
    Task<T> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(int id);
}

// Specific Repository
public interface IMovieRepository : IRepository<Movie>
{
    Task<IEnumerable<Movie>> GetNowShowingAsync();
    Task<IEnumerable<Movie>> SearchByTitleAsync(string title);
    Task<Movie> GetWithShowsAsync(int id);
}
```

### 6.2 Unit of Work Pattern

**Purpose**: Maintain consistency across multiple repositories

```csharp
public interface IUnitOfWork : IDisposable
{
    IMovieRepository Movies { get; }
    IBookingRepository Bookings { get; }
    ITheaterRepository Theaters { get; }
    
    Task<int> SaveChangesAsync();
    Task BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
}
```

### 6.3 Specification Pattern

**Purpose**: Encapsulate query logic

```csharp
public class NowShowingMoviesSpecification : Specification<Movie>
{
    public override Expression<Func<Movie, bool>> ToExpression()
    {
        return movie => movie.ReleaseDate <= DateTime.Now 
                     && movie.EndDate >= DateTime.Now
                     && movie.Status == MovieStatus.Active;
    }
}

// Usage
var spec = new NowShowingMoviesSpecification();
var movies = await _movieRepository.GetAsync(spec);
```

### 6.4 CQRS Pattern (Simplified)

**Purpose**: Separate read and write operations

```csharp
// Command (Write)
public class CreateBookingCommand
{
    public int UserId { get; set; }
    public int ShowId { get; set; }
    public List<int> SeatIds { get; set; }
}

// Command Handler
public class CreateBookingCommandHandler
{
    public async Task<BookingDto> Handle(CreateBookingCommand command)
    {
        // Handle booking creation
    }
}

// Query (Read)
public class GetMoviesByGenreQuery
{
    public string Genre { get; set; }
}

// Query Handler
public class GetMoviesByGenreQueryHandler
{
    public async Task<List<MovieDto>> Handle(GetMoviesByGenreQuery query)
    {
        // Return movies
    }
}
```

### 6.5 Dependency Injection

**Purpose**: Loose coupling and testability

```csharp
// Program.cs
builder.Services.AddScoped<IMovieRepository, MovieRepository>();
builder.Services.AddScoped<IMovieService, MovieService>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// Controller
public class MoviesController : ControllerBase
{
    private readonly IMovieService _movieService;
    
    // Dependencies injected via constructor
    public MoviesController(IMovieService movieService)
    {
        _movieService = movieService;
    }
}
```

---

## 7. Scalability Strategy

### 7.1 Horizontal Scaling

```mermaid
graph TB
    Client[Clients]
    
    subgraph "Load Balancer"
        LB[NGINX]
    end
    
    subgraph "Application Tier - Auto-scaled"
        API1[API Instance 1]
        API2[API Instance 2]
        API3[API Instance 3]
        APIx[API Instance N]
    end
    
    subgraph "Caching Tier"
        Redis[Redis Cluster]
    end
    
    subgraph "Database Tier"
        Master[(Master DB)]
        Read1[(Read Replica 1)]
        Read2[(Read Replica 2)]
    end
    
    Client --> LB
    LB --> API1
    LB --> API2
    LB --> API3
    LB --> APIx
    
    API1 --> Redis
    API2 --> Redis
    API3 --> Redis
    
    API1 --> Master
    API2 --> Master
    
    API3 --> Read1
    APIx --> Read2
    
    Master --> Read1
    Master --> Read2
```

### 7.2 Caching Strategy

**Multi-Level Caching**:

1. **L1 Cache**: In-Memory Cache (short TTL, 1-5 min)
   - Frequently accessed data
   - User session data

2. **L2 Cache**: Redis (medium TTL, 10-60 min)
   - Movie catalog
   - Theater information
   - Show schedules

3. **L3 Cache**: CDN (long TTL, 1-24 hours)
   - Movie posters
   - Static assets

**Cache Invalidation**:
```csharp
public async Task UpdateMovie(UpdateMovieDto dto)
{
    await _movieRepository.UpdateAsync(dto);
    await _cache.RemoveAsync($"movie:{dto.Id}");
    await _cache.RemoveAsync("movies:all");
}
```

### 7.3 Database Optimization

**Indexing Strategy**:
```sql
-- Composite index for frequent queries
CREATE INDEX IX_Shows_MovieId_DateTime 
ON Shows(MovieId, ShowDateTime) 
INCLUDE (ScreenId, Price);

-- Partial index for active movies
CREATE INDEX IX_Movies_Active 
ON Movies(Status) 
WHERE Status = 'Active';
```

**Read/Write Splitting**:
```csharp
// Write to master
await _unitOfWork.Bookings.AddAsync(booking);
await _unitOfWork.SaveChangesAsync();

// Read from replica
var movies = await _readOnlyContext.Movies.ToListAsync();
```

### 7.4 Performance Targets

| Metric | Target | Strategy |
|--------|--------|----------|
| API Response Time (P95) | < 200ms | Caching, indexing |
| Database Query Time | < 50ms | Optimized queries, indexes |
| Page Load Time | < 2s | Code splitting, lazy loading |
| Concurrent Users | 10,000+ | Horizontal scaling |
| Booking Processing | 1000/min | Async processing, queues |

---

## 8. Security Architecture

### 8.1 Security Layers

```mermaid
graph TB
    subgraph "Network Security"
        A1[HTTPS/TLS 1.3]
        A2[DDoS Protection]
        A3[Firewall Rules]
    end
    
    subgraph "Application Security"
        B1[JWT Authentication]
        B2[RBAC Authorization]
        B3[Input Validation]
        B4[Output Encoding]
    end
    
    subgraph "Data Security"
        C1[Encryption at Rest]
        C2[Encrypted Connections]
        C3[Password Hashing]
        C4[Sensitive Data Masking]
    end
    
    subgraph "API Security"
        D1[Rate Limiting]
        D2[CORS Policy]
        D3[API Versioning]
        D4[Request Signing]
    end
    
    A1 --> B1
    B1 --> C1
    B3 --> C4
    D1 --> B1
```

### 8.2 Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant AuthService
    participant DB
    
    Client->>API: POST /auth/login<br/>{email, password}
    API->>AuthService: Authenticate
    AuthService->>DB: Find user by email
    DB-->>AuthService: User data
    AuthService->>AuthService: Verify password hash
    
    alt Valid Credentials
        AuthService->>AuthService: Generate JWT token
        AuthService->>AuthService: Generate refresh token
        AuthService->>DB: Store refresh token
        AuthService-->>API: Tokens
        API-->>Client: {accessToken, refreshToken}
    else Invalid Credentials
        AuthService-->>API: Unauthorized
        API-->>Client: 401 Unauthorized
    end
```

### 8.3 Authorization Strategy

**Role-Based Access Control (RBAC)**:

```csharp
[Authorize(Roles = "Admin")]
[HttpPost("movies")]
public async Task<ActionResult> CreateMovie(CreateMovieDto dto)
{
    // Only admins can create movies
}

[Authorize(Roles = "User,Admin")]
[HttpPost("bookings")]
public async Task<ActionResult> CreateBooking(CreateBookingDto dto)
{
    // Both users and admins can create bookings
}
```

**Claims-Based Authorization**:
```csharp
[Authorize(Policy = "CanCancelBooking")]
[HttpDelete("bookings/{id}")]
public async Task<ActionResult> CancelBooking(int id)
{
    // Custom policy checks if user owns the booking
}

// Policy definition
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanCancelBooking", policy =>
        policy.RequireAssertion(context =>
        {
            var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var bookingUserId = // Get from booking
            return userId == bookingUserId || context.User.IsInRole("Admin");
        }));
});
```

### 8.4 Security Best Practices

#### Input Validation
```csharp
public class CreateBookingValidator : AbstractValidator<CreateBookingDto>
{
    public CreateBookingValidator()
    {
        RuleFor(x => x.ShowId)
            .GreaterThan(0)
            .WithMessage("Invalid show ID");
        
        RuleFor(x => x.SeatIds)
            .NotEmpty()
            .WithMessage("At least one seat must be selected")
            .Must(seats => seats.Count <= 10)
            .WithMessage("Maximum 10 seats per booking");
    }
}
```

#### SQL Injection Prevention
```csharp
// ✅ Good: Parameterized query
var movie = await _context.Movies
    .Where(m => m.Title == userInput)
    .FirstOrDefaultAsync();

// ❌ Bad: String concatenation
var query = $"SELECT * FROM Movies WHERE Title = '{userInput}'";
```

#### XSS Prevention
```csharp
// Angular automatically sanitizes
<div>{{ userReview }}</div>

// For backend
public string SanitizeHtml(string input)
{
    return HttpUtility.HtmlEncode(input);
}
```

---

## 9. Deployment Architecture

### 9.1 Production Deployment

```mermaid
graph TB
    subgraph "Internet"
        Users[Users]
    end
    
    subgraph "Azure/AWS Cloud"
        CDN[CDN - Static Assets]
        WAF[Web Application Firewall]
        
        subgraph "Application Gateway"
            AppGW[Load Balancer]
        end
        
        subgraph "Web Tier - Auto-scaled"
            VM1[App Server 1]
            VM2[App Server 2]
            VM3[App Server 3]
        end
        
        subgraph "Cache Tier"
            RedisCache[(Redis Cache)]
        end
        
        subgraph "Database Tier"
            PrimaryDB[(Primary SQL Server)]
            SecondaryDB[(Secondary SQL Server)]
        end
        
        subgraph "Storage"
            BlobStorage[Blob Storage]
        end
        
        subgraph "Monitoring"
            AppInsights[Application Insights]
            LogAnalytics[Log Analytics]
        end
    end
    
    Users --> CDN
    Users --> WAF
    WAF --> AppGW
    AppGW --> VM1
    AppGW --> VM2
    AppGW --> VM3
    
    VM1 --> RedisCache
    VM2 --> RedisCache
    VM3 --> RedisCache
    
    VM1 --> PrimaryDB
    VM2 --> PrimaryDB
    VM3 --> PrimaryDB
    
    PrimaryDB --> SecondaryDB
    
    VM1 --> BlobStorage
    
    VM1 --> AppInsights
    VM2 --> AppInsights
    VM3 --> AppInsights
    
    AppInsights --> LogAnalytics
```

---

## 10. Summary & Key Takeaways

### ✅ What We Covered

1. **Clean Architecture**: Separation of concerns with clear boundaries
2. **Layer Responsibilities**: Domain, Application, Infrastructure, API
3. **Communication Patterns**: REST, SignalR, Event-driven
4. **Design Patterns**: Repository, Unit of Work, Specification, CQRS
5. **Scalability**: Horizontal scaling, caching, database optimization
6. **Security**: Multi-layered security approach

### 🎯 Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture Style | Clean Architecture | Maintainability, testability |
| Communication | REST + SignalR | Standard + real-time needs |
| State Management | Angular Signals | Modern, reactive approach |
| Caching | Redis | Fast, scalable, pub/sub support |
| Authentication | JWT | Stateless, scalable |
| Database | SQL Server | ACID, strong consistency |

---

## 11. Next Steps

Now that you understand the high-level architecture, we'll dive into the database design.

👉 **[Module 03: Database Design and ER Diagrams](03-Database-Design-and-ER-Diagrams.md)**

In the next module, you'll learn:
- Complete ER diagram
- Table schemas and relationships
- Indexing strategy
- Data migration approach
- Sample data seeding

---

**Module 02 Complete** ✅  
**Progress**: 2/18 modules (11%)
