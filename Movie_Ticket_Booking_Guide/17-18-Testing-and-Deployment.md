# Module 17-18: Testing & Deployment (Combined)

This final combined module covers comprehensive testing strategies and production deployment for the Movie Ticket Booking System.

## Part 1: Testing Strategies

### 1.1 Backend Unit Testing (xUnit)

#### Test Project Setup

```powershell
cd tests/MovieTicket.UnitTests

# Install testing packages
dotnet add package xUnit
dotnet add package Moq
dotnet add package FluentAssertions
dotnet add package Microsoft.EntityFrameworkCore.InMemory
```

#### Domain Entity Tests

`tests/MovieTicket.UnitTests/Domain/MovieTests.cs`:

```csharp
using FluentAssertions;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Enums;
using Xunit;

namespace MovieTicket.UnitTests.Domain;

public class MovieTests
{
    [Fact]
    public void Create_WithValidData_ShouldCreateMovie()
    {
        // Arrange
        var title = "Test Movie";
        var description = "Test Description";
        var duration = 120;
        var genre = "Action";
        var language = "English";
        var releaseDate = DateTime.UtcNow.AddDays(30);

        // Act
        var movie = Movie.Create(title, description, duration, genre, language, releaseDate);

        // Assert
        movie.Should().NotBeNull();
        movie.Title.Should().Be(title);
        movie.Slug.Should().Be("test-movie");
        movie.Status.Should().Be(MovieStatus.ComingSoon);
    }

    [Fact]
    public void Create_WithEmptyTitle_ShouldThrowException()
    {
        // Arrange & Act & Assert
        var act = () => Movie.Create("", "Desc", 120, "Action", "English", DateTime.UtcNow);
        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void UpdateRating_ShouldCalculateCorrectAverage()
    {
        // Arrange
        var movie = Movie.Create("Test", "Desc", 120, "Action", "EN", DateTime.UtcNow);
        
        // Act
        movie.UpdateRating(4.5m, 1);
        movie.UpdateRating(3.5m, 2);

        // Assert
        movie.Rating.Should().Be(4.0m); // (4.5 + 3.5) / 2
        movie.TotalReviews.Should().Be(2);
    }
}
```

#### Service Tests

`tests/MovieTicket.UnitTests/Application/MovieServiceTests.cs`:

```csharp
using AutoMapper;
using FluentAssertions;
using Moq;
using MovieTicket.Application.DTOs.Movies;
using MovieTicket.Application.Services.Implementations;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Interfaces;
using Xunit;

namespace MovieTicket.UnitTests.Application;

public class MovieServiceTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<IMapper> _mapperMock;
    private readonly MovieService _sut;

    public MovieServiceTests()
    {
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _mapperMock = new Mock<IMapper>();
        _sut = new MovieService(_unitOfWorkMock.Object, _mapperMock.Object);
    }

    [Fact]
    public async Task GetNowShowingAsync_ShouldReturnMovies()
    {
        // Arrange
        var movies = new List<Movie>
        {
            Movie.Create("Movie 1", "Desc", 120, "Action", "EN", DateTime.UtcNow)
        };

        var movieDtos = new List<MovieDto>
        {
            new MovieDto { Id = 1, Title = "Movie 1" }
        };

        _unitOfWorkMock.Setup(x => x.Movies.GetNowShowingAsync())
            .ReturnsAsync(movies);

        _mapperMock.Setup(x => x.Map<IEnumerable<MovieDto>>(movies))
            .Returns(movieDtos);

        // Act
        var result = await _sut.GetNowShowingAsync();

        // Assert
        result.Should().HaveCount(1);
        result.First().Title.Should().Be("Movie 1");
        _unitOfWorkMock.Verify(x => x.Movies.GetNowShowingAsync(), Times.Once);
    }
}
```

### 1.2 Backend Integration Testing

`tests/MovieTicket.IntegrationTests/Controllers/MoviesControllerTests.cs`:

```csharp
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using MovieTicket.Application.DTOs.Movies;
using System.Net.Http.Json;
using Xunit;

namespace MovieTicket.IntegrationTests.Controllers;

public class MoviesControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public MoviesControllerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetNowShowing_ShouldReturnOk()
    {
        // Act
        var response = await _client.GetAsync("/api/movies/now-showing");

        // Assert
        response.Should().BeSuccessful();
        var content = await response.Content.ReadFromJsonAsync<ApiResponse<List<MovieDto>>>();
        content.Should().NotBeNull();
        content!.Success.Should().BeTrue();
    }

    [Fact]
    public async Task GetMovieById_WithInvalidId_ShouldReturn404()
    {
        // Act
        var response = await _client.GetAsync("/api/movies/99999");

        // Assert
        response.StatusCode.Should().Be(System.Net.HttpStatusCode.NotFound);
    }
}

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T Data { get; set; }
}
```

### 1.3 Frontend Unit Testing (Jasmine & Karma)

#### Component Tests

