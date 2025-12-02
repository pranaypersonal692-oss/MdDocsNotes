# GSF.Transport.WebApplication - Complete Technical Documentation

## Table of Contents
1. [Introduction](#1-introduction)
2. [Application Startup](#2-application-startup)
3. [Configuration Deep Dive](#3-configuration-deep-dive)
4. [Controllers Reference](#4-controllers-reference)
5. [Routing & URL Structure](#5-routing--url-structure)
6. [Authentication & Authorization](#6-authentication--authorization)
7. [Views & Frontend](#7-views--frontend)
8. [Middleware Pipeline](#8-middleware-pipeline)
9. [Dependency Injection](#9-dependency-injection)
10. [Error Handling](#10-error-handling)

---

## 1. Introduction

**GSF.Transport.WebApplication** is the presentation layer of the GSF Transport system. It serves as the entry point for all user interactions, whether through a web browser (MVC) or mobile app/SPA (REST API).

### Key Responsibilities
- **Request Handling**: Process incoming HTTP requests
- **Authentication**: Validate user identity and manage sessions
- **Routing**: Direct requests to appropriate controllers
- **Response Formatting**: Return HTML views or JSON responses
- **Dependency Injection**: Wire up all services and handlers

### Project Type
- **SDK**: `Microsoft.NET.Sdk.Web`
- **Target Framework**: `.NET Core 2.0`
- **Host**: IIS Integration + Kestrel Server

---

## 2. Application Startup

### 2.1 Program.cs - Application Entry Point

This is where the application begins execution.

```csharp
public class Program
{
    public static void Main(string[] args)
    {
        BuildWebHost(args).Run();
    }
    
    public static IWebHost BuildWebHost(string[] args) =>
        WebHost.CreateDefaultBuilder(args)
            .UseStartup<Startup>()
            .ConfigureLogging((hostingContext, logging) =>
            {
                logging.AddConfiguration(hostingContext.Configuration.GetSection("Logging"));
                logging.AddConsole();
                logging.AddDebug();
            })
            .ConfigureServices((context, service) =>
            {
                // Early registration of utility services
                var utilityService = new ServiceDescriptor(
                    typeof(IUtilityService), 
                    new UtilityService()
                );
                service.AddSingleton<ICipherService, CipherService>(); 
                service.Add(utilityService);
            })
            .UseIISIntegration()  // For hosting on IIS
            .UseKestrel()         // Cross-platform web server
            .Build();
}
```

**Key Points:**
- `UseStartup<Startup>()`: Delegates configuration to the [Startup](file:///d:/Pranay/Office/GSFTransport/GSFTransport/Modules/GSF.Transport.WebApplication/Startup.cs#42-285) class
- **Logging**: Console + Debug providers for development
- **Early DI**: `UtilityService` and `CipherService` are registered before `Startup.ConfigureServices`
- **Dual Hosting**: Supports both IIS and Kestrel

### 2.2 Startup.cs - Core Configuration

The [Startup](file:///d:/Pranay/Office/GSFTransport/GSFTransport/Modules/GSF.Transport.WebApplication/Startup.cs#42-285) class is the heart of the application. It configures services and the HTTP pipeline.

**Structure:**
```csharp
public class Startup
{
    public IConfiguration Configuration { get; }
    public IHostingEnvironment HostingEnvironment { get; }
    
    public Startup(IConfiguration configuration, 
                   IUtilityService utilityService, 
                   IHostingEnvironment hostingEnvironment)
    {
        Configuration = configuration;
        UtilityService = utilityService;
        HostingEnvironment = hostingEnvironment;
    }
    
    public void ConfigureServices(IServiceCollection services) { /* ... */ }
    public void Configure(IApplicationBuilder app, IHostingEnvironment env) { /* ... */ }
}
```

---

## 3. Configuration Deep Dive

### 3.1 appsettings.json - Application Settings

This file contains all configuration values.

**Connection Strings:**
```json
{
  "connectionStrings": {
    "GSFDbContext": "data source=10.200.102.56;initial catalog=MyGIIS;...",
    "GSFModuleDbContext": "data source=10.200.102.56;initial catalog=MyGIISQT;...",
    "GSFTransportModuleDbContext": "..."
  }
}
```

**IdentityServer Configuration:**
```json
{
  "IdentityServer": {
    "Authority": "http://20.20.102.50/auth",
    "RequireHttps": "false",
    "ApiName": "pd.info",
    "ApiSecret": "secret"
  }
}
```

**Multi-Brand Support:**
```json
{
  "Brand": {
    "GIIS": "Persist Security Info=False;User ID=sa;...",
    "OWIS": "...",
    "VIKAASA": "..."
  }
}
```

**Unit Testing Settings:**
```json
{
  "isUnitTest": "true",
  "activeUnitTestUserType": "parent",
  "UnitTestUsers": {
    "parent": "GDHKM|Tiara25411|5|Tiara|Parent|PG-SmartCampus|23"
  }
}
```

> **Note**: For development, the app supports unit test mode to bypass authentication.

### 3.2 ConfigureServices - Dependency Injection Setup

This method registers all services in the DI container.

**1. Database Contexts:**
```csharp
// Campus-specific DB (Multi-tenancy)
services.AddDbContext<GSFTransportCampusDBContext>(options => 
    options.UseSqlServer(Configuration.GetConnectionString("GSFModuleDbContext")));

// Global DB (Brand/Campus metadata)
services.AddDbContext<GSF.Core.Data.GSFDbContext>(options => 
    options.UseSqlServer(gsfDbContextConnectionString));

// Identity Server DB
services.AddDbContext<GSFIdentityDbContext>(options => 
    options.UseSqlServer(gsfDbContextConnectionString));
```

**2. Query Handlers:**
```csharp
services.AddTransient(
    typeof(IQueryHandlerAsync<SchoolBusInformationQuery, SchoolBusViewModel>), 
    typeof(SchoolBusInformationQueryHandler)
);

services.AddScoped(
    typeof(IQueryHandler<GetIntegratedBusListQuery, IntegratedBusViewModel>), 
    typeof(GetIntegratedBusListQuerys)
);
```

**3. Command Handlers:**
```csharp
services.AddTransient(
    typeof(ICommandHandlerAsync<StartBusServiceCommand>), 
    typeof(StartBusServiceCommandHandler)
);

services.AddTransient(
    typeof(ICommandHandlerAsync<StopBusServiceCommand>), 
    typeof(StopBusServiceCommandHandler)
);
```

**4. Authentication:**
```csharp
services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = GSFApplicationConstants.GSFWebApplicationAuthenticationScheme;
    options.DefaultChallengeScheme = GSFApplicationConstants.GSFWebApplicationAuthenticationScheme;
})
.AddCookie(GSFApplicationConstants.GSFWebApplicationAuthenticationScheme, options =>
{
    options.Cookie.Name = GSFApplicationConstants.GSFWebAppCookieName;
    options.Cookie.Path = "/";
})
.AddIdentityServerAuthentication(IdentityServerAuthenticationDefaults.AuthenticationScheme, options =>
{
    options.Authority = Configuration["IdentityServer:Authority"];
    options.RequireHttpsMetadata = Convert.ToBoolean(Configuration["IdentityServer:RequireHttps"]);
    options.ApiName = Configuration["IdentityServer:ApiName"];
    options.ApiSecret = Configuration["IdentityServer:ApiSecret"];
});
```

**5. CORS Configuration:**
```csharp
services.AddCors(options =>
{
    options.AddPolicy("CorsPolicy", builder => 
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader()
    );
});
```

### 3.3 Configure - HTTP Request Pipeline

This method sets up middleware that processes requests.

```csharp
public void Configure(IApplicationBuilder app, IHostingEnvironment env)
{
    if (env.IsDevelopment())
    {
        app.UseBrowserLink();
        app.UseDeveloperExceptionPage();
        app.UseGSFUnitTestAuthentication();  // Bypass auth for testing
    }
    else
    {
        app.UseExceptionHandler("/Home/Error");
    }
    
    app.UseCors("CorsPolicy");
    app.UseStaticFiles();       // Serve files from wwwroot/
    app.UseAuthentication();    // Validate user identity
    app.UseSession();          // Enable session state
    app.UseGSFUserContext<GSFCampusDbContext>();  // Custom middleware
    
    app.UseMvc(routes =>
    {
        routes.MapRoute(
            name: "default",
            template: "{controller=IntergratedStudentBusReport}/{action=Index}"
        );
    });
}
```

**Middleware Execution Order:**
1. **Exception Handling** (Development vs Production)
2. **CORS** (Allow cross-origin requests)
3. **Static Files** (CSS, JS, Images)
4. **Authentication** (Cookie/Bearer)
5. **Session** (User-specific data)
6. **GSFUserContext** (Custom: Set campus context)
7. **MVC** (Routing to controllers)

---

## 4. Controllers Reference

### 4.1 Controller Hierarchy

```
ControllerBase (ASP.NET Core)
  ├── GSFController (Custom base)
  │   ├── SchoolBusController (MVC)
  │   ├── BusAllocationController (MVC)
  │   └── IntergratedStudentBusReportController (MVC)
  ├── GSFApiController (Custom base for APIs)
  │   └── StudentBusController (REST API)
  └── LandingController (Authentication)
```

### 4.2 LandingController - Authentication Gateway

**Purpose**: Handle SSO login redirects and session setup.

**Key Actions:**

#### Index - Login Validation
```csharp
public async Task<IActionResult> Index(
    string session, 
    string id, 
    string campus, 
    string loginid, 
    string ipaddress, 
    string pageUrl)
{
    // 1. Decode encrypted parameters
    string _campusName = _utilityService.Decode<string>(campus);
    long _userId = _utilityService.Decode<long>(id);
    
    // 2. Switch to campus database
    SetCampusDbContext(_campusName);
    
    // 3. Validate session in LoginDetails table
    var userDetails = _gSFModuleDbContext.LoginDetails
        .FirstOrDefault(u => u.LoginId == _loginId 
            && u.SessionId == _session 
            && u.UserId == _userId);
    
    if (userDetails != null)
    {
        // 4. Fetch user data
        var user = _gSFModuleDbContext.GSFAllUsers.Find(_userId);
        
        // 5. Create claims
        var claims = await _userStore.GetIdentityClaimsAsync(
            _campusName, 
            new CampusUser { ... }
        );
        
        // 6. Sign in
        var claimsIdentity = new ClaimsIdentity(claims, "GSFWebApp");
        var principal = new ClaimsPrincipal(claimsIdentity);
        await _accessor.HttpContext.SignInAsync("GSFWebApp", principal);
        
        // 7. Redirect to target page
        return RedirectToAction(urlArray[1], urlArray[0]);
    }
    
    return RedirectToLogin();  // Redirect to main portal
}
```

**Flow Diagram:**
```
Main Portal (mygiis.org)
    ↓ User clicks "Transport Module"
    ↓ Redirect with encrypted params
LandingController.Index
    ↓ Decode & Validate
    ↓ Create Claims & Sign In
    ↓ Set Cookie
Redirect to Business Controller
```

### 4.3 SchoolBusController - Parent Bus Operations

**Purpose**: Handle bus requests from parents (MVC).

**Attributes:**
- `[GSFAuthorization]`: Ensures authenticated users only

**Key Actions:**

#### BusStatus - Get Current Bus Status
```csharp
[HttpGet]
public async Task<IActionResult> BusStatus(string studentId)
{
    var dataQuery = new SchoolBusInformationQuery
    {
        LoginDetails = GSFUser,  // From base class
        StudentId = studentId
    };
    
    var schoolBusViewModel = await _queryHandler.HandleAsync(dataQuery);
    return Json(schoolBusViewModel);
}
```

**Response Example:**
```json
{
  "StudentId": "encrypted_123",
  "PickupAddress": "Block 123, Street 45",
  "StudentBusStatus": "APPROVED",
  "Requestdate": "2025-01-15",
  "Route": false,
  "IsServiceStartStop": true,
  "ValidationError": null
}
```

#### Start - Request Bus Service
```csharp
[HttpPost]
public async Task<JsonResult> Start(SchoolBusViewModel vm)
{
    // 1. Validation
    if (string.IsNullOrEmpty(vm.StudentId))
        return Json("Invalid Student ID");
    
    if (vm.Requestdate == null || vm.Requestdate == DateTime.MinValue)
        return Json("Invalid Start Date");
    
    if (vm.Route == null)
        return Json("Invalid Route Selection");
    
    // 2. Map to Command
    StartBusServiceCommand command = vm.MapToStartBusServiceCommand(GSFUser);
    
    // 3. Execute
    await _startBusCommandHandler.HandleAsync(command);
    
    return Json(vm);
}
```

#### Stop - Request Bus Service Stop
```csharp
[HttpPost]
public async Task<JsonResult> Stop(SchoolBusViewModel vm)
{
    StopBusServiceCommand command = vm.MapToStopBusServiceCommand(GSFUser);
    await _stopBusCommandHandler.HandleAsync(command);
    return Json(vm);
}
```

#### Cancel - Cancel Pending Request
```csharp
[HttpPost]
public async Task<JsonResult> Cancel(SchoolBusViewModel vm)
{
    CancelBusServiceCommand command = vm.MapToCancelBusServiceCommand(GSFUser);
    await _cancelBusCommandHandler.HandleAsync(command);
    return Json(vm);
}
```

### 4.4 BusAllocationController - Admin Operations

**Purpose**: Admin interface for managing bus allocations.

**Key Actions:**

#### Index - Main Dashboard
```csharp
[HttpGet]
public async Task<IActionResult> Index()
{
    var busDetailsViewModel = await _busDetailsQueryHandler.HandleAsync(
        new BusDetailsQuery()
    );
    return View(busDetailsViewModel);
}
```

#### GetBusNumbers - AJAX Endpoint
```csharp
[HttpGet]
public async Task<IActionResult> GetBusNumbers(string busType)
{
    var query = new GetBusNumbersQuery { busType = busType };
    var busNumbers = await _getBusNumbersQueryHandler.HandleAsync(query);
    return Ok(busNumbers);  // Returns JSON
}
```

#### GetStudentsBusDetails - Fetch Student List
```csharp
[HttpGet]
public async Task<IActionResult> GetStudentsBusDetails(
    string busType, 
    string busNo, 
    long studentId)
{
    var query = new BusAllocationDetailQuery
    {
        busType = busType,
        busNo = busNo,
        studentId = studentId
    };
    
    var result = await _busAllocationDetailQueryHandler.HandleAsync(query);
    return Ok(result);
}
```

#### UpdateAssignedStudentsBusNo - Bulk Update
```csharp
[HttpPost]
public async Task<IActionResult> UpdateAssignedStudentsBusNo(
    [FromBody] BusAllocationViewModel viewModel)
{
    var command = new UpdateBusNoServiceCommand
    {
        LoginUserId = GSFUser.UserId.ToString(),
        LoggedInUser = GSFUser,
        Campus = GSFUser.Campus.ToString(),
        BusStatus = viewModel.BusStatus,
        BusNoAssignments = viewModel.BusNoAssignments 
    };
    
    await _updateBusNoServiceCommandHandler.HandleAsync(command);
    return Ok(new { Message = "Bus No. Updated successfully." });
}
```

#### SendEmailorSMS - Notify Parents
```csharp
[HttpPost]
public async Task<IActionResult> SendEmailorSMS(
    [FromBody] BusAllocationViewModel model)
{
    await _sendEmailCommandHandler.HandleAsync(new SendEmailCommand
    {
        SendEmail = model.SendEmail,
        GSFUser = GSFUser
    });
    
    return Ok(new { Message = "Emails sent successfully." });
}
```

### 4.5 StudentBusController (API) - Mobile/SPA Interface

**Purpose**: RESTful API for mobile apps and SPAs.

**Attributes:**
- `[Route("api/v1/[controller]")]`: API versioning
- `[Authorize(AuthenticationSchemes = "Bearer", Policy = "GSFAuthorizeIdentityHeader")]`

**Key Endpoints:**

#### GET /api/v1/StudentBus/{studentId}
```csharp
[HttpGet("{studentId}")]
public async Task<IActionResult> Get(string studentId)
{
    var result = await _queryHandlerAsync.HandleAsync(new StudentBusDetailsQuery
    {
        LoginDetails = GSFUser,
        StudentId = studentId
    });
    return Ok(result);
}
```

#### POST /api/v1/StudentBus/start
```csharp
[HttpPost("start")]
public async Task<IActionResult> Start([FromBody] BusRequestViewModel viewModel)
{
    if (!ModelState.IsValid)
        return BadRequest();
    
    var command = new StartBusServiceCommand
    {
        ParentID = GSFUser.UserId,
        StudentId = viewModel.StudentId,
        StartDate = viewModel.Date,
        Ways = /* logic */,
        UserContext = GSFUser
    };
    
    await _startBusCommandHandler.HandleAsync(command);
    return Ok(new ApiResponse { Message = "Success" });
}
```

#### POST /api/v1/StudentBus/stop
```csharp
[HttpPost("stop")]
public async Task<IActionResult> Stop([FromBody] BusRequestViewModel viewModel)
{
    var command = new StopBusServiceCommand { /* ... */ };
    await _stopBusCommandHandler.HandleAsync(command);
    return Ok(new ApiResponse { Message = "Stop request submitted" });
}
```

#### GET /api/v1/StudentBus/busstatus/{studentId}
```csharp
[HttpGet("busstatus/{studentId}")]
public async Task<IActionResult> BusStatus(string studentId)
{
    var dataQuery = new SchoolBusInformationQuery
    {
        LoginDetails = GSFUser,
        StudentId = studentId
    };
    
    var result = await _studentBusStatusQueryHandler.HandleAsync(dataQuery);
    return Ok(result);
}
```

### 4.6 IntergratedStudentBusReportController - Reporting

**Purpose**: Generate bus allocation reports.

#### Index - Report UI
```csharp
public IActionResult Index()
{
    return View();
}
```

#### GetIntegratedBusList - Fetch Data
```csharp
public IActionResult GetIntegratedBusList(IntegratedStudentBusFilter filter)
{
    var result = _intergratedBusReportQuery.Handle(new GetIntegratedBusListQuery
    {
        Filter = filter,
        GSFUser = GSFUser
    });
    
    return Json(result);
}
```

#### DownloadExcel - Export to Excel
```csharp
public IActionResult DownloadExcel(IntegratedStudentBusFilter filter)
{
    // 1. Fetch data
    var result = _intergratedBusReportQuery.Handle(new GetIntegratedBusListQuery
    {
        Filter = filter,
        GSFUser = GSFUser
    });
    
    // 2. Generate Excel
    var studentReportQuery = new IntegratedBusExcelQuery
    {
        Filter = filter,
        GSFUser = GSFUser,
        IntegratedBusViewModel = result
    };
    var bytes = _intergratedBusReporExcelQuery.Handle(studentReportQuery);
    
    // 3. Return file
    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    Response.Headers.Add("Content-Disposition", "attachment; filename=\"IntegratedBusReport.xlsx\"");
    
    return File(bytes, Response.ContentType);
}
```

### 4.7 BusServiceController - Extended Operations

**Purpose**: Additional bus service operations (used by mobile/external systems).

**Note**: This controller extends `ControllerBase`, not `GSFController`, suggesting it may be used for cross-brand/campus operations.

**Key Actions:**

#### GetStudentBusDetails
```csharp
public async Task<IActionResult> GetStudentBusDetails(
    string studentid, 
    string brand, 
    string campus, 
    bool isenc)
{
    var dataQuery = new BusGetStudentDetQuery
    {
        StudentId = studentid,
        Campus = campus,
        Brand = brand,
        isenc = isenc
    };
    
    var result = await _getStudentQueryHandler.HandleAsync(dataQuery);
    return Ok(result);
}
```

#### UpdateOrApprovedBusInfo - Admin Approval
```csharp
[HttpPost]
public async Task<ActionResult> UpdateOrApprovedBusInfo(
    [FromBody] studentBusDetailsViewModel viewModel)
{
    // Check if global user (multi-campus admin)
    List<GlobalUserCampus> globalcampuses = new List<GlobalUserCampus>();
    if (await _gsfUserContextService.IsGlobalUserAsync())
    {
        globalcampuses = await _gsfUserContextService.GetGlobalUserCampusesAsync();
    }
    
    var command = new UpdateOrApprovedBusDetCommand
    {
        StudentId = viewModel.StudentId,
        GlobalUserCampuses = globalcampuses,
        brand = viewModel.brand,
        campus = viewModel.campus
    };
    
    await _updateOrApprovedBusDetCommandHandler.HandleAsync(command);
    return Ok(new ApiResponse { Message = "Marked as completed" });
}
```

---

## 5. Routing & URL Structure

### 5.1 Default Route

```csharp
routes.MapRoute(
    name: "default",
    template: "{controller=IntergratedStudentBusReport}/{action=Index}"
);
```

### 5.2 Common URLs

| URL | Controller | Action | Purpose |
|-----|------------|--------|---------|
| `/` | IntegratedStudentBusReport | Index | Default landing page |
| `/Landing/Index?session=...&id=...` | Landing | Index | SSO login redirect |
| `/SchoolBus/BusStatus?studentId=xyz` | SchoolBus | BusStatus | Check bus status |
| `/SchoolBus/Start` | SchoolBus | Start | Start bus service |
| `/BusAllocation/Index` | BusAllocation | Index | Admin dashboard |
| `/api/v1/StudentBus/123` | StudentBus (API) | Get | API get student bus info |
| `/api/v1/StudentBus/start` | StudentBus (API) | Start | API start bus service |

---

## 6. Authentication & Authorization

### 6.1 Authentication Schemes

The application supports **dual authentication**:

1. **Cookie Authentication** (For web UI)
   - Scheme: `GSFWebApplicationAuthenticationScheme`
   - Cookie Name: `GSFWebAppCookieName`
   - Used by: MVC Controllers

2. **Bearer Token** (For APIs)
   - Scheme: `IdentityServerAuthenticationDefaults.AuthenticationScheme`
   - Source: IdentityServer4
   - Used by: API Controllers

### 6.2 Authorization Policies

**GSFAuthorizeIdentityHeader**: Custom policy for API endpoints
- Requires authenticated user
- Validates custom identity header

### 6.3 Base Controllers

**GSFController (MVC):**
```csharp
public abstract class GSFController : Controller
{
    protected LoggedInUser GSFUser
    {
        get
        {
            // Extract user info from Claims
            return new LoggedInUser
            {
                UserId = long.Parse(User.FindFirst("UserId").Value),
                Campus = User.FindFirst("Campus").Value,
                UserTypeId = int.Parse(User.FindFirst("UserTypeId").Value),
                // ...
            };
        }
    }
}
```

**GSFApiController (API):**
```csharp
public abstract class GSFApiController : ControllerBase
{
    protected LoggedInUser GSFUser
    {
        get { /* Same as GSFController */ }
    }
}
```

---

## 7. Views & Frontend

### 7.1 View Structure

```
Views/
├── BusAllocation/
│   └── Index.cshtml
├── IntergratedStudentBusReport/
│   └── Index.cshtml
├── SchoolBus/
│   └── StudentBusStartRequest.cshtml
├── Shared/
│   ├── _Layout.cshtml
│   ├── _NewRequest.cshtml
│   ├── _assignedBus.cshtml
│   ├── _busNotAssigned.cshtml
│   └── _busStop.cshtml
```

### 7.2 Static Assets

```
wwwroot/
├── angular/          # AngularJS framework
├── bootstrap-multiselect/
├── css/              # Custom stylesheets
├── datatablePagination/
└── images/
```

### 7.3 Frontend Technology

- **Framework**: AngularJS (for dynamic UI)
- **CSS Framework**: Bootstrap
- **JavaScript Libraries**:
  - DataTables (for grids)
  - Bootstrap Multiselect

---

## 8. Middleware Pipeline

### 8.1 Execution Order

```
Request
  ↓
1. Exception Handling
  ↓
2. CORS
  ↓
3. Static Files (if matches /css, /js, etc.)
  ↓
4. Authentication (validate cookie/bearer)
  ↓
5. Session (load user session)
  ↓
6. GSFUserContext (custom middleware - set campus)
  ↓
7. MVC Routing
  ↓
Controller Action
  ↓
Response
```

### 8.2 Custom Middleware

**UseGSFUserContext<T>()**: Custom middleware that:
1. Extracts campus from user claims
2. Sets up campus-specific context
3. Makes it available to controllers

---

## 9. Dependency Injection

### 9.1 Service Lifetimes

| Service Type | Lifetime | Example |
|--------------|----------|---------|
| **DbContext** | Scoped | [GSFTransportCampusDBContext](file:///d:/Pranay/Office/GSFTransport/GSFTransport/Modules/GSF.Transport.Service/Data/GSFTransportCampusDBContext.cs#18-1025) |
| **Query Handlers** | Transient | [SchoolBusInformationQueryHandler](file:///d:/Pranay/Office/GSFTransport/GSFTransport/Modules/GSF.Transport.Service/Query/SchoolBusInformationQuery.cs#22-136) |
| **Command Handlers** | Transient | [StartBusServiceCommandHandler](file:///d:/Pranay/Office/GSFTransport/GSFTransport/Modules/GSF.Transport.Service/Command/StartBusServiceCommand.cs#35-127) |
| **Utility Services** | Singleton | `IUtilityService`, `ICipherService` |
| **User Context** | Scoped | `IGSFUserContextService` |

### 9.2 Registration Pattern

**In `Startup.ConfigureServices`:**
```csharp
private void RegisterQuery(IServiceCollection services)
{
    services.AddTransient(
        typeof(IQueryHandlerAsync<SchoolBusInformationQuery, SchoolBusViewModel>), 
        typeof(SchoolBusInformationQueryHandler)
    );
    // ... more registrations
}

private void RegisterCommand(IServiceCollection services)
{
    services.AddTransient(
        typeof(ICommandHandlerAsync<StartBusServiceCommand>), 
        typeof(StartBusServiceCommandHandler)
    );
    // ... more registrations
}
```

---

## 10. Error Handling

### 10.1 Development vs Production

**Development:**
```csharp
app.UseDeveloperExceptionPage();  // Detailed error page
```

**Production:**
```csharp
app.UseExceptionHandler("/Home/Error");  // Generic error page
```

### 10.2 Common Error Patterns

**Controller-Level:**
```csharp
try
{
    var result = await _handler.HandleAsync(query);
    return Ok(result);
}
catch (Exception ex)
{
    _logger.LogError("Error: " + ex.Message);
    return StatusCode(StatusCodes.Status500InternalServerError);
}
```

**Handler-Level:**
```csharp
catch (SchoolBusValidationException ex)
{
    throw;  // Re-throw validation errors
}
catch (Exception ex)
{
    _logger.LogError("Handler error: " + ex.Message);
    throw;
}
```

---

## Appendix: Quick Reference

### Controller Summary

| Controller | Type | Purpose |
|------------|------|---------|
| **LandingController** | MVC | SSO login gateway |
| **SchoolBusController** | MVC | Parent bus operations |
| **BusAllocationController** | MVC | Admin bus allocation |
| **IntergratedStudentBusReportController** | MVC | Reporting |
| **StudentBusController** | API | Mobile/SPA endpoints |
| **BusServiceController** | API | Extended operations |

### Configuration Keys

| Key | Purpose |
|-----|---------|
| `connectionStrings:GSFDbContext` | Main database |
| `connectionStrings:GSFModuleDbContext` | Campus database |
| `IdentityServer:Authority` | OAuth server URL |
| `Brand:GIIS` | GIIS brand connection string |
| `isUnitTest` | Enable test mode |
