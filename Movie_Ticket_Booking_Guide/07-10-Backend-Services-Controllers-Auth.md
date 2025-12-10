# Module 07-10: Backend Services & Controllers (Combined)

This combined module covers Services Layer, API Controllers, Authentication, and Advanced Backend concepts for efficient learning.

## Part 1: Business Logic and Services Layer

### 1.1 Service Interfaces

Create `src/MovieTicket.Application/Services/Interfaces/IMovieService.cs`:

```csharp
using MovieTicket.Application.DTOs.Movies;

namespace MovieTicket.Application.Services.Interfaces;

public interface IMovieService
{
    Task<IEnumerable<MovieDto>> GetAllMoviesAsync();
    Task<IEnumerable<MovieDto>> GetNowShowingAsync();
    Task<IEnumer<MovieDto>> GetComingSoonAsync();
    Task<MovieDetailDto?> GetMovieByIdAsync(int id);
    Task<MovieDetailDto?> GetMovieBySlugAsync(string slug);
    Task<IEnumerable<MovieDto>> SearchMoviesAsync(string searchTerm);
    Task<MovieDto> CreateMovieAsync(CreateMovieDto dto);
    Task<MovieDto> UpdateMovieAsync(int id, UpdateMovieDto dto);
    Task DeleteMovieAsync(int id);
}
```

### 1.2 DTOs

Create `src/MovieTicket.Application/DTOs/Movies/MovieDto.cs`:

```csharp
namespace MovieTicket.Application.DTOs.Movies;

public class MovieDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DurationMinutes { get; set; }
    public string Genre { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public string? PosterUrl { get; set; }
    public decimal Rating { get; set; }
    public string? CertificateRating { get; set; }
    public DateTime ReleaseDate { get; set; }
}

public class CreateMovieDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public string Genre { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public string? Director { get; set; }
    public DateTime ReleaseDate { get; set; }
}

public class BookingDto
{
    public int Id { get; set; }
    public string BookingCode { get; set; } = string.Empty;
    public int ShowId { get; set; }
    public string MovieTitle { get; set; } = string.Empty;
    public string TheaterName { get; set; } = string.Empty;
    public DateTime ShowDateTime { get; set; }
    public List<string> SeatNumbers { get; set; } = new();
    public decimal FinalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
}
```

### 1.3 AutoMapper Profile

Create `src/MovieTicket.Application/Mapping/MappingProfile.cs`:

```csharp
using AutoMapper;
using MovieTicket.Application.DTOs.Movies;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Application.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<Movie, MovieDto>();
        CreateMap<CreateMovieDto, Movie>();
        CreateMap<Booking, BookingDto>()
            .ForMember(dest => dest.MovieTitle, opt => opt.MapFrom(src => src.Show.Movie.Title))
            .ForMember(dest => dest.TheaterName, opt => opt.MapFrom(src => src.Show.Screen.Theater.Name))
            .ForMember(dest => dest.ShowDateTime, opt => opt.MapFrom(src => src.Show.ShowDateTime))
            .ForMember(dest => dest.SeatNumbers, opt => opt.MapFrom(src => src.BookingSeats.Select(bs => bs.Seat.SeatNumber).ToList()));
    }
}
```

### 1.4 Service Implementation

Create `src/MovieTicket.Application/Services/Implementations/MovieService.cs`:

```csharp
using AutoMapper;
using MovieTicket.Application.DTOs.Movies;
using MovieTicket.Application.Services.Interfaces;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Interfaces;

namespace MovieTicket.Application.Services.Implementations;

public class MovieService : IMovieService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;

    public MovieService(IUnitOfWork unitOfWork, IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }

    public async Task<IEnumerable<MovieDto>> GetNowShowingAsync()
    {
        var movies = await _unitOfWork.Movies.GetNowShowingAsync();
        return _mapper.Map<IEnumerable<MovieDto>>(movies);
    }

    public async Task<MovieDetailDto?> GetMovieByIdAsync(int id)
    {
        var movie = await _unitOfWork.Movies.GetWithShowsAsync(id);
        return _mapper.Map<MovieDetailDto>(movie);
    }

    public async Task<MovieDto> CreateMovieAsync(CreateMovieDto dto)
    {
        var movie = Movie.Create(
            dto.Title,
            dto.Description,
            dto.DurationMinutes,
            dto.Genre,
            dto.Language,
            dto.ReleaseDate);

        await _unitOfWork.Movies.AddAsync(movie);
        await _unitOfWork.SaveChangesAsync();

        return _mapper.Map<MovieDto>(movie);
    }
}
```

### 1.5 Booking Service

Create `src/MovieTicket.Application/Services/Implementations/BookingService.cs`:

