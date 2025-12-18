# Part 9: Error Handling & Logging

## Table of Contents
- [Exception Handling](#exception-handling)
- [Custom Exceptions](#custom-exceptions)
- [Exception Filters](#exception-filters)
- [Logging](#logging)
- [Winston Integration](#winston-integration)
- [Best Practices](#best-practices)

---

## Exception Handling

### Built-in HTTP Exceptions

```typescript
import {
  BadRequestException,
  UnauthorizedException,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  InternalServerErrorException,
} from '@nestjs/common';

@Injectable()
export class UsersService {
  async findOne(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id } });
    
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    
    return user;
  }

  async create(dto: CreateUserDto): Promise<User> {
    const existing = await this.findByEmail(dto.email);
    
    if (existing) {
      throw new ConflictException('Email already exists');
    }
    
    try {
      return await this.usersRepository.save(dto);
    } catch (error) {
      throw new InternalServerErrorException('Failed to create user');
    }
  }
}
```

---

## Custom Exceptions

```typescript
// exceptions/business.exception.ts
export class BusinessException extends HttpException {
  constructor(message: string, statusCode: HttpStatus = HttpStatus.BAD_REQUEST) {
    super(
      {
        success: false,
        message,
        timestamp: new Date().toISOString(),
      },
      statusCode,
    );
  }
}

// exceptions/insufficient-funds.exception.ts
export class InsufficientFundsException extends BusinessException {
  constructor(required: number, available: number) {
    super(
      `Insufficient funds. Required: $${required}, Available: $${available}`,
      HttpStatus.BAD_REQUEST,
    );
  }
}

// Usage
async withdraw(userId: string, amount: number) {
  const balance = await this.getBalance(userId);
  
  if (balance < amount) {
    throw new InsufficientFundsException(amount, balance);
  }
  
  // Process withdrawal...
}
```

---

## Exception Filters

### Global Exception Filter

```typescript
// filters/http-exception.filter.ts
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    const errorResponse = {
      success: false,
     statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
      message: typeof message === 'string' ? message : message['message'],
    };

    this.logger.error(
      `${request.method} ${request.url}`,
      exception instanceof Error ? exception.stack : JSON.stringify(exception),
    );

    response.status(status).json(errorResponse);
  }
}

// Apply globally
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalFilters(new AllExceptionsFilter());
  await app.listen(3000);
}
```

---

## Logging

### Built-in Logger

```typescript
import { Logger } from '@nestjs/common';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  async findAll(): Promise<User[]> {
    this.logger.log('Fetching all users');
    const users = await this.usersRepository.find();
    this.logger.log(`Found ${users.length} users`);
    return users;
  }

  async create(dto: CreateUserDto): Promise<User> {
    this.logger.log(`Creating user: ${dto.email}`);
    
    try {
      const user = await this.usersRepository.save(dto);
      this.logger.log(`User created successfully: ${user.id}`);
      return user;
    } catch (error) {
      this.logger.error(`Failed to create user: ${error.message}`, error.stack);
      throw error;
    }
  }
}
```

---

## Winston Integration

```bash
npm install winston nest-winston
```

```typescript
// logger/winston.config.ts
import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';

export const winstonConfig = WinstonModule.createLogger({
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.colorize(),
        winston.format.printf(({ timestamp, level, message, context, ...meta }) => {
          return `${timestamp} [${context}] ${level}: ${message} ${
            Object.keys(meta).length ? JSON.stringify(meta) : ''
          }`;
        }),
      ),
    }),
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json(),
      ),
    }),
    new winston.transports.File({
      filename: 'logs/combined.log',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json(),
      ),
    }),
  ],
});

// app.module.ts
@Module({
  imports: [
    WinstonModule.forRoot(winstonConfig),
  ],
})

// Usage
@Injectable()
export class UsersService {
  constructor(@Inject(WINSTON_MODULE_PROVIDER) private logger: Logger) {}

  async findAll() {
    this.logger.info('Fetching all users', { context: 'UsersService' });
    return this.usersRepository.find();
  }
}
```

---

## Best Practices

### 1. Structured Logging

```typescript
this.logger.log({
  message: 'User created',
  userId: user.id,
  email: user.email,
  timestamp: new Date().toISOString(),
});
```

### 2. Log Levels

```typescript
this.logger.verbose('Detailed information');
this.logger.debug('Debug information');
this.logger.log('General information');
this.logger.warn('Warning messages');
this.logger.error('Error messages', error.stack);
```

### 3. Request Tracking

```typescript
@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    req['requestId'] = uuid();
    next();
  }
}
```

---

## Key Takeaways

✅ **Exception filters** - Global error handling  
✅ **Custom exceptions** - Business-specific errors  
✅ **Logging** - Track application behavior  
✅ **Winston** - Production-grade logging  

---

## Next Steps

➡️ **[Part 10: Testing](./Part10-Testing.md)**

---

**[← Previous: Configuration](./Part08-Configuration-Environment.md)** | **[Next: Testing →](./Part10-Testing.md)**
