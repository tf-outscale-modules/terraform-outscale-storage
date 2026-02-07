# Shaping Notes: Outscale Storage Module

## Scope

Single flat Terraform module covering all Outscale storage features:

- **BSU Volumes** — Create, attach, manage block storage with type selection (standard, gp2, io1)
- **Snapshots** — Create, copy, export BSU snapshots
- **Images (OMI)** — Create, copy, export machine images
- **Object Storage (OOS)** — S3-compatible bucket and object management

## Key Decisions

1. **Single flat module** with `enable_*` feature flags (all default `false`) rather than nested submodules
2. **Dual providers**: `outscale/outscale` for BSU resources + `hashicorp/aws` for OOS (S3-compatible API)
3. **`_key` pattern** for cross-references: variables accept both a `volume_key` (referencing another map key in the module) and a direct `volume_id` for external resources
4. **No `snapshot_import_task`** resource — it doesn't exist in the Outscale provider; import from bucket is handled via `outscale_snapshot`'s `file_location`/`snapshot_size` args
5. **Outscale tags vs AWS tags**: Outscale uses repeated `tags { key, value }` blocks; AWS uses `tags = {}` maps — handled transparently per resource file
6. **Resource files split by domain**: `volumes.tf`, `snapshots.tf`, `images.tf`, `oos.tf`

## Context

- Target cloud: Outscale (3DS OUTSCALE)
- Provider: `outscale/outscale` ~> 1.0
- OOS uses AWS S3 API compatibility, requiring `hashicorp/aws` ~> 5.0 with custom endpoints
- All standards, product docs, and tooling conventions defined in `agent-os/`
