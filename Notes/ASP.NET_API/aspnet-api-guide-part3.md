# Building Scalable & Maintainable ASP.NET APIs - Part 3
## Repository Pattern & Database Layer

> **Production Example**: E-Commerce Order Management API (Continued)

---

## Table of Contents
1. [Database Context Configuration](#database-context-configuration)
2. [Generic Repository Implementation](#generic-repository-implementation)
3. [Specific Repositories](#specific-repositories)
4. [Unit of Work Implementation](#unit-of-work-implementation)
5. [Database Migrations](#database-migrations)
6. [Query Optimization](#query-optimization)

---

## Database Context Configuration

### DbContext Setup

**OrderManagement.Infrastructure/Data/Context/ApplicationDbContext.cs**
```csharp
using Microsoft.EntityFrameworkCore;
using OrderManagement.Domain.Entities;
using OrderManagement.Domain.ValueObjects;

namespace OrderManagement.Infrastructure.Data.Context;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }
    
    public DbSet<Customer> Customers { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Apply all configurations from assembly
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
        
        // Global query filter for soft delete
        modelBuilder.Entity<Customer>().HasQueryFilter(c => !c.IsDeleted);
        modelBuilder.Entity<Product>().HasQueryFilter(p => !p.IsDeleted);
        modelBuilder.Entity<Order>().HasQueryFilter(o => !o.IsDeleted);
        modelBuilder.Entity<OrderItem>().HasQueryFilter(oi => !oi.IsDeleted);
    }
    
    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Automatically set timestamps
        var entries = ChangeTracker.Entries()
            .Where(e => e.Entity is BaseEntity && 
                       (e.State == EntityState.Added || e.State == EntityState.Modified));
        
        foreach (var entry in entries)
        {
            var entity = (BaseEntity)entry.Entity;
            
            if (entry.State == EntityState.Added)
            {
                entity.CreatedAt = DateTime.UtcNow;
                // In real scenario, get from current user context
                entity.CreatedBy = "system";
            }
            else
            {
                entity.UpdatedAt = DateTime.UtcNow;
                entity.UpdatedBy = "system";
            }
        }
        
        return base.SaveChangesAsync(cancellationToken);
    }
}
```

### Entity Configuration (Fluent API)

**OrderManagement.Infrastructure/Data/Configuration/CustomerConfiguration.cs**
```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OrderManagement.Domain.Entities;

namespace OrderManagement.Infrastructure.Data.Configuration;

public class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder)
    {
        builder.ToTable("Customers");
        
        builder.HasKey(c => c.Id);
        
        builder.Property(c => c.FirstName)
            .IsRequired()
            .HasMaxLength(100);
        
        builder.Property(c => c.LastName)
            .IsRequired()
            .HasMaxLength(100);
        
        builder.Property(c => c.Email)
            .IsRequired()
            .HasMaxLength(255);
        
        builder.HasIndex(c => c.Email)
            .IsUnique();
        
        builder.Property(c => c.PhoneNumber)
            .HasMaxLength(20);
        
        // Value object configuration
        builder.OwnsOne(c => c.ShippingAddress, address =>
        {
            address.Property(a => a.Street).HasMaxLength(200);
            address.Property(a => a.City).HasMaxLength(100);
            address.Property(a => a.State).HasMaxLength(100);
            address.Property(a => a.ZipCode).HasMaxLength(20);
            address.Property(a => a.Country).HasMaxLength(100);
        });
        
        builder.OwnsOne(c => c.BillingAddress, address =>
        {
            address.Property(a => a.Street).HasMaxLength(200);
            address.Property(a => a.City).HasMaxLength(100);
            address.Property(a => a.State).HasMaxLength(100);
            address.Property(a => a.ZipCode).HasMaxLength(20);
            address.Property(a => a.Country).HasMaxLength(100);
        });
        
        // Relationships
        builder.HasMany(c => c.Orders)
            .WithOne(o => o.Customer)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);
        
        // Indexes for performance
        builder.HasIndex(c => c.LastName);
        builder.HasIndex(c => c.CreatedAt);
    }
}
```

**OrderManagement.Infrastructure/Data/Configuration/ProductConfiguration.cs**
```csharp
public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products");
        
        builder.HasKey(p => p.Id);
        
        builder.Property(p => p.Name)
            .IsRequired()
            .HasMaxLength(200);
        
        builder.Property(p => p.Description)
            .HasMaxLength(2000);
        
        builder.Property(p => p.SKU)
            .IsRequired()
            .HasMaxLength(50);
        
        builder.HasIndex(p => p.SKU)
            .IsUnique();
        
        builder.Property(p => p.Price)
            .HasPrecision(18, 2);
        
        builder.Property(p => p.Category)
            .HasConversion<string>()
            .HasMaxLength(50);
        
        builder.Property(p => p.ImageUrl)
            .HasMaxLength(500);
        
        // Indexes
        builder.HasIndex(p => p.Name);
        builder.HasIndex(p => p.Category);
        builder.HasIndex(p => p.IsActive);
    }
}
```

**OrderManagement.Infrastructure/Data/Configuration/OrderConfiguration.cs**
```csharp
public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("Orders");
        
        builder.HasKey(o => o.Id);
        
        builder.Property(o => o.OrderNumber)
            .IsRequired()
            .HasMaxLength(50);
        
        builder.HasIndex(o => o.OrderNumber)
            .IsUnique();
        
        builder.Property(o => o.Status)
            .HasConversion<string>()
            .HasMaxLength(20);
        
        builder.Property(o => o.PaymentMethod)
            .HasConversion<string>()
            .HasMaxLength(20);
        
        builder.Property(o => o.PaymentStatus)
            .HasConversion<string>()
            .HasMaxLength(20);
        
        builder.OwnsOne(o => o.ShippingAddress, address =>
        {
            address.Property(a => a.Street).HasMaxLength(200);
            address.Property(a => a.City).HasMaxLength(100);
            address.Property(a => a.State).HasMaxLength(100);
            address.Property(a => a.ZipCode).HasMaxLength(20);
            address.Property(a => a.Country).HasMaxLength(100);
        });
        
        builder.Property(o => o.ShippingCost)
            .HasPrecision(18, 2);
        
        builder.Property(o => o.TaxAmount)
            .HasPrecision(18, 2);
        
        builder.Property(o => o.DiscountAmount)
            .HasPrecision(18, 2);
        
        builder.Property(o => o.Notes)
            .HasMaxLength(1000);
        
        // Relationships
        builder.HasMany(o => o.Items)
            .WithOne(oi => oi.Order)
            .HasForeignKey(oi => oi.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
        
        // Computed columns (if supported by database)
        // builder.Property(o => o.Total)
        //     .HasComputedColumnSql("[Subtotal] + [ShippingCost] + [TaxAmount] - [DiscountAmount]");
        
        // Indexes
        builder.HasIndex(o => o.CustomerId);
        builder.HasIndex(o => o.OrderDate);
        builder.HasIndex(o => o.Status);
        builder.HasIndex(o => new { o.CustomerId, o.OrderDate });
    }
}
```

**OrderManagement.Infrastructure/Data/Configuration/OrderItemConfiguration.cs**
```csharp
public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.ToTable("OrderItems");
        
        builder.HasKey(oi => oi.Id);
        
        builder.Property(oi => oi.Quantity)
            .IsRequired();
        
        builder.Property(oi => oi.UnitPrice)
            .HasPrecision(18, 2);
        
        builder.Property(oi => oi.DiscountPercentage)
            .HasPrecision(5, 2);
        
        // Relationships
        builder.HasOne(oi => oi.Product)
            .WithMany(p => p.OrderItems)
            .HasForeignKey(oi => oi.ProductId)
            .OnDelete(DeleteBehavior.Restrict);
        
        // Indexes
        builder.HasIndex(oi => oi.OrderId);
        builder.HasIndex(oi => oi.ProductId);
    }
}
```

---

## Generic Repository Implementation

**OrderManagement.Domain/Interfaces/IRepository.cs**
```csharp
using System.Linq.Expressions;

namespace OrderManagement.Domain.Interfaces;

public interface IRepository<T> where T : class
{
    // Retrieval
    Task<T> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task<T> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate);
    
    // Queryable (for complex queries)
    Task<IQueryable<T>> GetQueryableAsync();
    
    // Count
    Task<int> CountAsync();
    Task<int> CountAsync(Expression<Func<T, bool>> predicate);
    
    // Existence check
    Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate);
    
    // Modification
    Task AddAsync(T entity);
    Task AddRangeAsync(IEnumerable<T> entities);
    Task UpdateAsync(T entity);
    Task UpdateRangeAsync(IEnumerable<T> entities);
    Task DeleteAsync(T entity);
    Task DeleteRangeAsync(IEnumerable<T> entities);
}
```

**OrderManagement.Infrastructure/Data/Repositories/Repository.cs**
```csharp
using Microsoft.EntityFrameworkCore;
using OrderManagement.Domain.Interfaces;
using OrderManagement.Infrastructure.Data.Context;
using System.Linq.Expressions;

namespace OrderManagement.Infrastructure.Data.Repositories;

public class Repository<T> : IRepository<T> where T : class
{
    protected readonly ApplicationDbContext _context;
    protected readonly DbSet<T> _dbSet;
    
    public Repository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }
    
    public virtual async Task<T> GetByIdAsync(int id)
    {
        return await _dbSet.FindAsync(id);
    }
    
    public virtual async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _dbSet.ToListAsync();
    }
    
    public virtual async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.Where(predicate).ToListAsync();
    }
    
    public virtual async Task<T> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.FirstOrDefaultAsync(predicate);
    }
    
    public virtual async Task<IQueryable<T>> GetQueryableAsync()
    {
        return await Task.FromResult(_dbSet.AsQueryable());
    }
    
    public virtual async Task<int> CountAsync()
    {
        return await _dbSet.CountAsync();
    }
    
    public virtual async Task<int> CountAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.CountAsync(predicate);
    }
    
    public virtual async Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.AnyAsync(predicate);
    }
    
    public virtual async Task AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
    }
    
    public virtual async Task AddRangeAsync(IEnumerable<T> entities)
    {
        await _dbSet.AddRangeAsync(entities);
    }
    
    public virtual async Task UpdateAsync(T entity)
    {
        _dbSet.Update(entity);
        await Task.CompletedTask;
    }
    
    public virtual async Task UpdateRangeAsync(IEnumerable<T> entities)
    {
        _dbSet.UpdateRange(entities);
        await Task.CompletedTask;
    }
    
    public virtual async Task DeleteAsync(T entity)
    {
        _dbSet.Remove(entity);
        await Task.CompletedTask;
    }
    
    public virtual async Task DeleteRangeAsync(IEnumerable<T> entities)
    {
        _dbSet.RemoveRange(entities);
        await Task.CompletedTask;
    }
}
```

---

## Specific Repositories

**OrderManagement.Domain/Interfaces/IOrderRepository.cs**
```csharp
namespace OrderManagement.Domain.Interfaces;

public interface IOrderRepository : IRepository<Order>
{
    Task<Order> GetOrderWithDetailsAsync(int orderId);
    Task<IEnumerable<Order>> GetOrdersByCustomerAsync(int customerId);
    Task<IEnumerable<Order>> GetOrdersByStatusAsync(OrderStatus status);
    Task<IEnumerable<Order>> GetOrdersByDateRangeAsync(DateTime startDate, DateTime endDate);
    Task<decimal> GetTotalRevenueAsync(DateTime startDate, DateTime endDate);
    Task<Dictionary<OrderStatus, int>> GetOrderCountByStatusAsync();
    Task<IEnumerable<Order>> GetRecentOrdersAsync(int count);
}
```

**OrderManagement.Infrastructure/Data/Repositories/OrderRepository.cs**
```csharp
using Microsoft.EntityFrameworkCore;
using OrderManagement.Domain.Entities;
using OrderManagement.Domain.Enums;
using OrderManagement.Domain.Interfaces;
using OrderManagement.Infrastructure.Data.Context;

namespace OrderManagement.Infrastructure.Data.Repositories;

public class OrderRepository : Repository<Order>, IOrderRepository
{
    public OrderRepository(ApplicationDbContext context) : base(context)
    {
    }
    
    public async Task<Order> GetOrderWithDetailsAsync(int orderId)
    {
        return await _dbSet
            .Include(o => o.Customer)
            .Include(o => o.Items)
                .ThenInclude(oi => oi.Product)
            .FirstOrDefaultAsync(o => o.Id == orderId);
    }
    
    public async Task<IEnumerable<Order>> GetOrdersByCustomerAsync(int customerId)
    {
        return await _dbSet
            .Include(o => o.Items)
                .ThenInclude(oi => oi.Product)
            .Where(o => o.CustomerId == customerId)
            .OrderByDescending(o => o.OrderDate)
            .ToListAsync();
    }
    
    public async Task<IEnumerable<Order>> GetOrdersByStatusAsync(OrderStatus status)
    {
        return await _dbSet
            .Include(o => o.Customer)
            .Include(o => o.Items)
            .Where(o => o.Status == status)
            .OrderByDescending(o => o.OrderDate)
            .ToListAsync();
    }
    
    public async Task<IEnumerable<Order>> GetOrdersByDateRangeAsync(
        DateTime startDate, 
        DateTime endDate)
    {
        return await _dbSet
            .Include(o => o.Customer)
            .Include(o => o.Items)
            .Where(o => o.OrderDate >= startDate && o.OrderDate <= endDate)
            .OrderByDescending(o => o.OrderDate)
            .ToListAsync();
    }
    
    public async Task<decimal> GetTotalRevenueAsync(DateTime startDate, DateTime endDate)
    {
        return await _dbSet
            .Where(o => o.OrderDate >= startDate && 
                       o.OrderDate <= endDate &&
                       o.Status != OrderStatus.Cancelled)
            .SumAsync(o => o.Total);
    }
    
    public async Task<Dictionary<OrderStatus, int>> GetOrderCountByStatusAsync()
    {
        return await _dbSet
            .GroupBy(o => o.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Status, x => x.Count);
    }
    
    public async Task<IEnumerable<Order>> GetRecentOrdersAsync(int count)
    {
        return await _dbSet
            .Include(o => o.Customer)
            .Include(o => o.Items)
                .ThenInclude(oi => oi.Product)
            .OrderByDescending(o => o.OrderDate)
            .Take(count)
            .ToListAsync();
    }
}
```

**OrderManagement.Domain/Interfaces/IProductRepository.cs & Implementation**
```csharp
public interface IProductRepository : IRepository<Product>
{
    Task<Product> GetBySKUAsync(string sku);
    Task<IEnumerable<Product>> GetProductsByCategoryAsync(ProductCategory category);
    Task<IEnumerable<Product>> GetLowStockProductsAsync(int threshold);
    Task<IEnumerable<Product>> GetTopSellingProductsAsync(int count);
    Task<bool> IsSKUUniqueAsync(string sku, int? excludeId = null);
}

public class ProductRepository : Repository<Product>, IProductRepository
{
    public ProductRepository(ApplicationDbContext context) : base(context)
    {
    }
    
    public async Task<Product> GetBySKUAsync(string sku)
    {
        return await _dbSet.FirstOrDefaultAsync(p => p.SKU == sku);
    }
    
    public async Task<IEnumerable<Product>> GetProductsByCategoryAsync(ProductCategory category)
    {
        return await _dbSet
            .Where(p => p.Category == category && p.IsActive)
            .OrderBy(p => p.Name)
            .ToListAsync();
    }
    
    public async Task<IEnumerable<Product>> GetLowStockProductsAsync(int threshold)
    {
        return await _dbSet
            .Where(p => p.StockQuantity <= threshold && p.IsActive)
            .OrderBy(p => p.StockQuantity)
            .ToListAsync();
    }
    
    public async Task<IEnumerable<Product>> GetTopSellingProductsAsync(int count)
    {
        return await _dbSet
            .Include(p => p.OrderItems)
            .Where(p => p.IsActive)
            .OrderByDescending(p => p.OrderItems.Sum(oi => oi.Quantity))
            .Take(count)
            .ToListAsync();
    }
    
    public async Task<bool> IsSKUUniqueAsync(string sku, int? excludeId = null)
    {
        var query = _dbSet.Where(p => p.SKU == sku);
        
        if (excludeId.HasValue)
            query = query.Where(p => p.Id != excludeId.Value);
        
        return !await query.AnyAsync();
    }
}
```

**OrderManagement.Domain/Interfaces/ICustomerRepository.cs & Implementation**
```csharp
public interface ICustomerRepository : IRepository<Customer>
{
    Task<Customer> GetByEmailAsync(string email);
    Task<IEnumerable<Customer>> GetTopCustomersAsync(int count);
    Task<bool> IsEmailUniqueAsync(string email, int? excludeId = null);
}

public class CustomerRepository : Repository<Customer>, ICustomerRepository
{
    public CustomerRepository(ApplicationDbContext context) : base(context)
    {
    }
    
    public async Task<Customer> GetByEmailAsync(string email)
    {
        return await _dbSet
            .Include(c => c.Orders)
            .FirstOrDefaultAsync(c => c.Email == email);
    }
    
    public async Task<IEnumerable<Customer>> GetTopCustomersAsync(int count)
    {
        return await _dbSet
            .Include(c => c.Orders)
            .OrderByDescending(c => c.Orders.Sum(o => o.Total))
            .Take(count)
            .ToListAsync();
    }
    
    public async Task<bool> IsEmailUniqueAsync(string email, int? excludeId = null)
    {
        var query = _dbSet.Where(c => c.Email == email);
        
        if (excludeId.HasValue)
            query = query.Where(c => c.Id != excludeId.Value);
        
        return !await query.AnyAsync();
    }
}
```

---

## Unit of Work Implementation

**OrderManagement.Domain/Interfaces/IUnitOfWork.cs**
```csharp
namespace OrderManagement.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IOrderRepository Orders { get; }
    IProductRepository Products { get; }
    ICustomerRepository Customers { get; }
    
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}
```

**OrderManagement.Infrastructure/Data/UnitOfWork/UnitOfWork.cs**
```csharp
using Microsoft.EntityFrameworkCore.Storage;
using OrderManagement.Domain.Interfaces;
using OrderManagement.Infrastructure.Data.Context;
using OrderManagement.Infrastructure.Data.Repositories;

namespace OrderManagement.Infrastructure.Data.UnitOfWork;

public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private IDbContextTransaction _transaction;
    
    // Lazy initialization of repositories
    private IOrderRepository _orderRepository;
    private IProductRepository _productRepository;
    private ICustomerRepository _customerRepository;
    
    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;
    }
    
    public IOrderRepository Orders => 
        _orderRepository ??= new OrderRepository(_context);
    
    public IProductRepository Products => 
        _productRepository ??= new ProductRepository(_context);
    
    public ICustomerRepository Customers => 
        _customerRepository ??= new CustomerRepository(_context);
    
    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }
    
    public async Task Begintransaction Async()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }
    
    public async Task CommitTransactionAsync()
    {
        try
        {
            await _transaction?.CommitAsync();
        }
        catch
        {
            await RollbackTransactionAsync();
            throw;
        }
        finally
        {
            _transaction?.Dispose();
            _transaction = null;
        }
    }
    
    public async Task RollbackTransactionAsync()
    {
        await _transaction?.RollbackAsync();
        _transaction?.Dispose();
        _transaction = null;
    }
    
    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}
```

---

## Database Migrations

### Create Initial Migration

```bash
# From Infrastructure project directory
dotnet ef migrations add InitialCreate --startup-project ../OrderManagement.API

# Update database
dotnet ef database update --startup-project ../OrderManagement.API
```

### Seed Data

**OrderManagement.Infrastructure/Data/Seed/DataSeeder.cs**
```csharp
namespace OrderManagement.Infrastructure.Data.Seed;

public static class DataSeeder
{
    public static async Task SeedDataAsync(ApplicationDbContext context)
    {
        if (await context.Products.AnyAsync())
            return; // Data already seeded
        
        // Seed Products
        var products = new List<Product>
        {
            new Product
            {
                Name = "Laptop Pro 15\"",
                Description = "High-performance laptop",
                SKU = "LAP-PRO-15",
                Price = 1299.99m,
                StockQuantity = 50,
                Category = ProductCategory.Electronics,
                IsActive = true,
                ImageUrl = "https://example.com/laptop.jpg"
            },
            new Product
            {
                Name = "Wireless Mouse",
                Description = "Ergonomic wireless mouse",
                SKU = "MOU-WRL-01",
                Price = 29.99m,
                StockQuantity = 200,
                Category = ProductCategory.Electronics,
                IsActive = true,
                ImageUrl = "https://example.com/mouse.jpg"
            },
            // Add more products...
        };
        
        await context.Products.AddRangeAsync(products);
        
        // Seed Customers
        var customers = new List<Customer>
        {
            new Customer
            {
                FirstName = "John",
                LastName = "Doe",
                Email = "john.doe@example.com",
                PhoneNumber = "+1234567890",
                ShippingAddress = new Address(
                    "123 Main St",
                    "New York",
                    "NY",
                    "10001",
                    "USA"
                ),
                BillingAddress = new Address(
                    "123 Main St",
                    "New York",
                    "NY",
                    "10001",
                    "USA"
                )
            },
            // Add more customers...
        };
        
        await context.Customers.AddRangeAsync(customers);
        await context.SaveChangesAsync();
    }
}
```

**Call seeder in Program.cs:**
```csharp
// In Program.cs, before app.Run()
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await context.Database.MigrateAsync(); // Apply migrations
    await DataSeeder.SeedDataAsync(context);
}
```

---

## Query Optimization

### Compiled Queries

```csharp
// For frequently used queries, compile them for better performance
public static class CompiledQueries
{
    public static readonly Func<ApplicationDbContext, int, Task<Order>> GetOrderById =
        EF.CompileAsyncQuery((ApplicationDbContext context, int id) =>
            context.Orders
                .Include(o => o.Customer)
                .Include(o => o.Items)
                    .ThenInclude(oi => oi.Product)
                .FirstOrDefault(o => o.Id == id));
    
    public static readonly Func<ApplicationDbContext, int, Task<IEnumerable<Order>>> GetCustomerOrders =
        EF.CompileAsyncQuery((ApplicationDbContext context, int customerId) =>
            context.Orders
                .Include(o => o.Items)
                .Where(o => o.CustomerId == customerId)
                .OrderByDescending(o => o.OrderDate));
}

// Usage
var order = await CompiledQueries.GetOrderById(_context, orderId);
```

### AsNoTracking for Read-Only Queries

```csharp
// Use AsNoTracking() for read-only queries to improve performance
public async Task<IEnumerable<ProductDto>> GetProductsForDisplayAsync()
{
    var products = await _context.Products
        .AsNoTracking() // Don't track changes
        .Where(p => p.IsActive)
        .OrderBy(p => p.Name)
        .ToListAsync();
    
    return _mapper.Map<IEnumerable<ProductDto>>(products);
}
```

### Pagination Best Practices

```csharp
public async Task<PagedResult<OrderDto>> GetPagedOrdersAsync(
    int pageNumber, 
    int pageSize)
{
    var query = _context.Orders
        .Include(o => o.Customer)
        .AsNoTracking();
    
    var totalCount = await query.CountAsync();
    
    var orders = await query
        .OrderByDescending(o => o.OrderDate)
        .Skip((pageNumber - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync();
    
    return new PagedResult<OrderDto>
    {
        Items = _mapper.Map<List<OrderDto>>(orders),
        TotalCount = totalCount,
        PageNumber = pageNumber,
        PageSize = pageSize
    };
}
```

### Projection to DTOs

```csharp
// Project directly to DTOs to fetch only needed data
public async Task<IEnumerable<OrderSummaryDto>> GetOrderSummariesAsync()
{
    return await _context.Orders
        .AsNoTracking()
        .Select(o => new OrderSummaryDto
        {
            Id = o.Id,
            OrderNumber = o.OrderNumber,
            CustomerName = o.Customer.FirstName + " " + o.Customer.LastName,
            Total = o.Total,
            Status = o.Status.ToString()
        })
        .ToListAsync();
}
```

---

## Key Takeaways

✅ **DbContext** is configured with Fluent API for precise control  
✅ **Generic repository** eliminates code duplication  
✅ **Specific repositories** add custom queries  
✅ **Unit of Work** coordinates transactions  
✅ **Query optimization** improves performance  
✅ **Migrations** manage database schema changes  
✅ **Seed data** provides initial application data  

---

Continue to [Part 4: Authentication & Authorization](aspnet-api-guide-part4.md) →
