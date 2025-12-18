# Part 10: Testing

## Table of Contents
- [Testing Setup](#testing-setup)
- [Unit Testing](#unit-testing)
- [Integration Testing](#integration-testing)
- [E2E Testing](#e2e-testing)
- [Mocking](#mocking)
- [Best Practices](#best-practices)

---

## Testing Setup

NestJS uses Jest by default.

```json
// package.json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "test:e2e": "jest --config ./test/jest-e2e.json"
  }
}
```

---

## Unit Testing

### Service Testing

```typescript
// users.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { User } from './entities/user.entity';
import { Repository } from 'typeorm';

describe('UsersService', () => {
  let service: UsersService;
  let repository: Repository<User>;

  const mockUserRepository = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    repository = module.get<Repository<User>>(getRepositoryToken(User));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('should return an array of users', async () => {
      const users = [
        { id: '1', email: 'test@test.com', name: 'Test' },
        { id: '2', email: 'test2@test.com', name: 'Test2' },
      ];
      
      mockUserRepository.find.mockResolvedValue(users);

      const result = await service.findAll();

      expect(result).toEqual(users);
      expect(repository.find).toHaveBeenCalledTimes(1);
    });
  });

  describe('findOne', () => {
    it('should return a user by id', async () => {
      const user = { id: '1', email: 'test@test.com', name: 'Test' };
      mockUserRepository.findOne.mockResolvedValue(user);

      const result = await service.findOne('1');

      expect(result).toEqual(user);
      expect(repository.findOne).toHaveBeenCalledWith({ where: { id: '1' } });
    });

    it('should throw NotFoundException if user not found', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);

      await expect(service.findOne('999')).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('should create and save a new user', async () => {
      const createUserDto = {
        email: 'test@test.com',
        name: 'Test',
        password: 'password123',
      };
      
      const user = { id: '1', ...createUserDto };
      
      mockUserRepository.create.mockReturnValue(user);
      mockUserRepository.save.mockResolvedValue(user);

      const result = await service.create(createUserDto);

      expect(result).toEqual(user);
      expect(repository.create).toHaveBeenCalledWith(createUserDto);
      expect(repository.save).toHaveBeenCalledWith(user);
    });
  });
});
```

### Controller Testing

```typescript
// users.controller.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

describe('UsersController', () => {
  let controller: UsersController;
  let service: UsersService;

  const mockUsersService = {
    findAll: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('findAll', () => {
    it('should return an array of users', async () => {
      const users = [{ id: '1', email: 'test@test.com' }];
      mockUsersService.findAll.mockResolvedValue(users);

      expect(await controller.findAll()).toEqual(users);
      expect(service.findAll).toHaveBeenCalled();
    });
  });

  describe('create', () => {
    it('should create a user', async () => {
      const dto = { email: 'test@test.com', name: 'Test', password: 'pass' };
      const user = { id: '1', ...dto };
      
      mockUsersService.create.mockResolvedValue(user);

      expect(await controller.create(dto)).toEqual(user);
      expect(service.create).toHaveBeenCalledWith(dto);
    });
  });
});
```

---

## E2E Testing

```typescript
// test/app.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('/auth (POST)', () => {
    it('should register a new user', () => {
      return request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: 'test@test.com',
          password: 'password123',
          name: 'Test User',
        })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('access_token');
          expect(res.body.user).toHaveProperty('email', 'test@test.com');
        });
    });

    it('should login with valid credentials', () => {
      return request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: 'test@test.com',
          password: 'password123',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('access_token');
        });
    });

    it('should reject invalid credentials', () => {
      return request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: 'test@test.com',
          password: 'wrongpassword',
        })
        .expect(401);
    });
  });

  describe('/users (GET)', () => {
    let authToken: string;

    beforeAll(async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: 'test@test.com',
          password: 'password123',
        });
      
      authToken = response.body.access_token;
    });

    it('should require authentication', () => {
      return request(app.getHttpServer())
        .get('/users')
        .expect(401);
    });

    it('should return users when authenticated', () => {
      return request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(Array.isArray(res.body)).toBe(true);
        });
    });
  });
});
```

---

## Mocking

### Mock External Services

```typescript
const mockEmailService = {
  sendWelcome: jest.fn().mockResolvedValue(true),
  sendPasswordReset: jest.fn().mockResolvedValue(true),
};

await Test.createTestingModule({
  providers: [
    UsersService,
    {
      provide: EmailService,
      useValue: mockEmailService,
    },
  ],
}).compile();
```

### Mock Database

```typescript
// For unit tests, mock the repository
const mockRepository = {
  find: jest.fn(),
  findOne: jest.fn(),
  save: jest.fn(),
};

// For E2E tests, use test database
TypeOrmModule.forRoot({
  type: 'postgres',
  database: 'test_db',
  entities: [__dirname + '/**/*.entity{.ts,.js}'],
  synchronize: true, // OK for test database
  dropSchema: true, // Clean slate for each test run
});
```

---

## Best Practices

### 1. Test Coverage

```bash
# Aim for 80%+ coverage on critical paths
npm run test:cov
```

### 2. Test Structure (AAA Pattern)

```typescript
it('should create a user', async () => {
  // Arrange
  const dto = { email: 'test@test.com', name: 'Test' };
  mockRepository.create.mockReturnValue(dto);
  mockRepository.save.mockResolvedValue(dto);

  // Act
  const result = await service.create(dto);

  // Assert
  expect(result).toEqual(dto);
  expect(repository.save).toHaveBeenCalledWith(dto);
});
```

### 3. Use Test Utilities

```typescript
// test/utils/test-utils.ts
export const createMockRepository = () => ({
  find: jest.fn(),
  findOne: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
});

export const createTestUser = (overrides = {}) => ({
  id: '1',
  email: 'test@test.com',
  name: 'Test User',
  ...overrides,
});
```

---

## Key Takeaways

✅ **Unit tests** - Test individual components  
✅ **E2E tests** - Test complete flows  
✅ **Mocking** - Isolate dependencies  
✅ **Coverage** - Aim for high coverage  

---

## Next Steps

➡️ **[Part 11: Microservices](./Part11-Microservices.md)**

---

**[← Previous: Error Handling](./Part09-Error-Handling-Logging.md)** | **[Next: Microservices →](./Part11-Microservices.md)**
