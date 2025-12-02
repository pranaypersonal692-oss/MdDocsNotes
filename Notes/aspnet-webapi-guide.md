# Building a Real-World Scalable and Robust API with ASP.NET Web API

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Architecture Overview](#architecture-overview)
4. [Project Setup](#project-setup)
5. [Layered Architecture Implementation](#layered-architecture-implementation)
6. [Database Integration](#database-integration)
7. [Dependency Injection](#dependency-injection)
8. [API Endpoints and Controllers](#api-endpoints-and-controllers)
9. [Error Handling and Logging](#error-handling-and-logging)
10. [Authentication and Authorization](#authentication-and-authorization)
11. [Validation](#validation)
12. [Pagination and Filtering](#pagination-and-filtering)
13. [Caching Strategies](#caching-strategies)
14. [API Versioning](#api-versioning)
15. [Performance Optimization](#performance-optimization)
16. [Testing](#testing)
17. [Documentation](#documentation)
18. [Deployment](#deployment)

---

## Introduction

This guide provides a comprehensive walkthrough for building a production-ready, scalable, and robust RESTful API using **ASP.NET Core Web API**. We'll create a sample e-commerce product catalog API that demonstrates industry best practices.

### Key Features We'll Implement
- Clean Architecture with proper separation of concerns
- Entity Framework Core for data access
- JWT-based authentication and role-based authorization
- Global error handling and structured logging
- Input validation and data sanitization
- API versioning
- Response caching and performance optimization
- Comprehensive unit and integration tests
- Swagger/OpenAPI documentation

---

## Prerequisites

### Required Knowledge
- C# programming fundamentals
- Object-Oriented Programming concepts
- RESTful API principles
- Basic SQL and database concepts
- LINQ queries

### Required Software
- **.NET 8 SDK** (or latest LTS version)
- **Visual Studio 2022** or **VS Code** with C# extension
- **SQL Server** (or SQL Server Express/LocalDB)
- **Postman** or similar API testing tool
- **Git** for version control

### Verify .NET Installation
```bash
dotnet --version
```

---

## Architecture Overview

### Clean Architecture Layers

Our API will follow Clean Architecture principles with these layers:

```
Solution Structure:
├── ProductCatalog.API          # Presentation Layer (Controllers, Middleware)
├── ProductCatalog.Application  # Business Logic Layer (Services, DTOs, Interfaces)
├── ProductCatalog.Domain       # Domain Layer (Entities, Enums, Exceptions)
├── ProductCatalog.Infrastructure # Data Access Layer (EF Core, Repositories)
└── ProductCatalog.Tests        # Test Projects
```

### Layer Responsibilities

**1. Domain Layer** (ProductCatalog.Domain)
- Contains business entities (Product, Category, Order)
- Domain exceptions
- Enumerations and value objects
- No dependencies on other layers

**2. Application Layer** (ProductCatalog.Application)
- Business logic and orchestration
- DTOs (Data Transfer Objects)
- Service interfaces and implementations
- Mapping profiles (AutoMapper)
- Validation rules

**3. Infrastructure Layer** (ProductCatalog.Infrastructure)
- EF Core DbContext
- Repository implementations
- External service integrations
- Data migrations

**4. API/Presentation Layer** (ProductCatalog.API)
- Controllers
- Middleware
- Filters
- API configuration
- Dependency injection setup

---

## Project Setup

### Step 1: Create Solution Structure

```bash
# Create solution directory
mkdir ProductCatalogAPI
cd ProductCatalogAPI

# Create solution file
dotnet new sln -n ProductCatalog

# Create projects
dotnet new webapi -n ProductCatalog.API
dotnet new classlib -n ProductCatalog.Domain
dotnet new classlib -n ProductCatalog.Application
dotnet new classlib -n ProductCatalog.Infrastructure
dotnet new xunit -n ProductCatalog.Tests

# Add projects to solution
dotnet sln add ProductCatalog.API/ProductCatalog.API.csproj
dotnet sln add ProductCatalog.Domain/ProductCatalog.Domain.csproj
dotnet sln add ProductCatalog.Application/ProductCatalog.Application.csproj
dotnet sln add ProductCatalog.Infrastructure/ProductCatalog.Infrastructure.csproj
dotnet sln add ProductCatalog.Tests/ProductCatalog.Tests.csproj
```

### Step 2: Set Up Project References

```bash
# API references Application and Infrastructure
cd ProductCatalog.API
dotnet add reference ../ProductCatalog.Application/ProductCatalog.Application.csproj
dotnet add reference ../ProductCatalog.Infrastructure/ProductCatalog.Infrastructure.csproj

# Application references Domain
cd ../ProductCatalog.Application
dotnet add reference ../ProductCatalog.Domain/ProductCatalog.Domain.csproj

# Infrastructure references Application and Domain
cd ../ProductCatalog.Infrastructure
dotnet add reference ../ProductCatalog.Domain/ProductCatalog.Domain.csproj
dotnet add reference ../ProductCatalog.Application/ProductCatalog.Application.csproj

# Tests reference API
cd ../ProductCatalog.Tests
dotnet add reference ../ProductCatalog.API/ProductCatalog.API.csproj
```

### Step 3: Install NuGet Packages

**ProductCatalog.API**
```bash
cd ProductCatalog.API
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Swashbuckle.AspNetCore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Console
dotnet add package Serilog.Sinks.File
```

**ProductCatalog.Application**
```bash
cd ../ProductCatalog.Application
dotnet add package AutoMapper.Extensions.Microsoft.DependencyInjection
dotnet add package FluentValidation.DependencyInjectionExtensions
dotnet add package FluentValidation.AspNetCore
```

**ProductCatalog.Infrastructure**
```bash
cd ../ProductCatalog.Infrastructure
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
```

**ProductCatalog.Tests**
```bash
cd ../ProductCatalog.Tests
dotnet add package Microsoft.AspNetCore.Mvc.Testing
dotnet add package Moq
dotnet add package FluentAssertions
dotnet add package Microsoft.EntityFrameworkCore.InMemory
```

---

## Layered Architecture Implementation

### Step 1: Domain Layer - Define Entities

**ProductCatalog.Domain/Entities/BaseEntity.cs**
```csharp
namespace ProductCatalog.Domain.Entities
{
    public abstract class BaseEntity
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;
    }
}
```

**ProductCatalog.Domain/Entities/Category.cs**
```csharp
namespace ProductCatalog.Domain.Entities
{
    public class Category : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        
        // Navigation properties
        public virtual ICollection<Product> Products { get; set; } = new List<Product>();
    }
}
```

**ProductCatalog.Domain/Entities/Product.cs**
```csharp
namespace ProductCatalog.Domain.Entities
{
    public class Product : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string SKU { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int StockQuantity { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsActive { get; set; } = true;
        
        // Foreign keys
        public int CategoryId { get; set; }
        
        // Navigation properties
        public virtual Category Category { get; set; } = null!;
    }
}
```

### Step 2: Domain Layer - Custom Exceptions

**ProductCatalog.Domain/Exceptions/NotFoundException.cs**
```csharp
namespace ProductCatalog.Domain.Exceptions
{
    public class NotFoundException : Exception
    {
        public NotFoundException(string message) : base(message)
        {
        }
        
        public NotFoundException(string name, object key) 
            : base($"Entity \"{name}\" ({key}) was not found.")
        {
        }
    }
}
```

**ProductCatalog.Domain/Exceptions/ValidationException.cs**
```csharp
namespace ProductCatalog.Domain.Exceptions
{
    public class ValidationException : Exception
    {
        public IDictionary<string, string[]> Errors { get; }
        
        public ValidationException() 
            : base("One or more validation failures have occurred.")
        {
            Errors = new Dictionary<string, string[]>();
        }
        
        public ValidationException(IDictionary<string, string[]> errors) 
            : this()
        {
            Errors = errors;
        }
    }
}
```

### Step 3: Application Layer - DTOs

**ProductCatalog.Application/DTOs/ProductDto.cs**
```csharp
namespace ProductCatalog.Application.DTOs
{
    public class ProductDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string SKU { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int StockQuantity { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsActive { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
```

**ProductCatalog.Application/DTOs/CreateProductDto.cs**
```csharp
namespace ProductCatalog.Application.DTOs
{
    public class CreateProductDto
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string SKU { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int StockQuantity { get; set; }
        public string? ImageUrl { get; set; }
        public int CategoryId { get; set; }
    }
}
```

**ProductCatalog.Application/DTOs/UpdateProductDto.cs**
```csharp
namespace ProductCatalog.Application.DTOs
{
    public class UpdateProductDto
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public decimal? Price { get; set; }
        public int? StockQuantity { get; set; }
        public string? ImageUrl { get; set; }
        public bool? IsActive { get; set; }
        public int? CategoryId { get; set; }
    }
}
```

### Step 4: Application Layer - Service Interfaces

**ProductCatalog.Application/Interfaces/IProductService.cs**
```csharp
using ProductCatalog.Application.DTOs;
using ProductCatalog.Application.Common;

namespace ProductCatalog.Application.Interfaces
{
    public interface IProductService
    {
        Task<PagedResult<ProductDto>> GetAllProductsAsync(
            int pageNumber, 
            int pageSize, 
            string? searchTerm, 
            int? categoryId);
        
        Task<ProductDto?> GetProductByIdAsync(int id);
        Task<ProductDto> CreateProductAsync(CreateProductDto dto);
        Task<ProductDto> UpdateProductAsync(int id, UpdateProductDto dto);
        Task<bool> DeleteProductAsync(int id);
    }
}
```

### Step 5: Application Layer - AutoMapper Profiles

**ProductCatalog.Application/Mappings/MappingProfile.cs**
```csharp
using AutoMapper;
using ProductCatalog.Application.DTOs;
using ProductCatalog.Domain.Entities;

namespace ProductCatalog.Application.Mappings
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Product, ProductDto>()
                .ForMember(dest => dest.CategoryName, 
                    opt => opt.MapFrom(src => src.Category.Name));
            
            CreateMap<CreateProductDto, Product>();
            
            CreateMap<UpdateProductDto, Product>()
                .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));
            
            CreateMap<Category, CategoryDto>();
            CreateMap<CreateCategoryDto, Category>();
        }
    }
}
```

### Step 6: Application Layer - Common Models

**ProductCatalog.Application/Common/PagedResult.cs**
```csharp
namespace ProductCatalog.Application.Common
{
    public class PagedResult<T>
    {
        public IEnumerable<T> Items { get; set; } = new List<T>();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
        public bool HasPrevious => PageNumber > 1;
        public bool HasNext => PageNumber < TotalPages;
    }
}
```

**ProductCatalog.Application/Common/ApiResponse.cs**
```csharp
namespace ProductCatalog.Application.Common
{
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public T? Data { get; set; }
        public IDictionary<string, string[]>? Errors { get; set; }
        
        public static ApiResponse<T> SuccessResponse(T data, string message = "Success")
        {
            return new ApiResponse<T>
            {
                Success = true,
                Message = message,
                Data = data
            };
        }
        
        public static ApiResponse<T> ErrorResponse(string message, IDictionary<string, string[]>? errors = null)
        {
            return new ApiResponse<T>
            {
                Success = false,
                Message = message,
                Errors = errors
            };
        }
    }
}
```

---

## Database Integration

### Step 1: Infrastructure Layer - Repository Interface

**ProductCatalog.Application/Interfaces/IRepository.cs**
```csharp
using System.Linq.Expressions;

namespace ProductCatalog.Application.Interfaces
{
    public interface IRepository<T> where T : class
    {
        Task<T?> GetByIdAsync(int id);
        Task<IEnumerable<T>> GetAllAsync();
        Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
        Task<T> AddAsync(T entity);
        Task UpdateAsync(T entity);
        Task DeleteAsync(T entity);
        Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null);
    }
}
```

### Step 2: Infrastructure Layer - Repository Implementation

**ProductCatalog.Infrastructure/Repositories/Repository.cs**
```csharp
using Microsoft.EntityFrameworkCore;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Infrastructure.Data;
using System.Linq.Expressions;

namespace ProductCatalog.Infrastructure.Repositories
{
    public class Repository<T> : IRepository<T> where T : class
    {
        protected readonly ApplicationDbContext _context;
        protected readonly DbSet<T> _dbSet;
        
        public Repository(ApplicationDbContext context)
        {
            _context = context;
            _dbSet = context.Set<T>();
        }
        
        public async Task<T?> GetByIdAsync(int id)
        {
            return await _dbSet.FindAsync(id);
        }
        
        public async Task<IEnumerable<T>> GetAllAsync()
        {
            return await _dbSet.ToListAsync();
        }
        
        public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
        {
            return await _dbSet.Where(predicate).ToListAsync();
        }
        
        public async Task<T> AddAsync(T entity)
        {
            await _dbSet.AddAsync(entity);
            await _context.SaveChangesAsync();
            return entity;
        }
        
        public async Task UpdateAsync(T entity)
        {
            _dbSet.Update(entity);
            await _context.SaveChangesAsync();
        }
        
        public async Task DeleteAsync(T entity)
        {
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync();
        }
        
        public async Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null)
        {
            return predicate == null 
                ? await _dbSet.CountAsync() 
                : await _dbSet.CountAsync(predicate);
        }
    }
}
```

### Step 3: Infrastructure Layer - DbContext

**ProductCatalog.Infrastructure/Data/ApplicationDbContext.cs**
```csharp
using Microsoft.EntityFrameworkCore;
using ProductCatalog.Domain.Entities;

namespace ProductCatalog.Infrastructure.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
            : base(options)
        {
        }
        
        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
        
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Product configuration
            modelBuilder.Entity<Product>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(200);
                
                entity.Property(e => e.SKU)
                    .IsRequired()
                    .HasMaxLength(50);
                
                entity.HasIndex(e => e.SKU)
                    .IsUnique();
                
                entity.Property(e => e.Price)
                    .HasColumnType("decimal(18,2)");
                
                entity.HasOne(e => e.Category)
                    .WithMany(c => c.Products)
                    .HasForeignKey(e => e.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);
                
                entity.HasQueryFilter(e => !e.IsDeleted); // Global query filter
            });
            
            // Category configuration
            modelBuilder.Entity<Category>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100);
                
                entity.HasQueryFilter(e => !e.IsDeleted);
            });
            
            // Seed data
            SeedData(modelBuilder);
        }
        
        private void SeedData(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Category>().HasData(
                new Category { Id = 1, Name = "Electronics", Description = "Electronic devices and accessories" },
                new Category { Id = 2, Name = "Clothing", Description = "Apparel and fashion items" },
                new Category { Id = 3, Name = "Books", Description = "Physical and digital books" }
            );
            
            modelBuilder.Entity<Product>().HasData(
                new Product 
                { 
                    Id = 1, 
                    Name = "Laptop", 
                    Description = "High-performance laptop", 
                    SKU = "ELEC-LAP-001", 
                    Price = 999.99m, 
                    StockQuantity = 50, 
                    CategoryId = 1 
                },
                new Product 
                { 
                    Id = 2, 
                    Name = "T-Shirt", 
                    Description = "Cotton t-shirt", 
                    SKU = "CLTH-TSH-001", 
                    Price = 19.99m, 
                    StockQuantity = 200, 
                    CategoryId = 2 
                }
            );
        }
        
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            // Auto-set UpdatedAt timestamp
            var entries = ChangeTracker.Entries()
                .Where(e => e.State == EntityState.Modified);
            
            foreach (var entry in entries)
            {
                if (entry.Entity is BaseEntity entity)
                {
                    entity.UpdatedAt = DateTime.UtcNow;
                }
            }
            
            return base.SaveChangesAsync(cancellationToken);
        }
    }
}
```

### Step 4: Create Database Migration

```bash
cd ProductCatalog.Infrastructure
dotnet ef migrations add InitialCreate --startup-project ../ProductCatalog.API
dotnet ef database update --startup-project ../ProductCatalog.API
```

---

## Dependency Injection

### Step 1: Configure Services in API Project

**ProductCatalog.API/Program.cs**
```csharp
using Microsoft.EntityFrameworkCore;
using ProductCatalog.Infrastructure.Data;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Application.Services;
using ProductCatalog.Infrastructure.Repositories;
using Serilog;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using ProductCatalog.API.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .WriteTo.Console()
    .WriteTo.File("logs/log-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddControllers();

// Database
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// AutoMapper
builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());

// Repositories
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

// Services
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();

// Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtSettings["SecretKey"]!))
    };
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Response caching
builder.Services.AddResponseCaching();
builder.Services.AddMemoryCache();

// API versioning
builder.Services.AddApiVersioning(options =>
{
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.DefaultApiVersion = new Microsoft.AspNetCore.Mvc.ApiVersion(1, 0);
    options.ReportApiVersions = true;
});

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Product Catalog API", Version = "v1" });
    
    // JWT Authentication in Swagger
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Configure HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.UseResponseCaching();

// Custom middleware
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();

app.MapControllers();

app.Run();
```

### Step 2: Configure appsettings.json

**ProductCatalog.API/appsettings.json**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=ProductCatalogDB;Trusted_Connection=true;MultipleActiveResultSets=true"
  },
  "JwtSettings": {
    "SecretKey": "YourSuperSecretKeyHereMustBeAtLeast32CharactersLong",
    "Issuer": "ProductCatalogAPI",
    "Audience": "ProductCatalogClient",
    "ExpiryInMinutes": 60
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning"
      }
    }
  },
  "AllowedHosts": "*"
}
```

---

## API Endpoints and Controllers

### Step 1: Base API Controller

**ProductCatalog.API/Controllers/BaseApiController.cs**
```csharp
using Microsoft.AspNetCore.Mvc;
using ProductCatalog.Application.Common;

namespace ProductCatalog.API.Controllers
{
    [ApiController]
    [Route("api/v{version:apiVersion}/[controller]")]
    [Produces("application/json")]
    public abstract class BaseApiController : ControllerBase
    {
        protected IActionResult HandleResult<T>(ApiResponse<T> response)
        {
            if (response.Success)
            {
                return Ok(response);
            }
            
            return BadRequest(response);
        }
    }
}
```

### Step 2: Products Controller

**ProductCatalog.API/Controllers/ProductsController.cs**
```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Application.DTOs;
using ProductCatalog.Application.Common;

namespace ProductCatalog.API.Controllers
{
    [ApiVersion("1.0")]
    public class ProductsController : BaseApiController
    {
        private readonly IProductService _productService;
        private readonly ILogger<ProductsController> _logger;
        
        public ProductsController(IProductService productService, ILogger<ProductsController> logger)
        {
            _productService = productService;
            _logger = logger;
        }
        
        /// <summary>
        /// Get all products with pagination and filtering
        /// </summary>
        [HttpGet]
        [ResponseCache(Duration = 60)]
        public async Task<IActionResult> GetProducts(
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? searchTerm = null,
            [FromQuery] int? categoryId = null)
        {
            _logger.LogInformation("Fetching products - Page: {PageNumber}, Size: {PageSize}", pageNumber, pageSize);
            
            var result = await _productService.GetAllProductsAsync(pageNumber, pageSize, searchTerm, categoryId);
            var response = ApiResponse<PagedResult<ProductDto>>.SuccessResponse(result);
            
            return Ok(response);
        }
        
        /// <summary>
        /// Get product by ID
        /// </summary>
        [HttpGet("{id}")]
        [ResponseCache(Duration = 60)]
        public async Task<IActionResult> GetProduct(int id)
        {
            var product = await _productService.GetProductByIdAsync(id);
            
            if (product == null)
            {
                return NotFound(ApiResponse<ProductDto>.ErrorResponse($"Product with ID {id} not found"));
            }
            
            return Ok(ApiResponse<ProductDto>.SuccessResponse(product));
        }
        
        /// <summary>
        /// Create a new product
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateProduct([FromBody] CreateProductDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            
            var product = await _productService.CreateProductAsync(dto);
            var response = ApiResponse<ProductDto>.SuccessResponse(product, "Product created successfully");
            
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, response);
        }
        
        /// <summary>
        /// Update an existing product
        /// </summary>
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] UpdateProductDto dto)
        {
            var product = await _productService.UpdateProductAsync(id, dto);
            var response = ApiResponse<ProductDto>.SuccessResponse(product, "Product updated successfully");
            
            return Ok(response);
        }
        
        /// <summary>
        /// Delete a product
        /// </summary>
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var result = await _productService.DeleteProductAsync(id);
            
            if (!result)
            {
                return NotFound(ApiResponse<bool>.ErrorResponse($"Product with ID {id} not found"));
            }
            
            return Ok(ApiResponse<bool>.SuccessResponse(true, "Product deleted successfully"));
        }
    }
}
```

---

## Error Handling and Logging

### Step 1: Exception Handling Middleware

**ProductCatalog.API/Middleware/ExceptionHandlingMiddleware.cs**
```csharp
using System.Net;
using System.Text.Json;
using ProductCatalog.Domain.Exceptions;
using ProductCatalog.Application.Common;

namespace ProductCatalog.API.Middleware
{
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionHandlingMiddleware> _logger;
        
        public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }
        
        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex);
            }
        }
        
        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            _logger.LogError(exception, "An unhandled exception occurred");
            
            context.Response.ContentType = "application/json";
            
            var response = exception switch
            {
                NotFoundException notFoundEx => new
                {
                    context.Response.StatusCode = (int)HttpStatusCode.NotFound,
                    Response = ApiResponse<object>.ErrorResponse(notFoundEx.Message)
                },
                ValidationException validationEx => new
                {
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest,
                    Response = ApiResponse<object>.ErrorResponse("Validation failed", validationEx.Errors)
                },
                _ => new
                {
                    context.Response.StatusCode = (int)HttpStatusCode.InternalServerError,
                    Response = ApiResponse<object>.ErrorResponse("An internal server error occurred")
                }
            };
            
            var jsonResponse = JsonSerializer.Serialize(response.Response);
            await context.Response.WriteAsync(jsonResponse);
        }
    }
}
```

### Step 2: Request Logging Middleware

**ProductCatalog.API/Middleware/RequestLoggingMiddleware.cs**
```csharp
using System.Diagnostics;

namespace ProductCatalog.API.Middleware
{
    public class RequestLoggingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<RequestLoggingMiddleware> _logger;
        
        public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }
        
        public async Task InvokeAsync(HttpContext context)
        {
            var stopwatch = Stopwatch.StartNew();
            
            _logger.LogInformation(
                "Incoming {Method} request to {Path}",
                context.Request.Method,
                context.Request.Path);
            
            await _next(context);
            
            stopwatch.Stop();
            
            _logger.LogInformation(
                "Completed {Method} {Path} with status code {StatusCode} in {ElapsedMilliseconds}ms",
                context.Request.Method,
                context.Request.Path,
                context.Response.StatusCode,
                stopwatch.ElapsedMilliseconds);
        }
    }
}
```

---

## Authentication and Authorization

### Step 1: Create User Entity and Identity Context

**ProductCatalog.Domain/Entities/ApplicationUser.cs**
```csharp
using Microsoft.AspNetCore.Identity;

