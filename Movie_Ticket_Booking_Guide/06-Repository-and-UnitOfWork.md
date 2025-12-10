# Module 06: Repository Pattern and Unit of Work

## 📖 Table of Contents
1. [Repository Pattern Overview](#repository-pattern-overview)
2. [Generic Repository](#generic-repository)
3. [Specific Repositories](#specific-repositories)
4. [Unit of Work Pattern](#unit-of-work-pattern)
5. [Specification Pattern](#specification-pattern)

---

## 1. Repository Pattern Overview

The Repository pattern abstracts data access logic and provides a collection-like interface for accessing domain objects.

**Benefits**:
- Decouples business logic from data access
- Enables unit testing with mocks
- Centralizes data access logic
- Supports DDD principles

---

## 2. Generic Repository

Create `src/MovieTicket.Domain/Interfaces/IRepository.cs`:

```csharp
using MovieTicket.Domain.Common;
using System.Linq.Expressions;

namespace MovieTicket.Domain.Interfaces;

public interface IRepository<T> where T : BaseEntity
{
    Task<T?> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate);
    Task<T> AddAsync(T entity);
    Task AddRangeAsync(IEnumerable<T> entities);
    void Update(T entity);
    void Remove(T entity);
    void RemoveRange(IEnumerable<T> entities);
    Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null);
    Task<bool> AnyAsync(Expression<Func<T, bool>> predicate);
}
```

Create `src/MovieTicket.Infrastructure/Repositories/Repository.cs`:

```csharp
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Common;
using MovieTicket.Domain.Interfaces;
using MovieTicket.Infrastructure.Persistence;
using System.Linq.Expressions;

namespace MovieTicket.Infrastructure.Repositories;

public class Repository<T> : IRepository<T> where T : BaseEntity
{
    protected readonly ApplicationDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public Repository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public virtual async Task<T?> GetByIdAsync(int id)
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

    public virtual async Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.FirstOrDefaultAsync(predicate);
    }

    public virtual async Task<T> AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
        return entity;
    }

    public virtual async Task AddRangeAsync(IEnumerable<T> entities)
    {
        await _dbSet.AddRangeAsync(entities);
    }

    public virtual void Update(T entity)
    {
        _dbSet.Update(entity);
    }

    public virtual void Remove(T entity)
    {
        _dbSet.Remove(entity);
    }

    public virtual void RemoveRange(IEnumerable<T> entities)
    {
        _dbSet.RemoveRange(entities);
    }

    public virtual async Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null)
    {
        return predicate == null 
            ? await _dbSet.CountAsync() 
            : await _dbSet.CountAsync(predicate);
    }

    public virtual async Task<bool> AnyAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.AnyAsync(predicate);
    }
}
```

---

## 3. Specific Repositories

### 3.1 Movie Repository

Create `src/MovieTicket.Domain/Interfaces/IMovieRepository.cs`:

```csharp
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Domain.Interfaces;

public interface IMovieRepository : IRepository<Movie>
{
    Task<IEnumerable<Movie>> GetNowShowingAsync();
    Task<IEnumerable<Movie>> GetComingSoonAsync();
    Task<IEnumerable<Movie>> SearchByTitleAsync(string searchTerm);
    Task<IEnumerable<Movie>> GetByGenreAsync(string genre);
    Task<Movie?> GetBySlugAsync(string slug);
    Task<Movie?> GetWithShowsAsync(int id);
    Task<IEnumerable<Movie>> GetTopRatedAsync(int count = 10);
}
```

Create `src/MovieTicket.Infrastructure/Repositories/MovieRepository.cs`:

```csharp
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Enums;
using MovieTicket.Domain.Interfaces;
using MovieTicket.Infrastructure.Persistence;

namespace MovieTicket.Infrastructure.Repositories;

public class MovieRepository : Repository<Movie>, IMovieRepository
{
    public MovieRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Movie>> GetNowShowingAsync()
    {
        var today = DateTime.UtcNow.Date;
        return await _dbSet
            .Where(m => m.Status == MovieStatus.NowShowing 
                     && m.ReleaseDate <= today 
                     && (!m.EndDate.HasValue || m.EndDate >= today))
            .OrderByDescending(m => m.Rating)
            .ToListAsync();
    }

    public async Task<IEnumerable<Movie>> GetComingSoonAsync()
    {
        var today = DateTime.UtcNow.Date;
        return await _dbSet
            .Where(m => m.Status == MovieStatus.ComingSoon && m.ReleaseDate > today)
            .OrderBy(m => m.ReleaseDate)
            .ToListAsync();
    }

    public async Task<IEnumerable<Movie>> SearchByTitleAsync(string searchTerm)
    {
        return await _dbSet
            .Where(m => m.Title.Contains(searchTerm))
            .OrderByDescending(m => m.Rating)
            .ToListAsync();
    }

    public async Task<IEnumerable<Movie>> GetByGenreAsync(string genre)
    {
        return await _dbSet
            .Where(m => m.Genre.Contains(genre))
            .OrderByDescending(m => m.Rating)
            .ToListAsync();
    }

    public async Task<Movie?> GetBySlugAsync(string slug)
    {
        return await _dbSet
            .Include(m => m.Reviews.Where(r => r.IsApproved))
            .FirstOrDefaultAsync(m => m.Slug == slug);
    }

    public async Task<Movie?> GetWithShowsAsync(int id)
    {
        return await _dbSet
            .Include(m => m.Shows)
                .ThenInclude(s => s.Screen)
                .ThenInclude(sc => sc.Theater)
            .FirstOrDefaultAsync(m => m.Id == id);
    }

    public async Task<IEnumerable<Movie>> GetTopRatedAsync(int count = 10)
    {
        return await _dbSet
            .Where(m => m.Status == MovieStatus.NowShowing)
            .OrderByDescending(m => m.Rating)
            .Take(count)
            .ToListAsync();
    }
}
```

### 3.2 Booking Repository

Create `src/MovieTicket.Domain/Interfaces/IBookingRepository.cs`:

```csharp
using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.Interfaces;

public interface IBookingRepository : IRepository<Booking>
{
    Task<Booking?> GetByBookingCodeAsync(string bookingCode);
    Task<IEnumerable<Booking>> GetUserBookingsAsync(int userId);
    Task<IEnumerable<Booking>> GetShowBookingsAsync(int showId);
    Task<Booking?> GetWithDetailsAsync(int id);
    Task<IEnumerable<int>> GetBookedSeatIdsAsync(int showId);
}
```

Create `src/MovieTicket.Infrastructure/Repositories/BookingRepository.cs`:

```csharp
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Interfaces;
using MovieTicket.Infrastructure.Persistence;

namespace MovieTicket.Infrastructure.Repositories;

public class BookingRepository : Repository<Booking>, IBookingRepository
{
    public BookingRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<Booking?> GetByBookingCodeAsync(string bookingCode)
    {
        return await _dbSet
            .Include(b => b.Show)
                .ThenInclude(s => s.Movie)
            .Include(b => b.Show)
                .ThenInclude(s => s.Screen)
                .ThenInclude(sc => sc.Theater)
            .Include(b => b.BookingSeats)
                .ThenInclude(bs => bs.Seat)
            .Include(b => b.Payment)
            .FirstOrDefaultAsync(b => b.BookingCode == bookingCode);
    }

    public async Task<IEnumerable<Booking>> GetUserBookingsAsync(int userId)
    {
        return await _dbSet
            .Where(b => b.UserId == userId)
            .Include(b => b.Show)
                .ThenInclude(s => s.Movie)
            .Include(b => b.Show)
                .ThenInclude(s => s.Screen)
                .ThenInclude(sc => sc.Theater)
            .OrderByDescending(b => b.BookedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<Booking>> GetShowBookingsAsync(int showId)
    {
        return await _dbSet
            .Where(b => b.ShowId == showId && b.Status == Domain.Enums.BookingStatus.Confirmed)
            .Include(b => b.BookingSeats)
            .ToListAsync();
    }

    public async Task<Booking?> GetWithDetailsAsync(int id)
    {
        return await _dbSet
            .Include(b => b.User)
            .Include(b => b.Show)
                .ThenInclude(s => s.Movie)
            .Include(b => b.Show)
                .ThenInclude(s => s.Screen)
                .ThenInclude(sc => sc.Theater)
            .Include(b => b.BookingSeats)
                .ThenInclude(bs => bs.Seat)
            .Include(b => b.Payment)
            .FirstOrDefaultAsync(b => b.Id == id);
    }

    public async Task<IEnumerable<int>> GetBookedSeatIdsAsync(int showId)
    {
        return await _context.BookingSeats
            .Where(bs => bs.Booking.ShowId == showId 
                      && bs.Booking.Status == Domain.Enums.BookingStatus.Confirmed)
            .Select(bs => bs.SeatId)
            .ToListAsync();
    }
}
```

### 3.3 Theater, Show, and User Repositories

Create similar repositories for Theater, Show, and User following the same pattern.

---

## 4. Unit of Work Pattern

Create `src/MovieTicket.Domain/Interfaces/IUnitOfWork.cs`:

```csharp
namespace MovieTicket.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IMovieRepository Movies { get; }
    IBookingRepository Bookings { get; }
    ITheaterRepository Theaters { get; }
    IShowRepository Shows { get; }
    IUserRepository Users { get; }
    
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
}
```

Create `src/MovieTicket.Infrastructure/Repositories/UnitOfWork.cs`:

```csharp
using Microsoft.EntityFrameworkCore.Storage;
using MovieTicket.Domain.Interfaces;
using MovieTicket.Infrastructure.Persistence;

namespace MovieTicket.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private IDbContextTransaction? _transaction;

    public IMovieRepository Movies { get; }
    public IBookingRepository Bookings { get; }
    public ITheaterRepository Theaters { get; }
    public IShowRepository Shows { get; }
    public IUserRepository Users { get; }

    public UnitOfWork(
        ApplicationDbContext context,
        IMovieRepository movieRepository,
        IBookingRepository bookingRepository,
        ITheaterRepository theaterRepository,
        IShowRepository showRepository,
        IUserRepository userRepository)
    {
        _context = context;
        Movies = movieRepository;
        Bookings = bookingRepository;
        Theaters = theaterRepository;
        Shows = showRepository;
        Users = userRepository;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitAsync()
    {
        try
        {
            await _context.SaveChangesAsync();
            if (_transaction != null)
            {
                await _transaction.CommitAsync();
            }
        }
        catch
        {
            await RollbackAsync();
            throw;
        }
        finally
        {
            if (_transaction != null)
            {
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }
    }

    public async Task RollbackAsync()
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}
```

### Register in DI Container

Update `src/MovieTicket.Infrastructure/DependencyInjection.cs`:

```csharp
using Microsoft.Extensions.DependencyInjection;
using MovieTicket.Domain.Interfaces;
using MovieTicket.Infrastructure.Repositories;

namespace MovieTicket.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {
        // Repositories
        services.AddScoped<IMovieRepository, MovieRepository>();
        services.AddScoped<IBookingRepository, BookingRepository>();
        services.AddScoped<ITheaterRepository, TheaterRepository>();
        services.AddScoped<IShowRepository, ShowRepository>();
        services.AddScoped<IUserRepository, UserRepository>();
        
        // Unit of Work
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        
        return services;
    }
}
```

---

## 5. Specification Pattern

Create `src/MovieTicket.Domain/Specifications/ISpecification.cs`:

```csharp
using System.Linq.Expressions;

namespace MovieTicket.Domain.Specifications;

public interface ISpecification<T>
{
    Expression<Func<T, bool>> Criteria { get; }
    List<Expression<Func<T, object>>> Includes { get; }
    Expression<Func<T, object>>? OrderBy { get; }
    Expression<Func<T, object>>? OrderByDescending { get; }
}
```

Create `src/MovieTicket.Domain/Specifications/BaseSpecification.cs`:

```csharp
using System.Linq.Expressions;

namespace MovieTicket.Domain.Specifications;

public abstract class BaseSpecification<T> : ISpecification<T>
{
    public Expression<Func<T, bool>> Criteria { get; }
    public List<Expression<Func<T, object>>> Includes { get; } = new();
    public Expression<Func<T, object>>? OrderBy { get; private set; }
    public Expression<Func<T, object>>? OrderByDescending { get; private set; }

    protected BaseSpecification(Expression<Func<T, bool>> criteria)
    {
        Criteria = criteria;
    }

    protected void AddInclude(Expression<Func<T, object>> includeExpression)
    {
        Includes.Add(includeExpression);
    }

    protected void ApplyOrderBy(Expression<Func<T, object>> orderByExpression)
    {
        OrderBy = orderByExpression;
    }

    protected void ApplyOrderByDescending(Expression<Func<T, object>> orderByDescExpression)
    {
        OrderByDescending = orderByDescExpression;
    }
}
```

Create `src/MovieTicket.Domain/Specifications/MovieSpecifications.cs`:

```csharp
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.Enums;

namespace MovieTicket.Domain.Specifications;

public class NowShowingMoviesSpecification : BaseSpecification<Movie>
{
    public NowShowingMoviesSpecification() 
        : base(m => m.Status == MovieStatus.NowShowing)
    {
        ApplyOrderByDescending(m => m.Rating);
    }
}

public class MovieByGenreSpecification : BaseSpecification<Movie>
{
    public MovieByGenreSpecification(string genre) 
        : base(m => m.Genre.Contains(genre) && m.Status == MovieStatus.NowShowing)
    {
        ApplyOrderByDescending(m => m.Rating);
    }
}

public class MovieWithShowsSpecification : BaseSpecification<Movie>
{
    public MovieWithShowsSpecification(int movieId) 
        : base(m => m.Id == movieId)
    {
        AddInclude(m => m.Shows);
    }
}
```

---

**Module 06 Complete** ✅  
**Progress**: 6/18 modules (33.3%)

👉 **Next: [Module 07: Business Logic and Services](07-Business-Logic-and-Services.md)**
