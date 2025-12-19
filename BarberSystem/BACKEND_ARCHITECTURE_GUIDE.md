# Barber System Backend - Comprehensive Architecture Guide

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Database Architecture](#database-architecture)
5. [Core Modules](#core-modules)
   - [Auth Module](#auth-module)
   - [Services Module](#services-module)
   - [Bookings Module](#bookings-module)
   - [Calendar Module](#calendar-module)
   - [Prisma Module](#prisma-module)
6. [Request/Response Flow](#requestresponse-flow)
7. [Authentication & Authorization](#authentication--authorization)
8. [API Endpoints](#api-endpoints)
9. [Architecture Diagrams](#architecture-diagrams)

---

## Overview

The Barber System Backend is a **Phase 1 MVP** for an **AI-Powered Barber Shop Queue & Booking System**. It provides RESTful APIs for managing bookings, services, and user authentication with seamless integration to Google Calendar.

### Key Features

- 🔐 **Firebase Authentication** (Phone, Email, Google Sign-In)
- 📅 **Google Calendar Integration** (Automatic sync of bookings)
- 🗓️ **Booking Management** (CRUD operations with conflict detection)
- ⚡ **Real-time Validation** (Business hours, overlapping bookings, buffer times)
- 🎯 **Service Management** (Define services with durations and buffers)
- 🔒 **Protected Routes** (Firebase JWT-based authentication)

---

## Technology Stack

### Core Framework
- **NestJS** (v10.0.0) - Progressive Node.js framework for building efficient and scalable server-side applications
- **TypeScript** - Type-safe development
- **Node.js** - Runtime environment

### Database & ORM
- **PostgreSQL** - Relational database
- **Prisma ORM** (v5.7.1) - Next-generation ORM for TypeScript & Node.js
  - Type-safe database client
  - Schema management
  - Migrations

### Authentication & External Services
- **Firebase Admin SDK** (v12.0.0) - User authentication and token verification
- **Google APIs** (v130.0.0) - Google Calendar integration

### Validation & Configuration
- **class-validator** (v0.14.0) - Decorator-based validation
- **class-transformer** (v0.5.1) - Object transformation
- **@nestjs/config** (v3.1.1) - Configuration management

---

## Project Structure

```
backend/
├── prisma/
│   └── schema.prisma          # Database schema definition
├── src/
│   ├── auth/                  # Authentication module
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── auth.module.ts
│   │   ├── auth.decorator.ts
│   │   ├── firebase-auth.guard.ts
│   │   └── dto/
│   │       └── auth.dto.ts
│   ├── bookings/              # Bookings management module
│   │   ├── bookings.controller.ts
│   │   ├── bookings.service.ts
│   │   ├── bookings.module.ts
│   │   └── dto/
│   │       ├── create-booking.dto.ts
│   │       └── update-booking.dto.ts
│   ├── services/              # Services management module
│   │   ├── services.controller.ts
│   │   ├── services.service.ts
│   │   ├── services.module.ts
│   │   └── dto/
│   │       └── create-service.dto.ts
│   ├── calendar/              # Google Calendar integration
│   │   ├── calendar.service.ts
│   │   └── calendar.module.ts
│   ├── prisma/                # Database service
│   │   ├── prisma.service.ts
│   │   └── prisma.module.ts
│   ├── config/                # Configuration
│   │   └── configuration.ts
│   ├── app.module.ts          # Root application module
│   └── main.ts                # Application entry point
└── package.json
```

---

## Database Architecture

The database is designed using **Prisma ORM** with PostgreSQL. Here's the schema:

### Database Schema

```mermaid
erDiagram
    User ||--o{ Booking : creates
    Service ||--o{ Booking : "booked for"
    
    User {
        String id PK
        String firebaseUid UK
        String email UK
        String phoneNumber UK
        AuthProvider provider
        String displayName
        String photoURL
        Boolean isActive
        DateTime createdAt
        DateTime updatedAt
    }
    
    Service {
        String id PK
        String name
        Int durationMinutes
        Int bufferMinutes
        DateTime createdAt
        DateTime updatedAt
    }
    
    Booking {
        String id PK
        String customerName
        String customerPhone
        String serviceId FK
        DateTime startTime
        DateTime endTime
        BookingSource source
        String googleCalendarEventId
        DateTime createdAt
        DateTime updatedAt
    }
```

### Models Explained

#### **User Model**
Represents authenticated users (barbers, admins, or customers).

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `firebaseUid` | String | Unique Firebase user ID |
| `email` | String | User email (optional, unique) |
| `phoneNumber` | String | User phone (optional, unique) |
| `provider` | Enum | Authentication provider (PHONE, EMAIL, GOOGLE) |
| `displayName` | String | User's display name |
| `photoURL` | String | Profile picture URL |
| `isActive` | Boolean | Account status (default: true) |

#### **Service Model**
Represents services offered by the barber shop.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `name` | String | Service name (e.g., "Haircut", "Beard Trim") |
| `durationMinutes` | Int | Service duration in minutes |
| `bufferMinutes` | Int | Buffer time after service (cleanup, prep) |

#### **Booking Model**
Represents customer bookings.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `customerName` | String | Customer's name |
| `customerPhone` | String | Customer's phone number |
| `serviceId` | UUID | Foreign key to Service |
| `startTime` | DateTime | Booking start time |
| `endTime` | DateTime | Booking end time (calculated) |
| `source` | Enum | Booking source (MANUAL) |
| `googleCalendarEventId` | String | Google Calendar event ID (optional) |

### Enums

- **AuthProvider**: `PHONE`, `EMAIL`, `GOOGLE`
- **BookingSource**: `MANUAL` (future: AI, WALK_IN, etc.)

---

## Core Modules

### Auth Module

#### Purpose
Handles user authentication using Firebase Authentication and manages user registration/login.

#### Components

**1. AuthController** ([auth.controller.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/auth/auth.controller.ts))

Exposes authentication endpoints:

| Endpoint | Method | Protection | Description |
|----------|--------|------------|-------------|
| `/auth/register-or-login` | POST | Public | Register or login user with Firebase token |
| `/auth/me` | GET | Protected | Get current user details |

**2. AuthService** ([auth.service.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/auth/auth.service.ts))

Core authentication logic:

```typescript
async verifyAndCreateUser(dto: RegisterOrLoginDto): Promise<UserResponseDto>
```

**Flow:**
1. Verify Firebase ID token using Firebase Admin SDK
2. Extract user details (uid, email, phone, name, picture)
3. Check if user exists in database by `firebaseUid`
4. If **new user**: Create user record in PostgreSQL
5. If **existing user**: Update user info if changed
6. Return user response DTO

```typescript
async getCurrentUser(firebaseUid: string): Promise<UserResponseDto>
```

**Flow:**
1. Fetch user from database by `firebaseUid`
2. Throw `UnauthorizedException` if not found
3. Return user details

**3. FirebaseAuthGuard** ([firebase-auth.guard.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/auth/firebase-auth.guard.ts))

Protects routes by validating Firebase JWT tokens:

**Flow:**
1. Extract `Authorization` header from request
2. Extract token (remove "Bearer " prefix)
3. Verify token using Firebase Admin SDK
4. Attach decoded token to `request.user`
5. Allow or deny access

**4. DTOs**

- **RegisterOrLoginDto**: Request body for registration/login
  ```typescript
  {
    idToken: string;      // Firebase ID token
    provider: AuthProvider; // PHONE | EMAIL | GOOGLE
  }
  ```

- **UserResponseDto**: User information response
  ```typescript
  {
    id: string;
    email?: string;
    phoneNumber?: string;
    displayName?: string;
    photoURL?: string;
    provider: string;
    firebaseUid: string;
  }
  ```

---

### Services Module

#### Purpose
Manages barber shop services (haircuts, beard trims, etc.).

#### Components

**1. ServicesController** ([services.controller.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/services/services.controller.ts))

| Endpoint | Method | Protection | Description |
|----------|--------|------------|-------------|
| `/services` | GET | Public | Get all services |
| `/services` | POST | Protected | Create new service |

**2. ServicesService** ([services.service.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/services/services.service.ts))

```typescript
async findAll(): Promise<Service[]>
```
- Fetches all services from database
- Orders by `createdAt` descending

```typescript
async create(createServiceDto: CreateServiceDto): Promise<Service>
```
- Creates new service in database
- Validates input using DTOs

```typescript
async findOne(id: string): Promise<Service | null>
```
- Fetches single service by ID
- Used for validation in bookings

**3. DTOs**

- **CreateServiceDto**:
  ```typescript
  {
    name: string;            // Min length: 1
    durationMinutes: number; // Min: 5
    bufferMinutes: number;   // Min: 0
  }
  ```

---

### Bookings Module

#### Purpose
Core booking management system with conflict detection, business hours validation, and Google Calendar synchronization.

#### Components

**1. BookingsController** ([bookings.controller.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/bookings/bookings.controller.ts))

| Endpoint | Method | Protection | Description |
|----------|--------|------------|-------------|
| `/bookings?date=YYYY-MM-DD` | GET | Public | Get bookings for specific date |
| `/bookings` | POST | Protected | Create new booking |
| `/bookings/:id` | PUT | Protected | Update booking |
| `/bookings/:id` | DELETE | Protected | Delete booking |

**2. BookingsService** ([bookings.service.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/bookings/bookings.service.ts))

This is the most complex service with extensive business logic.

##### **Method: `findByDate(date: string)`**

**Purpose**: Fetch all bookings for a specific date

**Flow:**
1. Parse date string to JavaScript Date
2. Set start of day (00:00:00.000)
3. Set end of day (23:59:59.999)
4. Query bookings where `startTime` is between start and end
5. Include service details (join)
6. Order by `startTime` ascending
7. Return bookings array

##### **Method: `create(createBookingDto: CreateBookingDto)`**

**Purpose**: Create new booking with comprehensive validation

**Flow:**

```mermaid
flowchart TD
    A[Start: Create Booking] --> B[1. Validate Service Exists]
    B --> C{Service Found?}
    C -->|No| D[Throw BadRequestException]
    C -->|Yes| E[2. Parse Start Time]
    E --> F{Valid ISO 8601?}
    F -->|No| G[Throw BadRequestException]
    F -->|Yes| H[3. Calculate End Time]
    H --> I[endTime = startTime + duration]
    I --> J[4. Validate Business Hours]
    J --> K{Within Hours?}
    K -->|No| L[Throw BadRequestException]
    K -->|Yes| M[5. Check Overlaps]
    M --> N{Has Conflicts?}
    N -->|Yes| O[Throw BadRequestException]
    N -->|No| P[6. Create Booking in DB]
    P --> Q[7. Sync to Google Calendar]
    Q --> R{Calendar Sync OK?}
    R -->|Yes| S[Update with Calendar Event ID]
    R -->|No| T[Log Error, Continue]
    S --> U[Return Booking]
    T --> U
```

**Step-by-Step:**

1. **Validate Service**: Call `servicesService.findOne(serviceId)`
   - If not found → throw `BadRequestException`

2. **Parse Start Time**: Convert ISO 8601 string to Date
   - If invalid → throw `BadRequestException`

3. **Calculate End Time**: 
   ```typescript
   endTime = new Date(startTime.getTime() + service.durationMinutes * 60000)
   ```

4. **Validate Business Hours**: Call `validateBusinessHours(startTime, endTime)`
   - Converts times to minutes since midnight
   - Checks if booking falls within configured hours
   - If outside → throw `BadRequestException`

5. **Check Overlaps**: Call `checkOverlap(startTime, endTime, bufferMinutes)`
   - Adds buffer to end time
   - Queries database for conflicting bookings
   - Checks 4 overlap scenarios:
     - New booking starts during existing
     - New booking ends during existing
     - New booking contains existing
     - Existing contains new booking
   - If conflict → throw detailed error with existing booking info

6. **Create Booking**: Insert into database with:
   - Customer info
   - Service reference
   - Calculated times
   - Source: MANUAL

7. **Sync to Google Calendar**: Call `calendarService.createEvent()`
   - Creates event in Google Calendar
   - Updates booking with `googleCalendarEventId`
   - If fails → log error but don't fail booking

##### **Method: `update(id: string, updateBookingDto: UpdateBookingDto)`**

**Purpose**: Update existing booking with similar validation

**Flow:**
1. Check if booking exists (with service details)
2. Validate new service if changed
3. Calculate new times (use existing if not provided)
4. Validate business hours
5. Check overlaps (excluding current booking)
6. Update booking in database
7. Update Google Calendar event if exists

##### **Method: `delete(id: string)`**

**Purpose**: Delete booking and remove from calendar

**Flow:**
1. Check if booking exists
2. Delete from database
3. Delete from Google Calendar (if synced)
   - Log error if fails, continue

##### **Private Helper: `validateBusinessHours()`**

Converts hours to minutes for comparison:
```typescript
startTimeInMinutes = startHour * 60 + startMinute
```
Checks against configured business hours.

##### **Private Helper: `checkOverlap()`**

Uses complex Prisma query with multiple OR conditions to detect any time conflicts.

**3. DTOs**

- **CreateBookingDto**:
  ```typescript
  {
    customerName: string;    // Min length: 1
    customerPhone: string;   // Regex: /^\+?[1-9]\d{1,14}$/
    serviceId: string;       // UUID v4
    startTime: string;       // ISO 8601 datetime
  }
  ```

- **UpdateBookingDto**: 
  - All fields optional (partial type from CreateBookingDto)

---

### Calendar Module

#### Purpose
Integrates with Google Calendar API to synchronize bookings automatically.

#### Components

**1. CalendarService** ([calendar.service.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/calendar/calendar.service.ts))

##### **Initialization**

```typescript
constructor(private configService: ConfigService)
```

**Flow:**
1. Load Google service account credentials from path
2. Create GoogleAuth client with calendar scope
3. Initialize Google Calendar API (v3)
4. Store calendar ID from config
5. Log success/failure

> If service account not configured, logs warning but continues (graceful degradation).

##### **Method: `createEvent(booking: Booking, service: Service)`**

**Purpose**: Create Google Calendar event for new booking

**Flow:**
1. Check if calendar is initialized
2. Build event object:
   ```typescript
   {
     summary: "Booking: {customerName} - {serviceName}",
     description: "Customer: {name}\nPhone: {phone}\nService: {service}\nDuration: {duration}",
     start: {
       dateTime: booking.startTime (ISO),
       timeZone: "Asia/Kolkata"
     },
     end: {
       dateTime: booking.endTime (ISO),
       timeZone: "Asia/Kolkata"
     },
     colorId: "9" // Blue
   }
   ```
3. Call `calendar.events.insert()`
4. Return event ID
5. Log success/failure

##### **Method: `updateEvent(eventId: string, booking: Booking, service: Service)`**

**Purpose**: Update existing calendar event

**Flow:**
1. Check if calendar initialized
2. Build updated event object (same structure as create)
3. Call `calendar.events.update()`
4. Log success/failure

##### **Method: `deleteEvent(eventId: string)`**

**Purpose**: Delete calendar event

**Flow:**
1. Check if calendar initialized
2. Call `calendar.events.delete()`
3. Log success/failure

---

### Prisma Module

#### Purpose
Provides database connection and query capabilities throughout the application.

#### Components

**1. PrismaService** ([prisma.service.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/prisma/prisma.service.ts))

Extends `PrismaClient` and implements lifecycle hooks:

```typescript
class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy
```

##### **Lifecycle Methods**

**`onModuleInit()`**: 
- Called when NestJS module initializes
- Connects to PostgreSQL database
- Logs success message

**`onModuleDestroy()`**:
- Called when NestJS application shuts down
- Disconnects from database
- Ensures clean shutdown

##### **Configuration**

In development mode, logs all queries:
```typescript
{
  log: ['query', 'info', 'warn', 'error']
}
```

In production, logs only errors.

---

## Request/Response Flow

### Overall Application Flow

```mermaid
flowchart TB
    Client[Client Application]
    
    subgraph NestJS Backend
        Gateway[API Gateway - main.ts]
        CORS[CORS Middleware]
        Validation[Global Validation Pipe]
        
        subgraph Modules
            AuthModule[Auth Module]
            ServicesModule[Services Module]
            BookingsModule[Bookings Module]
            CalendarModule[Calendar Module]
        end
        
        PrismaService[Prisma Service]
    end
    
    Firebase[Firebase Auth]
    GoogleCalendar[Google Calendar API]
    PostgreSQL[(PostgreSQL Database)]
    
    Client -->|HTTP Request| Gateway
    Gateway --> CORS
    CORS --> Validation
    Validation --> Modules
    
    AuthModule -->|Verify Token| Firebase
    AuthModule --> PrismaService
    
    ServicesModule --> PrismaService
    
    BookingsModule --> ServicesModule
    BookingsModule --> CalendarModule
    BookingsModule --> PrismaService
    
    CalendarModule -->|Sync Events| GoogleCalendar
    
    PrismaService -->|SQL Queries| PostgreSQL
    
    Modules -->|Response| Gateway
    Gateway -->|JSON Response| Client
```

### Detailed Request Lifecycle

#### 1. **Incoming Request Processing**

```mermaid
sequenceDiagram
    participant Client
    participant MainTS as main.ts
    participant CORS as CORS Filter
    participant ValidationPipe
    participant Controller
    
    Client->>MainTS: HTTP Request
    MainTS->>CORS: Check Origin
    CORS->>ValidationPipe: Validate Request Body
    ValidationPipe->>Controller: Route to Controller
    Controller-->>Client: Response
```

**main.ts Configuration:**
```typescript
app.enableCors({
  origin: true,        // Allow all origins (dev mode)
  credentials: true
});

app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,           // Strip unknown properties
    forbidNonWhitelisted: true, // Throw error on unknown properties
    transform: true            // Auto-transform payloads to DTO instances
  })
);
```

#### 2. **Authentication Flow**

```mermaid
sequenceDiagram
    participant Client
    participant AuthController
    participant FirebaseAuthGuard
    participant FirebaseSDK
    participant AuthService
    participant PrismaService
    participant Database
    
    Client->>AuthController: POST /auth/register-or-login
    AuthController->>AuthService: verifyAndCreateUser(dto)
    AuthService->>FirebaseSDK: verifyIdToken(idToken)
    FirebaseSDK-->>AuthService: Decoded Token {uid, email, phone}
    AuthService->>PrismaService: findUnique({firebaseUid})
    PrismaService->>Database: SELECT * FROM users WHERE firebaseUid=?
    Database-->>PrismaService: User or null
    
    alt User Not Found
        AuthService->>PrismaService: create({userData})
        PrismaService->>Database: INSERT INTO users
    else User Exists
        AuthService->>PrismaService: update({userData})
        PrismaService->>Database: UPDATE users
    end
    
    Database-->>PrismaService: User Record
    PrismaService-->>AuthService: User Object
    AuthService-->>AuthController: UserResponseDto
    AuthController-->>Client: 200 OK {user}
```

#### 3. **Protected Route Flow**

```mermaid
sequenceDiagram
    participant Client
    participant Controller
    participant FirebaseAuthGuard
    participant FirebaseSDK
    participant Service
    
    Client->>Controller: Request + Authorization: Bearer {token}
    Controller->>FirebaseAuthGuard: canActivate()
    FirebaseAuthGuard->>FirebaseSDK: verifyIdToken(token)
    
    alt Valid Token
        FirebaseSDK-->>FirebaseAuthGuard: Decoded Token
        FirebaseAuthGuard-->>Controller: true (attach user to request)
        Controller->>Service: Business Logic
        Service-->>Client: 200 OK {data}
    else Invalid Token
        FirebaseSDK-->>FirebaseAuthGuard: Error
        FirebaseAuthGuard-->>Client: 401 Unauthorized
    end
```

#### 4. **Create Booking Flow**

```mermaid
sequenceDiagram
    participant Client
    participant BookingsController
    participant FirebaseAuthGuard
    participant BookingsService
    participant ServicesService
    participant PrismaService
    participant CalendarService
    participant GoogleAPI
    participant Database
    
    Client->>BookingsController: POST /bookings + Auth Header
    BookingsController->>FirebaseAuthGuard: Verify Token
    FirebaseAuthGuard-->>BookingsController: Authorized
    
    BookingsController->>BookingsService: create(dto)
    
    BookingsService->>ServicesService: findOne(serviceId)
    ServicesService->>Database: SELECT service
    Database-->>ServicesService: Service
    ServicesService-->>BookingsService: Service
    
    BookingsService->>BookingsService: validateBusinessHours()
    BookingsService->>BookingsService: checkOverlap()
    BookingsService->>PrismaService: booking.create()
    PrismaService->>Database: INSERT INTO bookings
    Database-->>PrismaService: Booking
    
    BookingsService->>CalendarService: createEvent(booking, service)
    CalendarService->>GoogleAPI: events.insert()
    GoogleAPI-->>CalendarService: Event ID
    
    CalendarService-->>BookingsService: eventId
    BookingsService->>PrismaService: update({googleCalendarEventId})
    PrismaService->>Database: UPDATE bookings
    
    Database-->>PrismaService: Updated Booking
    PrismaService-->>BookingsService: Booking
    BookingsService-->>BookingsController: Booking
    BookingsController-->>Client: 201 Created {booking}
```

#### 5. **Get Bookings by Date Flow**

```mermaid
sequenceDiagram
    participant Client
    participant BookingsController
    participant BookingsService
    participant PrismaService
    participant Database
    
    Client->>BookingsController: GET /bookings?date=2024-01-15
    BookingsController->>BookingsService: findByDate("2024-01-15")
    
    BookingsService->>BookingsService: Parse date, set start/end of day
    BookingsService->>PrismaService: findMany({where, include, orderBy})
    PrismaService->>Database: SELECT bookings with services
    Database-->>PrismaService: Bookings[]
    PrismaService-->>BookingsService: Bookings[]
    BookingsService-->>BookingsController: Bookings[]
    BookingsController-->>Client: 200 OK {bookings}
```

---

## Authentication & Authorization

### Firebase Integration

The system uses **Firebase Authentication** for user management:

1. **Client Side**: Users authenticate via Firebase (phone OTP, email, Google)
2. **Token Generation**: Firebase generates JWT ID token
3. **Token Transmission**: Client sends token in `Authorization: Bearer {token}` header
4. **Server Verification**: Backend verifies token using Firebase Admin SDK
5. **User Creation**: On first login, user record created in PostgreSQL

### FirebaseAuthGuard

Applied to protected routes using decorator:
```typescript
@UseGuards(FirebaseAuthGuard)
```

**Workflow:**
1. Extracts token from `Authorization` header
2. Calls `admin.auth().verifyIdToken(token)`
3. If valid: attaches decoded token to `request.user`, allows access
4. If invalid: throws `UnauthorizedException`

### GetUser Decorator

Custom decorator to extract user from request:
```typescript
@GetUser() user: any
```

Accesses `request.user` populated by guard.

---

## API Endpoints

### Authentication Endpoints

#### **POST /auth/register-or-login**

Register new user or login existing user.

**Request:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "provider": "GOOGLE"
}
```

**Response (201):**
```json
{
  "id": "uuid-here",
  "email": "user@example.com",
  "phoneNumber": "+1234567890",
  "displayName": "John Doe",
  "photoURL": "https://...",
  "provider": "GOOGLE",
  "firebaseUid": "firebase-uid-here"
}
```

**Errors:**
- `401 Unauthorized`: Invalid Firebase token
- `500 Internal Server Error`: Authentication failed

---

#### **GET /auth/me**

Get current authenticated user details.

**Headers:**
```
Authorization: Bearer {firebase-id-token}
```

**Response (200):**
```json
{
  "id": "uuid-here",
  "email": "user@example.com",
  "displayName": "John Doe",
  "provider": "GOOGLE",
  "firebaseUid": "firebase-uid-here"
}
```

**Errors:**
- `401 Unauthorized`: Missing, invalid, or expired token
- `401 Unauthorized`: User not found

---

### Services Endpoints

#### **GET /services**

Get all available services.

**Response (200):**
```json
[
  {
    "id": "service-uuid-1",
    "name": "Haircut",
    "durationMinutes": 30,
    "bufferMinutes": 10,
    "createdAt": "2024-01-15T10:00:00Z",
    "updatedAt": "2024-01-15T10:00:00Z"
  },
  {
    "id": "service-uuid-2",
    "name": "Beard Trim",
    "durationMinutes": 15,
    "bufferMinutes": 5,
    "createdAt": "2024-01-15T10:05:00Z",
    "updatedAt": "2024-01-15T10:05:00Z"
  }
]
```

---

#### **POST /services** 🔒

Create new service (protected).

**Headers:**
```
Authorization: Bearer {firebase-id-token}
```

**Request:**
```json
{
  "name": "Premium Haircut",
  "durationMinutes": 45,
  "bufferMinutes": 15
}
```

**Response (201):**
```json
{
  "id": "service-uuid-3",
  "name": "Premium Haircut",
  "durationMinutes": 45,
  "bufferMinutes": 15,
  "createdAt": "2024-01-15T11:00:00Z",
  "updatedAt": "2024-01-15T11:00:00Z"
}
```

**Validations:**
- `name`: Required, min length 1
- `durationMinutes`: Required, min 5
- `bufferMinutes`: Required, min 0

**Errors:**
- `401 Unauthorized`: Missing or invalid token
- `400 Bad Request`: Validation errors

---

### Bookings Endpoints

#### **GET /bookings?date=YYYY-MM-DD**

Get all bookings for a specific date.

**Query Parameters:**
- `date` (required): Date in format `YYYY-MM-DD`

**Example:** `/bookings?date=2024-01-15`

**Response (200):**
```json
[
  {
    "id": "booking-uuid-1",
    "customerName": "Alice Johnson",
    "customerPhone": "+1234567890",
    "serviceId": "service-uuid-1",
    "startTime": "2024-01-15T10:00:00.000Z",
    "endTime": "2024-01-15T10:30:00.000Z",
    "source": "MANUAL",
    "googleCalendarEventId": "google-event-id-123",
    "createdAt": "2024-01-14T15:00:00Z",
    "updatedAt": "2024-01-14T15:00:00Z",
    "service": {
      "id": "service-uuid-1",
      "name": "Haircut",
      "durationMinutes": 30,
      "bufferMinutes": 10
    }
  }
]
```

**Errors:**
- `400 Bad Request`: Missing date parameter

---

#### **POST /bookings** 🔒

Create new booking (protected).

**Headers:**
```
Authorization: Bearer {firebase-id-token}
```

**Request:**
```json
{
  "customerName": "Bob Smith",
  "customerPhone": "+9876543210",
  "serviceId": "service-uuid-1",
  "startTime": "2024-01-15T14:00:00.000Z"
}
```

**Response (201):**
```json
{
  "id": "booking-uuid-2",
  "customerName": "Bob Smith",
  "customerPhone": "+9876543210",
  "serviceId": "service-uuid-1",
  "startTime": "2024-01-15T14:00:00.000Z",
  "endTime": "2024-01-15T14:30:00.000Z",
  "source": "MANUAL",
  "googleCalendarEventId": "google-event-id-456",
  "createdAt": "2024-01-15T12:00:00Z",
  "updatedAt": "2024-01-15T12:00:00Z",
  "service": {
    "id": "service-uuid-1",
    "name": "Haircut",
    "durationMinutes": 30,
    "bufferMinutes": 10
  }
}
```

**Validations:**
- `customerName`: Required, min length 1
- `customerPhone`: Required, valid phone number format
- `serviceId`: Required, valid UUID v4
- `startTime`: Required, valid ISO 8601 datetime

**Business Rules:**
- Must be within business hours (configured in `.env`)
- Cannot overlap with existing bookings (including buffer times)
- Service must exist

**Errors:**
- `401 Unauthorized`: Missing or invalid token
- `400 Bad Request`: Validation errors
- `400 Bad Request`: Service not found
- `400 Bad Request`: Outside business hours
- `400 Bad Request`: Time slot conflicts with existing booking

---

#### **PUT /bookings/:id** 🔒

Update existing booking (protected).

**Headers:**
```
Authorization: Bearer {firebase-id-token}
```

**Request (all fields optional):**
```json
{
  "customerName": "Bob Smith Jr.",
  "startTime": "2024-01-15T15:00:00.000Z"
}
```

**Response (200):**
```json
{
  "id": "booking-uuid-2",
  "customerName": "Bob Smith Jr.",
  "customerPhone": "+9876543210",
  "serviceId": "service-uuid-1",
  "startTime": "2024-01-15T15:00:00.000Z",
  "endTime": "2024-01-15T15:30:00.000Z",
  "source": "MANUAL",
  "googleCalendarEventId": "google-event-id-456",
  "service": {...}
}
```

**Errors:**
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: Booking not found
- `400 Bad Request`: Validation errors or conflicts

---

#### **DELETE /bookings/:id** 🔒

Delete booking (protected).

**Headers:**
```
Authorization: Bearer {firebase-id-token}
```

**Response (200):**
```json
{
  "message": "Booking deleted successfully"
}
```

**Errors:**
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: Booking not found

---

## Architecture Diagrams

### System Architecture

```mermaid
graph TB
    subgraph Client Layer
        Mobile[Mobile App<br/>React Native]
        Web[Web App<br/>React]
    end
    
    subgraph API Layer
        NestJS[NestJS Backend<br/>TypeScript]
        
        subgraph Controllers
            AuthCtrl[Auth Controller]
            ServicesCtrl[Services Controller]
            BookingsCtrl[Bookings Controller]
        end
        
        subgraph Services
            AuthSvc[Auth Service]
            ServicesSvc[Services Service]
            BookingsSvc[Bookings Service]
            CalendarSvc[Calendar Service]
            PrismaSvc[Prisma Service]
        end
        
        subgraph Guards & Middleware
            AuthGuard[Firebase Auth Guard]
            ValidationPipe[Validation Pipe]
        end
    end
    
    subgraph External Services
        Firebase[Firebase<br/>Authentication]
        GoogleCal[Google Calendar<br/>API]
    end
    
    subgraph Data Layer
        PostgreSQL[(PostgreSQL<br/>Database)]
    end
    
    Mobile --> NestJS
    Web --> NestJS
    
    NestJS --> AuthCtrl
    NestJS --> ServicesCtrl
    NestJS --> BookingsCtrl
    
    AuthCtrl --> AuthGuard
    ServicesCtrl --> AuthGuard
    BookingsCtrl --> AuthGuard
    
    AuthCtrl --> ValidationPipe
    ServicesCtrl --> ValidationPipe
    BookingsCtrl --> ValidationPipe
    
    AuthCtrl --> AuthSvc
    ServicesCtrl --> ServicesSvc
    BookingsCtrl --> BookingsSvc
    
    AuthSvc --> Firebase
    AuthSvc --> PrismaSvc
    
    ServicesSvc --> PrismaSvc
    
    BookingsSvc --> ServicesSvc
    BookingsSvc --> CalendarSvc
    BookingsSvc --> PrismaSvc
    
    CalendarSvc --> GoogleCal
    PrismaSvc --> PostgreSQL
    
    style NestJS fill:#e8336d
    style Firebase fill:#ffca28
    style GoogleCal fill:#4285f4
    style PostgreSQL fill:#336791
```

### Module Dependencies

```mermaid
graph LR
    AppModule[App Module<br/>Root]
    
    subgraph Core Modules
        ConfigModule[Config Module<br/>Global]
        PrismaModule[Prisma Module<br/>Database]
    end
    
    subgraph Feature Modules
        AuthModule[Auth Module]
        ServicesModule[Services Module]
        BookingsModule[Bookings Module]
        CalendarModule[Calendar Module]
    end
    
    AppModule --> ConfigModule
    AppModule --> PrismaModule
    AppModule --> AuthModule
    AppModule --> ServicesModule
    AppModule --> BookingsModule
    AppModule --> CalendarModule
    
    AuthModule --> PrismaModule
    ServicesModule --> PrismaModule
    BookingsModule --> PrismaModule
    BookingsModule --> ServicesModule
    BookingsModule --> CalendarModule
    CalendarModule --> ConfigModule
    
    style AppModule fill:#e8336d
    style ConfigModule fill:#4caf50
    style PrismaModule fill:#336791
```

### Booking Creation Flow Diagram

```mermaid
stateDiagram-v2
    [*] --> ReceiveRequest: POST /bookings
    
    ReceiveRequest --> ValidateAuth: Check Firebase Token
    ValidateAuth --> ValidateDTO: Token Valid
    ValidateAuth --> Unauthorized: Token Invalid
    
    ValidateDTO --> ValidateService: DTO Valid
    ValidateDTO --> BadRequest: DTO Invalid
    
    ValidateService --> CalculateTime: Service Found
    ValidateService --> BadRequest: Service Not Found
    
    CalculateTime --> ValidateHours: Calculate End Time
    ValidateHours --> CheckOverlap: Within Hours
    ValidateHours --> BadRequest: Outside Hours
    
    CheckOverlap --> CreateBooking: No Conflicts
    CheckOverlap --> BadRequest: Has Conflicts
    
    CreateBooking --> SyncCalendar: DB Insert Success
    SyncCalendar --> UpdateEventId: Calendar Sync OK
    SyncCalendar --> ReturnBooking: Calendar Sync Failed
    
    UpdateEventId --> ReturnBooking: Update Success
    
    ReturnBooking --> [*]: 201 Created
    BadRequest --> [*]: 400 Error
    Unauthorized --> [*]: 401 Error
```

### Data Flow Diagram

```mermaid
flowchart LR
    Client[Client]
    
    subgraph Backend
        API[API Endpoints]
        BL[Business Logic<br/>Services]
        ORM[Prisma ORM]
    end
    
    DB[(PostgreSQL)]
    ExtAPI[External APIs<br/>Firebase, Google]
    
    Client <-->|HTTP/JSON| API
    API <--> BL
    BL <--> ORM
    ORM <-->|SQL| DB
    BL <-->|REST/OAuth| ExtAPI
    
    style Client fill:#90caf9
    style API fill:#e8336d
    style BL fill:#ffb74d
    style ORM fill:#81c784
    style DB fill:#336791
    style ExtAPI fill:#ba68c8
```

---

## Configuration

The application is configured via environment variables (`.env` file):

```bash
# Server
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/barber_db"

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH="./config/firebase-service-account.json"

# Google Calendar
GOOGLE_SERVICE_ACCOUNT_PATH="./config/google-service-account.json"
GOOGLE_CALENDAR_ID="primary"

# Business Hours
BUSINESS_HOURS_START="09:00"
BUSINESS_HOURS_END="18:00"
```

**Configuration Service** ([configuration.ts](file:///d:/WinterArc2025/Startup_Ideas/Barber_System/backend/src/config/configuration.ts)) loads and validates these values.

---

## Error Handling

### Common HTTP Status Codes

| Code | Usage |
|------|-------|
| `200 OK` | Successful GET, PUT, DELETE |
| `201 Created` | Successful POST (resource created) |
| `400 Bad Request` | Validation errors, business rule violations |
| `401 Unauthorized` | Missing or invalid authentication token |
| `404 Not Found` | Requested resource doesn't exist |
| `500 Internal Server Error` | Unexpected server errors |

### Validation Errors

NestJS `ValidationPipe` automatically validates DTOs:

**Example Error Response:**
```json
{
  "statusCode": 400,
  "message": [
    "Invalid service ID format",
    "Please provide a valid phone number (e.g., +1234567890)"
  ],
  "error": "Bad Request"
}
```

---

## Key Design Patterns

### 1. **Dependency Injection**
All services injected via NestJS DI container:
```typescript
constructor(
  private prisma: PrismaService,
  private servicesService: ServicesService
) {}
```

### 2. **Repository Pattern**
Prisma acts as repository layer, abstracting database access.

### 3. **DTO Pattern**
Separate DTOs for requests and responses ensure type safety.

### 4. **Guard Pattern**
`FirebaseAuthGuard` implements `CanActivate` interface for route protection.

### 5. **Module Pattern**
Code organized into cohesive, loosely-coupled modules.

### 6. **Service Layer Pattern**
Business logic separated from controllers in service classes.

---

## Database Queries Examples

### Complex Overlap Detection Query

```typescript
const overlappingBookings = await this.prisma.booking.findMany({
  where: {
    AND: [
      { id: { not: excludeBookingId } }, // Exclude current booking
      {
        OR: [
          // Scenario 1: New starts during existing
          {
            AND: [
              { startTime: { lte: startTime } },
              { endTime: { gte: startTime } }
            ]
          },
          // Scenario 2: New ends during existing
          {
            AND: [
              { startTime: { lte: endTimeWithBuffer } },
              { endTime: { gte: endTimeWithBuffer } }
            ]
          },
          // Scenario 3: New contains existing
          {
            AND: [
              { startTime: { gte: startTime } },
              { endTime: { lte: endTimeWithBuffer } }
            ]
          },
          // Scenario 4: Existing contains new
          {
            AND: [
              { startTime: { lte: startTime } },
              { endTime: { gte: endTimeWithBuffer } }
            ]
          }
        ]
      }
    ]
  },
  include: { service: true }
});
```

This query uses:
- `AND`/`OR` conditions for complex logic
- Date comparisons
- Relation includes
- Buffer time calculations

---

## Scalability Considerations

### Current Implementation
- Single barber shop
- Single calendar
- Synchronous operations

### Future Enhancements
- **Multi-tenancy**: Support multiple barber shops
- **Queue System**: Bull/Redis for async calendar sync
- **Caching**: Redis for frequently accessed data
- **Rate Limiting**: Protect APIs from abuse
- **Horizontal Scaling**: Stateless design allows multiple instances
- **Database Indexing**: Already has indexes on `startTime`, `endTime`, `serviceId`

---

## Summary

This backend system provides a robust foundation for a barber booking system with:

✅ **Secure Authentication** via Firebase  
✅ **Comprehensive Validation** at every layer  
✅ **Conflict Detection** preventing double bookings  
✅ **External Integration** with Google Calendar  
✅ **Type Safety** using TypeScript and Prisma  
✅ **Clean Architecture** with separated concerns  
✅ **Error Handling** with meaningful messages  
✅ **Extensibility** for future AI-powered features

The modular design and clear separation of concerns make it easy to extend with additional features like AI queue management, real-time updates, or mobile notifications.