namespace ProductCatalog.Domain.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
```

### Step 2: Authentication Service

**ProductCatalog.Application/DTOs/Auth/LoginDto.cs**
```csharp
namespace ProductCatalog.Application.DTOs.Auth
{
    public class LoginDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
```

**ProductCatalog.Application/DTOs/Auth/RegisterDto.cs**
```csharp
namespace ProductCatalog.Application.DTOs.Auth
{
    public class RegisterDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
    }
}
```

**ProductCatalog.Application/DTOs/Auth/AuthResponseDto.cs**
```csharp
namespace ProductCatalog.Application.DTOs.Auth
{
    public class AuthResponseDto
    {
        public string Token { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
    }
}
```

**ProductCatalog.Application/Interfaces/IAuthService.cs**
```csharp
using ProductCatalog.Application.DTOs.Auth;

namespace ProductCatalog.Application.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponseDto> RegisterAsync(RegisterDto dto);
        Task<AuthResponseDto> LoginAsync(LoginDto dto);
    }
}
```

### Step 3: JWT Token Service

**ProductCatalog.Application/Interfaces/ITokenService.cs**
```csharp
using ProductCatalog.Domain.Entities;

namespace ProductCatalog.Application.Interfaces
{
    public interface ITokenService
    {
        string GenerateToken(ApplicationUser user, IList<string> roles);
    }
}
```

**ProductCatalog.Infrastructure/Services/TokenService.cs**
```csharp
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Domain.Entities;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ProductCatalog.Infrastructure.Services
{
    public class TokenService : ITokenService
    {
        private readonly IConfiguration _configuration;
        
        public TokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }
        
        public string GenerateToken(ApplicationUser user, IList<string> roles)
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email!),
                new Claim(ClaimTypes.Name, $"{user.FirstName} {user.LastName}")
            };
            
            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }
            
            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["JwtSettings:SecretKey"]!));
            
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            
            var expiry = DateTime.UtcNow.AddMinutes(
                Convert.ToDouble(_configuration["JwtSettings:ExpiryInMinutes"]));
            
            var token = new JwtSecurityToken(
                issuer: _configuration["JwtSettings:Issuer"],
                audience: _configuration["JwtSettings:Audience"],
                claims: claims,
                expires: expiry,
                signingCredentials: credentials
            );
            
            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
