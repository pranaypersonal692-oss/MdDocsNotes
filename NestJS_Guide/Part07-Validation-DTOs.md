# Part 7: Validation & DTOs

## Table of Contents
- [Data Transfer Objects (DTOs)](#data-transfer-objects-dtos)
- [Class Validator](#class-validator)
- [Validation Pipe](#validation-pipe)
- [Custom Validators](#custom-validators)
- [Transformation](#transformation)
- [Advanced Patterns](#advanced-patterns)

---

## Data Transfer Objects (DTOs)

DTOs define the structure of data being transferred between layers.

### Basic DTO

```typescript
// users/dto/create-user.dto.ts
export class CreateUserDto {
  email: string;
  password: string;
  name: string;
  age: number;
}
```

### With Validation

```bash
npm install class-validator class-transformer
```

```typescript
import { IsEmail, IsString, MinLength, IsInt, Min, Max } from 'class-validator';

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsString()
  name: string;

  @IsInt()
  @Min(18)
  @Max(120)
  age: number;
}
```

---

## Class Validator

### Common Decorators

```typescript
import {
  IsString,
  IsNumber,
  IsBoolean,
  IsDate,
  IsEmail,
  IsUrl,
  IsUUID,
  IsEnum,
  IsArray,
  IsOptional,
  IsNotEmpty,
  MinLength,
  MaxLength,
  Min,
  Max,
  Matches,
  ArrayMinSize,
  ArrayMaxSize,
  ValidateNested,
} from 'class-validator';

export class ProductDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @MinLength(10)
  @MaxLength(500)
  description: string;

  @IsNumber()
  @Min(0)
  price: number;

  @IsEnum(['active', 'inactive', 'archived'])
  status: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(5)
  tags: string[];

  @IsEmail()
  contactEmail: string;

 @IsUrl()
  @IsOptional()
  website?: string;

  @Matches(/^[A-Z]{3}-\d{4}$/)
  sku: string; // Format: ABC-1234
}
```

### Nested Validation

```typescript
import { Type } from 'class-transformer';

class AddressDto {
  @IsString()
  street: string;

  @IsString()
  city: string;

  @IsString()
  @Matches(/^\d{5}$/)
  zipCode: string;
}

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  name: string;

  @ValidateNested()
  @Type(() => AddressDto)
  address: AddressDto;
}
```

### Array Validation

```typescript
export class CreateOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}

class OrderItemDto {
  @IsUUID()
  productId: string;

  @IsInt()
  @Min(1)
  quantity: number;
}
```

---

## Validation Pipe

### Global Setup

```typescript
// main.ts
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip properties not in DTO
      forbidNonWhitelisted: true, // Throw error if extra properties
      transform: true, // Auto-transform to DTO instance
      transformOptions: {
        enableImplicitConversion: true, // Auto-convert types
      },
    }),
  );
  
  await app.listen(3000);
}
```

### Options Explained

```typescript
new ValidationPipe({
  whitelist: true,
  // Input: { email: "test@test.com", hackerField: "evil" }
  // Output: { email: "test@test.com" } // hackerField removed

  forbidNonWhitelisted: true,
  // Input: { email: "test@test.com", hackerField: "evil" }
  // Output: Error thrown

  transform: true,
  // Input: "123" (string)
  // Output: 123 (number) if DTO expects number

  transformOptions: {
    enableImplicitConversion: true,
    // Automatically convert types based on DTO
  },

  disableErrorMessages: false,
  // Set to true in production to hide validation details

  skipMissingProperties: false,
  // Skip validation for properties not provided

  validationError: {
    target: false, // Don't expose the object in error
    value: false, // Don't expose the value in error
  },
});
```

---

## Custom Validators

### Simple Custom Validator

```typescript
import { registerDecorator, ValidationOptions, ValidationArguments } from 'class-validator';

export function IsStrongPassword(validationOptions?: ValidationOptions) {
  return function (object: Object, propertyName: string) {
    registerDecorator({
      name: 'isStrongPassword',
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      validator: {
        validate(value: any, args: ValidationArguments) {
          if (typeof value !== 'string') return false;
          
          const hasUpperCase = /[A-Z]/.test(value);
          const hasLowerCase = /[a-z]/.test(value);
          const hasNumber = /\d/.test(value);
          const hasSpecialChar = /[!@#$%^&*]/.test(value);
          const isLongEnough = value.length >= 8;
          
          return hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar && isLongEnough;
        },
        defaultMessage(args: ValidationArguments) {
          return 'Password must contain uppercase, lowercase, number, special character and be at least 8 characters';
        },
      },
    });
  };
}

// Usage
export class CreateUserDto {
  @IsStrongPassword()
  password: string;
}
```

### Class-based Custom Validator

```typescript
import { ValidatorConstraint, ValidatorConstraintInterface, ValidationArguments } from 'class-validator';

@ValidatorConstraint({ name: 'isUserAlreadyExist', async: true })
export class IsUserAlreadyExistConstraint implements ValidatorConstraintInterface {
  constructor(private usersService: UsersService) {}

  async validate(email: string, args: ValidationArguments) {
    const user = await this.usersService.findByEmail(email);
    return !user; // Return true if user doesn't exist
  }

  defaultMessage(args: ValidationArguments) {
    return 'User with email $value already exists';
  }
}

// Register in module
@Module({
  providers: [IsUserAlreadyExistConstraint],
})

// Usage
export class CreateUserDto {
  @Validate(IsUserAlreadyExistConstraint)
  @IsEmail()
  email: string;
}
```

---

## Transformation

### Class Transformer

```typescript
import { Exclude, Expose, Transform, Type } from 'class-transformer';

export class UserResponseDto {
  @Expose()
  id: string;

  @Expose()
  email: string;

  @Expose()
  name: string;

  @Exclude() // Never include password in response
  password: string;

  @Transform(({ value }) => value.toUpperCase())
  name: string;

  @Type(() => Date)
  createdAt: Date;
}

// In service
async findAll(): Promise<UserResponseDto[]> {
  const users = await this.usersRepository.find();
  return plainToClass(UserResponseDto, users, {
    excludeExtraneousValues: true,
  });
}
```

### Sanitization

```typescript
import { Transform } from 'class-transformer';
import { IsString } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @Transform(({ value }) => value.trim())
  title: string;

  @IsString()
  @Transform(({ value }) => value.toLowerCase())
  slug: string;

  @Transform(({ value }) => {
    // Strip HTML tags
    return value.replace(/<[^>]*>/g, '');
  })
  content: string;
}
```

---

## Advanced Patterns

### Update DTO from Create DTO

```typescript
import { PartialType } from '@nestjs/mapped-types';

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsString()
  name: string;
}

// All fields become optional
export class UpdateUserDto extends PartialType(CreateUserDto) {}
```

### Pick and Omit Types

```typescript
import { OmitType, PickType } from '@nestjs/mapped-types';

// Pick specific fields
export class LoginDto extends PickType(CreateUserDto, ['email', 'password'] as const) {}

// Omit specific fields
export class UpdateProfileDto extends OmitType(CreateUserDto, ['password'] as const) {}
```

### Intersection Types

```typescript
import { IntersectionType } from '@nestjs/mapped-types';

class ContactInfoDto {
  @IsEmail()
  email: string;

  @IsString()
  phone: string;
}

class AddressDto {
  @IsString()
  street: string;

  @IsString()
  city: string;
}

// Combines both DTOs
export class UserProfileDto extends IntersectionType(ContactInfoDto, AddressDto) {}
```

### Conditional Validation

```typescript
import { ValidateIf } from 'class-validator';

export class CreateShippingDto {
  @IsEnum(['standard', 'express'])
  shippingMethod: string;

  // Only validate if express shipping
  @ValidateIf(o => o.shippingMethod === 'express')
  @IsString()
  @IsNotEmpty()
  expressDeliveryAddress: string;
}
```

### Custom Messages

```typescript
export class CreateUserDto {
  @IsEmail({}, {
    message: 'Please provide a valid email address',
  })
  email: string;

  @MinLength(8, {
    message: 'Password must be at least 8 characters long',
  })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
    message: 'Password must contain uppercase, lowercase, and number',
  })
  password: string;
}
```

### Groups and Contexts

```typescript
export class CreateUserDto {
  @IsEmail({ groups: ['create', 'update'] })
  email: string;

  @IsString({ groups: ['create'] })
  @MinLength(8, { groups: ['create'] })
  password: string;

  @IsString({ groups: ['update'] })
  name: string;
}

// In controller
@Post()
create(@Body(new ValidationPipe({ groups: ['create'] })) dto: CreateUserDto) {
  // Only validates fields in 'create' group
}

@Put(':id')
update(@Body(new ValidationPipe({ groups: ['update'] })) dto: CreateUserDto) {
  // Only validates fields in 'update' group
}
```

---

## Real-World Example

```typescript
// create-order.dto.ts
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum PaymentMethod {
  CREDIT_CARD = 'credit_card',
  PAYPAL = 'paypal',
  BANK_TRANSFER = 'bank_transfer',
}

class OrderItemDto {
  @IsUUID()
  productId: string;

  @IsNumber()
  @Min(1)
  quantity: number;
}

class ShippingAddressDto {
  @IsString()
  @IsNotEmpty()
  street: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsString()
  @Matches(/^\d{5}(-\d{4})?$/, {
    message: 'Invalid ZIP code format',
  })
  zipCode: string;

  @IsString()
  @IsNotEmpty()
  country: string;
}

export class CreateOrderDto {
  @IsArray()
  @ArrayMinSize(1, { message: 'Order must contain at least one item' })
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @ValidateNested()
  @Type(() => ShippingAddressDto)
  shippingAddress: ShippingAddressDto;

  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;

  @ValidateIf(o => o.paymentMethod === PaymentMethod.CREDIT_CARD)
  @IsString()
  @Matches(/^\d{16}$/, { message: 'Invalid card number' })
  cardNumber?: string;
}
```

---

## Key Takeaways

✅ **DTOs** - Define data structure and validation  
✅ **class-validator** - Decorator-based validation  
✅ **ValidationPipe** - Automatic validation  
✅ **Custom validators** - Complex validation logic  
✅ **Transformation** - Auto-convert and sanitize  

---

## Next Steps

➡️ **[Part 8: Configuration & Environment](./Part08-Configuration-Environment.md)**

---

**[← Previous: Authentication](./Part06-Authentication-Authorization.md)** | **[Next: Configuration →](./Part08-Configuration-Environment.md)**
