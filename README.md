# 06 Task IaC Terraform - MongoDB Atlas

## Task overview

This task demonstrates how to provision MongoDB Atlas infrastructure using Terraform as an Infrastructure as Code tool.

The work was completed in three stages:

1. **Task1_1** - Create a MongoDB Atlas Project using Terraform.
2. **Task1_2** - Create a MongoDB Atlas Cluster with the required configuration.
3. **Task1_3** - Create a Database User and configure IP Access List entries.

---

## Requirements

### Task1_1

- Sign in to MongoDB Atlas.
- Generate API keys for Terraform authentication.
- Save the following values:
  - MongoDB Atlas Public Key
  - MongoDB Atlas Private Key
  - MongoDB Atlas Organization ID
- Export these values as Terraform environment variables.
- Run:

```bash
terraform init
terraform plan
terraform apply
```

### Task1_2

Create a MongoDB Atlas cluster using Terraform with the following parameters:

- Cluster name: `mycluster`
- Cloud provider: `AWS`
- Region: `US_EAST_1`
- Provider instance size: `M0`

### Task1_3

Create a MongoDB Atlas Database User and IP Access List entries:

- Username: `bob`
- Authentication database: `admin`
- Role: `readWrite`
- Database name: `db`
- IP Access List:
  - `0.0.0.0/1`
  - `128.0.0.0/1`

---

## What was implemented

The Terraform configuration provisions the following MongoDB Atlas resources:

- MongoDB Atlas Project
- MongoDB Atlas M0 Cluster
- MongoDB Atlas Database User
- MongoDB Atlas IP Access List rules

The configuration was written in two main Terraform files:

```text
main.tf
variables.tf
```

---

## Project structure

```text
terraform-mongodb-atlas/
├── .gitignore
├── .terraform.lock.hcl
├── README.md
├── main.tf
└── variables.tf
```

Terraform local files such as `.terraform/`, `terraform.tfstate`, `.tfvars`, and `.env` are excluded from Git.

---

## Environment variables

MongoDB Atlas credentials and sensitive values are not hardcoded in Terraform files.

The following environment variables are used:

```bash
export TF_VAR_MONGODB_ATLAS_PUBLIC_KEY="your_public_key"
export TF_VAR_MONGODB_ATLAS_PRIVATE_KEY="your_private_key"
export TF_VAR_MONGODB_ATLAS_ORGANIZATION_ID="your_organization_id"
export TF_VAR_MONGODB_ATLAS_DB_PASSWORD="your_database_user_password"
```

For better security, the database password can be entered silently:

```bash
read -s -p "MongoDB bob password: " TF_VAR_MONGODB_ATLAS_DB_PASSWORD
echo
export TF_VAR_MONGODB_ATLAS_DB_PASSWORD
```

---

## variables.tf

The `variables.tf` file stores input variable definitions used by Terraform.

Example:

```hcl
variable "MONGODB_ATLAS_PUBLIC_KEY" {
  description = "MongoDB Atlas Public API Key"
  type        = string
}

variable "MONGODB_ATLAS_PRIVATE_KEY" {
  description = "MongoDB Atlas Private API Key"
  type        = string
  sensitive   = true
}

variable "MONGODB_ATLAS_ORGANIZATION_ID" {
  description = "MongoDB Atlas Organization ID"
  type        = string
}

variable "MONGODB_ATLAS_DB_PASSWORD" {
  description = "Password for MongoDB Atlas database user bob"
  type        = string
  sensitive   = true
}
```

The `sensitive = true` argument helps hide sensitive values in Terraform CLI output.

---

## main.tf explanation

### 1. MongoDB Atlas provider

Terraform uses the MongoDB Atlas provider to communicate with the MongoDB Atlas API.

```hcl
provider "mongodbatlas" {
  public_key  = var.MONGODB_ATLAS_PUBLIC_KEY
  private_key = var.MONGODB_ATLAS_PRIVATE_KEY
}
```

The public and private keys are passed through environment variables.

---

### 2. MongoDB Atlas Project

The first Terraform resource creates a MongoDB Atlas project.

```hcl
resource "mongodbatlas_project" "myproject" {
  name   = "My Project"
  org_id = var.MONGODB_ATLAS_ORGANIZATION_ID
}
```

