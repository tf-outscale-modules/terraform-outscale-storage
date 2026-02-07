# Outscale Storage Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Outscale Provider][provider-badge]][provider-url]
[![Latest Release][release-badge]][release-url]

Terraform module for managing all Outscale cloud storage resources: BSU volumes, snapshots, images (OMI), and S3-compatible Object Storage (OOS).

## Features

- **BSU Volumes** — Create and attach block storage volumes (standard, gp2, io1) with configurable sizes and IOPS
- **Snapshots** — Create, copy, and export BSU snapshots with cross-volume references
- **Images (OMI)** — Create, copy, and export machine images with block device mappings
- **Object Storage (OOS)** — Manage S3-compatible buckets and objects via the AWS provider
- **Feature Flags** — Enable only the resources you need with `enable_*` variables
- **Cross-referencing** — Use `_key` pattern to reference resources within the module or `_id` for external resources
- **Consistent Tagging** — Common tags (Project, Environment, ManagedBy) automatically applied to all resources

## Requirements

| Name | Version |
|------|---------|
| [terraform](#requirement\_terraform) | >= 1.5 |
| [outscale](#requirement\_outscale) | ~> 1.0 |
| [aws](#requirement\_aws) | ~> 5.0 |

## Usage

### Basic Example

```hcl
module "storage" {
  source = "gitlab.com/leminnov/terraform/modules/outscale-storage"

  project_name = "my-project"
  environment  = "dev"

  enable_volume = true
  volumes = {
    data = {
      subregion_name = "eu-west-2a"
      size           = 50
      volume_type    = "gp2"
    }
  }
}
```

### Complete Example

```hcl
module "storage" {
  source = "gitlab.com/leminnov/terraform/modules/outscale-storage"

  project_name = "my-project"
  environment  = "prod"

  # Volumes
  enable_volume = true
  volumes = {
    data = {
      subregion_name = "eu-west-2a"
      size           = 100
      volume_type    = "io1"
      iops           = 3000
    }
  }
  volume_links = {
    data_attach = {
      device_name = "/dev/sdb"
      vm_id       = "i-12345678"
      volume_key  = "data"
    }
  }

  # Snapshots
  enable_snapshot = true
  snapshots = {
    data_backup = {
      volume_key  = "data"
      description = "Daily backup"
    }
  }

  # OOS
  enable_oos = true
  oos_buckets = {
    backups = {
      bucket = "my-project-prod-backups"
    }
  }

  tags = {
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

### Conditional Creation

All resources are disabled by default. Enable only what you need:

```hcl
module "storage" {
  source = "gitlab.com/leminnov/terraform/modules/outscale-storage"

  project_name = "my-project"
  environment  = "dev"

  # Only create OOS buckets — no volumes, snapshots, or images
  enable_oos = true
  oos_buckets = {
    assets = {
      bucket = "my-project-dev-assets"
    }
  }
}
```

## Security Considerations

1. **Sensitive variables** — Export API keys (`snapshot_export_osu_api_key`, `image_export_osu_api_key`) are marked as `sensitive` and should be provided via environment variables or CI/CD secrets
2. **State encryption** — Always use encrypted remote state backends when managing storage resources
3. **Least privilege** — Configure Outscale API keys with minimum required permissions for the resources being managed
4. **No hardcoded secrets** — Never commit API keys or credentials to `.tf` or `.tfvars` files

## Known Limitations

1. **No `snapshot_import_task` resource** — The Outscale provider does not support this resource type; use `outscale_snapshot` with `file_location` and `snapshot_size` arguments to import from a bucket
2. **OOS requires AWS provider** — Outscale OOS uses S3-compatible API, requiring the `hashicorp/aws` provider configured with custom endpoints
3. **Tag format differences** — Outscale resources use `tags { key, value }` blocks while OOS (AWS) resources use `tags = {}` maps; this is handled transparently by the module

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Documentation

| Document | Description |
|----------|-------------|
| [README](README.md) | Module overview and usage |
| [CHANGELOG](CHANGELOG.md) | Release history |

## Contributing

Contributions are welcome. Please ensure:

1. All code passes `terraform fmt -check`
2. All variables and outputs have descriptions
3. Tests pass with `terraform test`
4. Pre-commit hooks pass with `pre-commit run -a`

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.

## Disclaimer

This module is provided "as is", without warranty of any kind, express or implied. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.5-623CE4
[terraform-url]: https://www.terraform.io

[provider-badge]: https://img.shields.io/badge/Outscale%20Provider-~%3E1.0-blue
[provider-url]: https://registry.terraform.io/providers/outscale/outscale/latest

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/outscale-storage?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/outscale-storage/-/releases