```

### Step 4: Authentication Controller

**ProductCatalog.API/Controllers/AuthController.cs**
```csharp
using Microsoft.AspNetCore.Mvc;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Application.DTOs.Auth;
using ProductCatalog.Application.Common;

namespace ProductCatalog.API.Controllers
{
    [ApiVersion("1.0")]
    public class AuthController : BaseApiController
    {
        private readonly IAuthService _authService;
        
        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }
        
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            var result = await _authService.RegisterAsync(dto);
            var response = ApiResponse<AuthResponseDto>.SuccessResponse(result, "Registration successful");
            
            return Ok(response);
        }
        
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var result = await _authService.LoginAsync(dto);
            var response = ApiResponse<AuthResponseDto>.SuccessResponse(result, "Login successful");
            
            return Ok(response);
        }
    }
}
```

---

## Validation

### Step 1: FluentValidation Validators

**ProductCatalog.Application/Validators/CreateProductDtoValidator.cs**
```csharp
using FluentValidation;
using ProductCatalog.Application.DTOs;

namespace ProductCatalog.Application.Validators
{
    public class CreateProductDtoValidator : AbstractValidator<CreateProductDto>
    {
        public CreateProductDtoValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Product name is required")
                .MaximumLength(200).WithMessage("Product name must not exceed 200 characters");
            
