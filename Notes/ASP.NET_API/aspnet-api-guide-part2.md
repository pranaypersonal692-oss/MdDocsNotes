# Building Scalable & Maintainable ASP.NET APIs - Part 2
## Core Implementation: Domain, DTOs & Controllers

> **Production Example**: E-Commerce Order Management API (Continued)

---

## Table of Contents
1. [Domain Layer Implementation](#domain-layer-implementation)
2. [DTOs and Mapping](#dtos-and-mapping)
3. [FluentValidation](#fluentvalidation)
4. [Service Layer](#service-layer)
5. [Controllers](#controllers)

---

## Domain Layer Implementation

### Domain Entities

The Domain layer contains your business entities with no external dependencies.

**OrderManagement.Domain/Entities/BaseEntity.cs**
```csharp
namespace OrderManagement.Domain.Entities;

public abstract class BaseEntity
{
    public int Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string CreatedBy { get; set; }
    public string? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; }
}
```

**OrderManagement.Domain/Entities/Customer.cs**
```csharp
namespace OrderManagement.Domain.Entities;

public class Customer : BaseEntity
{
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Email { get; set; }
    public string PhoneNumber { get; set; }
    public Address ShippingAddress { get; set; }
    public Address BillingAddress { get; set; }
    
    // Navigation properties
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    
    // Computed properties
    public string FullName => $"{FirstName} {LastName}";
    public int TotalOrders => Orders?.Count ?? 0;
}
```

**OrderManagement.Domain/Entities/Product.cs**
```csharp
namespace OrderManagement.Domain.Entities;

public class Product : BaseEntity
{
    public string Name { get; set; }
    public string Description { get; set; }
    public string SKU { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public ProductCategory Category { get; set; }
    public string ImageUrl { get; set; }
    public bool IsActive { get; set; }
    
    // Navigation properties
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    
    // Business logic
    public bool IsInStock => StockQuantity > 0;
    public bool CanFulfillQuantity(int quantity) => StockQuantity >= quantity;
    
    public void ReduceStock(int quantity)
    {
        if (!CanFulfillQuantity(quantity))
            throw new InvalidOperationException($"Insufficient stock for product {Name}");
            
        StockQuantity -= quantity;
    }
    
    public void RestoreStock(int quantity)
    {
        StockQuantity += quantity;
    }
}
```

**OrderManagement.Domain/Entities/Order.cs**
```csharp
namespace OrderManagement.Domain.Entities;

public class Order : BaseEntity
{
    public string OrderNumber { get; set; }
    public int CustomerId { get; set; }
    public Customer Customer { get; set; }
    
    public DateTime OrderDate { get; set; }
    public OrderStatus Status { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public PaymentStatus PaymentStatus { get; set; }
    
    public Address ShippingAddress { get; set; }
    public decimal ShippingCost { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    
    public string Notes { get; set; }
    public DateTime? ShippedDate { get; set; }
    public DateTime? DeliveredDate { get; set; }
    
    // Navigation properties
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    
    // Computed properties
    public decimal Subtotal => Items?.Sum(x => x.TotalPrice) ?? 0;
    public decimal Total => Subtotal + ShippingCost + TaxAmount - DiscountAmount;
    public int TotalItems => Items?.Sum(x => x.Quantity) ?? 0;
    
    // Business methods
    public void AddItem(Product product, int quantity, decimal unitPrice)
    {
        if (Status != OrderStatus.Pending)
            throw new InvalidOperationException("Cannot modify a submitted order");
            
        var existingItem = Items.FirstOrDefault(x => x.ProductId == product.Id);
        
        if (existingItem != null)
        {
            existingItem.Quantity += quantity;
        }
        else
        {
            Items.Add(new OrderItem
            {
                ProductId = product.Id,
                Product = product,
                Quantity = quantity,
                UnitPrice = unitPrice
            });
        }
    }
    
    public void RemoveItem(int productId)
    {
        if (Status != OrderStatus.Pending)
            throw new InvalidOperationException("Cannot modify a submitted order");
            
        var item = Items.FirstOrDefault(x => x.ProductId == productId);
        if (item != null)
            Items.Remove(item);
    }
    
    public void Submit()
    {
        if (Items.Count == 0)
            throw new InvalidOperationException("Cannot submit an empty order");
            
        Status = OrderStatus.Processing;
        OrderDate = DateTime.UtcNow;
        OrderNumber = GenerateOrderNumber();
    }
    
    public void MarkAsShipped()
    {
        if (Status != OrderStatus.Processing)
            throw new InvalidOperationException("Only processing orders can be shipped");
            
        Status = OrderStatus.Shipped;
        ShippedDate = DateTime.UtcNow;
    }
    
    public void MarkAsDelivered()
    {
        if (Status != OrderStatus.Shipped)
            throw new InvalidOperationException("Only shipped orders can be delivered");
            
        Status = OrderStatus.Delivered;
        DeliveredDate = DateTime.UtcNow;
    }
    
    public void Cancel()
    {
        if (Status == OrderStatus.Delivered)
            throw new InvalidOperationException("Cannot cancel a delivered order");
            
        Status = OrderStatus.Cancelled;
    }
    
    private string GenerateOrderNumber()
    {
        return $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper()}";
    }
}
```

**OrderManagement.Domain/Entities/OrderItem.cs**
```csharp
namespace OrderManagement.Domain.Entities;

public class OrderItem : BaseEntity
{
    public int OrderId { get; set; }
    public Order Order { get; set; }
    
    public int ProductId { get; set; }
    public Product Product { get; set; }
    
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal DiscountPercentage { get; set; }
    
    // Computed properties
    public decimal DiscountAmount => (UnitPrice * Quantity) * (DiscountPercentage / 100);
    public decimal TotalPrice => (UnitPrice * Quantity) - DiscountAmount;
}
```

### Value Objects

Value Objects represent concepts with no identity, defined by their attributes.

**OrderManagement.Domain/ValueObjects/Address.cs**
```csharp
namespace OrderManagement.Domain.ValueObjects;

public class Address
{
    public string Street { get; private set; }
    public string City { get; private set; }
    public string State { get; private set; }
    public string ZipCode { get; private set; }
    public string Country { get; private set; }
    
    protected Address() { } // For EF Core
    
    public Address(string street, string city, string state, string zipCode, string country)
    {
        Street = street ?? throw new ArgumentNullException(nameof(street));
        City = city ?? throw new ArgumentNullException(nameof(city));
        State = state ?? throw new ArgumentNullException(nameof(state));
        ZipCode = zipCode ?? throw new ArgumentNullException(nameof(zipCode));
        Country = country ?? throw new ArgumentNullException(nameof(country));
    }
    
    public string FullAddress => $"{Street}, {City}, {State} {ZipCode}, {Country}";
    
    // Value objects are compared by their values, not identity
    public override bool Equals(object obj)
    {
        if (obj is not Address other) return false;
        
        return Street == other.Street &&
               City == other.City &&
               State == other.State &&
               ZipCode == other.ZipCode &&
               Country == other.Country;
    }
    
    public override int GetHashCode()
    {
        return HashCode.Combine(Street, City, State, ZipCode, Country);
    }
}
```

### Enums

**OrderManagement.Domain/Enums/OrderStatus.cs**
```csharp
namespace OrderManagement.Domain.Enums;

public enum OrderStatus
{
    Pending = 0,
    Processing = 1,
    Shipped = 2,
    Delivered = 3,
    Cancelled = 4,
    Refunded = 5
}

public enum PaymentStatus
{
    Pending = 0,
    Authorized = 1,
    Captured = 2,
    Failed = 3,
    Refunded = 4
}

public enum PaymentMethod
{
    CreditCard = 0,
    DebitCard = 1,
    PayPal = 2,
    BankTransfer = 3,
    CashOnDelivery = 4
}

public enum ProductCategory
{
    Electronics = 0,
    Clothing = 1,
    Books = 2,
    Home = 3,
    Sports = 4,
    Toys = 5
}
```

---

## DTOs and Mapping

DTOs (Data Transfer Objects) shape the data for API requests/responses.

### Application Layer DTOs

**OrderManagement.Application/DTOs/Order/OrderDto.cs**
```csharp
namespace OrderManagement.Application.DTOs.Order;

public class OrderDto
{
    public int Id { get; set; }
    public string OrderNumber { get; set; }
    public int CustomerId { get; set; }
    public string CustomerName { get; set; }
    public DateTime OrderDate { get; set; }
    public string Status { get; set; }
    public string PaymentMethod { get; set; }
    public string PaymentStatus { get; set; }
    public AddressDto ShippingAddress { get; set; }
    public decimal Subtotal { get; set; }
    public decimal ShippingCost { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal Total { get; set; }
    public int TotalItems { get; set; }
    public List<OrderItemDto> Items { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class OrderItemDto
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; }
    public string ProductSKU { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal DiscountPercentage { get; set; }
    public decimal TotalPrice { get; set; }
}

public class AddressDto
{
    public string Street { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string ZipCode { get; set; }
    public string Country { get; set; }
}
```

**OrderManagement.Application/DTOs/Order/CreateOrderDto.cs**
```csharp
namespace OrderManagement.Application.DTOs.Order;

public class CreateOrderDto
{
    public int CustomerId { get; set; }
    public AddressDto ShippingAddress { get; set; }
    public string PaymentMethod { get; set; }
    public List<CreateOrderItemDto> Items { get; set; }
    public string Notes { get; set; }
}

public class CreateOrderItemDto
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
}
```

**OrderManagement.Application/DTOs/Order/UpdateOrderDto.cs**
```csharp
namespace OrderManagement.Application.DTOs.Order;

public class UpdateOrderDto
{
    public string Status { get; set; }
    public string PaymentStatus { get; set; }
    public string Notes { get; set; }
}
```

**OrderManagement.Application/DTOs/Product/ProductDto.cs**
```csharp
namespace OrderManagement.Application.DTOs.Product;

public class ProductDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public string SKU { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public string Category { get; set; }
    public string ImageUrl { get; set; }
    public bool IsActive { get; set; }
    public bool IsInStock { get; set; }
}

public class CreateProductDto
{
    public string Name { get; set; }
    public string Description { get; set; }
    public string SKU { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public string Category { get; set; }
    public string ImageUrl { get; set; }
}

public class UpdateProductDto
{
    public string Name { get; set; }
    public string Description { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public bool IsActive { get; set; }
}
```

### AutoMapper Configuration

**OrderManagement.Application/Mappings/MappingProfile.cs**
```csharp
using AutoMapper;
using OrderManagement.Application.DTOs.Order;
using OrderManagement.Application.DTOs.Product;
using OrderManagement.Domain.Entities;
using OrderManagement.Domain.ValueObjects;

namespace OrderManagement.Application.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        // Order mappings
        CreateMap<Order, OrderDto>()
            .ForMember(dest => dest.CustomerName, 
                opt => opt.MapFrom(src => src.Customer.FullName))
            .ForMember(dest => dest.Status, 
                opt => opt.MapFrom(src => src.Status.ToString()))
            .ForMember(dest => dest.PaymentMethod, 
                opt => opt.MapFrom(src => src.PaymentMethod.ToString()))
            .ForMember(dest => dest.PaymentStatus, 
                opt => opt.MapFrom(src => src.PaymentStatus.ToString()));
        
        CreateMap<CreateOrderDto, Order>()
            .ForMember(dest => dest.PaymentMethod, 
                opt => opt.MapFrom(src => Enum.Parse<PaymentMethod>(src.PaymentMethod)))
            .ForMember(dest => dest.Items, opt => opt.Ignore());
        
        // OrderItem mappings
        CreateMap<OrderItem, OrderItemDto>()
            .ForMember(dest => dest.ProductName, 
                opt => opt.MapFrom(src => src.Product.Name))
            .ForMember(dest => dest.ProductSKU, 
                opt => opt.MapFrom(src => src.Product.SKU));
        
        // Product mappings
        CreateMap<Product, ProductDto>()
            .ForMember(dest => dest.Category, 
                opt => opt.MapFrom(src => src.Category.ToString()));
        
        CreateMap<CreateProductDto, Product>()
            .ForMember(dest => dest.Category, 
                opt => opt.MapFrom(src => Enum.Parse<ProductCategory>(src.Category)));
        
        CreateMap<UpdateProductDto, Product>()
            .ForMember(dest => dest.Id, opt => opt.Ignore())
            .ForMember(dest => dest.SKU, opt => opt.Ignore());
        
        // Address mappings
        CreateMap<Address, AddressDto>().ReverseMap();
    }
}
```

---

## FluentValidation

Input validation ensures data integrity before it reaches your business logic.

**OrderManagement.Application/Validators/CreateOrderValidator.cs**
```csharp
using FluentValidation;
using OrderManagement.Application.DTOs.Order;

namespace OrderManagement.Application.Validators;

public class CreateOrderValidator : AbstractValidator<CreateOrderDto>
{
    public CreateOrderValidator()
    {
        RuleFor(x => x.CustomerId)
            .GreaterThan(0)
            .WithMessage("Customer ID must be greater than 0");
        
        RuleFor(x => x.PaymentMethod)
            .NotEmpty()
            .WithMessage("Payment method is required")
            .Must(BeValidPaymentMethod)
            .WithMessage("Invalid payment method");
        
        RuleFor(x => x.ShippingAddress)
            .NotNull()
            .WithMessage("Shipping address is required")
            .SetValidator(new AddressValidator());
        
        RuleFor(x => x.Items)
            .NotEmpty()
            .WithMessage("Order must contain at least one item")
            .Must(items => items.Count <= 50)
            .WithMessage("Order cannot contain more than 50 items");
        
        RuleForEach(x => x.Items)
            .SetValidator(new CreateOrderItemValidator());
    }
    
    private bool BeValidPaymentMethod(string paymentMethod)
    {
        return Enum.TryParse<PaymentMethod>(paymentMethod, out _);
    }
}

public class CreateOrderItemValidator : AbstractValidator<CreateOrderItemDto>
{
    public CreateOrderItemValidator()
    {
        RuleFor(x => x.ProductId)
            .GreaterThan(0)
            .WithMessage("Product ID must be greater than 0");
        
        RuleFor(x => x.Quantity)
            .GreaterThan(0)
            .WithMessage("Quantity must be greater than 0")
            .LessThanOrEqualTo(100)
            .WithMessage("Quantity cannot exceed 100");
    }
}

public class AddressValidator : AbstractValidator<AddressDto>
{
    public AddressValidator()
    {
        RuleFor(x => x.Street)
            .NotEmpty()
            .MaximumLength(200);
        
        RuleFor(x => x.City)
            .NotEmpty()
            .MaximumLength(100);
        
        RuleFor(x => x.State)
            .NotEmpty()
            .MaximumLength(100);
        
        RuleFor(x => x.ZipCode)
            .NotEmpty()
            .Matches(@"^\d{5}(-\d{4})?$")
            .WithMessage("Invalid ZIP code format");
        
        RuleFor(x => x.Country)
            .NotEmpty()
            .MaximumLength(100);
    }
}
```

**OrderManagement.Application/Validators/CreateProductValidator.cs**
```csharp
using FluentValidation;
using OrderManagement.Application.DTOs.Product;

namespace OrderManagement.Application.Validators;

public class CreateProductValidator : AbstractValidator<CreateProductDto>
{
    public CreateProductValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .WithMessage("Product name is required")
            .MaximumLength(200)
            .WithMessage("Product name cannot exceed 200 characters");
        
        RuleFor(x => x.SKU)
            .NotEmpty()
            .WithMessage("SKU is required")
            .Matches(@"^[A-Z0-9-]+$")
            .WithMessage("SKU must contain only uppercase letters, numbers, and hyphens");
        
        RuleFor(x => x.Price)
            .GreaterThan(0)
            .WithMessage("Price must be greater than 0")
            .PrecisionScale(18, 2, false)
            .WithMessage("Price can have at most 2 decimal places");
        
        RuleFor(x => x.StockQuantity)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Stock quantity cannot be negative");
        
        RuleFor(x => x.Category)
            .NotEmpty()
            .Must(BeValidCategory)
            .WithMessage("Invalid product category");
        
        RuleFor(x => x.ImageUrl)
            .Must(BeValidUrl)
            .When(x => !string.IsNullOrEmpty(x.ImageUrl))
            .WithMessage("Invalid image URL");
    }
    
    private bool BeValidCategory(string category)
    {
        return Enum.TryParse<ProductCategory>(category, out _);
    }
    
    private bool BeValidUrl(string url)
    {
        return Uri.TryCreate(url, UriKind.Absolute, out var uri) &&
               (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
    }
}
```

---

## Service Layer

Services contain business logic and orchestrate operations.

**OrderManagement.Application/Interfaces/IOrderService.cs**
```csharp
namespace OrderManagement.Application.Interfaces;

public interface IOrderService
{
    Task<OrderDto> GetOrderByIdAsync(int id);
    Task<PagedResult<OrderDto>> GetOrdersAsync(OrderQueryParameters parameters);
    Task<OrderDto> CreateOrderAsync(CreateOrderDto dto);
    Task<OrderDto> UpdateOrderAsync(int id, UpdateOrderDto dto);
    Task DeleteOrderAsync(int id);
    Task<OrderDto> SubmitOrderAsync(int id);
    Task<OrderDto> CancelOrderAsync(int id);
    Task<OrderDto> MarkAsShippedAsync(int id);
    Task<OrderDto> MarkAsDeliveredAsync(int id);
}

public class OrderQueryParameters
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string Status { get; set; }
    public int? CustomerId { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string SortBy { get; set; } = "OrderDate";
    public bool SortDescending { get; set; } = true;
}

public class PagedResult<T>
{
    public List<T> Items { get; set; }
    public int TotalCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
    public bool HasPrevious => PageNumber > 1;
    public bool HasNext => PageNumber < TotalPages;
}
```

**OrderManagement.Application/Services/OrderService.cs**
```csharp
using AutoMapper;
using OrderManagement.Application.DTOs.Order;
using OrderManagement.Application.Exceptions;
using OrderManagement.Application.Interfaces;
using OrderManagement.Domain.Entities;
using OrderManagement.Domain.Interfaces;

namespace OrderManagement.Application.Services;

public class OrderService : IOrderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    private readonly ILogger<OrderService> _logger;
    
    public OrderService(
        IUnitOfWork unitOfWork,
        IMapper mapper,
        ILogger<OrderService> logger)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
        _logger = logger;
    }
    
    public async Task<OrderDto> GetOrderByIdAsync(int id)
    {
        var order = await _unitOfWork.Orders.GetOrderWithDetailsAsync(id);
        
        if (order == null)
            throw new NotFoundException($"Order with ID {id} not found");
        
        return _mapper.Map<OrderDto>(order);
    }
    
    public async Task<PagedResult<OrderDto>> GetOrdersAsync(OrderQueryParameters parameters)
    {
        var query = await _unitOfWork.Orders.GetOrdersQueryableAsync();
        
        // Apply filters
        if (!string.IsNullOrEmpty(parameters.Status))
        {
            if (Enum.TryParse<OrderStatus>(parameters.Status, out var status))
                query = query.Where(x => x.Status == status);
        }
        
        if (parameters.CustomerId.HasValue)
            query = query.Where(x => x.CustomerId == parameters.CustomerId.Value);
        
        if (parameters.FromDate.HasValue)
            query = query.Where(x => x.OrderDate >= parameters.FromDate.Value);
        
        if (parameters.ToDate.HasValue)
            query = query.Where(x => x.OrderDate <= parameters.ToDate.Value);
        
        // Get total count
        var totalCount = await query.CountAsync();
        
        // Apply sorting
        query = parameters.SortBy?.ToLower() switch
        {
            "total" => parameters.SortDescending 
                ? query.OrderByDescending(x => x.Total)
                : query.OrderBy(x => x.Total),
            "customer" => parameters.SortDescending
                ? query.OrderByDescending(x => x.Customer.LastName)
                : query.OrderBy(x => x.Customer.LastName),
            _ => parameters.SortDescending
                ? query.OrderByDescending(x => x.OrderDate)
                : query.OrderBy(x => x.OrderDate)
        };
        
        // Apply pagination
        var orders = await query
            .Skip((parameters.PageNumber - 1) * parameters.PageSize)
            .Take(parameters.PageSize)
            .ToListAsync();
        
        return new PagedResult<OrderDto>
        {
            Items = _mapper.Map<List<OrderDto>>(orders),
            TotalCount = totalCount,
            PageNumber = parameters.PageNumber,
            PageSize = parameters.PageSize
        };
    }
    
    public async Task<OrderDto> CreateOrderAsync(CreateOrderDto dto)
    {
        await _unitOfWork.BeginTransactionAsync();
        
        try
        {
            // Verify customer exists
            var customer = await _unitOfWork.Customers.GetByIdAsync(dto.CustomerId);
            if (customer == null)
                throw new NotFoundException($"Customer with ID {dto.CustomerId} not found");
            
            // Create order
            var order = _mapper.Map<Order>(dto);
            order.Status = OrderStatus.Pending;
            order.PaymentStatus = PaymentStatus.Pending;
            
            // Add order items and verify stock
            foreach (var itemDto in dto.Items)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(itemDto.ProductId);
                if (product == null)
                    throw new NotFoundException($"Product with ID {itemDto.ProductId} not found");
                
                if (!product.CanFulfillQuantity(itemDto.Quantity))
                    throw new BusinessException($"Insufficient stock for product {product.Name}");
                
                order.AddItem(product, itemDto.Quantity, product.Price);
            }
            
            await _unitOfWork.Orders.AddAsync(order);
            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();
            
            _logger.LogInformation("Order created successfully. Order ID: {OrderId}", order.Id);
            
            // Reload with details
            var createdOrder = await _unitOfWork.Orders.GetOrderWithDetailsAsync(order.Id);
            return _mapper.Map<OrderDto>(createdOrder);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
    
    public async Task<OrderDto> SubmitOrderAsync(int id)
    {
        await _unitOfWork.BeginTransactionAsync();
        
        try
        {
            var order = await _unitOfWork.Orders.GetOrderWithDetailsAsync(id);
            if (order == null)
                throw new NotFoundException($"Order with ID {id} not found");
            
            // Reduce stock for all items
            foreach (var item in order.Items)
            {
                item.Product.ReduceStock(item.Quantity);
                await _unitOfWork.Products.UpdateAsync(item.Product);
            }
            
            // Submit order
            order.Submit();
            await _unitOfWork.Orders.UpdateAsync(order);
            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();
            
            _logger.LogInformation("Order submitted. Order Number: {OrderNumber}", order.OrderNumber);
            
            return _mapper.Map<OrderDto>(order);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
    
    public async Task<OrderDto> CancelOrderAsync(int id)
    {
        await _unitOfWork.BeginTransactionAsync();
        
        try
        {
            var order = await _unitOfWork.Orders.GetOrderWithDetailsAsync(id);
            if (order == null)
                throw new NotFoundException($"Order with ID {id} not found");
            
            // Restore stock if order was already submitted
            if (order.Status != OrderStatus.Pending)
            {
                foreach (var item in order.Items)
                {
                    item.Product.RestoreStock(item.Quantity);
                    await _unitOfWork.Products.UpdateAsync(item.Product);
                }
            }
            
            order.Cancel();
            await _unitOfWork.Orders.UpdateAsync(order);
            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();
            
            _logger.LogInformation("Order cancelled. Order Number: {OrderNumber}", order.OrderNumber);
            
            return _mapper.Map<OrderDto>(order);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
    
    // Additional methods: UpdateOrderAsync, DeleteOrderAsync, MarkAsShippedAsync, MarkAsDeliveredAsync...
}
```

---

## Controllers

Controllers handle HTTP requests and call appropriate services.

**OrderManagement.API/Controllers/OrdersController.cs**
```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OrderManagement.Application.DTOs.Order;
using OrderManagement.Application.Interfaces;

namespace OrderManagement.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly ILogger<OrdersController> _logger;
    
    public OrdersController(
        IOrderService orderService,
        ILogger<OrdersController> logger)
    {
        _orderService = orderService;
        _logger = logger;
    }
    
    /// <summary>
    /// Get all orders with pagination and filtering
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<OrderDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<OrderDto>>> GetOrders(
        [FromQuery] OrderQueryParameters parameters)
    {
        var result = await _orderService.GetOrdersAsync(parameters);
        
        // Add pagination metadata to response headers
        Response.Headers.Add("X-Pagination", System.Text.Json.JsonSerializer.Serialize(new
        {
            result.TotalCount,
            result.PageSize,
            result.PageNumber,
            result.TotalPages,
            result.HasNext,
            result.HasPrevious
        }));
        
        return Ok(result);
    }
    
    /// <summary>
    /// Get order by ID
    /// </summary>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<OrderDto>> GetOrder(int id)
    {
        var order = await _orderService.GetOrderByIdAsync(id);
        return Ok(order);
    }
    
    /// <summary>
    /// Create a new order
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<OrderDto>> CreateOrder([FromBody] CreateOrderDto dto)
    {
        var order = await _orderService.CreateOrderAsync(dto);
        return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
    }
    
    /// <summary>
    /// Update an existing order
    /// </summary>
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<OrderDto>> UpdateOrder(
        int id, 
        [FromBody] UpdateOrderDto dto)
    {
        var order = await _orderService.UpdateOrderAsync(id, dto);
        return Ok(order);
    }
    
    /// <summary>
    /// Delete an order
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteOrder(int id)
    {
        await _orderService.DeleteOrderAsync(id);
        return NoContent();
    }
    
    /// <summary>
    /// Submit order for processing
    /// </summary>
    [HttpPost("{id}/submit")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<OrderDto>> SubmitOrder(int id)
    {
        var order = await _orderService.SubmitOrderAsync(id);
        return Ok(order);
    }
    
    /// <summary>
    /// Cancel an order
    /// </summary>
    [HttpPost("{id}/cancel")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> CancelOrder(int id)
    {
        var order = await _orderService.CancelOrderAsync(id);
        return Ok(order);
    }
    
    /// <summary>
    /// Mark order as shipped
    /// </summary>
    [HttpPost("{id}/ship")]
    [Authorize(Roles = "Admin,Warehouse")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> ShipOrder(int id)
    {
        var order = await _orderService.MarkAsShippedAsync(id);
        return Ok(order);
    }
    
    /// <summary>
    /// Mark order as delivered
    /// </summary>
    [HttpPost("{id}/deliver")]
    [Authorize(Roles = "Admin,Warehouse")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> DeliverOrder(int id)
    {
        var order = await _orderService.MarkAsDeliveredAsync(id);
        return Ok(order);
    }
}
```

**OrderManagement.API/Controllers/ProductsController.cs**
```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    
    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }
    
    [HttpGet]
    public async Task<ActionResult<PagedResult<ProductDto>>> GetProducts(
        [FromQuery] ProductQueryParameters parameters)
    {
        var result = await _productService.GetProductsAsync(parameters);
        return Ok(result);
    }
    
    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDto>> GetProduct(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);
        return Ok(product);
    }
    
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ProductDto>> CreateProduct([FromBody] CreateProductDto dto)
    {
        var product = await _productService.CreateProductAsync(dto);
        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }
    
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ProductDto>> UpdateProduct(
        int id, 
        [FromBody] UpdateProductDto dto)
    {
        var product = await _productService.UpdateProductAsync(id, dto);
        return Ok(product);
    }
    
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        await _productService.DeleteProductAsync(id);
        return NoContent();
    }
}
```

---

## Key Takeaways

✅ **Domain entities** contain business logic and validation  
✅ **Value objects** represent concepts without identity  
✅ **DTOs** shape API requests/responses  
✅ **AutoMapper** eliminates manual mapping code  
✅ **FluentValidation** provides robust input validation  
✅ **Services** orchestrate business operations  
✅ **Controllers** are thin, delegating to services  

---

Continue to [Part 3: Repository Pattern & Database](aspnet-api-guide-part3.md) →