`src/app/features/movies/components/movie-list/movie-list.component.spec.ts`:

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { MovieListComponent } from './movie-list.component';
import { MovieService } from '../../services/movie.service';
import { MovieStateService } from '../../services/movie-state.service';
import { of } from 'rxjs';
import { signal } from '@angular/core';

describe('MovieListComponent', () => {
  let component: MovieListComponent;
  let fixture: ComponentFixture<MovieListComponent>;
  let mockMovieService: jasmine.SpyObj<MovieService>;
  let mockStateService: jasmine.SpyObj<MovieStateService>;

  beforeEach(async () => {
    mockMovieService = jasmine.createSpyObj('MovieService', ['getNowShowing']);
    mockStateService = jasmine.createSpyObj('MovieStateService', [], {
      movies: signal([]),
      loading: signal(false)
    });

    await TestBed.configureTestingModule({
      imports: [MovieListComponent],
      providers: [
        { provide: MovieService, useValue: mockMovieService },
        { provide: MovieStateService, useValue: mockStateService }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(MovieListComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load movies on init', () => {
    const mockResponse = {
      success: true,
      data: [{ id: 1, title: 'Test Movie' }]
    };
    mockMovieService.getNowShowing.and.returnValue(of(mockResponse as any));

    component.ngOnInit();

    expect(mockMovieService.getNowShowing).toHaveBeenCalled();
  });
});
```

#### Service Tests

`src/app/features/movies/services/movie.service.spec.ts`:

```typescript
import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { MovieService } from './movie.service';
import { environment } from '../../../../environments/environment';

describe('MovieService', () => {
  let service: MovieService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [MovieService]
    });
    service = TestBed.inject(MovieService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should fetch now showing movies', () => {
    const mockMovies = [{ id: 1, title: 'Test Movie' }];

    service.getNowShowing().subscribe(response => {
      expect(response.data).toEqual(mockMovies);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/movies/now-showing`);
    expect(req.request.method).toBe('GET');
    req.flush({ success: true, data: mockMovies });
  });
});
```

### 1.4 E2E Testing (Playwright)

#### Install Playwright

```bash
npm install -D @playwright/test
npx playwright install
```

#### E2E Test Example

`e2e/booking-flow.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Booking Flow', () => {
  test('user can complete booking', async ({ page }) => {
    // 1. Navigate to movies
    await page.goto('http://localhost:4200/movies');
    await expect(page.locator('h2')).toContainText('Now Showing');

    // 2. Select a movie
    await page.click('.movie-card:first-child');
    await expect(page).toHaveURL(/.*movies\/\d+/);

    // 3. Select show
    await page.click('button:has-text("Book Tickets")');

    // 4. Select seats
    await page.click('.seat.available:nth-child(1)');
    await page.click('.seat.available:nth-child(2)');
    await page.click('button:has-text("Continue")');

    // 5. Login
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');

    // 6. Payment
    await page.fill('input[name="cardNumber"]', '4242424242424242');
    await page.click('button:has-text("Pay Now")');

    // 7. Verify booking confirmation
    await expect(page.locator('.booking-confirmed')).toBeVisible();
  });
});
```

---

## Part 2: Deployment

### 2.1 Docker Containerization

#### Backend Dockerfile

Create `Dockerfile` in solution root:

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files and restore
COPY ["src/MovieTicket.API/MovieTicket.API.csproj", "src/MovieTicket.API/"]
COPY ["src/MovieTicket.Application/MovieTicket.Application.csproj", "src/MovieTicket.Application/"]
COPY ["src/MovieTicket.Domain/MovieTicket.Domain.csproj", "src/MovieTicket.Domain/"]
COPY ["src/MovieTicket.Infrastructure/MovieTicket.Infrastructure.csproj", "src/MovieTicket.Infrastructure/"]

RUN dotnet restore "src/MovieTicket.API/MovieTicket.API.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/src/MovieTicket.API"
RUN dotnet build "MovieTicket.API.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "MovieTicket.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 80
EXPOSE 443

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MovieTicket.API.dll"]
```

#### Frontend Dockerfile

Create `client/Dockerfile`:

```dockerfile
# Build stage
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build --prod

# Runtime stage
FROM nginx:alpine
COPY --from=build /app/dist/movie-booking-app/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrong@Passw0rd
      - MSSQL_PID=Developer
    ports:
      - "1433:1433"
    volumes:
      - sqldata:/var/opt/mssql

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data

  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "5000:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=MovieTicketBookingDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True
      - ConnectionStrings__RedisConnection=redis:6379
    depends_on:
      - sqlserver
      - redis

  frontend:
    build:
      context: ./client
      dockerfile: Dockerfile
    ports:
      - "4200:80"
    depends_on:
      - api

volumes:
  sqldata:
  redisdata:
```

### 2.2 CI/CD Pipeline (GitHub Actions)

Create `.github/workflows/ci-cd.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      
      - name: Restore dependencies
        run: dotnet restore
      
      - name: Build
        run: dotnet build --no-restore
      
      - name: Test
        run: dotnet test --no-build --verbosity normal

  frontend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies
        working-directory: ./client
        run: npm ci
      
      - name: Run tests
        working-directory: ./client
        run: npm run test:ci
      
      - name: Build
        working-directory: ./client
        run: npm run build --prod

  deploy:
    needs: [backend-test, frontend-test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push Docker images
        run: |
          docker-compose build
          docker-compose push
      
      - name: Deploy to Azure
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ secrets.AZURE_WEBAPP_NAME }}
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

### 2.3 Azure Deployment

#### Azure Resources Setup

```bash
# Login to Azure
az login

# Create resource group
az group create --name MovieBookingRG --location eastus

# Create App Service Plan
az appservice plan create \
  --name MovieBookingPlan \
  --resource-group MovieBookingRG \
  --sku B1 \
  --is-linux

# Create Web App for API
az webapp create \
  --resource-group MovieBookingRG \
  --plan MovieBookingPlan \
  --name moviebooking-api \
  --deployment-container-image-name moviebooking/api:latest

# Create SQL Database
az sql server create \
  --name moviebookingserver \
  --resource-group MovieBookingRG \
  --location eastus \
  --admin-user sqladmin \
  --admin-password <YourPassword>

az sql db create \
  --resource-group MovieBookingRG \
  --server moviebookingserver \
  --name MovieTicketBookingDB \
  --service-objective S0

# Create Redis Cache
az redis create \
  --location eastus \
  --name moviebooking-redis \
  --resource-group MovieBookingRG \
  --sku Basic \
  --vm-size c0
```

### 2.4 Production Configuration

#### Backend Production Settings

`appsettings.Production.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=moviebookingserver.database.windows.net;Database=MovieTicketBookingDB;User Id=sqladmin;Password=<YourPassword>;Encrypt=True;",
    "RedisConnection": "moviebooking-redis.redis.cache.windows.net:6380,password=<RedisKey>,ssl=True"
  },
  "JwtSettings": {
    "SecretKey": "<ProductionSecretKey>",
    "Issuer": "https://api.moviebooking.com",
    "Audience": "https://moviebooking.com"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*.moviebooking.com"
}
```

#### Frontend Production Environment

`src/environments/environment.prod.ts`:

```typescript
export const environment = {
  production: true,
  apiUrl: 'https://api.moviebooking.com/api',
  apiTimeout: 30000
};
```

### 2.5 Monitoring & Logging

#### Application Insights Setup

```csharp
// Program.cs
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
});
```

#### Health Checks Endpoint

```csharp
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description
            })
        });
        await context.Response.WriteAsync(result);
    }
});
```

### 2.6 Performance Optimization

#### Backend Optimizations

1. **Response Compression**
```csharp
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<GzipCompressionProvider>();
});
```

2. **Output Caching**
```csharp
builder.Services.AddOutputCache(options =>
{
    options.AddBasePolicy(builder => builder.Cache());
    options.AddPolicy("Movies", builder => 
        builder.Expire(TimeSpan.FromMinutes(5)));
});
```

#### Frontend Optimizations

1. **Lazy Loading**
```typescript
// Already implemented in routes

2. **Build Optimization**
```json
// angular.json
{
  "configurations": {
    "production": {
      "optimization": true,
      "outputHashing": "all",
      "sourceMap": false,
      "namedChunks": false,
      "aot": true,
      "extractLicenses": true,
      "budgets": [
        {
          "type": "initial",
          "maximumWarning": "500kb",
          "maximumError": "1mb"
        }
      ]
    }
  }
}
```

---

## Summary

### ✅ Complete Guide Accomplishments

1. **HLD & Architecture** (Modules 01-03)
   - System requirements and user stories
   - Clean Architecture design
   - Complete database schema

2. **Backend Implementation** (Modules 04-10)
   - ASP.NET Core 8 setup
   - Domain-driven design
   - Repository & Unit of Work patterns
   - RESTful API with JWT auth
   - Advanced features (caching, logging)

3. **Frontend Implementation** (Modules 11-16)
   - Angular 19 with Signals
   - State management best practices
   - Reactive forms & routing
   - HTTP interceptors

4. **Testing & Deployment** (Modules 17-18)
   - Unit & Integration testing
   - E2E testing with Playwright
   - Docker containerization
   - CI/CD with GitHub Actions
   - Azure cloud deployment

### 🎓 Key Learnings

- Clean Architecture principles
- Modern state management with Signals
- Secure authentication with JWT
- Production-ready deployment strategies
- Comprehensive testing approaches

---

**All Modules Complete** ✅  
**Progress**: 18/18 modules (100%)

🎉 **Congratulations!** You now have a complete, production-ready guide for building a Movie Ticket Booking System with ASP.NET Core 8 and Angular 19!

For questions and updates, refer back to individual modules or the [Master Index](00-Master-Index.md).
