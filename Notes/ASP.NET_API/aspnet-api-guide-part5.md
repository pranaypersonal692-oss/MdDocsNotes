# Building Scalable & Maintainable ASP.NET APIs - Part 5
## Middleware, Logging & Error Handling

> **Production Example**: E-Commerce Order Management API (Continued)

---

## Table of Contents
1. [Global Exception Handling](#global-exception-handling)
2. [Custom Middleware](#custom-middleware)
3. [Structured Logging with Serilog](#structured-logging-with-serilog)
4. [Request/Response Logging](#requestresponse-logging)
5. [API Versioning](#api-versioning)
6. [Health Checks](#health-checks)

---

## Global Exception Handling

### Custom Exception Types

**OrderManagement.Application/Exceptions/CustomExceptions.cs**
```csharp
namespace OrderManagement.Application.Exceptions;

public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message)
    {
    }
}

public class BusinessException : Exception
{
    public BusinessException(string message) : base(message)
    {
    }
}

public class UnauthorizedException : Exception
{
    public UnauthorizedException(string message) : base(message)
    {
    }
}

public class ValidationException : Exception
{
    public Dictionary<string, string[]> Errors { get; }
    
    public ValidationException(Dictionary<string, string[]> errors)
        : base("One or more validation failures have occurred.")
    {
        Errors = errors;
    }
}
```

### Exception Handling Middleware

**OrderManagement.API/Middleware/ExceptionHandlingMiddleware.cs**
```csharp
using OrderManagement.Application.Exceptions;
using System.Net;
using System.Text.Json;

namespace OrderManagement.API.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _environment;
    
    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
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
        context.Response.ContentType = "application/json";
        
        var (statusCode, response) = exception switch
        {
            NotFoundException notFoundEx => (
                HttpStatusCode.NotFound,
                new ErrorResponse
                {
                    Status = (int)HttpStatusCode.NotFound,
                    Title = "Resource Not Found",
                    Detail = notFoundEx.Message,
                    Instance = context.Request.Path
                }),
            
            BusinessException businessEx => (
                HttpStatusCode.BadRequest,
                new ErrorResponse
                {
                    Status = (int)HttpStatusCode.BadRequest,
                    Title = "Business Rule Violation",
                    Detail = businessEx.Message,
                    Instance = context.Request.Path
                }),
            
            ValidationException validationEx => (
                HttpStatusCode.BadRequest,
                new ValidationErrorResponse
                {
                    Status = (int)HttpStatusCode.BadRequest,
                    Title = "Validation Error",
                    Detail = "One or more validation errors occurred",
                    Instance = context.Request.Path,
                    Errors = validationEx.Errors
                }),
            
            UnauthorizedException unauthorizedEx => (
                HttpStatusCode.Unauthorized,
                new ErrorResponse
                {
                    Status = (int)HttpStatusCode.Unauthorized,
                    Title = "Unauthorized",
                    Detail = unauthorizedEx.Message,
                    Instance = context.Request.Path
                }),
            
            _ => (
                HttpStatusCode.InternalServerError,
                new ErrorResponse
                {
                    Status = (int)HttpStatusCode.InternalServerError,
                    Title = "Internal Server Error",
                    Detail = _environment.IsDevelopment() 
                        ? exception.Message 
                        : "An unexpected error occurred",
                    Instance = context.Request.Path
                })
        };
        
        // Log the exception
        _logger.LogError(exception, 
            "An error occurred while processing {Method} {Path}. Status Code: {StatusCode}",
            context.Request.Method,
            context.Request.Path,
            (int)statusCode);
        
        // Include stack trace in development
        if (_environment.IsDevelopment() && statusCode == HttpStatusCode.InternalServerError)
        {
            response.StackTrace = exception.StackTrace;
        }
        
        context.Response.StatusCode = (int)statusCode;
        
        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };
        
        await context.Response.WriteAsync(JsonSerializer.Serialize(response, jsonOptions));
    }
}

public class ErrorResponse
{
    public int Status { get; set; }
    public string Title { get; set; }
    public string Detail { get; set; }
    public string Instance { get; set; }
    public string StackTrace { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

public class ValidationErrorResponse : ErrorResponse
{
    public Dictionary<string, string[]> Errors { get; set; }
}
```

**Register in Program.cs:**
```csharp
app.UseMiddleware<ExceptionHandlingMiddleware>();
```

---

## Custom Middleware

### Request Logging Middleware

**OrderManagement.API/Middleware/RequestLoggingMiddleware.cs**
```csharp
using System.Diagnostics;

namespace OrderManagement.API.Middleware;

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;
    
    public RequestLoggingMiddleware(
        RequestDelegate next,
        ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }
    
    public async Task InvokeAsync(HttpContext context)
    {
        // Generate unique request ID
        var requestId = Guid.NewGuid().ToString();
        context.Items["RequestId"] = requestId;
        
        var stopwatch = Stopwatch.StartNew();
        
        // Log request
        _logger.LogInformation(
            "HTTP {Method} {Path} started. Request ID: {RequestId}",
            context.Request.Method,
            context.Request.Path,
            requestId);
        
        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            
            // Log response
            _logger.LogInformation(
                "HTTP {Method} {Path} completed with {StatusCode} in {ElapsedMilliseconds}ms. Request ID: {RequestId}",
                context.Request.Method,
                context.Request.Path,
                context.Response.StatusCode,
                stopwatch.ElapsedMilliseconds,
                requestId);
        }
    }
}
```

### Rate Limiting Middleware

**OrderManagement.API/Middleware/RateLimitingMiddleware.cs**
```csharp
using Microsoft.Extensions.Caching.Memory;
using System.Net;

namespace OrderManagement.API.Middleware;

public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    private readonly ILogger<RateLimitingMiddleware> _logger;
    private readonly int _requestLimit;
    private readonly TimeSpan _timeWindow;
    
    public RateLimitingMiddleware(
        RequestDelegate next,
        IMemoryCache cache,
        ILogger<RateLimitingMiddleware> logger,
        IConfiguration configuration)
    {
        _next = next;
        _cache = cache;
        _logger = logger;
        _requestLimit = configuration.GetValue<int>("ApiSettings:RateLimitPerMinute", 100);
        _timeWindow = TimeSpan.FromMinutes(1);
    }
    
    public async Task InvokeAsync(HttpContext context)
    {
        var clientId = GetClientId(context);
        var cacheKey = $"RateLimit_{clientId}";
        
        if (!_cache.TryGetValue(cacheKey, out int requestCount))
        {
            requestCount = 0;
        }
        
        requestCount++;
        
        if (requestCount > _requestLimit)
        {
            _logger.LogWarning(
                "Rate limit exceeded for client {ClientId}. Requests: {RequestCount}",
                clientId,
                requestCount);
            
            context.Response.StatusCode = (int)HttpStatusCode.TooManyRequests;
            context.Response.Headers.Add("Retry-After", _timeWindow.TotalSeconds.ToString());
            
            await context.Response.WriteAsJsonAsync(new
            {
                error = "Rate limit exceeded",
                message = $"Too many requests. Please try again after {_timeWindow.TotalSeconds} seconds."
            });
            
            return;
        }
        
        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = _timeWindow
        };
        
        _cache.Set(cacheKey, requestCount, cacheOptions);
        
        // Add rate limit headers
        context.Response.Headers.Add("X-Rate-Limit-Limit", _requestLimit.ToString());
        context.Response.Headers.Add("X-Rate-Limit-Remaining", (_requestLimit - requestCount).ToString());
        
        await _next(context);
    }
    
    private string GetClientId(HttpContext context)
    {
        // Use API key if present
        if (context.Request.Headers.TryGetValue("X-API-Key", out var apiKey))
        {
            return apiKey.ToString();
        }
        
        // Use authenticated user
        if (context.User.Identity?.IsAuthenticated == true)
        {
            return context.User.Identity.Name;
        }
        
        // Fall back to IP address
        return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }
}
```

### Performance Monitoring Middleware

**OrderManagement.API/Middleware/PerformanceMonitoringMiddleware.cs**
```csharp
using System.Diagnostics;

namespace OrderManagement.API.Middleware;

public class PerformanceMonitoringMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<PerformanceMonitoringMiddleware> _logger;
    private readonly int _slowRequestThresholdMs;
    
    public PerformanceMonitoringMiddleware(
        RequestDelegate next,
        ILogger<PerformanceMonitoringMiddleware> logger,
        IConfiguration configuration)
    {
        _next = next;
        _logger = logger;
        _slowRequestThresholdMs = configuration.GetValue<int>("PerformanceSettings:SlowRequestThresholdMs", 1000);
    }
    
    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        
        await _next(context);
        
        stopwatch.Stop();
        
        if (stopwatch.ElapsedMilliseconds > _slowRequestThresholdMs)
        {
            _logger.LogWarning(
                "Slow request detected: {Method} {Path} took {ElapsedMilliseconds}ms",
                context.Request.Method,
                context.Request.Path,
                stopwatch.ElapsedMilliseconds);
        }
    }
}
```

---

## Structured Logging with Serilog

### Serilog Configuration

**Program.cs**
```csharp
using Serilog;
using Serilog.Events;

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.EntityFrameworkCore", LogEventLevel.Information)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "OrderManagementAPI")
    .Enrich.WithProperty("Environment", Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"))
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz}] [{Level:u3}] [{SourceContext}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        path: "logs/log-.txt",
        rollingInterval: RollingInterval.Day,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] [{SourceContext}] {Message:lj}{NewLine}{Exception}",
        retainedFileCountLimit: 30)
    .WriteTo.File(
        path: "logs/errors/error-.txt",
        restrictedToMinimumLevel: LogEventLevel.Error,
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 90)
    .CreateLogger();

try
{
    Log.Information("Starting Order Management API");
    
    var builder = WebApplication.CreateBuilder(args);
    
    builder.Host.UseSerilog();
    
    // ... rest of configuration
    
    var app = builder.Build();
    
    // Request logging
    app.UseSerilogRequestLogging(options =>
    {
        options.MessageTemplate = "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000}ms";
        options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
        {
            diagnosticContext.Set("RequestId", httpContext.Items["RequestId"]);
            diagnosticContext.Set("UserName", httpContext.User.Identity?.Name ?? "Anonymous");
            diagnosticContext.Set("ClientIP", httpContext.Connection.RemoteIpAddress);
        };
    });
    
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application failed to start");
}
finally
{
    Log.CloseAndFlush();
}
```

### Application Logging

```csharp
// In services
public class OrderService : IOrderService
{
    private readonly ILogger<OrderService> _logger;
    
    public async Task<OrderDto> CreateOrderAsync(CreateOrderDto dto)
    {
        _logger.LogInformation(
            "Creating order for customer {CustomerId} with {ItemCount} items",
            dto.CustomerId,
            dto.Items.Count);
        
        try
        {
            // Business logic
            var order = await ProcessOrder(dto);
            
            _logger.LogInformation(
                "Order {OrderNumber} created successfully with total {Total:C}",
                order.OrderNumber,
                order.Total);
            
            return order;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to create order for customer {CustomerId}",
                dto.CustomerId);
            throw;
        }
    }
}
```

### Logging Levels Best Practices

```csharp
// Trace: Very detailed diagnostic information
_logger.LogTrace("Entering method GetOrderById with id: {Id}", id);

// Debug: Debugging information during development
_logger.LogDebug("Query parameters: {@Parameters}", parameters);

// Information: General informational messages
_logger.LogInformation("Order {OrderId} shipped successfully", orderId);

// Warning: Warning messages for unexpected but handled situations
_logger.LogWarning("Low stock for product {ProductId}. Only {Quantity} remaining", 
    productId, quantity);

// Error: Error messages for failures
_logger.LogError(ex, "Failed to process payment for order {OrderId}", orderId);

// Critical: Critical failures requiring immediate attention
_logger.LogCritical(ex, "Database connection lost");
```

---

## Request/Response Logging

### Request/Response Logging Middleware

**OrderManagement.API/Middleware/RequestResponseLoggingMiddleware.cs**
```csharp
namespace OrderManagement.API.Middleware;

public class RequestResponseLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestResponseLoggingMiddleware> _logger;
    
    public RequestResponseLogging Middleware(
        RequestDelegate next,
        ILogger<RequestResponseLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }
    
    public async Task InvokeAsync(HttpContext context)
    {
        // Log request body
        context.Request.EnableBuffering();
        var requestBody = await ReadRequestBodyAsync(context.Request);
        
        if (!string.IsNullOrEmpty(requestBody))
        {
            _logger.LogDebug(
                "Request {Method} {Path} Body: {RequestBody}",
                context.Request.Method,
                context.Request.Path,
                requestBody);
        }
        
        // Capture response
        var originalBodyStream = context.Response.Body;
        using var responseBody = new MemoryStream();
        context.Response.Body = responseBody;
        
        await _next(context);
        
        // Log response body
        var responseBodyText = await ReadResponseBodyAsync(context.Response);
        
        if (!string.IsNullOrEmpty(responseBodyText))
        {
            _logger.LogDebug(
                "Response {Method} {Path} Body: {ResponseBody}",
                context.Request.Method,
                context.Request.Path,
                responseBodyText);
        }
        
        await responseBody.CopyToAsync(originalBodyStream);
    }
    
    private async Task<string> ReadRequestBodyAsync(HttpRequest request)
    {
        request.Body.Position = 0;
        using var reader = new StreamReader(request.Body, leaveOpen: true);
        var body = await reader.ReadToEndAsync();
        request.Body.Position = 0;
        return body;
    }
    
    private async Task<string> ReadResponseBodyAsync(HttpResponse response)
    {
        response.Body.Position = 0;
        using var reader = new StreamReader(response.Body, leaveOpen: true);
        var body = await reader.ReadToEndAsync();
        response.Body.Position = 0;
        return body;
    }
}
```

> **Warning**: Only enable request/response body logging in development or for debugging, as it can impact performance and log sensitive data.

---

## API Versioning

### Install Package

```bash
dotnet add package Microsoft.AspNetCore.Mvc.Versioning
dotnet add package Microsoft.AspNetCore.Mvc.Versioning.ApiExplorer
```

### Configure API Versioning

**Program.cs**
```csharp
using Microsoft.AspNetCore.Mvc;

builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true; // Add version info to response headers
    options.ApiVersionReader = ApiVersionReader.Combine(
        new UrlSegmentApiVersionReader(),
        new HeaderApiVersionReader("X-API-Version"),
        new QueryStringApiVersionReader("api-version")
    );
});

builder.Services.AddVersionedApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;
});
```

### Versioned Controllers

```csharp
// V1 Controller
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
public class OrdersV1Controller : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<OrderDto>>> GetOrders()
    {
        // V1 implementation
    }
}

// V2 Controller with breaking changes
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("2.0")]
public class OrdersV2Controller : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<OrderDtoV2>>> GetOrders(
        [FromQuery] PaginationParameters parameters)
    {
        // V2 implementation with pagination
    }
}

// Support multiple versions
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
[ApiVersion("2.0")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetProductsV1()
    {
        // V1 implementation
    }
    
    [HttpGet]
    [MapToApiVersion("2.0")]
    public async Task<ActionResult<PagedResult<ProductDtoV2>>> GetProductsV2(
        [FromQuery] ProductQueryParameters parameters)
    {
        // V2 implementation
    }
}
```

---

## Health Checks

### Configure Health Checks

**Program.cs**
```csharp
builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>("database")
    .AddRedis(builder.Configuration.GetConnectionString("RedisConnection"), "redis")
    .AddUrlGroup(new Uri("https://api.thirdparty.com/health"), "third-party-api")
    .AddCheck<CustomHealthCheck>("custom-check");

// Health check UI (optional)
builder.Services.AddHealthChecksUI()
    .AddInMemoryStorage();
```

### Custom Health Check

**OrderManagement.API/HealthChecks/CustomHealthCheck.cs**
```csharp
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace OrderManagement.API.HealthChecks;

public class CustomHealthCheck : IHealthCheck
{
    private readonly IUnitOfWork _unitOfWork;
    
    public CustomHealthCheck(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }
    
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Check if we can query the database
            var orderCount = await _unitOfWork.Orders.CountAsync();
            
            var data = new Dictionary<string, object>
            {
                { "TotalOrders", orderCount },
                { "CheckedAt", DateTime.UtcNow }
            };
            
            return HealthCheckResult.Healthy("Application is healthy", data);
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Application is unhealthy", ex);
        }
    }
}
```

### Health Check Endpoints

**Program.cs**
```csharp
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        
        var response = new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration.TotalMilliseconds,
                data = e.Value.Data
            }),
            totalDuration = report.TotalDuration.TotalMilliseconds
        };
        
        await context.Response.WriteAsJsonAsync(response);
    }
});

// Liveness probe (for Kubernetes)
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false // No checks, just return 200 if app is running
});

// Readiness probe (for Kubernetes)
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
```

---

## Middleware Pipeline Order

**Correct order in Program.cs:**
```csharp
var app = builder.Build();

// 1. Exception handling (must be first)
app.UseMiddleware<ExceptionHandlingMiddleware>();

// 2. HTTPS redirection
app.UseHttpsRedirection();

// 3. Static files (if any)
app.UseStaticFiles();

// 4. Routing
app.UseRouting();

// 5. CORS
app.UseCors("AllowSpecificOrigins");

// 6. Request logging
app.UseMiddleware<RequestLoggingMiddleware>();

// 7. Rate limiting
app.UseMiddleware<RateLimitingMiddleware>();

// 8. Performance monitoring
app.UseMiddleware<PerformanceMonitoringMiddleware>();

// 9. Authentication
app.UseAuthentication();

// 10. Authorization
app.UseAuthorization();

// 11. Serilog request logging
app.UseSerilogRequestLogging();

// 12. Map controllers
app.MapControllers();

// 13. Health checks
app.MapHealthChecks("/health");

app.Run();
```

---

## Key Takeaways

✅ **Global exception handling** provides consistent error responses  
✅ **Custom middleware** adds cross-cutting concerns  
✅ **Structured logging** improves observability  
✅ **Request/Response logging** aids debugging  
✅ **API versioning** manages breaking changes  
✅ **Health checks** monitor application status  
✅ **Middleware order** is critical for correct behavior  

---

Continue to [Part 6: Performance, Caching & Scalability](aspnet-api-guide-part6.md) →