            RuleFor(x => x.SKU)
                .NotEmpty().WithMessage("SKU is required")
                .MaximumLength(50).WithMessage("SKU must not exceed 50 characters")
                .Matches("^[A-Z]{4}-[A-Z]{3}-[0-9]{3}$")
                .WithMessage("SKU must be in format: XXXX-XXX-000");
            
            RuleFor(x => x.Price)
                .GreaterThan(0).WithMessage("Price must be greater than 0")
                .LessThan(1000000).WithMessage("Price must be less than 1,000,000");
            
            RuleFor(x => x.StockQuantity)
                .GreaterThanOrEqualTo(0).WithMessage("Stock quantity cannot be negative");
            
            RuleFor(x => x.CategoryId)
                .GreaterThan(0).WithMessage("Valid category must be selected");
        }
    }
}
```

### Step 2: Register FluentValidation

In `Program.cs`, add:
```csharp
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<CreateProductDtoValidator>();
```

---

## Pagination and Filtering

### Implementation in ProductService

**ProductCatalog.Application/Services/ProductService.cs**
```csharp
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using ProductCatalog.Application.DTOs;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Application.Common;
using ProductCatalog.Domain.Entities;
using ProductCatalog.Domain.Exceptions;

namespace ProductCatalog.Application.Services
{
    public class ProductService : IProductService
    {
        private readonly IRepository<Product> _repository;
        private readonly IMapper _mapper;
        
