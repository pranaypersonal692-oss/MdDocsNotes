# Infrastructure as Code with Terraform

## Table of Contents
1. [Introduction to Infrastructure as Code](#introduction-to-infrastructure-as-code)
2. [Terraform Fundamentals](#terraform-fundamentals)
3. [Terraform Configuration Language (HCL)](#terraform-configuration-language-hcl)
4. [Providers and Resources](#providers-and-resources)
5. [State Management](#state-management)
6. [Modules](#modules)
7. [Variables and Outputs](#variables-and-outputs)
8. [Best Practices](#best-practices)

---

## Introduction to Infrastructure as Code

### What is Infrastructure as Code (IaC)?

**IaC** is the practice of managing and provisioning infrastructure through code instead of manual processes.

**Traditional Approach:**
```
1. Login to AWS Console
2. Click "Create EC2 Instance"
3. Select AMI, instance type, network, storage...
4. Click "Launch"
5. Repeat for staging, production...
6. Hope you didn't miss anything!
```

**IaC Approach:**
```terraform
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  tags = {
    Name = "WebServer"
  }
}

# terraform apply → Infrastructure created!
```

### Benefits of IaC

**1. Version Control:**
```
infrastructure/
├── main.tf
├── variables.tf
└── outputs.tf

Git commit history:
- v1.0.0: Initial infrastructure
- v1.1.0: Added load balancer
- v1.2.0: Updated instance types
```

**2. Consistency:**
```
Same code → Same infrastructure
  Dev      →  Staging  →  Production
(identical)  (identical)  (identical)
```

**3. Automation:**
```
Pull Request → CI/CD → terraform plan → Review → Merge → terraform apply
```

**4. Documentation:**
```terraform
# Code IS documentation!
resource "aws_db_instance" "database" {
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.medium"
  # Everything is explicit and visible
}
```

---

## Terraform Fundamentals

### Installation

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

### Basic Workflow

```
terraform init    # Initialize project
terraform plan    # Preview changes
terraform apply   # Apply changes
terraform destroy # Destroy infrastructure
```

---

## Terraform Configuration Language (HCL)

### Basic Syntax

```terraform
# Resource block
resource "resource_type" "name" {
  parameter = "value"
  
  nested_block {
    setting = "value"
  }
}

# Data source
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
}

# Variable
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# Output
output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

---

## Providers and Resources

### AWS Provider Example

```terraform
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "main-vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "public-subnet"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl start nginx
              EOF
  
  tags = {
    Name = "web-server"
  }
}

# Security Group
resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## State Management

### Terraform State

**Purpose:** Tracks real infrastructure and maps to configuration

```
terraform.tfstate (JSON file):
{
  "resources": [
    {
      "type": "aws_instance",
      "name": "web",
      "instances": [{
        "attributes": {
          "id": "i-1234567890abcdef0",
          "public_ip": "54.123.45.67"
        }
      }]
    }
  ]
}
```

### Remote State (Best Practice)

**S3 Backend:**
```terraform
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### State Commands

```bash
# List resources
terraform state list

# Show resource details
terraform state show aws_instance.web

# Move resource
terraform state mv aws_instance.web aws_instance.web_server

# Remove from state (keep resource)
terraform state rm aws_instance.web

# Pull remote state
terraform state pull
```

---

## Modules

### What are Modules?

Reusable, composable infrastructure components.

**Module Structure:**
```
modules/
└── vpc/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

**VPC Module Example:**
```terraform
# modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  
  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]
  
  tags = {
    Name = "${var.name}-public-${count.index + 1}"
  }
}

# modules/vpc/variables.tf
variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
```

**Using the Module:**
```terraform
module "vpc" {
  source = "./modules/vpc"
  
  name           = "production-vpc"
  cidr_block     = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  azs            = ["us-east-1a", "us-east-1b"]
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Reference module outputs
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
  # ...
}
```

---

## Variables and Outputs

### Input Variables

```terraform
# variables.tf
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "enable_monitoring" {
  type    = bool
  default = true
}
```

**Providing Values:**
```terraform
# terraform.tfvars
environment    = "production"
instance_count = 5
instance_type  = "t3.large"

tags = {
  Project   = "MyApp"
  ManagedBy = "Terraform"
}
```

### Outputs

```terraform
# outputs.tf
output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.web[*].id
}

output "load_balancer_dns" {
  description = "DNS name of load balancer"
  value       = aws_lb.main.dns_name
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true  # Won't show in logs
}
```

---

## Best Practices

### 1. **Directory Structure**

```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   ├── compute/
│   └── database/
└── global/
    └── s3/
```

### 2. **State Locking**

```terraform
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### 3. **Use Data Sources**

```terraform
# Don't hardcode AMI IDs
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  # ...
}
```

### 4. **Use Locals for Computed Values**

```terraform
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_instance" "web" {
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web"
    }
  )
}
```

### 5. **Use Count and For_Each**

```terraform
# Count
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  tags = {
    Name = "web-${count.index + 1}"
  }
}

# For_each (more flexible)
variable "instances" {
  type = map(object({
    instance_type = string
    ami           = string
  }))
}

resource "aws_instance" "app" {
  for_each = var.instances
  
  ami           = each.value.ami
  instance_type = each.value.instance_type
  
  tags = {
    Name = each.key
  }
}
```

### 6. **Protect Critical Resources**

```terraform
resource "aws_db_instance" "production" {
  # ... configuration
  
  lifecycle {
    prevent_destroy = true  # Can't be destroyed
  }
}

resource "aws_instance" "web" {
  # ...
  
  lifecycle {
    create_before_destroy = true  # Create new before destroying old
    ignore_changes       = [tags] # Don't recreate if tags change
  }
}
```

### 7. **Use Workspaces**

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select prod

# List workspaces
terraform workspace list
```

```terraform
# Use workspace in config
resource "aws_instance" "web" {
  instance_type = terraform.workspace == "prod" ? "t3.large" : "t3.micro"
  
  tags = {
    Environment = terraform.workspace
  }
}
```

---

## Summary

**Key Takeaways:**

✅ **IaC** makes infrastructure **reproducible** and **version-controlled**
✅ **Terraform** is cloud-agnostic and declarative
✅ **State** tracks real infrastructure
✅ **Modules** enable reusable components
✅ **Remote state** with locking for team collaboration
✅ Use **workspaces** for environment separation
✅ **Plan before apply** to preview changes

**Next Steps:**
- **Next**: [11-Configuration-Management.md](./11-Configuration-Management.md)
- **Related**: [12-AWS-DevOps.md](./12-AWS-DevOps.md)

---

*Remember: Infrastructure as Code is not just automation, it's documentation!*