This completed **Task1_1**.

---

### 3. MongoDB Atlas Cluster

For the cluster, the newer `mongodbatlas_advanced_cluster` resource was used instead of the deprecated `mongodbatlas_cluster` resource.

```hcl
resource "mongodbatlas_advanced_cluster" "mycluster" {
  project_id   = mongodbatlas_project.myproject.id
  name         = "mycluster"
  cluster_type = "REPLICASET"

  replication_specs = [
    {
      region_configs = [
        {
          electable_specs = {
            instance_size = "M0"
          }

          provider_name         = "TENANT"
          backing_provider_name = "AWS"
          region_name           = "US_EAST_1"
          priority              = 7
        }
      ]
    }
  ]
}
```

Explanation:

- `name = "mycluster"` sets the cluster name.
- `instance_size = "M0"` creates a free-tier/shared cluster.
- `provider_name = "TENANT"` is used for shared/free-tier Atlas deployments.
- `backing_provider_name = "AWS"` selects AWS as the underlying cloud provider.
- `region_name = "US_EAST_1"` sets the required region.

This completed **Task1_2**.

---

### 4. Database user

The next resource creates the database user `bob`.

```hcl
resource "mongodbatlas_database_user" "bob" {
  username           = "bob"
  password           = var.MONGODB_ATLAS_DB_PASSWORD
  project_id         = mongodbatlas_project.myproject.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "db"
  }

  depends_on = [
    mongodbatlas_advanced_cluster.mycluster
  ]
}
```

Explanation:

- `username = "bob"` creates the required user.
- `password = var.MONGODB_ATLAS_DB_PASSWORD` keeps the password outside the main Terraform file.
- `auth_database_name = "admin"` sets the authentication database.
- `role_name = "readWrite"` gives read and write permissions.
- `database_name = "db"` limits the role to the required database.
- `depends_on` ensures that the database user is created only after the cluster is created.

This was part of **Task1_3**.

---

### 5. IP Access List

The task required opening access using two CIDR blocks:

```hcl
locals {
  cidr_block_list = [
    "0.0.0.0/1",
    "128.0.0.0/1"
  ]
}

resource "mongodbatlas_project_ip_access_list" "cidr" {
  count      = length(local.cidr_block_list)
  project_id = mongodbatlas_project.myproject.id
  cidr_block = local.cidr_block_list[count.index]
  comment    = "Allow access for Terraform MongoDB Atlas task"
}
```

Explanation:

- `locals` stores a list of CIDR blocks.
- `count` creates one IP access list entry for each CIDR block.
- `0.0.0.0/1` and `128.0.0.0/1` together cover the IPv4 address space required by the task.

This completed the IP Access List part of **Task1_3**.

---

## Terraform commands used

The following Terraform workflow was used:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### terraform init

Initializes the Terraform working directory and downloads the required provider plugins.

### terraform fmt

Formats Terraform configuration files.

### terraform validate

Validates the Terraform configuration syntax.

### terraform plan

Shows what Terraform will create, update, or destroy.

### terraform apply

Applies the Terraform configuration and creates the resources in MongoDB Atlas.

---

## Verification

After running `terraform apply`, the following resources were successfully created:

- MongoDB Atlas Project: `My Project`
- MongoDB Atlas Cluster: `mycluster`
- Database User: `bob`
- User role: `readWrite@db`
- IP Access List entries:
  - `0.0.0.0/1`
  - `128.0.0.0/1`

Terraform output confirmed:

```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

A final verification was performed using:

```bash
terraform plan
```

Expected result:

```text
No changes. Your infrastructure matches the configuration.
```

---

## Security notes

Secrets are not stored directly in the Terraform configuration files.

The following files and directories are excluded from Git:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
.env
```

Important note: even when variables are marked as `sensitive`, Terraform state may still contain sensitive values. Because of this, Terraform state files must not be committed to GitHub.

---

## Result

The task was successfully completed.

Terraform was used to create and manage MongoDB Atlas infrastructure as code:

- Project creation
- Cluster provisioning
- Database user creation
- Network access configuration

This repository contains the final Terraform configuration for the MongoDB Atlas IaC task.