        public ProductService(IRepository<Product> repository, IMapper mapper)
        {
            _repository = repository;
            _mapper = mapper;
        }
        
        public async Task<PagedResult<ProductDto>> GetAllProductsAsync(
            int pageNumber, 
            int pageSize, 
            string? searchTerm, 
            int? categoryId)
        {
            var query = (await _repository.GetAllAsync()).AsQueryable();
            
            // Apply filters
            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                query = query.Where(p => 
                    p.Name.Contains(searchTerm) || 
                    p.Description.Contains(searchTerm) ||
                    p.SKU.Contains(searchTerm));
            }
            
            if (categoryId.HasValue)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }
            
            var totalCount = query.Count();
            
            // Apply pagination
            var items = query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToList();
            
            var dtos = _mapper.Map<List<ProductDto>>(items);
            
            return new PagedResult<ProductDto>
            {
                Items = dtos,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        
        public async Task<ProductDto?> GetProductByIdAsync(int id)
        {
            var product = await _repository.GetByIdAsync(id);
            return product == null ? null : _mapper.Map<ProductDto>(product);
        }
        
        public async Task<ProductDto> CreateProductAsync(CreateProductDto dto)
        {
            var product = _mapper.Map<Product>(dto);
            var created = await _repository.AddAsync(product);
            return _mapper.Map<ProductDto>(created);
        }
        
        public async Task<ProductDto> UpdateProductAsync(int id, UpdateProductDto dto)
        {
            var product = await _repository.GetByIdAsync(id);
            
            if (product == null)
            {
                throw new NotFoundException(nameof(Product), id);
            }
            
            _mapper.Map(dto, product);
            await _repository.UpdateAsync(product);
            
            return _mapper.Map<ProductDto>(product);
        }
        
        public async Task<bool> DeleteProductAsync(int id)
        {
            var product = await _repository.GetByIdAsync(id);
            
            if (product == null)
            {
                return false;
            }
            
            product.IsDeleted = true; // Soft delete
            await _repository.UpdateAsync(product);
            
            return true;
        }
    }
}
```

---

## Caching Strategies

### Step 1: Response Caching (already configured in Program.cs)

Usage in controllers:
```csharp
[HttpGet]
[ResponseCache(Duration = 60)] // Cache for 60 seconds
public async Task<IActionResult> GetProducts() { }
```

### Step 2: In-Memory Caching Service

**ProductCatalog.Application/Services/CachedProductService.cs**
```csharp
using Microsoft.Extensions.Caching.Memory;
using ProductCatalog.Application.DTOs;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Application.Common;

