# Part 5: Database Integration (TypeORM & Prisma)

## Table of Contents
- [Database Options in NestJS](#database-options-in-nestjs)
- [TypeORM Integration](#typeorm-integration)
- [Prisma Integration](#prisma-integration)
- [Repository Pattern](#repository-pattern)
- [Transactions](#transactions)
- [Migrations](#migrations)
- [Best Practices](#best-practices)

---

## Database Options in NestJS

NestJS supports multiple ORMs and database libraries:

| ORM/Library | Type | Use Case |
|-------------|------|----------|
| **TypeORM** | ORM | Full-featured, decorators, migrations |
| **Prisma** | ORM | Type-safe, modern, great DX |
| **Mongoose** | ODM | MongoDB only |
| **Sequelize** | ORM | Mature, wide DB support |
| **MikroORM** | ORM | Unit of Work pattern |

---

## TypeORM Integration

### Installation

```bash
npm install @nestjs/typeorm typeorm pg
# For MySQL: mysql2
# For SQLite: sqlite3
```

### Configuration

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5432,
      username: 'postgres',
      password: 'password',
      database: 'nestjs_db',
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: true, // ⚠️ Only for development!
    }),
  ],
})
export class AppModule {}
```

### Creating Entities

```typescript
// users/entities/user.entity.ts
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  BeforeInsert,
  Index,
} from 'typeorm';
import * as bcrypt from 'bcrypt';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @Index()
  email: string;

  @Column()
  name: string;

  @Column({ select: false }) // Exclude from default queries
  password: string;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @BeforeInsert()
  async hashPassword() {
    this.password = await bcrypt.hash(this.password, 10);
  }
}
```

### Relations

```typescript
// One-to-Many
@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @OneToMany(() => Post, (post) => post.user)
  posts: Post[];
}

@Entity('posts')
export class Post {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  title: string;

  @ManyToOne(() => User, (user) => user.posts)
  user: User;

  @Column()
  userId: number;
}

// Many-to-Many
@Entity('students')
export class Student {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToMany(() => Course, (course) => course.students)
  @JoinTable()
  courses: Course[];
}

@Entity('courses')
export class Course {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToMany(() => Student, (student) => student.courses)
  students: Student[];
}
```

### Repository Pattern with TypeORM

```typescript
// users/users.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [UsersService],
  controllers: [UsersController],
  exports: [UsersService],
})
export class UsersModule {}

// users/users.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findAll(): Promise<User[]> {
    return await this.usersRepository.find();
  }

  async findOne(id: string): Promise<User> {
    return await this.usersRepository.findOne({ where: { id } });
  }

  async findByEmail(email: string): Promise<User> {
    return await this.usersRepository.findOne({ 
      where: { email },
      select: ['id', 'email', 'password', 'name'], // Include password
    });
  }

  async create(createUserDto: CreateUserDto): Promise<User> {
    const user = this.usersRepository.create(createUserDto);
    return await this.usersRepository.save(user);
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    await this.usersRepository.update(id, updateUserDto);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.usersRepository.delete(id);
  }

  // Advanced queries
  async findActiveUsers(): Promise<User[]> {
    return await this.usersRepository.find({
      where: { isActive: true },
      order: { createdAt: 'DESC' },
      take: 10, // Limit
    });
  }

  async searchUsers(searchTerm: string): Promise<User[]> {
    return await this.usersRepository
      .createQueryBuilder('user')
      .where('user.name ILIKE :searchTerm', { searchTerm: `%${searchTerm}%` })
      .orWhere('user.email ILIKE :searchTerm', { searchTerm: `%${searchTerm}%` })
      .getMany();
  }
}
```

---

## Prisma Integration

### Installation

```bash
npm install @prisma/client
npm install -D prisma
npx prisma init
```

### Schema Definition

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String    @id @default(uuid())
  email     String    @unique
  name      String
  password  String
  isActive  Boolean   @default(true)
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  posts     Post[]
  
  @@index([email])
  @@map("users")
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@map("posts")
}
```

### Prisma Service

```typescript
// prisma/prisma.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}

// prisma/prisma.module.ts
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

### Using Prisma in Services

```typescript
// users/users.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { User, Prisma } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findAll(): Promise<User[]> {
    return this.prisma.user.findMany();
  }

  async findOne(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
      include: { posts: true }, // Include relations
    });
  }

  async create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }

  async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data,
    });
  }

  async remove(id: string): Promise<User> {
    return this.prisma.user.delete({
      where: { id },
    });
  }

  // Advanced queries
  async findActiveUsers(): Promise<User[]> {
    return this.prisma.user.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
  }

  async searchUsers(searchTerm: string): Promise<User[]> {
    return this.prisma.user.findMany({
      where: {
        OR: [
          { name: { contains: searchTerm, mode: 'insensitive' } },
          { email: { contains: searchTerm, mode: 'insensitive' } },
        ],
      },
    });
  }
}
```

---

## Transactions

### TypeORM Transactions

```typescript
import { DataSource } from 'typeorm';

@Injectable()
export class OrdersService {
  constructor(
    private dataSource: DataSource,
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
  ) {}

  async createOrder(userId: string, items: CreateOrderItemDto[]) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Create order
      const order = queryRunner.manager.create(Order, {
        userId,
        total: 0,
      });
      await queryRunner.manager.save(order);

