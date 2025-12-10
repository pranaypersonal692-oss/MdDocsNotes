# Quick Reference Guide - Movie Ticket Booking System

## 🚀 Quick Navigation

| Section | Module | Description | Key Topics |
|---------|--------|-------------|------------|
| **Start** | [Master Index](00-Master-Index.md) | Complete guide overview | All modules, navigation |
| **HLD** | [Module 01](01-Introduction-and-System-Overview.md) | System overview | Requirements, user stories |
| **HLD** | [Module 02](02-High-Level-Architecture-Design.md) | Architecture design | Clean architecture, patterns |
| **HLD** | [Module 03](03-Database-Design-and-ER-Diagrams.md) | Database design | ER diagrams, schemas |
| **Backend** | [Module 04](04-Backend-Project-Setup.md) | Project setup | Solution structure, DI |
| **Backend** | [Module 05](05-Domain-Models-and-DbContext.md) | Domain models | Entities, EF Core |
| **Backend** | [Module 06](06-Repository-and-UnitOfWork.md) | Data access | Repository, Unit of Work |
| **Backend** | [Module 07-10](07-10-Backend-Services-Controllers-Auth.md) | Complete backend | Services, API, Auth |
| **Frontend** | [Module 11-16](11-16-Angular-Frontend-Complete.md) | Complete frontend | Angular 19, Signals |
| **Deploy** | [Module 17-18](17-18-Testing-and-Deployment.md) | Testing & deployment | Docker, CI/CD, Azure |

---

## 📋 Command Cheatsheet

### Backend Commands

```bash
# Create solution
dotnet new sln -n MovieTicketBooking

# Create projects
dotnet new classlib -n MovieTicket.Domain
dotnet new classlib -n MovieTicket.Application
dotnet new classlib -n MovieTicket.Infrastructure
dotnet new webapi -n MovieTicket.API

# Add project references
dotnet add MovieTicket.Application reference MovieTicket.Domain
dotnet add MovieTicket.Infrastructure reference MovieTicket.Domain
dotnet add MovieTicket.Infrastructure reference MovieTicket.Application
dotnet add MovieTicket.API reference MovieTicket.Application
dotnet add MovieTicket.API reference MovieTicket.Infrastructure

# Install key packages
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package AutoMapper.Extensions.Microsoft.DependencyInjection
dotnet add package FluentValidation.DependencyInjectionExtensions
dotnet add package Serilog.AspNetCore

# Migrations
dotnet ef migrations add InitialCreate --startup-project ../MovieTicket.API
dotnet ef database update --startup-project ../MovieTicket.API

# Run
dotnet run --project src/MovieTicket.API
```

### Frontend Commands

```bash
# Create Angular project
ng new movie-booking-app --standalone --routing --style=scss

# Generate components
ng generate component features/movies/components/movie-list --standalone
ng generate service features/movies/services/movie

# Install dependencies
npm install @angular/material @angular/cdk
npm install date-fns
npm install jwt-decode

# Run development server
ng serve
ng serve --open  # Opens browser automatically

# Build for production
ng build --configuration production

# Run tests
ng test
ng e2e
```

### Docker Commands

```bash
# Build images
docker build -t moviebooking-api .
docker build -t moviebooking-frontend ./client

# Run with docker-compose
docker-compose up -d
docker-compose down

# View logs
docker-compose logs -f api
docker-compose logs -f frontend
```

---

## 🔑 Key Code Patterns

### Backend: Repository Pattern

```csharp
// Interface
public interface IMovieRepository : IRepository<Movie>
{
    Task<IEnumerable<Movie>> GetNowShowingAsync();
}

// Implementation
public class MovieRepository : Repository<Movie>, IMovieRepository
{
    public async Task<IEnumerable<Movie>> GetNowShowingAsync()
    {
        return await _dbSet
            .Where(m => m.Status == MovieStatus.NowShowing)
            .ToListAsync();
    }
}

// Usage in service
public class MovieService
{
    private readonly IUnitOfWork _unitOfWork;
    
    public async Task<IEnumerable<MovieDto>> GetNowShowingAsync()
    {
        var movies = await _unitOfWork.Movies.GetNowShowingAsync();
        return _mapper.Map<IEnumerable<MovieDto>>(movies);
    }
}
```

### Frontend: Signal State Management

