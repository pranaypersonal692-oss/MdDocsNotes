# Part 8: Configuration & Environment Variables

## Table of Contents
- [ConfigModule](#configmodule)
- [Environment Variables](#environment-variables)
- [Configuration Files](#configuration-files)
- [Validation](#validation)
- [Best Practices](#best-practices)

---

## ConfigModule

### Installation

```bash
npm install @nestjs/config
```

### Basic Setup

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, // Make ConfigModule available everywhere
      envFilePath: '.env', // Path to .env file
    }),
  ],
})
export class AppModule {}
```

### Using Configuration

```typescript
import { ConfigService } from '@nestjs/config';

@Injectable()
export class DatabaseService {
  constructor(private configService: ConfigService) {}

  getConnectionString(): string {
    const host = this.configService.get<string>('DB_HOST');
    const port = this.configService.get<number>('DB_PORT');
    const user = this.configService.get<string>('DB_USER');
    const password = this.configService.get<string>('DB_PASSWORD');
    const database = this.configService.get<string>('DB_NAME');
    
    return `postgresql://${user}:${password}@${host}:${port}/${database}`;
  }

  // With default value
  getPort(): number {
    return this.configService.get<number>('PORT', 3000);
  }
}
```

---

## Environment Variables

### .env File

```env
# .env
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=secret
DB_NAME=nestjs_db

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=your-refresh-secret
JWT_REFRESH_EXPIRES_IN=7d

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-password

# AWS
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket
```

### Multi-Environment Setup

```typescript
ConfigModule.forRoot({
  isGlobal: true,
  envFilePath: [
    `.env.${process.env.NODE_ENV}`, // .env.development or .env.production
    '.env', // Fallback
  ],
  ignoreEnvFile: process.env.NODE_ENV === 'production', // Use system env vars in production
});
```

---

## Configuration Files

### Custom Configuration

```typescript
// config/database.config.ts
import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
}));

// config/jwt.config.ts
export default registerAs('jwt', () => ({
  secret: process.env.JWT_SECRET,
  expiresIn: process.env.JWT_EXPIRES_IN || '1h',
  refreshSecret: process.env.JWT_REFRESH_SECRET,
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
}));
```

### Load Configuration

```typescript
import databaseConfig from './config/database.config';
import jwtConfig from './config/jwt.config';

@Module({
  imports: [
    ConfigModule.forRoot({
      load: [databaseConfig, jwtConfig],
      isGlobal: true,
    }),
  ],
})
export class AppModule {}
```

### Use Configuration

```typescript
@Injectable()
export class AuthService {
  constructor(
    @Inject(jwtConfig.KEY)
    private jwtConfiguration: ConfigType<typeof jwtConfig>,
  ) {}

  getJwtSecret(): string {
    return this.jwtConfiguration.secret;
  }
}
```

---

## Validation

### Schema Validation

```bash
npm install joi
```

```typescript
import * as Joi from 'joi';

@Module({
  imports: [
    ConfigModule.forRoot({
      validationSchema: Joi.object({
        NODE_ENV: Joi.string()
          .valid('development', 'production', 'test')
          .default('development'),
        PORT: Joi.number().default(3000),
        
        DB_HOST: Joi.string().required(),
        DB_PORT: Joi.number().default(5432),
        DB_USER: Joi.string().required(),
        DB_PASSWORD: Joi.string().required(),
        DB_NAME: Joi.string().required(),
        
        JWT_SECRET: Joi.string().required(),
        JWT_EXPIRES_IN: Joi.string().default('1h'),
      }),
    }),
  ],
})
export class AppModule {}
```

---

## Best Practices

### 1. Type-Safe Configuration

```typescript
// config/app.config.ts
export interface AppConfig {
  port: number;
  environment: string;
  apiPrefix: string;
}

export default registerAs('app', (): AppConfig => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  environment: process.env.NODE_ENV || 'development',
  apiPrefix: process.env.API_PREFIX || 'api',
}));

// Usage with type safety
@Injectable()
export class AppService {
  constructor(
    @Inject(appConfig.KEY)
    private config: ConfigType<typeof appConfig>,
  ) {}

  getPort(): number {
    return this.config.port; // Fully typed!
  }
}
```

### 2. Never Commit .env Files

```
# .gitignore
.env
.env.local
.env.*.local
```

### 3. Provide .env.example

```env
# .env.example
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=
DB_PASSWORD=
DB_NAME=
JWT_SECRET=
```

---

## Key Takeaways

✅ **ConfigModule** - Centralized configuration  
✅ **Type-safe** - Use registerAs for types  
✅ **Validation** - Validate config on startup  
✅ **Never commit** - .env files to version control  

---

## Next Steps

➡️ **[Part 9: Error Handling & Logging](./Part09-Error-Handling-Logging.md)**

---

**[← Previous: Validation](./Part07-Validation-DTOs.md)** | **[Next: Error Handling →](./Part09-Error-Handling-Logging.md)**
