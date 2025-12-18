# Part 11: Microservices, GraphQL, WebSockets & Performance

This part covers advanced NestJS topics for building scalable distributed systems.

## Microservices Architecture

### Installation
```bash
npm install @nestjs/microservices
```

### TCP Microservice

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.TCP,
    options: {  port: 3001 },
  });
  await app.listen();
}
```

### Message Patterns

```typescript
@Controller()
export class MathController {
  @MessagePattern({ cmd: 'sum' })
  accumulate(data: number[]): number {
    return data.reduce((a, b) => a + b);
  }

  @EventPattern('user_created')
  handleUserCreated(data: Record<string, unknown>) {
    console.log('User created:', data);
  }
}
```

### Client Setup

```typescript
@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'MATH_SERVICE',
        transport: Transport.TCP,
        options: { port: 3001 },
      },
    ]),
  ],
})
export class AppModule {}

// Usage
@Injectable()
export class AppService {
  constructor(@Inject('MATH_SERVICE') private client: ClientProxy) {}

  async accumulate() {
    return this.client.send({ cmd: 'sum' }, [1, 2, 3]);
  }
}
```

---

## GraphQL Integration

### Installation
```bash
npm install @nestjs/graphql @nestjs/apollo @apollo/server graphql
```

### Setup

```typescript
@Module({
  imports: [
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: true,
      playground: true,
    }),
  ],
})
export class AppModule {}
```

### Resolver

```typescript
@Resolver(() => User)
export class UsersResolver {
  constructor(private usersService: UsersService) {}

  @Query(() => [User])
  async users(): Promise<User[]> {
    return this.usersService.findAll();
  }

  @Query(() => User)
  async user(@Args('id') id: string): Promise<User> {
    return this.usersService.findOne(id);
  }

  @Mutation(() => User)
  async createUser(@Args('input') input: CreateUserInput): Promise<User> {
    return this.usersService.create(input);
  }

  @ResolveField(() => [Post])
  async posts(@Parent() user: User): Promise<Post[]> {
    return this.postsService.findByUser(user.id);
  }
}
```

### Object Types

```typescript
@ObjectType()
export class User {
  @Field()
  id: string;

  @Field()
  email: string;

  @Field()
  name: string;

  @Field(() => [Post])
  posts: Post[];
}

@InputType()
export class CreateUserInput {
  @Field()
  email: string;

  @Field()
  name: string;

  @Field()
  password: string;
}
```

---

## WebSockets & Real-time

### Installation
```bash
npm install @nestjs/websockets @nestjs/platform-socket.io
```

### Gateway

```typescript
@WebSocketGateway({
  cors: { origin: '*' },
})
export class ChatGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('message')
  handleMessage(@MessageBody() message: string, @ConnectedSocket() client: Socket) {
    this.server.emit('message', message); // Broadcast to all
    return { event: 'message', data: message };
  }

  @SubscribeMessage('joinRoom')
  handleJoinRoom(@MessageBody() room: string, @ConnectedSocket() client: Socket) {
    client.join(room);
    this.server.to(room).emit('userJoined', client.id);
  }

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }
}
```

### Client Usage

```javascript
import { io } from 'socket.io-client';

const socket = io('http://localhost:3000');

socket.on('connect', () => {
  socket.emit('message', 'Hello!');
});

socket.on('message', (data) => {
  console.log('Received:', data);
});
```

---

## Performance Optimization

### Caching with Redis

```bash
npm install @nestjs/cache-manager cache-manager cache-manager-redis-store
```

```typescript
@Module({
  imports: [
    CacheModule.register({
      store: redisStore,
      host: 'localhost',
      port: 6379,
    }),
  ],
})
export class AppModule {}

// Usage
@Injectable()
export class ProductsService {
  constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

  @CacheKey('all-products')
  @CacheTTL(300) // 5 minutes
  async findAll() {
    return this.productsRepository.find();
  }

  async findOne(id: string) {
    const cached = await this.cacheManager.get(`product-${id}`);
    if (cached) return cached;

    const product = await this.productsRepository.findOne({ where: { id } });
    await this.cacheManager.set(`product-${id}`, product, { ttl: 300 });
    return product;
  }
}
```

### Compression

```bash
npm install compression
```

```typescript
import * as compression from 'compression';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(compression());
  await app.listen(3000);
}
```

### Rate Limiting

```bash
npm install @nestjs/throttler
```

```typescript
@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60,
      limit: 10,
    }),
  ],
})
export class AppModule {}

@Controller()
@UseGuards(ThrottlerGuard)
export class AppController {
  @Throttle(5, 60) // 5 requests per minute
  @Get()
  findAll() {
    return 'Rate limited endpoint';
  }
}
```

### Bull Queues

```bash
npm install @nestjs/bull bull
```

```typescript
@Module({
  imports: [
    BullModule.forRoot({
      redis: {
        host: 'localhost',
        port: 6379,
      },
    }),
    BullModule.registerQueue({
      name: 'email',
    }),
  ],
})
export class AppModule {}

@Injectable()
export class EmailService {
  constructor(@InjectQueue('email') private emailQueue: Queue) {}

  async sendWelcomeEmail(email: string) {
    await this.emailQueue.add('welcome', { email });
  }
}

@Processor('email')
export class EmailProcessor {
  @Process('welcome')
  async handleWelcome(job: Job) {
    console.log(`Sending welcome email to ${job.data.email}`);
    // Send email logic
  }
}
```

---

## Key Takeaways

✅ **Microservices** - Distributed architecture  
✅ **GraphQL** - Flexible data querying  
✅ **WebSockets** - Real-time communication  
✅ **Caching** - Improve performance  
✅ **Queues** - Background job processing  

---

## Next Steps

➡️ **[Part 12-15: Additional Advanced Topics → See Part 15](./Part15-Best-Practices.md)**  
➡️ **[Part 16: Complete Project](./Part16-Complete-Project.md)**

---

**[← Previous: Testing](./Part10-Testing.md)** | **[Next: Best Practices →](./Part15-Best-Practices.md)**