namespace ProductCatalog.Application.Services
{
    public class CachedProductService : IProductService
    {
        private readonly IProductService _productService;
        private readonly IMemoryCache _cache;
        private const int CacheDurationMinutes = 5;
        
        public CachedProductService(IProductService productService, IMemoryCache cache)
        {
            _productService = productService;
            _cache = cache;
        }
        
        public async Task<ProductDto?> GetProductByIdAsync(int id)
        {
            string cacheKey = $"product_{id}";
            
            if (!_cache.TryGetValue(cacheKey, out ProductDto? product))
            {
                product = await _productService.GetProductByIdAsync(id);
                
                if (product != null)
                {
                    var cacheOptions = new MemoryCacheEntryOptions()
                        .SetAbsoluteExpiration(TimeSpan.FromMinutes(CacheDurationMinutes));
                    
                    _cache.Set(cacheKey, product, cacheOptions);
                }
            }
            
            return product;
        }
        
        // Other methods delegate to _productService and invalidate cache when needed
        public Task<PagedResult<ProductDto>> GetAllProductsAsync(int pageNumber, int pageSize, string? searchTerm, int? categoryId)
            => _productService.GetAllProductsAsync(pageNumber, pageSize, searchTerm, categoryId);
        
        public async Task<ProductDto> CreateProductAsync(CreateProductDto dto)
        {
            var result = await _productService.CreateProductAsync(dto);
            _cache.Remove($"product_{result.Id}");
            return result;
        }
        
