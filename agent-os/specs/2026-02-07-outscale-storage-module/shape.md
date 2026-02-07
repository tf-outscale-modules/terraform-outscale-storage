# Shaping Notes: Outscale Storage Module

## Scope

Single flat Terraform module covering Outscale block storage features:

- **BSU Volumes** — Create, attach, manage block storage with type selection (standard, gp2, io1)
- **Snapshots** — Create, copy, export BSU snapshots
- **Images (OMI)** — Create, copy, export machine images

## Key Decisions

1. **Single flat module** with `enable_*` feature flags (all default `false`) rather than nested submodules
2. **Single provider**: `outscale/outscale` only (OOS removed — out of scope)
3. **`_key` pattern** for cross-references: variables accept both a `volume_key` (referencing another map key in the module) and a direct `volume_id` for external resources
4. **No `snapshot_import_task`** resource — it doesn't exist in the Outscale provider; import from bucket is handled via `outscale_snapshot`'s `file_location`/`snapshot_size` args
5. **Outscale tags**: uses repeated `tags { key, value }` blocks (not AWS-style `tags = {}` maps)
6. **Resource files split by domain**: `volumes.tf`, `snapshots.tf`, `images.tf`

## Context

- Target cloud: Outscale (3DS OUTSCALE)
- Provider: `outscale/outscale` ~> 1.0
- All standards, product docs, and tooling conventions defined in `agent-os/`
