# Building Scalable & Maintainable ASP.NET APIs - Part 7
## Testing & Deployment

> **Production Example**: E-Commerce Order Management API (Concluded)

---

## Table of Contents
1. [Unit Testing](#unit-testing)
2. [Integration Testing](#integration-testing)
3. [API Testing](#api-testing)
4. [Test Data Builders](#test-data-builders)
5. [Continuous Integration](#continuous-integration)
6. [Deployment Strategies](#deployment-strategies)
7. [Production Checklist](#production-checklist)

---

## Unit Testing

### Setting Up xUnit

```bash
dotnet add package xUnit
dotnet add package xUnit.runner.visualstudio
dotnet add package Moq
dotnet add package FluentAssertions
dotnet add package AutoFixture
```

### Testing Services

**OrderManagement.UnitTests/Services/OrderServiceTests.cs**
```csharp
using AutoFixture;
using FluentAssertions;
using Moq;
using OrderManagement.Application.DTOs.Order;
using OrderManagement.Application.Exceptions;
using OrderManagement.Application.Services;
using OrderManagement.Domain.Entities;
using OrderManagement.Domain.Interfaces;
using Xunit;

namespace OrderManagement.UnitTests.Services;

public class OrderServiceTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<IMapper> _mockMapper;
    private readonly Mock<ILogger<OrderService>> _mockLogger;
    private readonly OrderService _sut; // System Under Test
    private readonly IFixture _fixture;
    
    public OrderServiceTests()
    {
        _mockUnitOfWork = new Mock<IUnitOfWork>();
        _mockMapper = new Mock<IMapper>();
        _mockLogger = new Mock<ILogger<OrderService>>();
        _sut = new OrderService(_mockUnitOfWork.Object, _mockMapper.Object, _mockLogger.Object);
        _fixture = new Fixture();
    }
    
    [Fact]
    public async Task GetOrderByIdAsync_WhenOrderExists_ReturnsOrderDto()
    {
        // Arrange
        var orderId = 1;
        var order = _fixture.Build<Order>()
            .With(o => o.Id, orderId)
            .Create();
        
        var expectedDto = _fixture.Build<OrderDto>()
            .With(o => o.Id, orderId)
            .Create();
        
        _mockUnitOfWork.Setup(uow => uow.Orders.GetOrderWithDetailsAsync(orderId))
            .ReturnsAsync(order);
        
        _mockMapper.Setup(m => m.Map<OrderDto>(order))
            .Returns(expectedDto);
        
        // Act
        var result = await _sut.GetOrderByIdAsync(orderId);
        
        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(orderId);
        result.Should().BeEquivalentTo(expectedDto);
        
        _mockUnitOfWork.Verify(uow => uow.Orders.GetOrderWithDetailsAsync(orderId), Times.Once);
        _mockMapper.Verify(m => m.Map<OrderDto>(order), Times.Once);
    }
    
    [Fact]
    public async Task GetOrderByIdAsync_WhenOrderDoesNotExist_ThrowsNotFoundException()
    {
        // Arrange
        var orderId = 999;
        
        _mockUnitOfWork.Setup(uow => uow.Orders.GetOrderWithDetailsAsync(orderId))
            .ReturnsAsync((Order)null);
        
        // Act
        Func<Task> act = async () => await _sut.GetOrderByIdAsync(orderId);
        
        // Assert
        await act.Should().ThrowAsync<NotFoundException>()
            .WithMessage($"Order with ID {orderId} not found");
    }
    
    [Fact]
    public async Task CreateOrderAsync_WithValidData_ReturnsCreatedOrder()
    {
        // Arrange
        var customerId = 1;
        var customer = _fixture.Build<Customer>()
            .With(c => c.Id, customerId)
            .Create();
        
        var productId = 1;
        var product = _fixture.Build<Product>()
            .With(p => p.Id, productId)
            .With(p => p.Price, 100m)
            .With(p => p.StockQuantity, 50)
            .Create();
        
        var createDto = _fixture.Build<CreateOrderDto>()
            .With(dto => dto.CustomerId, customerId)
            .With(dto => dto.Items, new List<CreateOrderItemDto>
            {
                new CreateOrderItemDto { ProductId = productId, Quantity = 2 }
            })
            .Create();
        
        _mockUnitOfWork.Setup(uow => uow.Customers.GetByIdAsync(customerId))
            .ReturnsAsync(customer);
        
        _mockUnitOfWork.Setup(uow => uow.Products.GetByIdAsync(productId))
            .ReturnsAsync(product);
        
        _mockUnitOfWork.Setup(uow => uow.Orders.AddAsync(It.IsAny<Order>()))
            .Returns(Task.CompletedTask);
        
        _mockUnitOfWork.Setup(uow => uow.SaveChangesAsync(default))
            .ReturnsAsync(1);
        
        // Act
        var result = await _sut.CreateOrderAsync(createDto);
        
        // Assert
        result.Should().NotBeNull();
        
        _mockUnitOfWork.Verify(uow => uow.BeginTransactionAsync(), Times.Once);
        _mockUnitOfWork.Verify(uow => uow.SaveChangesAsync(default), Times.Once);
        _mockUnitOfWork.Verify(uow => uow.CommitTransactionAsync(), Times.Once);
    }
    
    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task CreateOrderAsync_WithInvalidCustomerId_ThrowsNotFoundException(int customerId)
    {
        // Arrange
        var createDto = _fixture.Build<CreateOrderDto>()
            .With(dto => dto.CustomerId, customerId)
            .Create();
        
        _mockUnitOfWork.Setup(uow => uow.Customers.GetByIdAsync(customerId))
            .ReturnsAsync((Customer)null);
        
        // Act
        Func<Task> act = async () => await _sut.CreateOrderAsync(createDto);
        
        // Assert
        await act.Should().ThrowAsync<NotFoundException>();
    }
    
    [Fact]
    public async Task CreateOrderAsync_WhenProductOutOfStock_ThrowsBusinessException()
    {
        // Arrange
        var customerId = 1;
        var customer = _fixture.Build<Customer>()
            .With(c => c.Id, customerId)
            .Create();
        
        var productId = 1;
        var product = _fixture.Build<Product>()
            .With(p => p.Id, productId)
            .With(p => p.StockQuantity, 0) // Out of stock
            .Create();
        
        var createDto = _fixture.Build<CreateOrderDto>()
            .With(dto => dto.CustomerId, customerId)
            .With(dto => dto.Items, new List<CreateOrderItemDto>
            {
                new CreateOrderItemDto { ProductId = productId, Quantity = 1 }
            })
            .Create();
        
        _mockUnitOfWork.Setup(uow => uow.Customers.GetByIdAsync(customerId))
            .ReturnsAsync(customer);
        
        _mockUnitOfWork.Setup(uow => uow.Products.GetByIdAsync(productId))
            .ReturnsAsync(product);
        
        // Act
        Func<Task> act = async () => await _sut.CreateOrderAsync(createDto);
        
        // Assert
        await act.Should().ThrowAsync<BusinessException>()
            .WithMessage($"Insufficient stock for product {product.Name}");
        
        _mockUnitOfWork.Verify(uow => uow.RollbackTransactionAsync(), Times.Once);
    }
}
```

### Testing Domain Logic

**OrderManagement.UnitTests/Domain/OrderTests.cs**
```csharp
public class OrderTests
{
    private readonly IFixture _fixture;
    
    public OrderTests()
    {
        _fixture = new Fixture();
    }
    
    [Fact]
    public void AddItem_WhenOrderIsPending_AddsItemToOrder()
    {
        // Arrange
        var order = _fixture.Build<Order>()
            .With(o => o.Status, OrderStatus.Pending)
            .With(o => o.Items, new List<OrderItem>())
            .Create();
        
        var product = _fixture.Create<Product>();
        int quantity = 2;
        decimal unitPrice = 100m;
        
        // Act
        order.AddItem(product, quantity, unitPrice);
        
        // Assert
        order.Items.Should().HaveCount(1);
        order.Items.First().ProductId.Should().Be(product.Id);
        order.Items.First().Quantity.Should().Be(quantity);
        order.Items.First().UnitPrice.Should().Be(unitPrice);
    }
    
    [Fact]
    public void AddItem_WhenOrderIsProcessing_ThrowsInvalidOperationException()
    {
        // Arrange
        var order = _fixture.Build<Order>()
            .With(o => o.Status, OrderStatus.Processing)
            .Create();
        
        var product = _fixture.Create<Product>();
        
        // Act
        Action act = () => order.AddItem(product, 1, 100m);
        
        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("Cannot modify a submitted order");
    }
    
    [Fact]
    public void Submit_WhenOrderHasItems_SetsStatusToProcessing()
    {
        // Arrange
        var order = _fixture.Build<Order>()
            .With(o => o.Status, OrderStatus.Pending)
            .With(o => o.Items, new List<OrderItem>
            {
                _fixture.Create<OrderItem>()
            })
            .Create();
        
        // Act
        order.Submit();
        
        // Assert
        order.Status.Should().Be(OrderStatus.Processing);
        order.OrderNumber.Should().NotBeNullOrEmpty();
        order.OrderDate.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }
    
    [Fact]
    public void Submit_WhenOrderIsEmpty_ThrowsInvalidOperationException()
    {
        // Arrange
        var order = _fixture.Build<Order>()
            .With(o => o.Status, OrderStatus.Pending)
            .With(o => o.Items, new List<OrderItem>())
            .Create();
        
        // Act
        Action act = () => order.Submit();
        
        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("Cannot submit an empty order");
    }
    
    [Fact]
    public void Total_CalculatesCorrectly()
    {
        // Arrange
        var order = _fixture.Build<Order>()
            .With(o => o.Items, new List<OrderItem>
            {
                new OrderItem { Quantity = 2, UnitPrice = 50m, DiscountPercentage = 0 },
                new OrderItem { Quantity = 1, UnitPrice = 100m, DiscountPercentage = 10 }
            })
            .With(o => o.ShippingCost, 10m)
            .With(o => o.TaxAmount, 20m)
            .With(o => o.DiscountAmount, 5m)
            .Create();
        
        // Act
        var total = order.Total;
        
        // Assert
        // Subtotal = (2 * 50) + (1 * 100 - 10) = 100 + 90 = 190
        // Total = 190 + 10 + 20 - 5 = 215
        total.Should().Be(215m);
    }
}
```

---

## Integration Testing

### WebApplicationFactory Setup

**OrderManagement.IntegrationTests/CustomWebApplicationFactory.cs**
```csharp
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using OrderManagement.Infrastructure.Data.Context;

namespace OrderManagement.IntegrationTests;

public class CustomWebApplicationFactory<TProgram> : WebApplicationFactory<TProgram> 
    where TProgram : class
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Remove existing DbContext
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));
            
            if (descriptor != null)
                services.Remove(descriptor);
            
            // Add in-memory database
            services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseInMemoryDatabase("InMemoryTestDb");
            });
            
            // Build service provider
            var sp = services.BuildServiceProvider();
            
            // Create scope and get DbContext
            using (var scope = sp.CreateScope())
            {
                var scopedServices = scope.ServiceProvider;
                var db = scopedServices.GetRequiredService<ApplicationDbContext>();
                
                db.Database.EnsureCreated();
                
                // Seed test data
                SeedTestData(db);
            }
        });
    }
    
    private void SeedTestData(ApplicationDbContext context)
    {
        context.Customers.AddRange(
            new Customer
            {
                Id = 1,
                FirstName = "Test",
                LastName = "User",
                Email = "test@example.com",
                PhoneNumber = "1234567890"
            }
        );
        
        context.Products.AddRange(
            new Product
            {
                Id = 1,
                Name = "Test Product",
                SKU = "TEST-001",
                Price = 99.99m,
                StockQuantity = 100,
                Category = ProductCategory.Electronics,
                IsActive = true
            }
        );
        
        context.SaveChanges();
    }
}
```

### Integration Tests

**OrderManagement.IntegrationTests/Controllers/OrdersControllerTests.cs**
```csharp
using FluentAssertions;
using OrderManagement.Application.DTOs.Order;
using System.Net;
using System.Net.Http.Json;
using Xunit;

namespace OrderManagement.IntegrationTests.Controllers;

public class OrdersControllerTests : IClassFixture<CustomWebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    
    public OrdersControllerTests(CustomWebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }
    
    [Fact]
    public async Task GetOrders_ReturnsSuccessStatusCode()
    {
        // Act
        var response = await _client.GetAsync("/api/orders");
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }
    
    [Fact]
    public async Task GetOrder_WithValidId_ReturnsOrder()
    {
        // Arrange
        var orderId = 1; // Assuming seeded order exists
        
        // Act
        var response = await _client.GetAsync($"/api/orders/{orderId}");
        var order = await response.Content.ReadFromJsonAsync<OrderDto>();
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        order.Should().NotBeNull();
        order.Id.Should().Be(orderId);
    }
    
    [Fact]
    public async Task GetOrder_WithInvalidId_ReturnsNotFound()
    {
        // Arrange
        var orderId = 999;
        
        // Act
        var response = await _client.GetAsync($"/api/orders/{orderId}");
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
    
    [Fact]
    public async Task CreateOrder_WithValidData_ReturnsCreatedOrder()
    {
        // Arrange
        var createDto = new CreateOrderDto
        {
            CustomerId = 1,
            PaymentMethod = "CreditCard",
            ShippingAddress = new AddressDto
            {
                Street = "123 Test St",
                City = "Test City",
                State = "TC",
                ZipCode = "12345",
                Country = "USA"
            },
            Items = new List<CreateOrderItemDto>
            {
                new CreateOrderItemDto { ProductId = 1, Quantity = 2 }
            }
        };
        
        // Act
        var response = await _client.PostAsJsonAsync("/api/orders", createDto);
        var createdOrder = await response.Content.ReadFromJsonAsync<OrderDto>();
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        createdOrder.Should().NotBeNull();
        createdOrder.CustomerId.Should().Be(createDto.CustomerId);
        createdOrder.Items.Should().HaveCount(1);
    }
    
    [Fact]
    public async Task CreateOrder_WithInvalidData_ReturnsBadRequest()
    {
        // Arrange
        var createDto = new CreateOrderDto
        {
            CustomerId = 0, // Invalid
            Items = new List<CreateOrderItemDto>()
        };
        
        // Act
        var response = await _client.PostAsJsonAsync("/api/orders", createDto);
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
}
```

---

## API Testing

### Using REST Client Extension

**orders.http**
```http
### Get All Orders
GET https://localhost:7001/api/orders
Authorization: Bearer {{accessToken}}

### Get Order by ID
GET https://localhost:7001/api/orders/1
Authorization: Bearer {{accessToken}}

### Create Order
POST https://localhost:7001/api/orders
Content-Type: application/json
Authorization: Bearer {{accessToken}}

{
  "customerId": 1,
  "paymentMethod": "CreditCard",
  "shippingAddress": {
    "street": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "USA"
  },
  "items": [
    {
      "productId": 1,
      "quantity": 2
    }
  ]
}

### Update Order
PUT https://localhost:7001/api/orders/1
Content-Type: application/json
Authorization: Bearer {{accessToken}}

{
  "status": "Shipped",
  "notes": "Updated order status"
}

### Login
POST https://localhost:7001/api/auth/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "Test@1234"
}
```

---

## Test Data Builders

### Builder Pattern for Test Data

**OrderManagement.UnitTests/Builders/OrderBuilder.cs**
```csharp
namespace OrderManagement.UnitTests.Builders;

public class OrderBuilder
{
    private Order _order;
    
    public OrderBuilder()
    {
        _order = new Order
        {
            Id = 1,
            OrderNumber = "ORD-20240101-ABC123",
            CustomerId = 1,
            OrderDate = DateTime.UtcNow,
            Status = OrderStatus.Pending,
            PaymentMethod = PaymentMethod.CreditCard,
            PaymentStatus = PaymentStatus.Pending,
            ShippingCost = 10m,
            TaxAmount = 15m,
            DiscountAmount = 0m,
            Items = new List<OrderItem>()
        };
    }
    
    public OrderBuilder WithId(int id)
    {
        _order.Id = id;
        return this;
    }
    
    public OrderBuilder WithCustomer(Customer customer)
    {
        _order.CustomerId = customer.Id;
        _order.Customer = customer;
        return this;
    }
    
    public OrderBuilder WithStatus(OrderStatus status)
    {
        _order.Status = status;
        return this;
    }
    
    public OrderBuilder WithItem(Product product, int quantity, decimal unitPrice)
    {
        _order.Items.Add(new OrderItem
        {
            ProductId = product.Id,
            Product = product,
            Quantity = quantity,
            UnitPrice = unitPrice
        });
        return this;
    }
    
    public OrderBuilder Submitted()
    {
        _order.Status = OrderStatus.Processing;
        _order.OrderDate = DateTime.UtcNow;
        _order.OrderNumber = $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..8].ToUpper()}";
        return this;
    }
    
    public Order Build()
    {
        return _order;
    }
}

// Usage in tests
var order = new OrderBuilder()
    .WithId(1)
    .WithStatus(OrderStatus.Processing)
    .WithItem(product1, 2, 50m)
    .WithItem(product2, 1, 100m)
    .Submitted()
    .Build();
```

---

## Continuous Integration

### GitHub Actions Workflow

**.github/workflows/ci.yml**
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    services:
      sqlserver:
        image: mcr.microsoft.com/mssql/server:2022-latest
        env:
          ACCEPT_EULA: Y
          SA_PASSWORD: YourStrong@Passw0rd
        ports:
          - 1433:1433
        options: >-
          --health-cmd="/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd' -Q 'SELECT 1'"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
      
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore --configuration Release
    
    - name: Run Unit Tests
      run: dotnet test tests/OrderManagement.UnitTests --no-build --configuration Release --verbosity normal --logger "trx;LogFileName=unit-tests.trx"
    
    - name: Run Integration Tests
      run: dotnet test tests/OrderManagement.IntegrationTests --no-build --configuration Release --verbosity normal --logger "trx;LogFileName=integration-tests.trx"
      env:
        ConnectionStrings__DefaultConnection: "Server=localhost;Database=TestDb;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;"
        ConnectionStrings__RedisConnection: "localhost:6379"
    
    - name: Publish Test Results
      uses: dorny/test-reporter@v1
      if: always()
      with:
        name: Test Results
        path: '**/*.trx'
        reporter: dotnet-trx
    
    - name: Code Coverage
      run: |
        dotnet test --no-build --configuration Release --collect:"XPlat Code Coverage"
    
    - name: Upload Coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage.cobertura.xml
        fail_ci_if_error: true
```

---

## Deployment Strategies

### Docker Deployment

**Dockerfile**
```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files and restore
COPY ["src/OrderManagement.API/OrderManagement.API.csproj", "OrderManagement.API/"]
COPY ["src/OrderManagement.Application/OrderManagement.Application.csproj", "OrderManagement.Application/"]
COPY ["src/OrderManagement.Domain/OrderManagement.Domain.csproj", "OrderManagement.Domain/"]
COPY ["src/OrderManagement.Infrastructure/OrderManagement.Infrastructure.csproj", "OrderManagement.Infrastructure/"]

RUN dotnet restore "OrderManagement.API/OrderManagement.API.csproj"

# Copy everything else and build
COPY src/ .
WORKDIR "/src/OrderManagement.API"
RUN dotnet build "OrderManagement.API.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "OrderManagement.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 80
EXPOSE 443

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "OrderManagement.API.dll"]
```

**docker-compose.yml**
```yaml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: order-management-api
    ports:
      - "5000:80"
      - "5001:443"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=OrderManagementDb;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;
      - ConnectionStrings__RedisConnection=redis:6379
      - JwtSettings__SecretKey=${JWT_SECRET_KEY}
    depends_on:
      - sqlserver
      - redis
    networks:
      - app-network
  
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrong@Passw0rd
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
    networks:
      - app-network
  
  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network

volumes:
  sqlserver-data:
  redis-data:

networks:
  app-network:
    driver: bridge
```

### Kubernetes Deployment

**k8s/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-management-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-management-api
  template:
    metadata:
      labels:
        app: order-management-api
    spec:
      containers:
      - name: api
        image: your-registry/order-management-api:latest
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: database-connection
        - name: ConnectionStrings__RedisConnection
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: redis-connection
        - name: JwtSettings__SecretKey
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: order-management-api-service
spec:
  selector:
    app: order-management-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

---

## Production Checklist

### Security
- [ ] HTTPS enforced
- [ ] JWT secret key properly secured (use Azure Key Vault, AWS Secrets Manager)
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS protection headers configured
- [ ] CORS properly configured
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints
- [ ] Sensitive data encrypted in database

### Performance
- [ ] Database indexes created
- [ ] Response caching enabled where appropriate
- [ ] Distributed caching (Redis) configured
- [ ] Connection pooling optimized
- [ ] Async/await used throughout
- [ ] Query optimization performed
- [ ] CDN configured for static assets (if any)

### Monitoring & Logging
- [ ] Structured logging (Serilog) configured
- [ ] Application Insights / ELK stack integrated
- [ ] Health checks implemented
- [ ] Performance monitoring enabled
- [ ] Error tracking (Sentry, Raygun) configured
- [ ] Alerts configured for critical errors

### Reliability
- [ ] Database backups automated
- [ ] Retry policies configured
- [ ] Circuit breaker pattern implemented
- [ ] Graceful shutdown handling
- [ ] Database migrations tested
- [ ] Rollback plan documented

### Testing
- [ ] Unit test coverage > 80%
- [ ] Integration tests passing
- [ ] Load testing performed
- [ ] Security testing completed
- [ ] API documentation (Swagger) up to date

### Deployment
- [ ] CI/CD pipeline configured
- [ ] Blue-green or canary deployment strategy
- [ ] Environment variables externalized
- [ ] Container image scanned for vulnerabilities
- [ ] Database migration strategy defined
- [ ] Rollback procedure documented

---

## Key Takeaways

✅ **Unit tests** verify business logic in isolation  
✅ **Integration tests** ensure components work together  
✅ **Test data builders** simplify test setup  
✅ **CI/CD** automates testing and deployment  
✅ **Docker** provides consistent environments  
✅ **Kubernetes** enables scalable orchestration  
✅ **Production checklist** ensures deployment readiness  

---

## Conclusion

You've now learned how to build a production-grade, scalable, and maintainable ASP.NET API covering:

1. **Architecture** - Clean Architecture, SOLID principles, layered design
2. **Implementation** - Entities, DTOs, services, controllers
3. **Data Access** - Repository pattern, Unit of Work, EF Core
4. **Security** - JWT authentication, authorization, refresh tokens
5. **Middleware** - Exception handling, logging, rate limiting
6. **Performance** - Caching, query optimization, async patterns
7. **Testing** - Unit, integration, and API testing
8. **Deployment** - Docker, Kubernetes, CI/CD

### Next Steps

- Implement message queues (RabbitMQ, Azure Service Bus) for async processing
- Add GraphQL endpoint using Hot Chocolate
- Implement event sourcing with EventStore
- Add API Gateway (Ocelot, YARP)
- Implement microservices architecture
- Add observability with OpenTelemetry

### Resources

- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core)
- [Entity Framework Core Documentation](https://docs.microsoft.com/ef/core)
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Microsoft Architecture Guides](https://dotnet.microsoft.com/learn/aspnet/architecture)

---

**Happy Coding! 🚀**
