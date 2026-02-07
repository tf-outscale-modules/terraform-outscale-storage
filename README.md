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
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_outscale"></a> [outscale](#requirement\_outscale) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_outscale"></a> [outscale](#provider\_outscale) | ~> 1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [outscale_image.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/image) | resource |
| [outscale_image_export_task.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/image_export_task) | resource |
| [outscale_snapshot.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/snapshot) | resource |
| [outscale_snapshot_export_task.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/snapshot_export_task) | resource |
| [outscale_volume.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/volume) | resource |
| [outscale_volume_link.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/volume_link) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_image"></a> [enable\_image](#input\_enable\_image) | Enable image (OMI) resources. | `bool` | `false` | no |
| <a name="input_enable_oos"></a> [enable\_oos](#input\_enable\_oos) | Enable OOS (S3-compatible object storage) resources. | `bool` | `false` | no |
| <a name="input_enable_snapshot"></a> [enable\_snapshot](#input\_enable\_snapshot) | Enable snapshot resources. | `bool` | `false` | no |
| <a name="input_enable_volume"></a> [enable\_volume](#input\_enable\_volume) | Enable BSU volume resources. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment. Valid values: dev, staging, prod. | `string` | n/a | yes |
| <a name="input_image_export_osu_api_key"></a> [image\_export\_osu\_api\_key](#input\_image\_export\_osu\_api\_key) | OSU API key for image export tasks. Required when image\_export\_tasks is non-empty. | <pre>object({<br/>    api_key_id = string<br/>    secret_key = string<br/>  })</pre> | `null` | no |
| <a name="input_image_export_tasks"></a> [image\_export\_tasks](#input\_image\_export\_tasks) | Map of image export tasks. Use image\_key to reference an image from the images map, or image\_id for an external image. | <pre>map(object({<br/>    image_key         = optional(string)<br/>    image_id          = optional(string)<br/>    disk_image_format = string<br/>    osu_bucket        = string<br/>    osu_prefix        = optional(string)<br/>    tags              = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_images"></a> [images](#input\_images) | Map of images (OMI) to create. Specify vm\_id to create from a running VM, or source\_image\_id to copy an existing image. | <pre>map(object({<br/>    image_name         = string<br/>    description        = optional(string)<br/>    vm_id              = optional(string)<br/>    source_image_id    = optional(string)<br/>    source_region_name = optional(string)<br/>    no_reboot          = optional(bool)<br/>    block_device_mappings = optional(list(object({<br/>      device_name         = optional(string)<br/>      virtual_device_name = optional(string)<br/>      bsu = optional(object({<br/>        delete_on_vm_deletion = optional(bool)<br/>        iops                  = optional(number)<br/>        snapshot_id           = optional(string)<br/>        volume_size           = optional(number)<br/>        volume_type           = optional(string)<br/>      }))<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_oos_buckets"></a> [oos\_buckets](#input\_oos\_buckets) | Map of OOS (S3-compatible) buckets to create. | <pre>map(object({<br/>    bucket        = string<br/>    force_destroy = optional(bool, false)<br/>    tags          = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_oos_objects"></a> [oos\_objects](#input\_oos\_objects) | Map of OOS objects to create. Use bucket\_key to reference a bucket from the oos\_buckets map, or bucket for an external bucket name. | <pre>map(object({<br/>    bucket_key = optional(string)<br/>    bucket     = optional(string)<br/>    key        = string<br/>    source     = optional(string)<br/>    content    = optional(string)<br/>    tags       = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project. Used in resource naming and tagging. | `string` | n/a | yes |
| <a name="input_snapshot_export_osu_api_key"></a> [snapshot\_export\_osu\_api\_key](#input\_snapshot\_export\_osu\_api\_key) | OSU API key for snapshot export tasks. Required when snapshot\_export\_tasks is non-empty. | <pre>object({<br/>    api_key_id = string<br/>    secret_key = string<br/>  })</pre> | `null` | no |
| <a name="input_snapshot_export_tasks"></a> [snapshot\_export\_tasks](#input\_snapshot\_export\_tasks) | Map of snapshot export tasks. Use snapshot\_key to reference a snapshot from the snapshots map, or snapshot\_id for an external snapshot. | <pre>map(object({<br/>    snapshot_key      = optional(string)<br/>    snapshot_id       = optional(string)<br/>    disk_image_format = string<br/>    osu_bucket        = string<br/>    osu_prefix        = optional(string)<br/>    tags              = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_snapshots"></a> [snapshots](#input\_snapshots) | Map of snapshots to create. Use volume\_key to reference a volume from the volumes map, or volume\_id for an external volume. Set source\_snapshot\_id to copy an existing snapshot. | <pre>map(object({<br/>    description        = optional(string)<br/>    volume_key         = optional(string)<br/>    volume_id          = optional(string)<br/>    source_snapshot_id = optional(string)<br/>    source_region_name = optional(string)<br/>    file_location      = optional(string)<br/>    snapshot_size      = optional(number)<br/>    tags               = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources. Merged with common tags (Project, Environment, ManagedBy). | `map(string)` | `{}` | no |
| <a name="input_volume_links"></a> [volume\_links](#input\_volume\_links) | Map of volume-to-VM attachments. Use volume\_key to reference a volume from the volumes map, or volume\_id for an external volume. | <pre>map(object({<br/>    device_name = string<br/>    vm_id       = string<br/>    volume_key  = optional(string)<br/>    volume_id   = optional(string)<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Map of BSU volumes to create. Each key is a logical name used for cross-referencing. | <pre>map(object({<br/>    subregion_name = string<br/>    size           = number<br/>    volume_type    = optional(string, "standard")<br/>    iops           = optional(number)<br/>    snapshot_id    = optional(string)<br/>    tags           = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_export_task_ids"></a> [image\_export\_task\_ids](#output\_image\_export\_task\_ids) | Map of image export task keys to their IDs. |
| <a name="output_image_ids"></a> [image\_ids](#output\_image\_ids) | Map of image keys to their IDs. |
| <a name="output_oos_bucket_arns"></a> [oos\_bucket\_arns](#output\_oos\_bucket\_arns) | Map of OOS bucket keys to their ARNs. |
| <a name="output_oos_bucket_ids"></a> [oos\_bucket\_ids](#output\_oos\_bucket\_ids) | Map of OOS bucket keys to their IDs. |
| <a name="output_oos_object_ids"></a> [oos\_object\_ids](#output\_oos\_object\_ids) | Map of OOS object keys to their IDs. |
| <a name="output_snapshot_export_task_ids"></a> [snapshot\_export\_task\_ids](#output\_snapshot\_export\_task\_ids) | Map of snapshot export task keys to their IDs. |
| <a name="output_snapshot_ids"></a> [snapshot\_ids](#output\_snapshot\_ids) | Map of snapshot keys to their IDs. |
| <a name="output_volume_details"></a> [volume\_details](#output\_volume\_details) | Map of volume keys to their details (id, size, type, iops, state, subregion). |
| <a name="output_volume_ids"></a> [volume\_ids](#output\_volume\_ids) | Map of volume keys to their IDs. |
| <a name="output_volume_link_states"></a> [volume\_link\_states](#output\_volume\_link\_states) | Map of volume link keys to their state. |
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