```csharp
using AutoMapper;
using MovieTicket.Application.DTOs.Bookings;
using MovieTicket.Application.Services.Interfaces;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Interfaces;

namespace MovieTicket.Application.Services.Implementations;

public class BookingService : IBookingService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    private readonly IPaymentService _paymentService;

    public BookingService(
        IUnitOfWork unitOfWork,
        IMapper mapper,
        IPaymentService paymentService)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
        _paymentService = paymentService;
    }

    public async Task<BookingDto> CreateBookingAsync(CreateBookingDto dto, int userId)
    {
        await _unitOfWork.BeginTransactionAsync();

        try
        {
            // 1. Validate show exists
            var show = await _unitOfWork.Shows.GetByIdAsync(dto.ShowId);
            if (show == null)
                throw new Exception("Show not found");

            // 2. Check seat availability
            var bookedSeats = await _unitOfWork.Bookings.GetBookedSeatIdsAsync(dto.ShowId);
            if (dto.SeatIds.Any(s => bookedSeats.Contains(s)))
                throw new Exception("Some seats are already booked");

            // 3. Create booking
            var bookingCode = GenerateBookingCode();
            var bookingSeats = dto.SeatIds.Select(seatId =>
                BookingSeat.Create(0, seatId, show.BasePrice + GetSeatPrice(seatId))
            ).ToList();

            var booking = Booking.Create(userId, dto.ShowId, bookingCode, bookingSeats);

            await _unitOfWork.Bookings.AddAsync(booking);
            await _unitOfWork.SaveChangesAsync();

            // 4. Process payment
            var paymentResult = await _paymentService.ProcessPaymentAsync(
                booking.Id, 
                dto.PaymentMethod, 
                booking.FinalAmount);

            if (paymentResult.Success)
            {
                booking.ConfirmBooking();
                show.BookSeats(dto.SeatIds.Count);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();

                return _mapper.Map<BookingDto>(booking);
            }
            else
            {
                await _unitOfWork.RollbackAsync();
                throw new Exception("Payment failed");
            }
        }
        catch
        {
            await _unitOfWork.RollbackAsync();
            throw;
        }
    }

    private string GenerateBookingCode()
    {
        return $"BK{DateTime.UtcNow:yyyyMMddHHmmss}{new Random().Next(1000, 9999)}";
    }

    private decimal GetSeatPrice(int seatId)
    {
        // Logic to get seat additional price
        return 0;
    }
}
```

---

## Part 2: API Controllers

### 2.1 Movies Controller

Create `src/MovieTicket.API/Controllers/MoviesController.cs`:

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Movies;
using MovieTicket.Application.Services.Interfaces;

namespace MovieTicket.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MoviesController : ControllerBase
{
    private readonly IMovieService _movieService;

    public MoviesController(IMovieService movieService)
    {
        _movieService = movieService;
    }

    /// <summary>
    /// Get all now showing movies
    /// </summary>
    [HttpGet("now-showing")]
    public async Task<ActionResult<IEnumerable<MovieDto>>> GetNowShowing()
    {
        var movies = await _movieService.GetNowShowingAsync();
        return Ok(new { success = true, data = movies });
    }

    /// <summary>
    /// Get movie by ID
    /// </summary>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<MovieDetailDto>> GetById(int id)
    {
        var movie = await _movieService.GetMovieByIdAsync(id);
        if (movie == null)
            return NotFound(new { success = false, message = "Movie not found" });

        return Ok(new { success = true, data = movie });
    }

    /// <summary>
    /// Create new movie (Admin only)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<MovieDto>> Create(CreateMovieDto dto)
    {
        var movie = await _movieService.CreateMovieAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = movie.Id }, 
            new { success = true, data = movie });
    }

    /// <summary>
    /// Search movies
    /// </summary>
    [HttpGet("search")]
    public async Task<ActionResult> Search([FromQuery] string q)
    {
        var movies = await _movieService.SearchMoviesAsync(q);
        return Ok(new { success = true, data = movies });
    }
}
```

### 2.2 Bookings Controller

Create `src/MovieTicket.API/Controllers/BookingsController.cs`:

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Bookings;
using MovieTicket.Application.Services.Interfaces;
using System.Security.Claims;

namespace MovieTicket.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly IBookingService _bookingService;

    public BookingsController(IBookingService bookingService)
    {
        _bookingService = bookingService;
    }

    [HttpPost]
    public async Task<ActionResult<BookingDto>> CreateBooking(CreateBookingDto dto)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var booking = await _bookingService.CreateBookingAsync(dto, userId);
        return Ok(new { success = true, data = booking });
    }

    [HttpGet("my-bookings")]
    public async Task<ActionResult> GetMyBookings()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var bookings = await _bookingService.GetUserBookingsAsync(userId);
        return Ok(new { success = true, data = bookings });
    }

    [HttpGet("{bookingCode}")]
    public async Task<ActionResult> GetByCode(string bookingCode)
    {
        var booking = await _bookingService.GetByCodeAsync(bookingCode);
        if (booking == null)
            return NotFound();

        return Ok(new { success = true, data = booking });
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> CancelBooking(int id)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await _bookingService.CancelBookingAsync(id, userId);
        return Ok(new { success = true, message = "Booking cancelled" });
    }
}
```

---