```typescript
// State service
@Injectable({ providedIn: 'root' })
export class MovieStateService {
  private moviesSignal = signal<Movie[]>([]);
  
  movies = this.moviesSignal.asReadonly();
  
  nowShowing = computed(() =>
    this.moviesSignal().filter(m => m.status === 'NowShowing')
  );
  
  setMovies(movies: Movie[]): void {
    this.moviesSignal.set(movies);
  }
}

// Component usage
@Component({...})
export class MovieListComponent {
  state = inject(MovieStateService);
  
  // Access reactive data
  movies = this.state.movies(); // Gets current value
  nowShowing = this.state.nowShowing(); // Computed value
}
```

### API Response Format

```typescript
// Standard API response
interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
}

// Usage
return Ok(new { 
  success = true, 
  data = movies 
});
```

---

## 🎯 Important Configurations

### appsettings.json (Backend)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MovieTicketBookingDB;Trusted_Connection=True;",
    "RedisConnection": "localhost:6379"
  },
  "JwtSettings": {
    "SecretKey": "YourSecretKeyMinimum32CharactersLong",
    "Issuer": "MovieTicketBooking.API",
    "Audience": "MovieTicketBooking.Client",
    "ExpirationMinutes": 1440
  }
}
```

### environment.ts (Frontend)

```typescript
export const environment = {
  production: false,
  apiUrl: 'https://localhost:7001/api',
  apiTimeout: 30000
};
```

### CORS Configuration

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngularApp", policy =>
    {
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});
```

---

## 🐛 Common Issues & Solutions

### Issue 1: CORS Error
```
Access to XMLHttpRequest has been blocked by CORS policy
```
**Solution**: Ensure CORS is configured in Program.cs and app.UseCors() is called in correct order.

### Issue 2: 401 Unauthorized
```
Unauthorized access to protected endpoint
```
**Solution**: Check JWT token in localStorage, verify token expiration, ensure Authorization header format: `Bearer {token}`

### Issue 3: Migration Fails
```
Unable to create migration
```
**Solution**: Ensure DbContext is in Infrastructure project, use --startup-project flag pointing to API project.

### Issue 4: Circular Dependency
```
Unable to resolve service
```
**Solution**: Check DI registration order, avoid circular references in constructors, use IServiceProvider when needed.

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] Update connection strings
- [ ] Change JWT secret key
- [ ] Enable HTTPS
- [ ] Configure CORS for production domain
- [ ] Set environment to Production
- [ ] Enable response compression
- [ ] Configure rate limiting
- [ ] Set up application insights
- [ ] Configure health checks

### Database
- [ ] Run migrations on production DB
- [ ] Verify indexes
- [ ] Set up backups
- [ ] Configure connection pooling

### Security
- [ ] Store secrets in Azure Key Vault / AWS Secrets Manager
- [ ] Enable firewall rules
- [ ] Configure SSL certificates
- [ ] Set up DDoS protection
- [ ] Enable audit logging

### Monitoring
- [ ] Set up application logging
- [ ] Configure error tracking
- [ ] Set up performance monitoring
- [ ] Create alerts for critical issues

---

## 📊 Performance Benchmarks

| Metric | Target | Strategy |
|--------|--------|----------|
| API Response (P95) | < 200ms | Caching, indexing |
| Page Load | < 2s | Lazy loading, minification |
| Database Query | < 50ms | Optimized queries, indexes |
| Concurrent Users | 10,000+ | Horizontal scaling |

---

## 🔐 Security Checklist

- [x] JWT authentication implemented
- [x] Password hashing with BCrypt
- [x] HTTPS enforced
- [x] SQL injection prevention (parameterized queries)
- [x] XSS protection (input sanitization)
- [x] CSRF protection
- [x] Rate limiting configured
- [x] Input validation (FluentValidation)
- [x] Sensitive data encryption
- [x] Secure cookie configuration

---

## 📞 Support & Resources

### Documentation
- [ASP.NET Core Docs](https://docs.microsoft.com/aspnet/core)
- [Angular Docs](https://angular.io/docs)
- [EF Core Docs](https://docs.microsoft.com/ef/core)

### Community
- Stack Overflow
- GitHub Discussions
- Dev.to

---

**This quick reference guide complements the full 18-module guide. For detailed explanations, refer to individual modules.**

---

Last Updated: December 2025
