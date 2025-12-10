# Module 05: Domain Models and Database Context

## 📖 Table of Contents
1. [Domain Entities](#domain-entities)
2. [Value Objects](#value-objects)
3. [Enums](#enums)
4. [Entity Framework Configuration](#entity-framework-configuration)
5. [Database Context](#database-context)
6. [Migrations](#migrations)
7. [Data Seeding](#data-seeding)

---

## 1. Domain Entities

### 1.1 Base Entity

Create `src/MovieTicket.Domain/Common/BaseEntity.cs`:

```csharp
namespace MovieTicket.Domain.Common;

public abstract class BaseEntity
{
    public int Id { get; set; }
}
```

Create `src/MovieTicket.Domain/Common/AuditableEntity.cs`:

```csharp
namespace MovieTicket.Domain.Common;

public abstract class AuditableEntity : BaseEntity
{
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
```

Create `src/MovieTicket.Domain/Common/SoftDeletableEntity.cs`:

```csharp
namespace MovieTicket.Domain.Common;

public abstract class SoftDeletableEntity : AuditableEntity
{
    public bool IsDeleted { get; set; }
}
```

### 1.2 Movie Entity

Create `src/MovieTicket.Domain/Entities/Movie.cs`:

```csharp
using MovieTicket.Domain.Common;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Domain.Entities;

public class Movie : SoftDeletableEntity
{
    public string Title { get; private set; } = string.Empty;
    public string Slug { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public int DurationMinutes { get; private set; }
    public string Genre { get; private set; } = string.Empty; // Comma-separated or JSON
    public string Language { get; private set; } = string.Empty;
    public string? Director { get; private set; }
    public string? Cast { get; private set; } // JSON
    public string? PosterUrl { get; private set; }
    public string? BannerUrl { get; private set; }
    public string? TrailerUrl { get; private set; }
    public DateTime ReleaseDate { get; private set; }
    public DateTime? EndDate { get; private set; }
    public decimal Rating { get; private set; }
    public int TotalReviews { get; private set; }
    public string? CertificateRating { get; private set; } // U, UA, A, R
    public MovieStatus Status { get; private set; }

    // Navigation properties
    public virtual ICollection<Show> Shows { get; private set; } = new List<Show>();
    public virtual ICollection<Review> Reviews { get; private set; } = new List<Review>();

    // Private constructor for EF Core
    private Movie() { }

    // Factory method
    public static Movie Create(
        string title,
        string description,
        int durationMinutes,
        string genre,
        string language,
        DateTime releaseDate,
        string? certificateRating = null)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Title cannot be empty", nameof(title));

        if (durationMinutes <= 0)
            throw new ArgumentException("Duration must be positive", nameof(durationMinutes));

        var movie = new Movie
        {
            Title = title,
            Slug = GenerateSlug(title),
            Description = description,
            DurationMinutes = durationMinutes,
            Genre = genre,
            Language = language,
            ReleaseDate = releaseDate,
            CertificateRating = certificateRating,
            Rating = 0,
            TotalReviews = 0,
            Status = MovieStatus.ComingSoon,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        return movie;
    }

    // Business methods
    public void UpdateDetails(string title, string description, int durationMinutes)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Title cannot be empty", nameof(title));

        Title = title;
        Slug = GenerateSlug(title);
        Description = description;
        DurationMinutes = durationMinutes;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UpdatePoster(string posterUrl)
    {
        PosterUrl = posterUrl;
        UpdatedAt = DateTime.UtcNow;
    }

    public void SetStatus(MovieStatus status)
    {
        Status = status;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UpdateRating(decimal newRating, int reviewCount)
    {
        // Recalculate average
        decimal totalRating = Rating * TotalReviews;
        totalRating += newRating;
        TotalReviews = reviewCount;
        Rating = totalRating / TotalReviews;
        UpdatedAt = DateTime.UtcNow;
    }

    private static string GenerateSlug(string title)
    {
        return title.ToLowerInvariant()
            .Replace(" ", "-")
            .Replace(":", "")
            .Replace("'", "");
    }
}
```

### 1.3 Theater, Screen, and Seat Entities

Create `src/MovieTicket.Domain/Entities/Theater.cs`:

```csharp
using MovieTicket.Domain.Common;

namespace MovieTicket.Domain.Entities;

public class Theater : SoftDeletableEntity
{
    public string Name { get; private set; } = string.Empty;
    public string Slug { get; private set; } = string.Empty;
    public string Address { get; private set; } = string.Empty;
    public string City { get; private set; } = string.Empty;
    public string State { get; private set; } = string.Empty;
    public string ZipCode { get; private set; } = string.Empty;
    public string? PhoneNumber { get; private set; }
    public string? Email { get; private set; }
    public decimal? Latitude { get; private set; }
    public decimal? Longitude { get; private set; }
    public string? Amenities { get; private set; } // JSON
    public bool HasParking { get; private set; }
    public bool HasFoodCourt { get; private set; }
    public bool HasWheelchairAccess { get; private set; }
    public bool IsActive { get; private set; }

    public virtual ICollection<Screen> Screens { get; private set; } = new List<Screen>();

    private Theater() { }

    public static Theater Create(string name, string address, string city, string state, string zipCode)
    {
        return new Theater
        {
            Name = name,
            Slug = GenerateSlug(name),
            Address = address,
            City = city,
            State = state,
            ZipCode = zipCode,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    public void AddScreen(Screen screen)
    {
        Screens.Add(screen);
        UpdatedAt = DateTime.UtcNow;
    }

    private static string GenerateSlug(string name)
    {
        return name.ToLowerInvariant().Replace(" ", "-");
    }
}
```

Create `src/MovieTicket.Domain/Entities/Screen.cs`:

```csharp
using MovieTicket.Domain.Common;

namespace MovieTicket.Domain.Entities;

public class Screen : SoftDeletableEntity
{
    public int TheaterId { get; private set; }
    public string ScreenName { get; private set; } = string.Empty;
    public int TotalSeats { get; private set; }
    public string ScreenType { get; private set; } = "Standard"; // Standard, 3D, IMAX, Dolby
    public bool IsActive { get; private set; }

    public virtual Theater Theater { get; private set; } = null!;
    public virtual ICollection<Seat> Seats { get; private set; } = new List<Seat>();
    public virtual ICollection<Show> Shows { get; private set; } = new List<Show>();

    private Screen() { }

    public static Screen Create(int theaterId, string screenName, int totalSeats, string screenType = "Standard")
    {
        return new Screen
        {
            TheaterId = theaterId,
            ScreenName = screenName,
            TotalSeats = totalSeats,
            ScreenType = screenType,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }
}
```

Create `src/MovieTicket.Domain/Entities/Seat.cs`:

```csharp
using MovieTicket.Domain.Common;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Domain.Entities;

public class Seat : BaseEntity
{
    public int ScreenId { get; private set; }
    public string SeatNumber { get; private set; } = string.Empty;
    public string RowName { get; private set; } = string.Empty;
    public int ColumnNumber { get; private set; }
    public SeatType SeatType { get; private set; }
    public decimal BasePrice { get; private set; }
    public bool IsActive { get; private set; }

    public virtual Screen Screen { get; private set; } = null!;
    public virtual ICollection<BookingSeat> BookingSeats { get; private set; } = new List<BookingSeat>();

    private Seat() { }

    public static Seat Create(int screenId, string seatNumber, string rowName, int columnNumber, SeatType seatType, decimal basePrice)
    {
        return new Seat
        {
            ScreenId = screenId,
            SeatNumber = seatNumber,
            RowName = rowName,
            ColumnNumber = columnNumber,
            SeatType = seatType,
            BasePrice = basePrice,
            IsActive = true
        };
    }
}
```

### 1.4 Show Entity

Create `src/MovieTicket.Domain/Entities/Show.cs`:

```csharp
using MovieTicket.Domain.Common;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Domain.Entities;

public class Show : AuditableEntity
{
    public int MovieId { get; private set; }
    public int ScreenId { get; private set; }
    public DateTime ShowDateTime { get; private set; }
    public decimal BasePrice { get; private set; }
    public ShowFormat Format { get; private set; }
    public int TotalSeats { get; private set; }
    public int BookedSeats { get; private set; }
    public ShowStatus Status { get; private set; }

    // Computed property
    public int AvailableSeats => TotalSeats - BookedSeats;

    public virtual Movie Movie { get; private set; } = null!;
    public virtual Screen Screen { get; private set; } = null!;
    public virtual ICollection<Booking> Bookings { get; private set; } = new List<Booking>();

    private Show() { }

    public static Show Create(int movieId, int screenId, DateTime showDateTime, decimal basePrice, ShowFormat format, int totalSeats)
    {
        if (showDateTime <= DateTime.UtcNow)
            throw new ArgumentException("Show time must be in the future");

        return new Show
        {
            MovieId = movieId,
            ScreenId = screenId,
            ShowDateTime = showDateTime,
            BasePrice = basePrice,
            Format = format,
            TotalSeats = totalSeats,
            BookedSeats = 0,
            Status = ShowStatus.Active,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    public void BookSeats(int seatCount)
    {
        if (BookedSeats + seatCount > TotalSeats)
            throw new InvalidOperationException("Not enough seats available");

        BookedSeats += seatCount;
        UpdatedAt = DateTime.UtcNow;
    }

    public void CancelSeats(int seatCount)
    {
        BookedSeats -= seatCount;
        if (BookedSeats < 0) BookedSeats = 0;
        UpdatedAt = DateTime.UtcNow;
    }
}
```

### 1.5 Booking Entities

Create `src/MovieTicket.Domain/Entities/Booking.cs`:

```csharp
using MovieTicket.Domain.Common;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Domain.Entities;

public class Booking : AuditableEntity
{
    public int UserId { get; private set; }
    public int ShowId { get; private set; }
    public string BookingCode { get; private set; } = string.Empty;
    public decimal TotalAmount { get; private set; }
    public decimal DiscountAmount { get; private set; }
    public decimal ConvenienceFee { get; private set; }
    public decimal FinalAmount { get; private set; }
    public string? PromoCode { get; private set; }
    public int TotalSeats { get; private set; }
    public BookingStatus Status { get; private set; }
    public DateTime BookedAt { get; private set; }
    public bool IsCancelled { get; private set; }
    public DateTime? CancelledAt { get; private set; }
    public string? CancellationReason { get; private set; }

    public virtual User User { get; private set; } = null!;
    public virtual Show Show { get; private set; } = null!;
    public virtual Payment? Payment { get; private set; }
    public virtual ICollection<BookingSeat> BookingSeats { get; private set; } = new List<BookingSeat>();

    private Booking() { }

    public static Booking Create(int userId, int showId, string bookingCode, List<BookingSeat> seats, decimal convenienceFee = 0)
    {
        decimal totalAmount = seats.Sum(s => s.Price);
        
        var booking = new Booking
        {
            UserId = userId,
            ShowId = showId,
            BookingCode = bookingCode,
            TotalAmount = totalAmount,
            DiscountAmount = 0,
            ConvenienceFee = convenienceFee,
            FinalAmount = totalAmount + convenienceFee,
            TotalSeats = seats.Count,
            Status = BookingStatus.Pending,
            BookedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            BookingSeats = seats
        };

        return booking;
    }

    public void ConfirmBooking()
    {
        Status = BookingStatus.Confirmed;
        UpdatedAt = DateTime.UtcNow;
    }

    public void CancelBooking(string reason)
    {
        if (IsCancelled)
            throw new InvalidOperationException("Booking already cancelled");

        IsCancelled = true;
        CancelledAt = DateTime.UtcNow;
        CancellationReason = reason;
        Status = BookingStatus.Cancelled;
        UpdatedAt = DateTime.UtcNow;
    }

    public void ApplyPromoCode(string promoCode, decimal discountAmount)
    {
        PromoCode = promoCode;
        DiscountAmount = discountAmount;
        FinalAmount = TotalAmount + ConvenienceFee - DiscountAmount;
        UpdatedAt = DateTime.UtcNow;
    }
}
```

Create `src/MovieTicket.Domain/Entities/BookingSeat.cs`:

```csharp
using MovieTicket.Domain.Common;

namespace MovieTicket.Domain.Entities;

public class BookingSeat : BaseEntity
{
    public int BookingId { get; private set; }
    public int SeatId { get; private set; }
    public decimal Price { get; private set; }

    public virtual Booking Booking { get; private set; } = null!;
    public virtual Seat Seat { get; private set; } = null!;

    private BookingSeat() { }

    public static BookingSeat Create(int bookingId, int seatId, decimal price)
    {
        return new BookingSeat
        {
            BookingId = bookingId,
            SeatId = seatId,
            Price = price
        };
    }
}
```

### 1.6 Payment and User Entities

Create `src/MovieTicket.Domain/Entities/Payment.cs`:

```csharp
using MovieTicket.Domain.Common;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Domain.Entities;

public class Payment : AuditableEntity
{
    public int BookingId { get; private set; }
    public string PaymentMethod { get; private set; } = string.Empty;
    public decimal Amount { get; private set; }
    public string TransactionId { get; private set; } = string.Empty;
    public string PaymentGateway { get; private set; } = string.Empty;
    public string? GatewayResponse { get; private set; }
    public PaymentStatus Status { get; private set; }
    public DateTime? PaymentDate { get; private set; }
    public decimal? RefundAmount { get; private set; }
    public DateTime? RefundDate { get; private set; }
    public string? RefundTransactionId { get; private set; }
    public string? FailureReason { get; private set; }

    public virtual Booking Booking { get; private set; } = null!;

    private Payment() { }

    public static Payment Create(int bookingId, string paymentMethod, decimal amount, string transactionId, string paymentGateway)
    {
        return new Payment
        {
            BookingId = bookingId,
            PaymentMethod = paymentMethod,
            Amount = amount,
            TransactionId = transactionId,
            PaymentGateway = paymentGateway,
            Status = PaymentStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    public void MarkAsSuccess()
    {
        Status = PaymentStatus.Success;
        PaymentDate = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void MarkAsFailed(string reason)
    {
        Status = PaymentStatus.Failed;
        FailureReason = reason;
        UpdatedAt = DateTime.UtcNow;
    }

    public void ProcessRefund(decimal refundAmount, string refundTransactionId)
    {
        RefundAmount = refundAmount;
        RefundTransactionId = refundTransactionId;
        RefundDate = DateTime.UtcNow;
        Status = PaymentStatus.Refunded;
        UpdatedAt = DateTime.UtcNow;
    }
}
```

Create `src/MovieTicket.Domain/Entities/User.cs`:

```csharp
using MovieTicket.Domain.Common;

namespace MovieTicket.Domain.Entities;

public class User : SoftDeletableEntity
{
    public string Email { get; private set; } = string.Empty;
    public string PasswordHash { get; private set; } = string.Empty;
    public string FirstName { get; private set; } = string.Empty;
    public string LastName { get; private set; } = string.Empty;
    public string? PhoneNumber { get; private set; }
    public string Role { get; private set; } = "User"; // User, Admin
    public string? ProfilePictureUrl { get; private set; }
    public bool EmailVerified { get; private set; }
    public string? EmailVerificationToken { get; private set; }
    public string? PasswordResetToken { get; private set; }
    public DateTime? PasswordResetTokenExpiry { get; private set; }
    public int FailedLoginAttempts { get; private set; }
    public DateTime? LockoutEnd { get; private set; }
    public bool IsActive { get; private set; }

    public virtual ICollection<Booking> Bookings { get; private set; } = new List<Booking>();
    public virtual ICollection<Review> Reviews { get; private set; } = new List<Review>();

    private User() { }

    public static User Create(string email, string passwordHash, string firstName, string lastName, string? phoneNumber = null)
    {
        return new User
        {
            Email = email.ToLowerInvariant(),
            PasswordHash = passwordHash,
            FirstName = firstName,
            LastName = lastName,
            PhoneNumber = phoneNumber,
            Role = "User",
            EmailVerified = false,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    public string FullName => $"{FirstName} {LastName}";

    public void VerifyEmail()
    {
        EmailVerified = true;
        EmailVerificationToken = null;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UpdatePassword(string newPasswordHash)
    {
        PasswordHash = newPasswordHash;
        PasswordResetToken = null;
        PasswordResetTokenExpiry = null;
        UpdatedAt = DateTime.UtcNow;
    }

    public void IncrementFailedLoginAttempts()
    {
        FailedLoginAttempts++;
        if (FailedLoginAttempts >= 5)
        {
            LockoutEnd = DateTime.UtcNow.AddMinutes(15);
        }
    }

    public void ResetFailedLoginAttempts()
    {
        FailedLoginAttempts = 0;
        LockoutEnd = null;
    }

    public bool IsLockedOut => LockoutEnd.HasValue && LockoutEnd.Value > DateTime.UtcNow;
}
```

Create `src/MovieTicket.Domain/Entities/Review.cs`:

```csharp
using MovieTicket.Domain.Common;

namespace MovieTicket.Domain.Entities;

public class Review : SoftDeletableEntity
{
    public int MovieId { get; private set; }
    public int UserId { get; private set; }
    public int Rating { get; private set; } // 1-5
    public string? ReviewText { get; private set; }
    public bool IsApproved { get; private set; }

    public virtual Movie Movie { get; private set; } = null!;
    public virtual User User { get; private set; } = null!;

    private Review() { }

    public static Review Create(int movieId, int userId, int rating, string? reviewText = null)
    {
        if (rating < 1 || rating > 5)
            throw new ArgumentException("Rating must be between 1 and 5");

        return new Review
        {
            MovieId = movieId,
            UserId = userId,
            Rating = rating,
            ReviewText = reviewText,
            IsApproved = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    public void Approve()
    {
        IsApproved = true;
        UpdatedAt = DateTime.UtcNow;
    }
}
```

---

## 2. Value Objects

Create `src/MovieTicket.Domain/ValueObjects/Price.cs`:

```csharp
namespace MovieTicket.Domain.ValueObjects;

public record Price
{
    public decimal Amount { get; init; }
    public string Currency { get; init; }

    public Price(decimal amount, string currency = "USD")
    {
        if (amount < 0)
            throw new ArgumentException("Price cannot be negative");

        Amount = amount;
        Currency = currency;
    }

    public static Price operator +(Price a, Price b)
    {
        if (a.Currency != b.Currency)
            throw new InvalidOperationException("Cannot add prices with different currencies");

        return new Price(a.Amount + b.Amount, a.Currency);
    }
}
```

---

## 3. Enums

Create `src/MovieTicket.Domain/Enums/BookingStatus.cs`:

```csharp
namespace MovieTicket.Domain.Enums;

public enum BookingStatus
{
    Pending,
    Confirmed,
    Cancelled,
    Expired
}
```

Create `src/MovieTicket.Domain/Enums/PaymentStatus.cs`:

```csharp
namespace MovieTicket.Domain.Enums;

public enum PaymentStatus
{
    Pending,
    Success,
    Failed,
    Refunded
}
```

Create `src/MovieTicket.Domain/Enums/MovieStatus.cs`:

```csharp
namespace MovieTicket.Domain.Enums;

public enum MovieStatus
{
    ComingSoon,
    NowShowing,
    Archived
}
```

Create `src/MovieTicket.Domain/Enums/SeatType.cs`:

```csharp
namespace MovieTicket.Domain.Enums;

public enum SeatType
{
    Regular,
    Premium,
    VIP
}
```

Create `src/MovieTicket.Domain/Enums/ShowFormat.cs`:

```csharp
namespace MovieTicket.Domain.Enums;

public enum ShowFormat
{
    TwoD,
    ThreeD,
    IMAX,
    Dolby
}
```

Create `src/MovieTicket.Domain/Enums/ShowStatus.cs`:

```csharp
namespace MovieTicket.Domain.Enums;

public enum ShowStatus
{
    Active,
    Cancelled,
    Completed
}
```

---

## 4. Entity Framework Configuration

Create `src/MovieTicket.Infrastructure/Persistence/Configurations/MovieConfiguration.cs`:

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Infrastructure.Persistence.Configurations;

public class MovieConfiguration : IEntityTypeConfiguration<Movie>
{
    public void Configure(EntityTypeBuilder<Movie> builder)
    {
        builder.ToTable("Movies");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(m => m.Slug)
            .IsRequired()
            .HasMaxLength(250);

        builder.HasIndex(m => m.Slug)
            .IsUnique();

        builder.Property(m => m.Description)
            .HasMaxLength(4000);

        builder.Property(m => m.Genre)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(m => m.Language)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(m => m.Rating)
            .HasPrecision(3, 2);

        builder.Property(m => m.Status)
            .HasConversion<string>()
            .HasMaxLength(50);

        // Indexes
        builder.HasIndex(m => m.Status)
            .HasFilter("[IsDeleted] = 0");

        builder.HasIndex(m => m.ReleaseDate);

        // Relationships
        builder.HasMany(m => m.Shows)
            .WithOne(s => s.Movie)
            .HasForeignKey(s => s.MovieId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(m => m.Reviews)
            .WithOne(r => r.Movie)
            .HasForeignKey(r => r.MovieId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
```

Create similar configurations for other entities...

---

## 5. Database Context

Create `src/MovieTicket.Infrastructure/Persistence/ApplicationDbContext.cs`:

```csharp
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using System.Reflection;

namespace MovieTicket.Infrastructure.Persistence;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Movie> Movies => Set<Movie>();
    public DbSet<Theater> Theaters => Set<Theater>();
    public DbSet<Screen> Screens => Set<Screen>();
    public DbSet<Seat> Seats => Set<Seat>();
    public DbSet<Show> Shows => Set<Show>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<BookingSeat> BookingSeats => Set<BookingSeat>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Review> Reviews => Set<Review>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply all configurations from assembly
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());

        // Global query filters for soft delete
        modelBuilder.Entity<Movie>().HasQueryFilter(m => !m.IsDeleted);
        modelBuilder.Entity<Theater>().HasQueryFilter(t => !t.IsDeleted);
        modelBuilder.Entity<User>().HasQueryFilter(u => !u.IsDeleted);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Auto-set UpdatedAt for auditable entities
        foreach (var entry in ChangeTracker.Entries<Domain.Common.AuditableEntity>())
        {
            if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAt = DateTime.UtcNow;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
```

---

## 6. Migrations

```powershell
# From solution root
cd src/MovieTicket.Infrastructure

# Create initial migration
dotnet ef migrations add InitialCreate --startup-project ../MovieTicket.API

# Update database
dotnet ef database update --startup-project ../MovieTicket.API
```

---

## 7. Data Seeding

Create `src/MovieTicket.Infrastructure/Persistence/Seed/DataSeeder.cs`:

```csharp
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Infrastructure.Persistence.Seed;

public static class DataSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context)
    {
        if (!context.Users.Any())
        {
            var adminUser = User.Create(
                "admin@moviebooking.com",
                BCrypt.Net.BCrypt.HashPassword("Admin@123"),
                "Admin",
                "User");
            context.Users.Add(adminUser);
            await context.SaveChangesAsync();
        }

        if (!context.Movies.Any())
        {
            var movies = new[]
            {
                Movie.Create("Inception", "A mind-bending thriller", 148, "Sci-Fi,Thriller", "English", new DateTime(2010, 7, 16)),
                Movie.Create("The Dark Knight", "Batman vs Joker", 152, "Action,Crime", "English", new DateTime(2008, 7, 18))
            };

            context.Movies.AddRange(movies);
            await context.SaveChangesAsync();
        }
    }
}
```

Update `Program.cs` to seed data:

```csharp
// Before app.Run()
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await context.Database.MigrateAsync();
    await DataSeeder.SeedAsync(context);
}
```

---

**Module 05 Complete** ✅  
**Progress**: 5/18 modules (27.8%)

👉 **Next: [Module 06: Repository Pattern and Unit of Work](06-Repository-and-UnitOfWork.md)**