      // Create order items and calculate total
      let total = 0;
      for (const item of items) {
        const product = await queryRunner.manager.findOne(Product, {
          where: { id: item.productId },
        });

        if (product.stock < item.quantity) {
          throw new BadRequestException('Insufficient stock');
        }

        // Decrease stock
        product.stock -= item.quantity;
        await queryRunner.manager.save(product);

        // Create order item
        const orderItem = queryRunner.manager.create(OrderItem, {
          orderId: order.id,
          productId: item.productId,
          quantity: item.quantity,
          price: product.price,
        });
        await queryRunner.manager.save(orderItem);

        total += product.price * item.quantity;
      }

      // Update order total
      order.total = total;
      await queryRunner.manager.save(order);

      await queryRunner.commitTransaction();
      return order;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }
}
```

### Prisma Transactions

```typescript
@Injectable()
export class OrdersService {
  constructor(private prisma: PrismaService) {}

  async createOrder(userId: string, items: CreateOrderItemDto[]) {
    return await this.prisma.$transaction(async (prisma) => {
      // Create order
      const order = await prisma.order.create({
        data: {
          userId,
          total: 0,
        },
      });

      // Process items
      let total = 0;
      for (const item of items) {
        const product = await prisma.product.findUnique({
          where: { id: item.productId },
        });

        if (product.stock < item.quantity) {
          throw new BadRequestException('Insufficient stock');
        }

        // Update product stock
        await prisma.product.update({
          where: { id: item.productId },
          data: { stock: { decrement: item.quantity } },
        });

        // Create order item
        await prisma.orderItem.create({
          data: {
            orderId: order.id,
            productId: item.productId,
            quantity: item.quantity,
            price: product.price,
          },
        });

        total += product.price * item.quantity;
      }

      // Update order total
      return await prisma.order.update({
        where: { id: order.id },
        data: { total },
        include: { items: true },
      });
    });
  }
}
```

---

## Migrations

### TypeORM Migrations

```bash
# Generate migration
npm run typeorm migration:generate -- -n CreateUsers

# Run migrations
npm run typeorm migration:run

# Revert migration
npm run typeorm migration:revert
```

```typescript
// migrations/1234567890-CreateUsers.ts
import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class CreateUsers1234567890 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'users',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          { name: 'email', type: 'varchar', isUnique: true },
          { name: 'name', type: 'varchar' },
          { name: 'password', type: 'varchar' },
          { name: 'isActive', type: 'boolean', default: true },
          { name: 'createdAt', type: 'timestamp', default: 'now()' },
          { name: 'updatedAt', type: 'timestamp', default: 'now()' },
        ],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('users');
  }
}
```

### Prisma Migrations

```bash
# Create migration
npx prisma migrate dev --name init

# Apply migrations
npx prisma migrate deploy

# Reset database
npx prisma migrate reset
```

---

## Best Practices

### 1. Use DTOs with Database Models

```typescript
// Never expose entities directly
// ❌ Bad
@Get()
findAll(): Promise<User[]> {
  return this.usersService.findAll(); // Includes password!
}

// ✅ Good
@Get()
async findAll(): Promise<UserResponseDto[]> {
  const users = await this.usersService.findAll();
  return users.map(user => new UserResponseDto(user));
}

// user-response.dto.ts
export class UserResponseDto {
  id: string;
  email: string;
  name: string;
  createdAt: Date;

  constructor(user: User) {
    this.id = user.id;
    this.email = user.email;
    this.name = user.name;
    this.createdAt = user.createdAt;
  }
}
```

### 2. Use Eager/Lazy Loading Wisely

```typescript
// ✅ Load relations only when needed
async findOne(id: string): Promise<User> {
  return this.usersRepository.findOne({
    where: { id },
    relations: ['posts'], // Only load when needed
  });
}

// ✅ Use query builder for complex queries
async findUsersWithStats() {
  return this.usersRepository
    .createQueryBuilder('user')
    .leftJoinAndSelect('user.posts', 'post')
    .select([
      'user.id',
      'user.name',
      'COUNT(post.id) as postsCount',
    ])
    .groupBy('user.id')
    .getRawMany();
}
```

### 3. Index Important Columns

```typescript
@Entity('users')
@Index(['email', 'isActive']) // Composite index
export class User {
  @Column({ unique: true })
  @Index() // Single column index
  email: string;

  @Column()
  @Index()
  isActive: boolean;
}
```

### 4. Use Connection Pooling

```typescript
TypeOrmModule.forRoot({
  // ...
  extra: {
    max: 10, // Maximum pool size
    min: 2, // Minimum pool size
    idleTimeoutMillis: 30000,
  },
});
```

---

## Key Takeaways

✅ **TypeORM** - Decorator-based, feature-rich  
✅ **Prisma** - Type-safe, modern DX, better performance  
✅ **Use transactions** - For data integrity  
✅ **Migrations** - Version control for database  
✅ **DTOs** - Never expose entities directly  
✅ **Indexing** - Optimize queries  

---

## Next Steps

➡️ **[Part 6: Authentication & Authorization](./Part06-Authentication-Authorization.md)**

---

**[← Previous: Middleware & Guards](./Part04-Middleware-Guards-Interceptors.md)** | **[Next: Authentication →](./Part06-Authentication-Authorization.md)**