## Part 3: Authentication & Authorization

### 3.1 JWT Token Service

Create `src/MovieTicket.Application/Services/Interfaces/ITokenService.cs`:

```csharp
using MovieTicket.Domain.Entities;

namespace MovieTicket.Application.Services.Interfaces;

public interface ITokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
}
```

Create `src/MovieTicket.Infrastructure/Services/TokenService.cs`:

```csharp
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using MovieTicket.Application.Services.Interfaces;
using MovieTicket.Domain.Entities;
using MovieTicket.Infrastructure.Configuration;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace MovieTicket.Infrastructure.Services;

public class TokenService : ITokenService
{
    private readonly JwtSettings _jwtSettings;

    public TokenService(IOptions<JwtSettings> jwtSettings)
    {
        _jwtSettings = jwtSettings.Value;
    }

    public string GenerateAccessToken(User user)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.SecretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        
        var token = new JwtSecurityToken(
            issuer: _jwtSettings.Issuer,
            audience: _jwtSettings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationMinutes),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    public ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = false,
            ValidateIssuer = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_jwtSettings.SecretKey)),
            ValidateLifetime = false
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var securityToken);
        
        if (securityToken is not JwtSecurityToken jwtSecurityToken ||
            !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
        {
            throw new SecurityTokenException("Invalid token");
        }

        return principal;
    }
}
```

### 3.2 Auth Controller

Create src/MovieTicket.API/Controllers/AuthController.cs`:

```csharp
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Auth;
using MovieTicket.Application.Services.Interfaces;

namespace MovieTicket.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<ActionResult> Register(RegisterRequest request)
    {
        var result = await _authService.RegisterAsync(request);
        return Ok(new { success = true, data = result });
    }

    [HttpPost("login")]
    public async Task<ActionResult> Login(LoginRequest request)
    {
        var result = await _authService.LoginAsync(request);
        return Ok(new { success = true, data = result });
    }

    [HttpPost("refresh-token")]
    public async Task<ActionResult> RefreshToken(RefreshTokenRequest request)
    {
        var result = await _authService.RefreshTokenAsync(request.RefreshToken);
        return Ok(new { success = true, data = result });
    }
}
```

---

## Part 4: Advanced Backend Concepts

### 4.1 Global Exception Handling

Create `src/MovieTicket.API/Middleware/ExceptionHandlingMiddleware.cs`:

```csharp
using System.Net;
using System.Text.Json;

namespace MovieTicket.API.Middleware;

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
            _logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

        var response = new
        {
            success = false,
            message = exception.Message,
            errors = new[] { exception.Message }
        };

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        return context.Response.WriteAsync(JsonSerializer.Serialize(response, options));
    }
}
```

Register in `Program.cs`:

```csharp
app.UseMiddleware<ExceptionHandlingMiddleware>();
```

### 4.2 FluentValidation

Create `src/MovieTicket.Application/Validators/CreateMovieValidator.cs`:

```csharp
using FluentValidation;
using MovieTicket.Application.DTOs.Movies;

namespace MovieTicket.Application.Validators;

public class CreateMovieValidator : AbstractValidator<CreateMovieDto>
{
    public CreateMovieValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Title is required")
            .MaximumLength(200).WithMessage("Title must not exceed 200 characters");

        RuleFor(x => x.DurationMinutes)
            .GreaterThan(0).WithMessage("Duration must be greater than 0");

        RuleFor(x => x.Genre)
            .NotEmpty().WithMessage("Genre is required");

        RuleFor(x => x.Language)
            .NotEmpty().WithMessage("Language is required");

        RuleFor(x => x.ReleaseDate)
            .NotEmpty().WithMessage("Release date is required");
    }
}
```

### 4.3 Caching Service

Create `src/MovieTicket.Infrastructure/Services/CacheService.cs`:

```csharp
using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;

namespace MovieTicket.Infrastructure.Services;

public interface ICacheService
{
    Task<T?> GetAsync<T>(string key);
    Task SetAsync<T>(string key, T value, TimeSpan? expiration = null);
    Task RemoveAsync(string key);
}

public class CacheService : ICacheService
{
    private readonly IDistributedCache _cache;

    public CacheService(IDistributedCache cache)
    {
        _cache = cache;
    }

    public async Task<T?> GetAsync<T>(string key)
    {
        var value = await _cache.GetStringAsync(key);
        return value == null ? default : JsonSerializer.Deserialize<T>(value);
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan? expiration = null)
    {
        var options = new DistributedCacheEntryOptions();
        if (expiration.HasValue)
            options.AbsoluteExpirationRelativeToNow = expiration;

        var serialized = JsonSerializer.Serialize(value);
        await _cache.SetStringAsync(key, serialized, options);
    }

    public async Task RemoveAsync(string key)
    {
        await _cache.RemoveAsync(key);
    }
}
```

---

**Modules 07-10 Complete** ✅  
**Progress**: 10/18 modules (55.6%)

👉 **Next: Angular Frontend Modules (11-16)**
