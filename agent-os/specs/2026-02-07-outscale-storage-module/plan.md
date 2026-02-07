# Plan: Outscale Storage Terraform Module — Full Implementation

## Context

This is a greenfield Terraform module repository for Outscale cloud storage. All standards, product docs, and tooling conventions are defined in `agent-os/`, but no Terraform code exists yet. The goal is to implement a single flat module covering **all** Outscale storage features: BSU volumes, snapshots, images (OMI), and S3-compatible Object Storage (OOS).

### Key Decisions

- **Single flat module** with `enable_*` feature flags (all default `false`)
- **Dual providers**: `outscale/outscale` for BSU resources + `hashicorp/aws` for OOS (S3-compatible)
- **`_key` pattern** for cross-references: variables accept both a `volume_key` (referencing another map key in the module) and a direct `volume_id` for external resources
- **No `snapshot_import_task`** resource — it doesn't exist in the Outscale provider; import from bucket is handled via `outscale_snapshot`'s `file_location`/`snapshot_size` args
- **Outscale tags vs AWS tags**: Outscale uses repeated `tags { key, value }` blocks; AWS uses `tags = {}` maps — handled transparently per resource file
- Resource files split by domain: `volumes.tf`, `snapshots.tf`, `images.tf`, `oos.tf`

### Outscale Storage Resources Covered

| Resource | Provider | Purpose |
|----------|----------|---------|
| `outscale_volume` | outscale | BSU volume (standard/gp2/io1) |
| `outscale_volume_link` | outscale | Attach volume to VM |
| `outscale_snapshot` | outscale | Create/copy snapshots |
| `outscale_snapshot_export_task` | outscale | Export snapshot to OOS bucket |
| `outscale_image` | outscale | Create/copy OMI images |
| `outscale_image_export_task` | outscale | Export image to OOS bucket |
| `aws_s3_bucket` | aws | OOS bucket (S3-compatible) |
| `aws_s3_object` | aws | OOS object |

## Tasks

Tasks 1-13 covering spec docs, scaffolding, versions.tf, variables.tf, locals.tf, volumes.tf, snapshots.tf, images.tf, oos.tf, outputs.tf, examples, tests, and README.