        public async Task<ProductDto> UpdateProductAsync(int id, UpdateProductDto dto)
        {
            var result = await _productService.UpdateProductAsync(id, dto);
            _cache.Remove($"product_{id}");
            return result;
        }
        
        public async Task<bool> DeleteProductAsync(int id)
        {
            var result = await _productService.DeleteProductAsync(id);
            _cache.Remove($"product_{id}");
            return result;
        }
    }
}
```

---

## API Versioning

API versioning is already configured. Create version-specific controllers:

**ProductCatalog.API/Controllers/V2/ProductsController.cs**
```csharp
using Microsoft.AspNetCore.Mvc;

namespace ProductCatalog.API.Controllers.V2
{
    [ApiVersion("2.0")]
    [Route("api/v{version:apiVersion}/[controller]")]
    public class ProductsController : BaseApiController
    {
        // V2 specific implementations with breaking changes
    }
}
```

---

## Performance Optimization

### Best Practices Implemented

1. **Async/Await**: All database operations are asynchronous
2. **Query Filters**: Global query filters for soft deletes
3. **Pagination**: Limit result sets
4. **Caching**: Response caching and in-memory caching
5. **Connection Pooling**: Built-in with EF Core
6. **Indexing**: Database indexes on frequently queried columns

### Additional Optimizations

**Use AsNoTracking for Read-Only Queries**:
```csharp
var products = await _context.Products
    .AsNoTracking()
    .ToListAsync();
```

**Select Only Required Fields**:
```csharp
var products = await _context.Products
    .Select(p => new ProductDto 
    { 
        Id = p.Id, 
        Name = p.Name 
    })
    .ToListAsync();
```

---

## Testing

### Step 1: Unit Tests

**ProductCatalog.Tests/Services/ProductServiceTests.cs**
```csharp
using Xunit;
using Moq;
using AutoMapper;
using FluentAssertions;
using ProductCatalog.Application.Services;
using ProductCatalog.Application.Interfaces;
using ProductCatalog.Domain.Entities;
using ProductCatalog.Application.DTOs;

namespace ProductCatalog.Tests.Services
{
    public class ProductServiceTests
    {
        private readonly Mock<IRepository<Product>> _mockRepository;
        private readonly Mock<IMapper> _mockMapper;
        private readonly ProductService _service;
        
        public ProductServiceTests()
        {
            _mockRepository = new Mock<IRepository<Product>>();
            _mockMapper = new Mock<IMapper>();
            _service = new ProductService(_mockRepository.Object, _mockMapper.Object);
        }
        
        [Fact]
        public async Task GetProductByIdAsync_ExistingId_ReturnsProduct()
        {
            // Arrange
            var productId = 1;
            var product = new Product { Id = productId, Name = "Test Product" };
            var productDto = new ProductDto { Id = productId, Name = "Test Product" };
            
            _mockRepository.Setup(r => r.GetByIdAsync(productId))
                .ReturnsAsync(product);
            _mockMapper.Setup(m => m.Map<ProductDto>(product))
                .Returns(productDto);
            
            // Act
            var result = await _service.GetProductByIdAsync(productId);
            
            // Assert
            result.Should().NotBeNull();
            result.Id.Should().Be(productId);
            result.Name.Should().Be("Test Product");
        }
        
        [Fact]
        public async Task CreateProductAsync_ValidDto_ReturnsCreatedProduct()
        {
            // Arrange
            var createDto = new CreateProductDto { Name = "New Product", Price = 99.99m };
            var product = new Product { Id = 1, Name = "New Product", Price = 99.99m };
            var productDto = new ProductDto { Id = 1, Name = "New Product", Price = 99.99m };
            
            _mockMapper.Setup(m => m.Map<Product>(createDto))
                .Returns(product);
            _mockRepository.Setup(r => r.AddAsync(product))
                .ReturnsAsync(product);
            _mockMapper.Setup(m => m.Map<ProductDto>(product))
                .Returns(productDto);
            
            // Act
            var result = await _service.CreateProductAsync(createDto);
            
            // Assert
            result.Should().NotBeNull();
            result.Name.Should().Be("New Product");
            result.Price.Should().Be(99.99m);
        }
    }
}
```

### Step 2: Integration Tests

**ProductCatalog.Tests/Integration/ProductsControllerTests.cs**
```csharp
using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using FluentAssertions;
using Xunit;
using ProductCatalog.Application.DTOs;
using ProductCatalog.Application.Common;

