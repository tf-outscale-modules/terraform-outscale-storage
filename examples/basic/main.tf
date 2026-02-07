terraform {
  required_version = ">= 1.5"

  required_providers {
    outscale = {
      source  = "outscale/outscale"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Outscale provider for BSU volumes, snapshots, and images
provider "outscale" {
  access_key_id = var.access_key_id
  secret_key_id = var.secret_key_id
  region        = var.region
}

# AWS provider configured for Outscale OOS (S3-compatible)
provider "aws" {
  region     = var.region
  access_key = var.access_key_id
  secret_key = var.secret_key_id

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  endpoints {
    s3 = "https://oos.${var.region}.outscale.com"
  }
}

module "storage" {
  source = "../../"

  project_name = "my-project"
  environment  = "dev"

  # Enable volumes
  enable_volume = true
  volumes = {
    data = {
      subregion_name = "${var.region}a"
      size           = 50
      volume_type    = "gp2"
    }
  }

  # Enable snapshots
  enable_snapshot = true
  snapshots = {
    data_backup = {
      volume_key  = "data"
      description = "Daily backup of data volume"
    }
  }

  # Enable OOS
  enable_oos = true
  oos_buckets = {
    assets = {
      bucket = "my-project-dev-assets"
    }
  }

  tags = {
    Team = "platform"
  }
}