namespace ProductCatalog.Tests.Integration
{
    public class ProductsControllerTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly HttpClient _client;
        
        public ProductsControllerTests(WebApplicationFactory<Program> factory)
        {
            _client = factory.CreateClient();
        }
        
        [Fact]
        public async Task GetProducts_ReturnsSuccessStatusCode()
        {
            // Act
            var response = await _client.GetAsync("/api/v1/products");
            
            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
        }
        
        [Fact]
        public async Task GetProducts_ReturnsPagedResult()
        {
            // Act
            var response = await _client.GetFromJsonAsync<ApiResponse<PagedResult<ProductDto>>>(
                "/api/v1/products?pageNumber=1&pageSize=10");
            
            // Assert
            response.Should().NotBeNull();
            response!.Success.Should().BeTrue();
            response.Data.Should().NotBeNull();
            response.Data!.Items.Should().NotBeEmpty();
        }
    }
}
```

---

## Documentation

Swagger is already configured in `Program.cs`. Access it at:
- **Development**: `https://localhost:5001/swagger`

### Enhance Swagger with XML Comments

1. Enable XML documentation in `.csproj`:
```xml
<PropertyGroup>
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
    <NoWarn>$(NoWarn);1591</NoWarn>
</PropertyGroup>
```

2. Update Swagger configuration:
```csharp
builder.Services.AddSwaggerGen(c =>
{
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    c.IncludeXmlComments(xmlPath);
});
```

---

## Deployment

### Step 1: Publish the Application

```bash
dotnet publish -c Release -o ./publish
```

### Step 2: Configure for Production

**appsettings.Production.json**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=your-production-server;Database=ProductCatalogDB;User Id=your-user;Password=your-password;"
  },
  "JwtSettings": {
    "SecretKey": "YourProductionSecretKey",
    "ExpiryInMinutes": 30
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Warning"
    }
  }
}
```

### Step 3: Deploy to Azure App Service

```bash
# Install Azure CLI
az login

# Create resource group
az group create --name ProductCatalogRG --location eastus

# Create App Service plan
az appservice plan create --name ProductCatalogPlan --resource-group ProductCatalogRG --sku B1

# Create web app
az webapp create --name ProductCatalogAPI --resource-group ProductCatalogRG --plan ProductCatalogPlan

# Deploy
az webapp deployment source config-zip --resource-group ProductCatalogRG --name ProductCatalogAPI --src ./publish.zip
```

### Step 4: Configure Environment Variables

```bash
az webapp config appsettings set --resource-group ProductCatalogRG --name ProductCatalogAPI --settings \
  ConnectionStrings__DefaultConnection="your-connection-string" \
  JwtSettings__SecretKey="your-secret-key"
```

---

## Best Practices Summary

### Security
✅ JWT authentication with secure token generation
✅ Role-based authorization
✅ HTTPS enforcement
✅ CORS configuration
✅ Input validation with FluentValidation
✅ SQL injection prevention (EF Core parameterized queries)

### Performance
✅ Async/await pattern
✅ Response caching
✅ In-memory caching for frequently accessed data
✅ Database indexing
✅ Pagination for large datasets
✅ Query optimization with AsNoTracking

### Code Quality
✅ Clean Architecture with separation of concerns
✅ Dependency Injection
✅ Repository pattern
✅ DTO mapping with AutoMapper
✅ Global error handling
✅ Structured logging with Serilog

### Scalability
✅ Stateless API design
✅ API versioning for backward compatibility
✅ Soft deletes for data integrity
✅ Connection pooling
✅ Horizontal scaling ready

### Testing
✅ Unit tests with xUnit
✅ Integration tests
✅ Test coverage with mocking (Moq)

### Documentation
✅ Swagger/OpenAPI specification
✅ XML comments
✅ API versioning documentation

---

## Next Steps

1. **Add Redis for Distributed Caching**
2. **Implement Rate Limiting** (AspNetCoreRateLimit)
3. **Add Health Checks** (AspNetCore.HealthChecks)
4. **Implement Message Queuing** (RabbitMQ/Azure Service Bus)
5. **Add Application Insights** for monitoring
6. **Set up CI/CD Pipeline** (Azure DevOps/GitHub Actions)
7. **Implement GraphQL** endpoint (Hot Chocolate)
8. **Add Real-time Features** (SignalR)

---

## Conclusion

This guide provides a comprehensive foundation for building production-ready ASP.NET Web APIs. The architecture is scalable, maintainable, and follows industry best practices. Customize and extend based on your specific requirements.

For questions or improvements, refer to:
- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core)
- [Entity Framework Core Documentation](https://docs.microsoft.com/ef/core)
- [Clean Architecture Principles](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
